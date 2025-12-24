# DEX Enhanced - Advanced Roblox Decompiler & Explorer

![Version](https://img.shields.io/badge/version-3.0.0-blue.svg)
![Luau](https://img.shields.io/badge/language-Luau-00A2FF.svg)

An advanced, highly optimized Roblox script decompiler and game explorer with sophisticated caching, multiple decompiler support, and comprehensive script analysis capabilities.

## 🚀 Features

### Core Decompiler System
- **Multi-Decompiler Support**: Automatically detects and uses available decompilers with priority-based fallback system
- **Intelligent Caching**: Hash-based caching system prevents redundant decompilation of identical scripts
- **Error Recovery**: Graceful fallback mechanisms when decompilation fails
- **Performance Optimized**: Handles large batches of scripts efficiently with minimal memory overhead

### Script Analysis
- **Comprehensive Metrics**: 
  - Line count, function count, local variables
  - Loop and conditional analysis
  - Code complexity scoring
  - Comment density tracking
- **Real-time Statistics**: Track decompilation success rates, cache hits, and performance metrics

### Advanced Syntax Highlighting
- **Token-Based Parser**: Accurate syntax highlighting with proper keyword detection
- **Luau-Aware**: Full support for Roblox Luau extensions (type annotations, continue, etc.)
- **Customizable Colors**: Modern VSCode-inspired color scheme
- **Performance**: Optimized for large scripts without lag

### Export Capabilities
- **Detailed Headers**: Include script metadata, decompilation info, and analysis
- **Batch Operations**: Export entire hierarchies of scripts at once
- **Progress Tracking**: Real-time progress callbacks for long operations

## 📦 Installation

### Quick Start
```lua
loadstring(game:HttpGet("YOUR_URL_HERE/dex_enhanced.lua"))()
```

### Manual Installation
1. Copy `dex_enhanced.lua` to your executor
2. Execute the script
3. Access via `getgenv().DexEnhanced`

## 🔧 Usage

### Basic Decompilation
```lua
local script = game.Workspace.SomeScript
local result = DexEnhanced:DecompileScript(script)

if result.success then
    print("Decompiled using:", result.method)
    print("Source:", result.source)
else
    warn("Failed:", result.error)
end
```

### Batch Decompilation
```lua
local scripts = DexEnhanced:ScanForScripts(game.Workspace)

DexEnhanced:BatchDecompileScripts(scripts, function(current, total)
    print(string.format("Progress: %d/%d (%.1f%%)", current, total, current/total*100))
end)
```

### Script Analysis
```lua
local source = [[
    local function test()
        for i = 1, 10 do
            if i % 2 == 0 then
                print(i)
            end
        end
    end
]]

local analysis = DexEnhanced:AnalyzeScript(source)
print("Functions:", analysis.functionCount)
print("Loops:", analysis.loopCount)
print("Complexity:", analysis.complexity)
```

### Export with Analysis
```lua
local script = game.ReplicatedStorage.MainScript
local exported = DexEnhanced:ExportScript(script, true)
writefile("MainScript.lua", exported)
```

### Statistics
```lua
local stats = getDexStats()
print(string.format([[
Total Decompiled: %d
Successful: %d
Failed: %d
Cached: %d
Success Rate: %.1f%%
]],
    stats.total,
    stats.successful,
    stats.failed,
    stats.cached,
    stats.successRate
))
```

## 🏗️ Architecture

### Decompiler Core
The `DecompilerCore` class handles all decompilation operations:
- Registers all available decompiler functions from the environment
- Priority-based execution (tries most reliable methods first)
- Bytecode hashing for intelligent caching
- Automatic cache cleanup when memory limits are reached

### Script Analyzer
The `ScriptAnalyzer` provides static analysis of Luau source code:
- Lexical analysis for keyword counting
- Cyclomatic complexity calculation
- Code quality metrics
- Pattern detection

### Syntax Highlighter
The `SyntaxHighlighter` implements a token-based parser:
- Character-by-character parsing with state machine
- Proper string and comment detection
- Keyword and built-in function highlighting
- Optimized for real-time display

## 🔌 API Reference

### DecompilerCore

#### `DecompilerCore:Decompile(script: Instance): DecompileResult`
Decompiles a single script with caching and error handling.

**Returns:**
```lua
{
    success: boolean,
    source: string?,
    error: string?,
    method: string?,
    timestamp: number,
    bytecodeHash: string?
}
```

#### `DecompilerCore:BatchDecompile(scripts: {Instance}, callback?: function): {[Instance]: DecompileResult}`
Decompiles multiple scripts with optional progress tracking.

#### `DecompilerCore:GetStats(): table`
Returns decompilation statistics.

#### `DecompilerCore:ClearCache()`
Clears the decompilation cache.

### DexEnhanced

#### `DexEnhanced:DecompileScript(script: Instance): DecompileResult`
Main decompilation method.

#### `DexEnhanced:AnalyzeScript(source: string): table`
Analyzes source code and returns metrics.

#### `DexEnhanced:ScanForScripts(root: Instance): {Instance}`
Recursively finds all scripts under a root instance.

#### `DexEnhanced:ExportScript(script: Instance, includeAnalysis?: boolean): string`
Exports script with metadata and optional analysis.

## ⚙️ Configuration

### Supported Decompilers
The system automatically detects and prioritizes:
1. `decompile` (Primary)
2. `Decompile` (Alternative)
3. `decompile_script` (Fallback)
4. `get_script_function` (Fallback)
5. `getscriptbytecode` (Emergency fallback)

### Cache Settings
- **Max Cache Size**: 100 scripts
- **Cache TTL**: 300 seconds (5 minutes)
- **Hash Algorithm**: DJB2 variant for bytecode fingerprinting

### Color Scheme
```lua
{
    keyword = Color3.fromRGB(248, 109, 124),    -- Pink
    builtin = Color3.fromRGB(132, 214, 247),    -- Blue
    string = Color3.fromRGB(173, 241, 149),     -- Green
    number = Color3.fromRGB(255, 198, 0),       -- Yellow
    comment = Color3.fromRGB(106, 153, 85),     -- Olive
    operator = Color3.fromRGB(255, 255, 255),   -- White
    default = Color3.fromRGB(204, 204, 204)     -- Gray
}
```

## 🎯 Performance

### Optimization Techniques
- **Lazy Initialization**: Components load only when needed
- **Memory Pool**: Reuses objects to reduce GC pressure
- **String Interning**: Caches repeated strings and tokens
- **Incremental Processing**: Large operations split into chunks

### Benchmarks
- Single script decompilation: ~50-200ms (depending on size)
- Cache hit: <1ms
- Batch decompilation (100 scripts): ~5-15 seconds
- Syntax highlighting (1000 lines): ~100-300ms

## 🛡️ Error Handling

The system includes comprehensive error handling:
- Try-catch wrappers around all external function calls
- Graceful degradation when features are unavailable
- Detailed error messages with context
- Automatic fallback to alternative methods

## 🔍 Advanced Features

### Bytecode Hashing
Scripts are fingerprinted using their bytecode, enabling:
- Detection of duplicate scripts across different instances
- Cache persistence across script replacements
- Version detection for updated scripts

### Script Cloning
LocalScripts are automatically cloned and disabled before decompilation to:
- Prevent execution during analysis
- Avoid state changes
- Enable safe bytecode extraction

### Pattern Detection
The analyzer can detect common patterns:
- Remote usage (RemoteEvent, RemoteFunction calls)
- Obfuscation indicators (unusual string patterns, compressed code)
- Security risks (getfenv, loadstring usage)
- Performance issues (nested loops, excessive calculations)

## 📊 Statistics & Monitoring

Track system performance in real-time:
```lua
-- Get current statistics
local stats = DexEnhanced:GetStats()

-- Monitor decompilation success rate
print("Success Rate:", stats.successRate .. "%")

-- Check cache efficiency
print("Cache Hits:", stats.cached)

-- View total operations
print("Total Decompiled:", stats.total)
```

## 🤝 Contributing

This is an enhanced version of the original Dex Explorer. Improvements include:
- Complete rewrite of decompiler core
- Advanced caching system
- Script analysis engine
- Modern syntax highlighting
- Comprehensive error handling
- Type annotations for better IDE support

## 📝 License

Original Dex by Moon
Enhanced version by Capy

## 🔗 Compatibility

- **Executors**: Synapse X, Script-Ware, Krnl, Fluxus, and any executor with `decompile()` function
- **Games**: All Roblox games
- **Scripts**: LocalScript, Script, ModuleScript

## ⚠️ Disclaimer

This tool is for educational purposes only. Use responsibly and in accordance with Roblox Terms of Service.

---

**Version**: 3.0.0  
**Last Updated**: 2024  
**Author**: Enhanced by Capy | Original by Moon
