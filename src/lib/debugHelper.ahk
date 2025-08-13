; AutoHotPie Debug Helper
; Provides comprehensive logging functionality for debugging pie menu operations

; Debug system global variables are now declared in the main script
; This ensures proper scope and accessibility

; Debug function to show all global variable states
debugShowGlobalState() {
    OutputDebug, % "Debug System: === GLOBAL VARIABLE STATE ==="
    OutputDebug, % "Debug System: DebugMode = " . DebugMode
    OutputDebug, % "Debug System: DebugLogEnabled = " . DebugLogEnabled
    OutputDebug, % "Debug System: DebugLogFile = " . DebugLogFile
    OutputDebug, % "Debug System: DebugBufferSize = " . DebugBufferSize
    OutputDebug, % "Debug System: DebugLogBuffer.Length() = " . DebugLogBuffer.Length()
    OutputDebug, % "Debug System: ================================"
}

; Initialize debug system
debugInit() {
    global DebugLogEnabled, DebugLogFile, DebugLogBuffer, DebugBufferSize, DebugLastTimestamp, DebugMode
    
    OutputDebug, % "Debug System: debugInit() called"
    OutputDebug, % "Debug System: Global variables at start:"
    OutputDebug, % "  DebugMode = " . DebugMode
    OutputDebug, % "  DebugLogEnabled = " . DebugLogEnabled
    OutputDebug, % "  DebugLogFile = " . DebugLogFile
    OutputDebug, % "  DebugBufferSize = " . DebugBufferSize
    
    ; Check if debug mode is enabled
    if (!DebugMode) {
        OutputDebug, % "Debug System: DebugMode is false, not initializing"
        return
    }
    
    OutputDebug, % "Debug System: Starting initialization..."
    OutputDebug, % "Debug System: DebugMode = " . DebugMode
    OutputDebug, % "Debug System: A_ScriptDir = " . A_ScriptDir
    OutputDebug, % "Debug System: A_WorkingDir = " . A_WorkingDir
    
    ; Set up debug logging
    OutputDebug, % "Debug System: Setting up debug logging variables"
    DebugLogEnabled := true
    DebugLogBuffer := []
    DebugLastTimestamp := A_TickCount
    OutputDebug, % "Debug System: After setup - DebugLogEnabled = " . DebugLogEnabled . ", DebugBufferSize = " . DebugBufferSize
    
    ; Create log file path
    try {
        ; Try multiple possible locations for the log file
        possiblePaths := []
        ; Use a more unique filename to avoid conflicts
        uniqueId := A_Now . "-" . A_TickCount
        
        ; Start with the most likely working path (script directory)
        possiblePaths.Push(A_ScriptDir . "\debug\autohotpie-debug-" . uniqueId . ".log")
        
        ; Add working directory as backup
        possiblePaths.Push(A_WorkingDir . "\debug\autohotpie-debug-" . uniqueId . ".log")
        
        ; Add executable directory as last resort
        SplitPath, A_ScriptFullPath, , executableDir
        possiblePaths.Push(executableDir . "\debug\autohotpie-debug-" . uniqueId . ".log")
        
        ; Add a simple path as additional backup
        possiblePaths.Push(A_ScriptDir . "\debug\debug-" . uniqueId . ".log")
        
        OutputDebug, % "Debug System: Trying possible paths:"
        for index, path in possiblePaths {
            OutputDebug, % "  " . index . ": " . path
        }
        
        ; Use the first writable location
        for index, path in possiblePaths {
            OutputDebug, % "Debug System: Testing path " . index . ": " . path
            SplitPath, path, , debugDir
            OutputDebug, % "Debug System: Debug directory: " . debugDir
            if (!FileExist(debugDir)) {
                OutputDebug, % "Debug System: Creating directory: " . debugDir
                FileCreateDir, %debugDir%
            }
            
            ; Test if we can write to this location
            testFile := debugDir . "\test-write.tmp"
            OutputDebug, % "Debug System: Testing write with file: " . testFile
            try {
                FileDelete, %testFile%
                FileAppend, test, %testFile%
                FileDelete, %testFile%
                OutputDebug, % "Debug System: Directory write test successful"
                
                ; Try to write to the actual log file path (simplified test)
                try {
                    ; Just try to create the file with a simple test
                    FileAppend, % "Debug System Test - " . A_Now . "`n", %path%
                    OutputDebug, % "Debug System: Log file write test successful"
                    DebugLogFile := path
                    OutputDebug, % "Debug System: SUCCESS - DebugLogFile set to: " . DebugLogFile
                    break
                } catch e2 {
                    OutputDebug, % "Debug System: Log file write test failed - " . e2.message . " (Code: " . e2.extra . ")"
                    ; Don't give up immediately, try the next path
                    continue
                }
            } catch e {
                OutputDebug, % "Debug System: Directory write test failed - " . e.message
                continue
            }
        }
        
        ; Write initial log entry
        OutputDebug, % "Debug System: About to write initial log entry"
        
        ; Test write to the log file directly to verify it's accessible
        try {
            FileAppend, % "Debug System Initialization Test - " . A_Now . "`n", %DebugLogFile%
            OutputDebug, % "Debug System: Direct write test to log file successful"
        } catch e {
            OutputDebug, % "Debug System: Direct write test to log file failed - " . e.message
        }
        
        debugLog("INFO", "Debug logging initialized", "AutoHotkey Debug System Started")
        OutputDebug, % "Debug System: Initialization completed successfully"
        
    } catch e {
        DebugLogEnabled := false
        OutputDebug, % "Debug System Error: " . e.message
    }
}

; Main debug logging function
debugLog(level, message, context := "") {
    global DebugLogEnabled, DebugLogBuffer, DebugBufferSize, DebugLastTimestamp, DebugLogFile
    
    OutputDebug, % "Debug System: debugLog called - Level: " . level . ", Message: " . message
    OutputDebug, % "Debug System: DebugLogEnabled = " . DebugLogEnabled . ", DebugLogFile = " . DebugLogFile
    
    if (!DebugLogEnabled) {
        OutputDebug, % "Debug System: Logging disabled, ignoring log entry: " . level . " - " . message
        return
    }
    
    OutputDebug, % "Debug System: Logging entry - " . level . " - " . message
    
    ; Calculate delay since last log
    currentTime := A_TickCount
    delay := currentTime - DebugLastTimestamp
    DebugLastTimestamp := currentTime
    
    ; Create timestamp
    FormatTime, timestamp, , yyyy-MM-dd HH:mm:ss
    
    ; Create log entry
    logEntry := "[" . level . "] " . timestamp . " | " . message . " | Delay: " . delay . "ms"
    if (context) {
        logEntry := logEntry . "`nContext: " . context
    }
    
    ; Add to buffer
    DebugLogBuffer.Push(logEntry)
    OutputDebug, % "Debug System: Added to buffer, buffer size now: " . DebugLogBuffer.Length()
    
    ; Also output to debug console
    OutputDebug, % logEntry
    
    ; Flush buffer if it's full
    if (DebugLogBuffer.Length() >= DebugBufferSize) {
        OutputDebug, % "Debug System: Buffer full, flushing..."
        debugFlushBuffer()
    }
    
    ; Also try to write directly to file for immediate logging (bypass buffer)
    if (DebugLogFile) {
        try {
            FileAppend, % logEntry . "`n", %DebugLogFile%
            OutputDebug, % "Debug System: Direct write to file successful"
        } catch e {
            OutputDebug, % "Debug System: Direct write to file failed - " . e.message . " (Code: " . e.extra . ")"
        }
    }
}

; Log function calls
debugLogFunctionCall(functionName, parameters := "", context := "") {
    paramStr := ""
    if (parameters) {
        if (IsObject(parameters)) {
            paramStr := JSON.Dump(parameters)
        } else {
            paramStr := parameters
        }
    }
    
    debugLog("FUNCTION_CALL", "Function: " . functionName, "Parameters: " . paramStr . "`nContext: " . context)
}

; Log key events
debugLogKeyPress(key, modifiers := "", context := "") {
    debugLog("KEY_PRESS", "Key: """ . key . """ | Modifiers: """ . modifiers . """", context)
}

debugLogKeyRelease(key, modifiers := "", context := "") {
    debugLog("KEY_RELEASE", "Key: """ . key . """ | Modifiers: """ . modifiers . """", context)
}

debugLogModifierPress(modifier, context := "") {
    debugLog("MODIFIER_PRESS", "Modifier: """ . modifier . """", context)
}

debugLogModifierRelease(modifier, context := "") {
    debugLog("MODIFIER_RELEASE", "Modifier: """ . modifier . """", context)
}

; Log sleep/delay operations
debugLogSleep(duration, reason := "", context := "") {
    debugLog("SLEEP", "Duration: " . duration . "ms | Reason: """ . reason . """", context)
}

; Log errors
debugLogError(error, context := "") {
    debugLog("ERROR", "Error: " . error, context)
}

; Flush buffer to file
debugFlushBuffer() {
    global DebugLogEnabled, DebugLogFile, DebugLogBuffer
    
    OutputDebug, % "Debug System: FlushBuffer called"
    OutputDebug, % "Debug System: DebugLogEnabled = " . DebugLogEnabled
    OutputDebug, % "Debug System: DebugLogFile = " . DebugLogFile
    OutputDebug, % "Debug System: Buffer size = " . DebugLogBuffer.Length()
    
    if (!DebugLogEnabled || !DebugLogFile || DebugLogBuffer.Length() == 0) {
        OutputDebug, % "Debug System: FlushBuffer skipped - conditions not met"
        OutputDebug, % "Debug System: DebugLogEnabled = " . DebugLogEnabled . ", DebugLogFile = " . DebugLogFile . ", Buffer size = " . DebugLogBuffer.Length()
        return
    }
    
    try {
        OutputDebug, % "Debug System: Writing " . DebugLogBuffer.Length() . " entries to file"
        
        ; Create log content
        logContent := ""
        for index, entry in DebugLogBuffer {
            logContent := logContent . entry . "`n`n"
        }
        
        ; Append to file
        try {
            FileAppend, %logContent%, %DebugLogFile%, UTF-8
            OutputDebug, % "Debug System: Successfully wrote to file: " . DebugLogFile
            
            ; Clear buffer
            DebugLogBuffer := []
            OutputDebug, % "Debug System: Buffer cleared"
        } catch e {
            OutputDebug, % "Debug System: Failed to write to file - " . e.message . " (Code: " . e.extra . ")"
            OutputDebug, % "Debug System: File path: " . DebugLogFile
            OutputDebug, % "Debug System: Buffer size: " . DebugLogBuffer.Length()
        }
        
    } catch e {
        OutputDebug, % "Debug Flush Error: " . e.message
    }
}

; Get log file path
debugGetLogFilePath() {
    global DebugLogFile
    OutputDebug, % "Debug System: debugGetLogFilePath() called, DebugLogFile = " . DebugLogFile
    return DebugLogFile
}

; Clear log file
debugClearLog() {
    global DebugLogEnabled, DebugLogFile
    
    if (!DebugLogEnabled || !DebugLogFile) {
        return false
    }
    
    try {
        FileDelete, %DebugLogFile%
        debugLog("INFO", "Log file cleared")
        return true
    } catch e {
        debugLogError("Failed to clear log file: " . e.message)
        return false
    }
}

; Cleanup on script exit
debugCleanup() {
	if (DebugLogEnabled) {
		debugLog("INFO", "Debug system shutting down")
		debugFlushBuffer()
	}
}

; Manual cleanup function - call this when needed
debugManualCleanup() {
	if (DebugLogEnabled) {
		debugLog("INFO", "Manual debug cleanup called")
		debugFlushBuffer()
	}
}

; Test function to verify debug system is working
debugTest() {
	OutputDebug, % "Debug System: debugTest() called"
	OutputDebug, % "Debug System: DebugMode = " . DebugMode
	OutputDebug, % "Debug System: DebugLogEnabled = " . DebugLogEnabled
	OutputDebug, % "Debug System: DebugLogFile = " . DebugLogFile
	
	; Try to write a test log entry
	if (DebugLogEnabled && DebugLogFile) {
		OutputDebug, % "Debug System: Writing test log entry"
		debugLog("TEST", "Manual test log entry", "debugTest function")
		debugFlushBuffer()
		OutputDebug, % "Debug System: Test log entry completed"
	} else {
		OutputDebug, % "Debug System: Cannot write test log - DebugLogEnabled = " . DebugLogEnabled . ", DebugLogFile = " . DebugLogFile
	}
}

; Test file permissions and accessibility
debugTestFileAccess() {
	OutputDebug, % "Debug System: debugTestFileAccess() called"
	
	if (!DebugLogFile) {
		OutputDebug, % "Debug System: No debug log file path available"
		return
	}
	
	; Test 1: Check if file exists
	OutputDebug, % "Debug System: Testing file existence: " . DebugLogFile
	if (FileExist(DebugLogFile)) {
		OutputDebug, % "Debug System: File already exists"
	} else {
		OutputDebug, % "Debug System: File does not exist yet"
	}
	
	; Test 2: Try to create/append to file
	OutputDebug, % "Debug System: Testing file write access"
	try {
		FileAppend, % "File access test - " . A_Now . "`n", %DebugLogFile%
		OutputDebug, % "Debug System: File write test successful"
		
		; Test 3: Try to read the file
		try {
			FileRead, testContent, %DebugLogFile%
			OutputDebug, % "Debug System: File read test successful, content length: " . StrLen(testContent)
		} catch e {
			OutputDebug, % "Debug System: File read test failed - " . e.message . " (Code: " . e.extra . ")"
		}
		
	} catch e {
		OutputDebug, % "Debug System: File write test failed - " . e.message . " (Code: " . e.extra . ")"
		OutputDebug, % "Debug System: Error details - Message: " . e.message . ", Extra: " . e.extra . ", What: " . e.what
		
		; If write fails, try to create a new log file
		OutputDebug, % "Debug System: Attempting to create new log file due to write failure"
		debugCreateNewLogFile()
	}
}

; Create a new log file if the current one is inaccessible
debugCreateNewLogFile() {
	global DebugLogFile
	
	OutputDebug, % "Debug System: Creating new log file"
	
	; Generate a new unique filename
	uniqueId := A_Now . "-" . A_TickCount
	newPath := A_ScriptDir . "\debug\autohotpie-debug-new-" . uniqueId . ".log"
	
	try {
		FileAppend, % "New Debug Log File Created - " . A_Now . "`n", %newPath%
		DebugLogFile := newPath
		OutputDebug, % "Debug System: New log file created: " . DebugLogFile
	} catch e {
		OutputDebug, % "Debug System: Failed to create new log file - " . e.message
	}
}

; Force create a proper debug log file
debugForceCreateMainLog() {
	global DebugLogFile
	
	OutputDebug, % "Debug System: Force creating main debug log file"
	
	; Generate a unique filename
	uniqueId := A_Now . "-" . A_TickCount
	mainPath := A_ScriptDir . "\debug\autohotpie-debug-" . uniqueId . ".log"
	
	try {
		; Create the file with initial content
		FileAppend, % "AutoHotPie Debug Log - " . A_Now . "`n", %mainPath%
		FileAppend, % "Debug System Initialized`n", %mainPath%
		FileAppend, % "==========================================`n", %mainPath%
		
		; Set it as the current log file
		DebugLogFile := mainPath
		OutputDebug, % "Debug System: Main debug log file created: " . DebugLogFile
		return true
	} catch e {
		OutputDebug, % "Debug System: Failed to create main debug log file - " . e.message
		return false
	}
}
