# DEX Enhanced v3.0 - Advanced Roblox Exploit Tool

Powerful client-side decompiler, remote spy, script dumper, and game explorer for Roblox exploitation.

## 🔥 Features

### Decompiler
- **Multi-decompiler support** - Tries all available decompilers automatically
- **Smart caching** - Bytecode hashing prevents re-decompiling identical scripts
- **Batch operations** - Decompile entire games at once
- **Fast performance** - Optimized for speed, no bloat

### Remote Spy
- **Hook all remotes** - Automatically intercept RemoteEvent and RemoteFunction calls
- **Universal spy** - Hooks the __namecall metamethod to catch everything
- **Argument logging** - Captures all arguments sent to remotes
- **Real-time monitoring** - See remote calls as they happen

### Script Scanner
- **Find anti-cheats** - Automatically detect anti-cheat scripts by name patterns
- **Analyze scripts** - Get stats on functions, loops, remote calls
- **Bytecode analysis** - Compare scripts, check sizes, generate hashes

### Game Explorer
- **Find anything** - Search for scripts, remotes, instances by pattern
- **Game info** - Get PlaceId, JobId, player count, script count
- **Remote discovery** - List all RemoteEvents and RemoteFunctions
- **Instance utilities** - Better path generation, cloning, property access

### Script Dumper
- **Export scripts** - Save decompiled scripts to files
- **Batch export** - Dump entire game to folder
- **Clipboard support** - Copy scripts directly to clipboard
- **Metadata included** - Script path, type, status in exported files

### SaveInstance
- **Save game** - Export entire game to .rbxl file
- **Save workspace** - Export workspace to .rbxm file
- **Universal support** - Works with saveinstance, syn.save_instance

## 🚀 Quick Start

```lua
loadstring(game:HttpGet("YOUR_URL/dex_enhanced.lua"))()
```

## 📖 Usage

### Basic Decompilation
```lua
local script = game.Workspace.SomeScript
local source = Dex.decompile(script)
print(source)
```

### Dump Entire Game
```lua
local results = Dex.dumpAll(game)
for script, source in pairs(results) do
    print(script.Name, #source)
end
```

### Remote Spy
```lua
-- Hook all remotes
Dex.RemoteSpy.hookAll()

-- Wait for some gameplay
wait(10)

-- Check logs
for _, log in pairs(Dex.RemoteSpy.getLogs()) do
    print(log.remote, unpack(log.args))
end
```

### Universal Spy (Better)
```lua
-- Hook __namecall
Dex.UniversalSpy.hook()

-- Play the game
wait(30)

-- View logs
local logs = Dex.UniversalSpy.getLogs()
print("Captured", #logs, "remote calls")

for _, log in pairs(logs) do
    print(log.time, log.object, log.method)
end
```

### Find Anti-Cheats
```lua
local acs = Dex.ScriptScanner.findAntiCheat()
print("Found", #acs, "potential anti-cheats:")

for _, ac in pairs(acs) do
    print(ac:GetFullName())
    
    -- Decompile to see what it does
    local src = Dex.decompile(ac)
    print(src)
    
    -- Disable it
    if ac:IsA("LocalScript") then
        ac.Disabled = true
    end
end
```

### Export Scripts to Files
```lua
-- Create folder
makefolder("scripts")

-- Find all scripts
local scripts = Dex.GameExplorer.findScripts()

-- Export them
for i, script in pairs(scripts) do
    local src = Dex.ScriptDumper.dumpScript(script, true)
    writefile("scripts/" .. script.Name .. ".lua", src)
end

print("Exported", #scripts, "scripts")
```

### Compare Scripts
```lua
local script1 = game.ReplicatedStorage.Script1
local script2 = game.ReplicatedStorage.Script2

if Dex.BytecodeAnalyzer.compare(script1, script2) then
    print("Scripts are identical!")
else
    print("Scripts are different")
end
```

### Analyze Script
```lua
local script = game.Players.LocalPlayer.PlayerScripts.MainScript
local analysis = Dex.BytecodeAnalyzer.analyze(script)

print("Lines:", analysis.lines)
print("Functions:", analysis.functions)
print("Loops:", analysis.loops)
print("Remote calls:", analysis.remotes)
print("Bytecode size:", analysis.bytecodeSize)
```

### Find All Remotes
```lua
local remotes = Dex.GameExplorer.findRemotes()

for _, remote in pairs(remotes) do
    print(remote:GetFullName(), remote.ClassName)
end

-- Hook them all
Dex.RemoteSpy.hookAll()
```

### Get Game Info
```lua
local info = Dex.GameExplorer.getGameInfo()

print("Place ID:", info.placeId)
print("Job ID:", info.jobId)
print("Players:", info.players)
print("Total Scripts:", info.scripts)
print("Total Remotes:", info.remotes)
```

### Save Game
```lua
-- Save entire game
Dex.SaveInstance.saveGame("mygame.rbxl")

-- Save just workspace
Dex.SaveInstance.saveWorkspace("myworkspace.rbxm")
```

### Check Stats
```lua
-- Decompile some stuff first
Dex.dumpAll(workspace)

-- Check stats
local stats = Dex.getStats()
print("Total:", stats.total)
print("Success:", stats.success)
print("Cached:", stats.cached)
```

### Get Instance Path
```lua
local part = workspace.Map.Building.Door
local path = Dex.InstanceUtils.getPath(part)
print(path)
-- Output: workspace.Map.Building.Door
```

### Check Environment
```lua
Dex.EnvironmentInfo.printInfo()
-- Shows what exploit functions are available
```

## 🎯 Advanced Examples

### Find and Disable All Anti-Cheats
```lua
local acs = Dex.ScriptScanner.findAntiCheat()
for _, ac in pairs(acs) do
    if ac:IsA("LocalScript") then
        ac.Disabled = true
        ac:Destroy()
    end
end
print("Disabled", #acs, "anti-cheats")
```

### Export Entire Game with Analysis
```lua
makefolder("game_dump")

local scripts = Dex.GameExplorer.findScripts()

for _, script in pairs(scripts) do
    local src = Dex.decompile(script)
    local analysis = Dex.BytecodeAnalyzer.analyze(script)
    
    local header = string.format([[
-- %s
-- Path: %s
-- Lines: %d | Functions: %d | Loops: %d
-- Remotes: %d | Bytecode: %d bytes

]],
        script.Name,
        Dex.InstanceUtils.getPath(script),
        analysis.lines,
        analysis.functions,
        analysis.loops,
        analysis.remotes,
        analysis.bytecodeSize
    )
    
    local full = header .. src
    writefile("game_dump/" .. script.ClassName .. "_" .. script.Name .. ".lua", full)
end
```

### Monitor Remotes in Real-Time
```lua
Dex.UniversalSpy.hook()

spawn(function()
    while true do
        local logs = Dex.UniversalSpy.getLogs()
        if #logs > 0 then
            local last = logs[#logs]
            print("[" .. last.time .. "]", last.object, "->", last.method)
        end
        wait(0.1)
    end
end)
```

### Find Obfuscated Scripts
```lua
for _, script in pairs(Dex.GameExplorer.findScripts()) do
    local size = Dex.BytecodeAnalyzer.getSize(script)
    if size > 50000 then
        print("Large script (possibly obfuscated):", script:GetFullName(), size .. " bytes")
    end
end
```

## 📊 API Reference

### Dex.decompile(script)
Decompiles a single script, returns source code string

### Dex.batchDecompile(scripts, callback?)
Decompiles array of scripts with optional progress callback

### Dex.dumpAll(root?)
Decompiles all scripts under root (defaults to game)

### Dex.clearCache()
Clears decompilation cache

### Dex.RemoteSpy.hook(remote)
Hook a specific remote

### Dex.RemoteSpy.hookAll()
Hook all remotes in game

### Dex.RemoteSpy.getLogs()
Get all logged remote calls

### Dex.UniversalSpy.hook()
Hook __namecall to catch all remote calls

### Dex.UniversalSpy.getLogs()
Get all namecall logs

### Dex.ScriptScanner.findAntiCheat()
Find potential anti-cheat scripts

### Dex.ScriptScanner.analyzeAll()
Get full analysis of all scripts in game

### Dex.GameExplorer.findScripts(pattern?)
Find all scripts, optionally matching pattern

### Dex.GameExplorer.findRemotes()
Find all RemoteEvents and RemoteFunctions

### Dex.GameExplorer.getGameInfo()
Get game metadata

### Dex.BytecodeAnalyzer.analyze(script)
Analyze script and return stats

### Dex.BytecodeAnalyzer.compare(script1, script2)
Check if two scripts have identical bytecode

### Dex.ScriptDumper.dumpScript(script, includeMeta?)
Export script source with optional metadata

### Dex.ScriptDumper.dumpToFolder(root, folderPath)
Export all scripts to folder

### Dex.InstanceUtils.getPath(obj)
Get proper Lua path for instance

### Dex.SaveInstance.saveGame(filename?)
Save game to file

### Dex.EnvironmentInfo.check()
Check what exploit functions are available

## ⚡ Performance

- Single decompile: ~50-100ms
- Cache hit: <1ms
- Batch 100 scripts: ~5-10 seconds
- Remote hook overhead: <0.1ms per call

## 🔧 Compatibility

Works on:
- Synapse X
- Script-Ware
- Krnl
- Fluxus
- Electron
- Any executor with `decompile()` function

## 💡 Tips

- Always hook remotes/namecall BEFORE doing anything suspicious
- Use `findAntiCheat()` first to locate and disable detection
- Cache makes re-decompiling instant, don't clear unless needed
- Universal spy catches more than RemoteSpy but has slight overhead
- Save your dumps with `writefile()` for later analysis

## ⚠️ Notes

- This is CLIENT-SIDE only, you can't access server scripts
- Some games have protected remotes that won't log args
- Anti-cheats can detect hookmetamethod usage
- Bytecode comparison only works if scripts haven't changed
- Some executors have limited decompiler quality

---

**Version**: 3.0.0  
**No bloat, no error handling spam, just raw functionality**
