local DECOMPILER_V3 = "3.0.0"

local DecompilerCore = {}
local cache = {}
local stats = {total = 0, success = 0, cached = 0}

local decompilers = {}

local function initDecompilers()
	local funcs = {
		decompile, Decompile, decompile_script, 
		syn and syn.decompile,
		debug and debug.getinfo and function(s) return debug.getinfo(s).source end
	}
	
	for _, func in pairs(funcs) do
		if func then table.insert(decompilers, func) end
	end
end

local function hashScript(script)
	local bc = getscriptbytecode and getscriptbytecode(script)
	if bc then
		local h = 0
		for i = 1, math.min(#bc, 1000) do
			h = (h * 31 + string.byte(bc, i)) % 2147483647
		end
		return tostring(h)
	end
	return script:GetFullName() .. tostring(tick())
end

function DecompilerCore.decompile(script)
	stats.total = stats.total + 1
	
	local hash = hashScript(script)
	if cache[hash] and tick() - cache[hash].time < 600 then
		stats.cached = stats.cached + 1
		return cache[hash].source
	end
	
	local scr = script
	if script:IsA("LocalScript") and script.Parent then
		script.Archivable = true
		scr = script:Clone()
		scr.Disabled = true
		scr.Parent = nil
	end
	
	for _, decomp in pairs(decompilers) do
		local src = decomp(scr)
		if src and #src > 0 then
			stats.success = stats.success + 1
			cache[hash] = {source = src, time = tick()}
			return src
		end
	end
	
	if scr.Source and #scr.Source > 0 then
		stats.success = stats.success + 1
		return scr.Source
	end
	
	return string.format("-- Failed to decompile %s\n-- Path: %s", script.Name, script:GetFullName())
end

function DecompilerCore.batchDecompile(scripts, callback)
	local results = {}
	for i, script in pairs(scripts) do
		results[script] = DecompilerCore.decompile(script)
		if callback then callback(i, #scripts) end
	end
	return results
end

function DecompilerCore.dumpAll(root)
	local scripts = {}
	local function scan(obj)
		for _, child in pairs(obj:GetChildren()) do
			if child:IsA("LuaSourceContainer") then
				table.insert(scripts, child)
			end
			scan(child)
		end
	end
	scan(root or game)
	return DecompilerCore.batchDecompile(scripts)
end

function DecompilerCore.clearCache()
	cache = {}
end

local RemoteSpy = {}
local remoteHooks = {}
local remoteLogs = {}

function RemoteSpy.hook(remote)
	if remoteHooks[remote] then return end
	
	local oldFireServer = remote.FireServer
	local oldInvokeServer = remote.InvokeServer
	
	if remote:IsA("RemoteEvent") then
		remoteHooks[remote] = hookfunction(oldFireServer, function(self, ...)
			local args = {...}
			table.insert(remoteLogs, {
				remote = remote:GetFullName(),
				type = "RemoteEvent",
				args = args,
				time = tick()
			})
			return oldFireServer(self, ...)
		end)
	elseif remote:IsA("RemoteFunction") then
		remoteHooks[remote] = hookfunction(oldInvokeServer, function(self, ...)
			local args = {...}
			local result = {oldInvokeServer(self, ...)}
			table.insert(remoteLogs, {
				remote = remote:GetFullName(),
				type = "RemoteFunction",
				args = args,
				result = result,
				time = tick()
			})
			return unpack(result)
		end)
	end
end

function RemoteSpy.hookAll()
	for _, remote in pairs(game:GetDescendants()) do
		if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
			RemoteSpy.hook(remote)
		end
	end
end

function RemoteSpy.getLogs()
	return remoteLogs
end

function RemoteSpy.clearLogs()
	remoteLogs = {}
end

local InstanceUtils = {}

function InstanceUtils.getPath(obj)
	if obj == game:GetService("Players").LocalPlayer then 
		return 'game.Players.LocalPlayer'
	end
	
	local path = {}
	local curr = obj
	
	while curr and curr ~= game do
		table.insert(path, 1, curr)
		curr = curr.Parent
	end
	
	if #path == 0 then return "nil" end
	
	local result = path[1].ClassName == "Workspace" and "workspace" or 'game:GetService("' .. path[1].ClassName .. '")'
	
	for i = 2, #path do
		local safe = path[i].Name:match("^[%a_][%w_]*$")
		if safe and path[i].Parent:FindFirstChild(path[i].Name) == path[i] then
			result = result .. "." .. path[i].Name
		else
			result = result .. ':FindFirstChild("' .. path[i].Name .. '")'
		end
	end
	
	return result
end

function InstanceUtils.clone(obj, stripScripts)
	obj.Archivable = true
	local copy = obj:Clone()
	
	if stripScripts then
		for _, script in pairs(copy:GetDescendants()) do
			if script:IsA("LuaSourceContainer") then
				script:Destroy()
			end
		end
	end
	
	return copy
end

function InstanceUtils.getProperties(obj)
	local props = {}
	
	if gethiddenproperty and sethiddenproperty then
		for _, prop in pairs(getproperties(obj)) do
			props[prop] = gethiddenproperty(obj, prop)
		end
	end
	
	return props
end

function InstanceUtils.getConnections(obj)
	local connections = {}
	
	if getconnections then
		for _, signal in pairs({"Changed", "ChildAdded", "ChildRemoved", "DescendantAdded", "DescendantRemoving"}) do
			local success = pcall(function()
				local cons = getconnections(obj[signal])
				if cons and #cons > 0 then
					connections[signal] = cons
				end
			end)
		end
	end
	
	return connections
end

local ScriptDumper = {}

function ScriptDumper.dumpScript(script, includeMeta)
	local src = DecompilerCore.decompile(script)
	
	if not includeMeta then return src end
	
	local meta = string.format([[
-- %s
-- Type: %s
-- Path: %s
-- Enabled: %s
-- RunContext: %s

]], 
		script.Name,
		script.ClassName,
		InstanceUtils.getPath(script),
		not script.Disabled,
		script.RunContext or "Legacy"
	)
	
	return meta .. src
end

function ScriptDumper.dumpToFolder(root, folderPath)
	local scripts = {}
	local function scan(obj)
		for _, child in pairs(obj:GetChildren()) do
			if child:IsA("LuaSourceContainer") then
				table.insert(scripts, child)
			end
			scan(child)
		end
	end
	scan(root)
	
	for _, script in pairs(scripts) do
		local src = ScriptDumper.dumpScript(script, true)
		local path = folderPath .. "/" .. script.ClassName .. "_" .. script.Name .. ".lua"
		writefile(path, src)
	end
	
	return #scripts
end

function ScriptDumper.dumpToClipboard(scripts)
	local output = {}
	for _, script in pairs(scripts) do
		table.insert(output, ScriptDumper.dumpScript(script, true))
		table.insert(output, "\n" .. string.rep("-", 80) .. "\n")
	end
	
	local full = table.concat(output)
	
	if setclipboard then
		setclipboard(full)
		return true
	elseif Clipboard and Clipboard.set then
		Clipboard.set(full)
		return true
	end
	
	return false
end

local BytecodeAnalyzer = {}

function BytecodeAnalyzer.getSize(script)
	local bc = getscriptbytecode and getscriptbytecode(script)
	return bc and #bc or 0
end

function BytecodeAnalyzer.getHash(script)
	return hashScript(script)
end

function BytecodeAnalyzer.compare(script1, script2)
	return hashScript(script1) == hashScript(script2)
end

function BytecodeAnalyzer.analyze(script)
	local src = DecompilerCore.decompile(script)
	local lines = string.split(src, "\n")
	
	local analysis = {
		lines = #lines,
		chars = #src,
		functions = 0,
		loops = 0,
		conditionals = 0,
		remotes = 0,
		bytecodeSize = BytecodeAnalyzer.getSize(script)
	}
	
	for _, line in pairs(lines) do
		if line:match("function") then analysis.functions = analysis.functions + 1 end
		if line:match("for%s+") or line:match("while%s+") or line:match("repeat") then 
			analysis.loops = analysis.loops + 1 
		end
		if line:match("if%s+") then analysis.conditionals = analysis.conditionals + 1 end
		if line:match("FireServer") or line:match("InvokeServer") then 
			analysis.remotes = analysis.remotes + 1 
		end
	end
	
	return analysis
end

local GameExplorer = {}

function GameExplorer.findScripts(pattern)
	local results = {}
	for _, script in pairs(game:GetDescendants()) do
		if script:IsA("LuaSourceContainer") then
			if pattern then
				if script.Name:lower():match(pattern:lower()) then
					table.insert(results, script)
				end
			else
				table.insert(results, script)
			end
		end
	end
	return results
end

function GameExplorer.findRemotes()
	local remotes = {}
	for _, obj in pairs(game:GetDescendants()) do
		if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
			table.insert(remotes, obj)
		end
	end
	return remotes
end

function GameExplorer.findByClass(className)
	return game:GetDescendants():FindFirstChild(className)
end

function GameExplorer.getGameInfo()
	return {
		placeId = game.PlaceId,
		jobId = game.JobId,
		creator = game.CreatorId,
		players = #game.Players:GetPlayers(),
		scripts = #GameExplorer.findScripts(),
		remotes = #GameExplorer.findRemotes()
	}
end

local SaveInstance = {}

function SaveInstance.save(obj, filename)
	if saveinstance then
		saveinstance(obj, filename)
		return true
	elseif syn and syn.save_instance then
		syn.save_instance(obj, filename)
		return true
	end
	return false
end

function SaveInstance.saveGame(filename)
	return SaveInstance.save(game, filename or "game_" .. game.PlaceId .. ".rbxl")
end

function SaveInstance.saveWorkspace(filename)
	return SaveInstance.save(workspace, filename or "workspace_" .. game.PlaceId .. ".rbxm")
end

local UniversalSpy = {}
local originalNamecall
local namecallLogs = {}

function UniversalSpy.hook()
	if not originalNamecall then
		originalNamecall = hookmetamethod(game, "__namecall", function(self, ...)
			local method = getnamecallmethod()
			local args = {...}
			
			if method == "FireServer" or method == "InvokeServer" then
				table.insert(namecallLogs, {
					object = tostring(self),
					method = method,
					args = args,
					time = os.date("%X")
				})
			end
			
			return originalNamecall(self, ...)
		end)
	end
end

function UniversalSpy.unhook()
	if originalNamecall then
		hookmetamethod(game, "__namecall", originalNamecall)
		originalNamecall = nil
	end
end

function UniversalSpy.getLogs()
	return namecallLogs
end

function UniversalSpy.clearLogs()
	namecallLogs = {}
end

local ScriptScanner = {}

function ScriptScanner.findAntiCheat()
	local suspects = {}
	local patterns = {"anticheat", "anticheats", "ac", "detection", "detect", "security", "ban", "kick"}
	
	for _, script in pairs(GameExplorer.findScripts()) do
		local name = script.Name:lower()
		for _, pattern in pairs(patterns) do
			if name:match(pattern) then
				table.insert(suspects, script)
				break
			end
		end
	end
	
	return suspects
end

function ScriptScanner.findLocalScripts()
	local locals = {}
	for _, script in pairs(game:GetDescendants()) do
		if script:IsA("LocalScript") then
			table.insert(locals, script)
		end
	end
	return locals
end

function ScriptScanner.findModuleScripts()
	local modules = {}
	for _, script in pairs(game:GetDescendants()) do
		if script:IsA("ModuleScript") then
			table.insert(modules, script)
		end
	end
	return modules
end

function ScriptScanner.analyzeAll()
	local results = {
		localScripts = {},
		moduleScripts = {},
		suspicious = {},
		total = 0
	}
	
	for _, script in pairs(GameExplorer.findScripts()) do
		results.total = results.total + 1
		
		if script:IsA("LocalScript") then
			table.insert(results.localScripts, script)
		elseif script:IsA("ModuleScript") then
			table.insert(results.moduleScripts, script)
		end
		
		local name = script.Name:lower()
		if name:match("anti") or name:match("detect") or name:match("security") then
			table.insert(results.suspicious, script)
		end
	end
	
	return results
end

local EnvironmentInfo = {}

function EnvironmentInfo.check()
	return {
		executor = identifyexecutor and identifyexecutor() or "Unknown",
		decompiler = decompile and "Available" or "None",
		saveinstance = saveinstance and "Available" or "None",
		hookfunction = hookfunction and "Available" or "None",
		hookmetamethod = hookmetamethod and "Available" or "None",
		getscriptbytecode = getscriptbytecode and "Available" or "None",
		getconnections = getconnections and "Available" or "None",
		gethiddenproperty = gethiddenproperty and "Available" or "None",
		setclipboard = setclipboard and "Available" or "None"
	}
end

function EnvironmentInfo.printInfo()
	local info = EnvironmentInfo.check()
	print("=== Executor Environment ===")
	for k, v in pairs(info) do
		print(string.format("%s: %s", k, v))
	end
end

initDecompilers()

getgenv().Dex = {
	decompile = DecompilerCore.decompile,
	batchDecompile = DecompilerCore.batchDecompile,
	dumpAll = DecompilerCore.dumpAll,
	clearCache = DecompilerCore.clearCache,
	
	RemoteSpy = RemoteSpy,
	InstanceUtils = InstanceUtils,
	ScriptDumper = ScriptDumper,
	BytecodeAnalyzer = BytecodeAnalyzer,
	GameExplorer = GameExplorer,
	SaveInstance = SaveInstance,
	UniversalSpy = UniversalSpy,
	ScriptScanner = ScriptScanner,
	EnvironmentInfo = EnvironmentInfo,
	
	getStats = function() return stats end,
	version = DECOMPILER_V3
}

print("=== DEX Enhanced " .. DECOMPILER_V3 .. " ===")
print("Decompilers loaded:", #decompilers)
EnvironmentInfo.printInfo()
print("Usage: getgenv().Dex")

return getgenv().Dex
