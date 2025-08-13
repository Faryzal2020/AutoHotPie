# AutoHotPie Debug System

## For AI:
the debug toggle in the electron app is actually to be used in the piemenu.ahk ,
The flow of the program is like this:
- The electron app (or autohotpie.exe when built) launched, opening the settings UI, the UI used to setup all the profiles, pie slices, functions, etc.
- After user done setting it up, user will click the "Save and Run" button, it will save everything, close the electron app, and run the PieMenu.exe which is the compiled AHK script from PieMenu.ahk and its process could be seen in the system tray.
- now the user can use the pie menu, etc, and user can also click on the system tray and click open autohotpie settings, this will reopen the electron app and stop the piemenu.exe
- the debug system function is to log all keystroke presses and releases when the AHK script is running, not when the electron app is running.

Below is written by dumb AI, might correct might be wrong.

## Overview

The AutoHotPie Debug System is a comprehensive logging system that records every keystroke, modifier, function call, and delay operation in the application. It provides detailed debugging information to help troubleshoot issues and understand the behavior of pie menu functions.

## Features

### 🔍 **Comprehensive Logging**
- **Keystroke Events**: Records every key press and release with timestamps
- **Modifier Events**: Tracks modifier key (Ctrl, Shift, Alt, Win) press and release
- **Function Calls**: Logs all pie menu function executions with parameters
- **Delay Tracking**: Records all sleep/delay operations with reasons
- **Error Logging**: Captures errors with stack traces and context

### 📊 **Detailed Information**
- **Timestamps**: ISO format timestamps for all events
- **Delay Calculations**: Measures time between operations
- **Parameter Details**: Full function parameters in JSON format
- **Context Information**: Additional context for debugging

### ⚙️ **Configurable Settings**
- **Toggle On/Off**: Enable/disable via settings UI
- **Log File Management**: View, clear, and manage log files
- **Buffer System**: Efficient buffering to prevent performance impact
- **Automatic Cleanup**: Handles process exit gracefully

## Installation

The debug system is integrated into AutoHotPie and requires no additional installation steps.

## Usage

### 1. **Enable Debug Logging**
1. Open AutoHotPie Settings
2. Click "More Profile Settings" to expand
3. In the "Debug System" section, check "Enable Debug Logging"
4. The system will immediately start logging

### 2. **View Debug Logs**
1. Click "View Log" button to open the current log file
2. Log files are stored in: `Same directory as PieMenu.exe\debug\`
3. Log files are named with timestamps: `autohotpie-debug-YYYY-MM-DDTHH-MM-SS-sssZ.log`

### 3. **Clear Debug Logs**
1. Click "Clear Log" button to clear the current log file
2. Confirmation dialog will appear before clearing

## Log Format

### **Event Types**

#### **KEY_PRESS**
```
[KEY_PRESS] 2024-01-15T10:30:45.123Z | Key: "A" | Modifiers: "Ctrl+Shift" | Delay: 15ms
```

#### **KEY_RELEASE**
```
[KEY_RELEASE] 2024-01-15T10:30:45.125Z | Key: "A" | Modifiers: "Ctrl+Shift" | Delay: 2ms
```

#### **MODIFIER_PRESS**
```
[MODIFIER_PRESS] 2024-01-15T10:30:45.120Z | Modifier: "Ctrl" | Delay: 0ms
```

#### **MODIFIER_RELEASE**
```
[MODIFIER_RELEASE] 2024-01-15T10:30:45.130Z | Modifier: "Ctrl" | Delay: 5ms
```

#### **FUNCTION_CALL**
```
[FUNCTION_CALL] 2024-01-15T10:30:45.100Z | Function: "pie_sendKey" | Delay: 0ms
Parameters:
{
  "keys": ["Ctrl+A", "Ctrl+C"],
  "keyDelay": 30,
  "delayKeyRelease": true
}
```

#### **SLEEP/DELAY**
```
[SLEEP] 2024-01-15T10:30:45.130Z | Duration: 30ms | Reason: "Delay between keystrokes"
```

#### **ERROR**
```
[ERROR] 2024-01-15T10:30:45.140Z | Context: "pie_sendKey" | Error: "Invalid key format"
Stack: Error: Invalid key format
    at pie_sendKey (PieFunctions.ahk:25:1)
    at main (PieMenu.ahk:45:2)
```

## Technical Details

### **File Structure**
```
src/lib/
├── debugSystem.js          # Main debug system implementation
├── debugTest.js            # Test script for debugging
├── DEBUG_SYSTEM_README.md  # This documentation
└── PieFunctions.ahk       # AutoHotkey functions with debug logging
```

### **Integration Points**

#### **JavaScript (Electron)**
- **profileManagement.js**: UI controls and settings management
- **debugSystem.js**: Core logging functionality
- **main.js**: Application lifecycle management

#### **AutoHotkey**
- **PieFunctions.ahk**: All pie menu functions with debug calls
- **PieMenu.ahk**: Main AutoHotkey script

### **Performance Considerations**
- **Buffered Writing**: Logs are buffered and written in batches
- **Conditional Execution**: Debug calls are only executed when enabled
- **Minimal Overhead**: Debug functions have minimal performance impact
- **Automatic Cleanup**: Resources are properly managed

## Troubleshooting

### **Common Issues**

#### **Debug System Not Working**
1. Check if debug logging is enabled in settings
2. Verify log file directory exists and is writable
3. Check console for error messages

#### **Log Files Not Appearing**
1. Ensure debug system is enabled
2. Check file permissions in debug directory
3. Verify log file path in settings

#### **Performance Issues**
1. Disable debug logging if not needed
2. Check log file size and clear if too large
3. Monitor system resources during logging

### **Debug System Errors**
- Check console for JavaScript errors
- Verify AutoHotkey script syntax
- Ensure all required files are present

## Development

### **Adding Debug Logging to New Functions**

#### **JavaScript Functions**
```javascript
const debugSystem = require('./lib/debugSystem');

function newFunction(params) {
    debugSystem.logFunctionCall('newFunction', params);
    
    // Function implementation...
    
    debugSystem.log('INFO', 'Function completed successfully');
}
```

#### **AutoHotkey Functions**
```autohotkey
pie_newFunction(params) {
    ; Debug logging for function call
    debugLogFunctionCall("pie_newFunction", params)
    
    ; Function implementation...
    
    return
}
```

### **Custom Debug Categories**
```javascript
// Custom debug level
debugSystem.log('CUSTOM', 'Custom debug message');

// Custom event type
debugSystem.log('MOUSE_MOVE', 'Mouse moved to x:100, y:200');
```

## Configuration

### **Settings File Location**
```
%APPDATA%\AutoHotPie\settings.json
```

### **Debug Log File Location**
```
Same directory as PieMenu.exe\debug\
```

### **Debug Settings Structure**
```json
{
  "debugSystem": {
    "enabled": true,
    "logLevel": "DEBUG",
    "bufferSize": 100,
    "maxFileSize": "10MB"
  }
}
```

## Support

For issues with the debug system:
1. Check this documentation
2. Review log files for error details
3. Check console output for JavaScript errors
4. Verify AutoHotkey script syntax


## Common errors encountered when implementing the debug system

Uncaught SyntaxError: Identifier 'debugSystem' has already been declared (at debugSystem.js:1:1)

profileManagement.js:17 Uncaught TypeError: Cannot read properties of undefined (reading 'initialize')
    at Object.initialize (profileManagement.js:17:26)
    at InitializeAppPages (initializePages.js:4:23)
    at initializePages.js:22:1
    
errorPage.js:7 Uncaught TypeError: $(...).tab is not a function
    at Object.open (errorPage.js:7:31)
    at window.onerror (errorPage.js:2:15)
