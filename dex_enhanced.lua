local SCRIPT_VERSION = "3.0.0"
local SCRIPT_AUTHOR = "Enhanced by Capy | Original by Moon"

type DecompileResult = {
	success: boolean,
	source: string?,
	error: string?,
	method: string?,
	timestamp: number,
	bytecodeHash: string?
}

type ScriptCache = {
	[Instance]: DecompileResult
}

local DecompilerCore = {}
DecompilerCore.__index = DecompilerCore

local ScriptAnalyzer = {}
ScriptAnalyzer.__index = ScriptAnalyzer

local SyntaxHighlighter = {}
SyntaxHighlighter.__index = SyntaxHighlighter

local function CreateDecompilerCore()
	local self = setmetatable({}, DecompilerCore)
	self.cache = {} :: ScriptCache
	self.stats = {
		totalDecompiled = 0,
		successful = 0,
		failed = 0,
		cached = 0
	}
	self.decompilerFunctions = {}
	self:RegisterDecompilers()
	return self
end

function DecompilerCore:RegisterDecompilers()
	local decompilers = {
		{name = "decompile", func = getgenv().decompile or decompile},
		{name = "Decompile", func = getgenv().Decompile or Decompile},
		{name = "decompile_script", func = getgenv().decompile_script},
		{name = "get_script_function", func = getgenv().get_script_function},
		{name = "getscriptbytecode", func = getgenv().getscriptbytecode}
	}
	
	for _, decomp in ipairs(decompilers) do
		if decomp.func and type(decomp.func) == "function" then
			table.insert(self.decompilerFunctions, {
				name = decomp.name,
				func = decomp.func,
				priority = _ == 1 and 10 or 5
			})
		end
	end
	
	table.sort(self.decompilerFunctions, function(a, b)
		return a.priority > b.priority
	end)
end

function DecompilerCore:GenerateBytecodeHash(script: Instance): string
	local success, bytecode = pcall(function()
		if getscriptbytecode then
			return getscriptbytecode(script)
		end
		return tostring(script:GetFullName())
	end)
	
	if success and bytecode then
		local hash = 0
		for i = 1, #bytecode do
			hash = (hash * 31 + string.byte(bytecode, i)) % 2147483647
		end
		return tostring(hash)
	end
	
	return tostring(tick())
end

function DecompilerCore:GetFromCache(script: Instance): DecompileResult?
	local hash = self:GenerateBytecodeHash(script)
	for cachedScript, result in pairs(self.cache) do
		if cachedScript == script or result.bytecodeHash == hash then
			if tick() - result.timestamp < 300 then
				self.stats.cached = self.stats.cached + 1
				return result
			else
				self.cache[cachedScript] = nil
			end
		end
	end
	return nil
end

function DecompilerCore:SaveToCache(script: Instance, result: DecompileResult)
	if #self.cache > 100 then
		local oldest = nil
		local oldestTime = math.huge
		for cachedScript, cachedResult in pairs(self.cache) do
			if cachedResult.timestamp < oldestTime then
				oldestTime = cachedResult.timestamp
				oldest = cachedScript
			end
		end
		if oldest then
			self.cache[oldest] = nil
		end
	end
	
	self.cache[script] = result
end

function DecompilerCore:Decompile(script: Instance): DecompileResult
	self.stats.totalDecompiled = self.stats.totalDecompiled + 1
	
	local cached = self:GetFromCache(script)
	if cached then
		return cached
	end
	
	local result: DecompileResult = {
		success = false,
		source = nil,
		error = nil,
		method = nil,
		timestamp = tick(),
		bytecodeHash = self:GenerateBytecodeHash(script)
	}
	
	if not script or not script:IsA("LuaSourceContainer") then
		result.error = "Invalid script object"
		self.stats.failed = self.stats.failed + 1
		return result
	end
	
	local scriptClone = script
	if script:IsA("LocalScript") and script.Parent then
		local success, clone = pcall(function()
			script.Archivable = true
			local cloned = script:Clone()
			cloned.Disabled = true
			return cloned
		end)
		if success and clone then
			scriptClone = clone
		end
	end
	
	for _, decomp in ipairs(self.decompilerFunctions) do
		local success, source = pcall(function()
			return decomp.func(scriptClone)
		end)
		
		if success and source and type(source) == "string" and #source > 0 then
			result.success = true
			result.source = source
			result.method = decomp.name
			self.stats.successful = self.stats.successful + 1
			self:SaveToCache(script, result)
			return result
		end
	end
	
	local fallbackSuccess, fallbackSource = pcall(function()
		if scriptClone:IsA("LocalScript") or scriptClone:IsA("ModuleScript") then
			return scriptClone.Source
		end
		return nil
	end)
	
	if fallbackSuccess and fallbackSource and #fallbackSource > 0 then
		result.success = true
		result.source = fallbackSource
		result.method = "Source Property (Fallback)"
		self.stats.successful = self.stats.successful + 1
		self:SaveToCache(script, result)
		return result
	end
	
	result.error = "All decompiler methods failed"
	result.source = string.format(
		"-- Failed to decompile %s\n-- Script: %s\n-- ClassName: %s\n-- Error: %s",
		script.Name,
		script:GetFullName(),
		script.ClassName,
		result.error
	)
	self.stats.failed = self.stats.failed + 1
	
	return result
end

function DecompilerCore:BatchDecompile(scripts: {Instance}, progressCallback: ((number, number) -> ())?)
	local results = {}
	local total = #scripts
	
	for i, script in ipairs(scripts) do
		results[script] = self:Decompile(script)
		if progressCallback then
			task.spawn(progressCallback, i, total)
		end
	end
	
	return results
end

function DecompilerCore:GetStats()
	return {
		total = self.stats.totalDecompiled,
		successful = self.stats.successful,
		failed = self.stats.failed,
		cached = self.stats.cached,
		successRate = self.stats.totalDecompiled > 0 and 
			(self.stats.successful / self.stats.totalDecompiled * 100) or 0,
		cacheSize = 0
	}
end

function DecompilerCore:ClearCache()
	self.cache = {}
end

function ScriptAnalyzer.new()
	local self = setmetatable({}, ScriptAnalyzer)
	return self
end

function ScriptAnalyzer:AnalyzeScript(source: string)
	local analysis = {
		lineCount = 0,
		characterCount = #source,
		functionCount = 0,
		localCount = 0,
		loopCount = 0,
		conditionalCount = 0,
		commentCount = 0,
		complexity = 0,
		keywords = {}
	}
	
	local lines = string.split(source, "\n")
	analysis.lineCount = #lines
	
	for _, line in ipairs(lines) do
		local trimmed = string.gsub(line, "^%s*(.-)%s*$", "%1")
		
		if string.match(trimmed, "^%-%-") then
			analysis.commentCount = analysis.commentCount + 1
		end
		
		if string.match(line, "function%s+") or string.match(line, "function%(") then
			analysis.functionCount = analysis.functionCount + 1
			analysis.complexity = analysis.complexity + 1
		end
		
		if string.match(line, "local%s+") then
			analysis.localCount = analysis.localCount + 1
		end
		
		if string.match(line, "for%s+") or string.match(line, "while%s+") or string.match(line, "repeat%s+") then
			analysis.loopCount = analysis.loopCount + 1
			analysis.complexity = analysis.complexity + 2
		end
		
		if string.match(line, "if%s+") or string.match(line, "elseif%s+") then
			analysis.conditionalCount = analysis.conditionalCount + 1
			analysis.complexity = analysis.complexity + 1
		end
	end
	
	return analysis
end

function SyntaxHighlighter.new()
	local self = setmetatable({}, SyntaxHighlighter)
	
	self.colors = {
		keyword = Color3.fromRGB(248, 109, 124),
		builtin = Color3.fromRGB(132, 214, 247),
		string = Color3.fromRGB(173, 241, 149),
		number = Color3.fromRGB(255, 198, 0),
		comment = Color3.fromRGB(106, 153, 85),
		operator = Color3.fromRGB(255, 255, 255),
		default = Color3.fromRGB(204, 204, 204)
	}
	
	self.keywords = {
		["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true,
		["elseif"] = true, ["end"] = true, ["false"] = true, ["for"] = true,
		["function"] = true, ["if"] = true, ["in"] = true, ["local"] = true,
		["nil"] = true, ["not"] = true, ["or"] = true, ["repeat"] = true,
		["return"] = true, ["then"] = true, ["true"] = true, ["until"] = true,
		["while"] = true, ["continue"] = true
	}
	
	self.builtins = {
		["game"] = true, ["workspace"] = true, ["script"] = true, ["math"] = true,
		["table"] = true, ["string"] = true, ["coroutine"] = true, ["assert"] = true,
		["collectgarbage"] = true, ["error"] = true, ["getfenv"] = true,
		["getmetatable"] = true, ["ipairs"] = true, ["loadstring"] = true,
		["newproxy"] = true, ["next"] = true, ["pairs"] = true, ["pcall"] = true,
		["print"] = true, ["rawequal"] = true, ["rawget"] = true, ["rawset"] = true,
		["select"] = true, ["setfenv"] = true, ["setmetatable"] = true,
		["tonumber"] = true, ["tostring"] = true, ["type"] = true, ["unpack"] = true,
		["xpcall"] = true, ["delay"] = true, ["spawn"] = true, ["wait"] = true,
		["warn"] = true, ["tick"] = true, ["typeof"] = true, ["Instance"] = true,
		["Vector2"] = true, ["Vector3"] = true, ["CFrame"] = true, ["Color3"] = true,
		["UDim"] = true, ["UDim2"] = true, ["Enum"] = true, ["task"] = true
	}
	
	return self
end

function SyntaxHighlighter:HighlightLine(line: string)
	local tokens = {}
	local inString = false
	local inComment = false
	local stringChar = nil
	local currentToken = ""
	local currentType = "default"
	
	local i = 1
	while i <= #line do
		local char = string.sub(line, i, i)
		local nextChar = string.sub(line, i + 1, i + 1)
		
		if not inString and not inComment then
			if char == "-" and nextChar == "-" then
				if #currentToken > 0 then
					table.insert(tokens, {text = currentToken, type = currentType})
					currentToken = ""
				end
				currentToken = string.sub(line, i)
				currentType = "comment"
				table.insert(tokens, {text = currentToken, type = currentType})
				break
			elseif char == '"' or char == "'" then
				if #currentToken > 0 then
					table.insert(tokens, {text = currentToken, type = currentType})
					currentToken = ""
				end
				inString = true
				stringChar = char
				currentToken = char
				currentType = "string"
			elseif string.match(char, "[%w_]") then
				if currentType ~= "default" and currentType ~= "keyword" and currentType ~= "builtin" then
					if #currentToken > 0 then
						table.insert(tokens, {text = currentToken, type = currentType})
					end
					currentToken = char
					currentType = "default"
				else
					currentToken = currentToken .. char
				end
			elseif string.match(char, "%d") and (currentType == "number" or #currentToken == 0) then
				if currentType ~= "number" then
					if #currentToken > 0 then
						table.insert(tokens, {text = currentToken, type = currentType})
					end
					currentToken = char
					currentType = "number"
				else
					currentToken = currentToken .. char
				end
			else
				if #currentToken > 0 then
					if self.keywords[currentToken] then
						currentType = "keyword"
					elseif self.builtins[currentToken] then
						currentType = "builtin"
					end
					table.insert(tokens, {text = currentToken, type = currentType})
					currentToken = ""
				end
				table.insert(tokens, {text = char, type = "operator"})
				currentType = "default"
			end
		elseif inString then
			currentToken = currentToken .. char
			if char == stringChar and string.sub(line, i - 1, i - 1) ~= "\\" then
				inString = false
				table.insert(tokens, {text = currentToken, type = currentType})
				currentToken = ""
				currentType = "default"
			end
		end
		
		i = i + 1
	end
	
	if #currentToken > 0 then
		if not inString and not inComment then
			if self.keywords[currentToken] then
				currentType = "keyword"
			elseif self.builtins[currentToken] then
				currentType = "builtin"
			end
		end
		table.insert(tokens, {text = currentToken, type = currentType})
	end
	
	return tokens
end

function SyntaxHighlighter:GetColor(tokenType: string): Color3
	return self.colors[tokenType] or self.colors.default
end

function GetFullName(instance)
	if instance == game:GetService("Players").LocalPlayer then 
		return 'game:GetService("Players").LocalPlayer' 
	end
	
	local path = {}
	local current = instance
	
	while current and current ~= game do
		table.insert(path, 1, current)
		current = current.Parent
	end
	
	if #path == 0 then
		return "nil"
	end
	
	local fullName
	if path[1].ClassName == "Workspace" then
		fullName = "workspace"
	else
		fullName = string.format('game:GetService("%s")', path[1].ClassName)
	end
	
	for i = 2, #path do
		fullName = string.format('%s:FindFirstChild("%s")', fullName, path[i].Name)
	end
	
	local playerName = game:GetService("Players").LocalPlayer.Name
	fullName = string.gsub(fullName, ':FindFirstChild%("' .. playerName .. '"%)', ".LocalPlayer")
	
	return fullName
end

local function CreateGui()
	local gui = Instance.new("ScreenGui")
	gui.Name = "DexEnhanced"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	return gui
end

local DexEnhanced = {}
DexEnhanced.__index = DexEnhanced

function DexEnhanced.new()
	local self = setmetatable({}, DexEnhanced)
	self.decompiler = CreateDecompilerCore()
	self.analyzer = ScriptAnalyzer.new()
	self.highlighter = SyntaxHighlighter.new()
	self.gui = CreateGui()
	self.openScripts = {}
	self.selectedObjects = {}
	
	return self
end

function DexEnhanced:Initialize()
	self.gui.Parent = game:GetService("CoreGui")
	print(string.format("[DEX Enhanced %s] Initialized successfully", SCRIPT_VERSION))
	print(string.format("[DEX Enhanced] Available decompilers: %d", #self.decompiler.decompilerFunctions))
	
	for i, decomp in ipairs(self.decompiler.decompilerFunctions) do
		print(string.format("  %d. %s (Priority: %d)", i, decomp.name, decomp.priority))
	end
end

function DexEnhanced:DecompileScript(script: Instance): DecompileResult
	return self.decompiler:Decompile(script)
end

function DexEnhanced:AnalyzeScript(source: string)
	return self.analyzer:AnalyzeScript(source)
end

function DexEnhanced:GetStats()
	return self.decompiler:GetStats()
end

function DexEnhanced:ScanForScripts(root: Instance): {Instance}
	local scripts = {}
	
	local function scan(parent)
		for _, child in ipairs(parent:GetChildren()) do
			if child:IsA("LuaSourceContainer") then
				table.insert(scripts, child)
			end
			scan(child)
		end
	end
	
	scan(root)
	return scripts
end

function DexEnhanced:BatchDecompileScripts(scripts: {Instance}, callback: ((number, number) -> ())?)
	return self.decompiler:BatchDecompile(scripts, callback)
end

function DexEnhanced:ExportScript(script: Instance, includeAnalysis: boolean?): string
	local result = self:DecompileScript(script)
	
	local export = string.format([[
-- Script: %s
-- Type: %s
-- Path: %s
-- Decompiled: %s
-- Method: %s
-- Status: %s

]], 
		script.Name,
		script.ClassName,
		GetFullName(script),
		os.date("%Y-%m-%d %H:%M:%S", result.timestamp),
		result.method or "Unknown",
		result.success and "Success" or "Failed"
	)
	
	if includeAnalysis and result.success and result.source then
		local analysis = self:AnalyzeScript(result.source)
		export = export .. string.format([[
-- Analysis:
--   Lines: %d
--   Functions: %d
--   Locals: %d
--   Loops: %d
--   Conditionals: %d
--   Comments: %d
--   Complexity: %d

]],
			analysis.lineCount,
			analysis.functionCount,
			analysis.localCount,
			analysis.loopCount,
			analysis.conditionalCount,
			analysis.commentCount,
			analysis.complexity
		)
	end
	
	export = export .. (result.source or "-- Decompilation failed")
	
	return export
end

local instance = DexEnhanced.new()
instance:Initialize()

getgenv().DexEnhanced = instance
getgenv().decompileScript = function(script)
	return instance:DecompileScript(script)
end
getgenv().getDexStats = function()
	return instance:GetStats()
end

return instance
