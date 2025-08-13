#Requires AutoHotKey v1.1.34.04+
#Persistent
#NoEnv
#SingleInstance force
SetBatchLines -1
ListLines Off
SetWinDelay, 0		; Changed to 0 upon recommendation of documentation
SetControlDelay, 0	; Changed to 0 upon recommendation of documentation

#Include %A_ScriptDir%\lib\Gdip_All.ahk
#Include %A_ScriptDir%\lib\GdipHelper.ahk
#Include %A_ScriptDir%\lib\BGFunks.ahk
#Include %A_ScriptDir%\lib\PieFunctions.ahk
#Include %A_ScriptDir%\lib\Json.ahk
#Include %A_ScriptDir%\lib\debugHelper.ahk


;Set Per monitor DPI awareness: https://www.autohotkey.com/boards/viewtopic.php?p=295182#p295182
DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")
CoordMode, Mouse, Screen
SetTitleMatchMode, RegEx ;May not need this anymore

;Check AHK version and if AHK is installed.  Prompt install or update.
if (!A_IsCompiled)
	checkAHK()

; Debug system global variables (must be declared before including debugHelper.ahk)
global DebugMode := false  ; Will be set from settings
global DebugLogEnabled := false
global DebugLogFile := ""
global DebugLogBuffer := []
global DebugBufferSize := 100
global DebugLastTimestamp := A_TickCount

global RemapLButton := ""

;Read Json Settings file to object from AppData\Local\AutoHotPie

global UserDataFolder, Settings
global IsStandAlone := false
loadSettingsFile() ;loads JSON to Settings global variable

; Read debug setting from loaded settings
if (Settings && Settings.global && Settings.global.debugSystem) {
    DebugMode := Settings.global.debugSystem.enabled
    ; OutputDebug, % "Debug mode set from settings: " . (DebugMode ? "enabled" : "disabled")
} else {
    DebugMode := false
    ; OutputDebug, % "Debug mode not found in settings, using default: disabled"
}

; Show settings data popup before continuing
; Use a timer to show the popup after debug system initialization completes
; This popup will display all loaded settings data before the script continues running
SetTimer, ShowSettingsPopup, -500

; Initialize debug system if enabled
if (DebugMode) {
    try {
        debugInit()
        
        ; Show global state after initialization
        if (IsFunc("debugShowGlobalState")) {
            debugShowGlobalState()
        }
        
        ; Direct check of global variables
        OutputDebug, % "=== DIRECT GLOBAL VARIABLE CHECK ==="
        OutputDebug, % "DebugMode = " . DebugMode
        OutputDebug, % "DebugLogEnabled = " . DebugLogEnabled
        OutputDebug, % "DebugLogFile = " . DebugLogFile
        OutputDebug, % "DebugBufferSize = " . DebugBufferSize
        
        ; Check what debugInit() actually set
        if (DebugLogFile) {
            OutputDebug, % "SUCCESS: debugInit() set DebugLogFile to: " . DebugLogFile
        } else {
            OutputDebug, % "ERROR: debugInit() did not set DebugLogFile"
        }
        
        ; If debugInit() failed to create a proper debug log file, force create one
        if (!DebugLogFile || InStr(DebugLogFile, "fallback")) {
            OutputDebug, % "WARNING: Using fallback or no debug file, forcing main debug log creation"
            if (IsFunc("debugForceCreateMainLog")) {
                if (debugForceCreateMainLog()) {
                    OutputDebug, % "SUCCESS: Forced creation of main debug log file: " . DebugLogFile
                } else {
                    OutputDebug, % "ERROR: Failed to force create main debug log file"
                }
            }
        }
        
        OutputDebug, % "====================================="
        
        ; Add a test log entry to verify the system is working
        debugLog("INFO", "Debug mode enabled from settings", "Settings loaded")
        debugLog("TEST", "Debug system test - AutoHotkey script starting", "Initialization phase")
        
        ; Add additional test entries to verify logging is working
        debugLog("TEST", "Testing debug log function", "Verification phase")
        debugLog("TEST", "Testing debug buffer", "Verification phase")
        
        ; Force flush any buffered logs
        debugLog("INFO", "About to flush debug buffer", "Pre-flush")
        debugFlushBuffer()
        debugLog("INFO", "Debug buffer flushed", "Post-flush")
        
        ; Test file writing directly
        try {
            
            ; Also test writing to the debug log file if it's available
            if (IsFunc("debugGetLogFilePath")) {
                actualDebugPath := debugGetLogFilePath()
                if (actualDebugPath) {
                    debugLog("INFO", "Testing write to actual debug file", "Path: " . actualDebugPath)
                    ; Force a flush to see if it works
                    debugFlushBuffer()
                }
            }
            
                    ; Test global variable access
        OutputDebug, % "Main script - DebugLogFile = " . DebugLogFile
        OutputDebug, % "Main script - DebugLogEnabled = " . DebugLogEnabled
        OutputDebug, % "Main script - DebugMode = " . DebugMode
        
        ; Test if the main debug system is working (without overriding it)
        OutputDebug, % "=== MAIN DEBUG SYSTEM TEST ==="
        OutputDebug, % "Main debug system DebugLogFile = " . DebugLogFile
        
        ; Test if debugLog works with the main debug system
        if (DebugLogFile) {
            OutputDebug, % "Main debug system test - Writing to debug log"
            debugLog("MAIN_SYSTEM_TEST", "Main debug system test entry", "System verification")
            debugFlushBuffer()
            OutputDebug, % "Main debug system test completed"
        } else {
            OutputDebug, % "Main debug system not properly initialized"
        }
    }
        
    } catch e {
        ; If debug initialization fails, disable debug mode
        DebugMode := false
        OutputDebug, % "Debug system initialization failed: " . e.message . " - Disabling debug mode"
    }
}

;Initialize Variables and GDI+ Screen bitmap
;Tariq Porter, you will forever have a special place in my heart.

global Mon := {left: 0,	right: 0, top: 0,bottom: 0, pieDPIScale: 1}
global G ; For GDIP
global pGraphics, hbm, hdc, obm, hwnd ;For Gdip+ stuff, may not be needed.
global BitmapPadding

global PieOpenLocX	;X Position of where pie menu is opened
global PieOpenLocY	;Y ^
global SubPieLocX	;X Position of where pie menu is opened
global SubPieLocY	;Y ^
global ActivePieHotkey
global ActivePieNumber
global ActivePieSliceHotkeyArray := [] ;loadSliceHotkeys()
global PressedSliceHotkeyName := ""
global PressedPieKeyAgain := false
global ActiveProfile
global PieLaunchedState := false

global PenClicked := false
global PieMenuRanWithMod := false

global LMB
LMB.pressed := false
global SliceHotkey
SliceHotkey.pressed := false
global ExitKey
ExitKey.pressed := false

; global pieDPIScale
getMonitorCoords(Mon.left , Mon.right , Mon.top , Mon.bottom )

;Init G Text
SetUpGDIP(0, 0, 50, 50) ;windows were appearing over taskbar without -0.01
SetUpGDIP(0, 0, 0, 0) ; To Fix white box in screenshare (https://github.com/dumbeau/AutoHotPie/issues/115)

verifyFont()

;Set up icon menu tray options
if (A_IsCompiled){
	if (!IsStandAlone){
		Menu, Tray, Add , AutoHotPie Settings, openSettings
	}
	Menu, Tray, NoStandard
	Menu, Tray, Add , Restart, Rel
	Menu, Tray, Add , Exit, QuitPieMenus
	Menu, Tray, Tip , AutoHotPie
} else {
	if (!IsStandAlone){
		Menu, Tray, Add , AutoHotPie Settings, openSettings
	}
	Menu, Tray, Add , Restart, Rel
}
if (!IsStandAlone){
	Menu, Tray, Default , AutoHotPie Settings
}
loadPieMenus()



return ;End Initialization

pieLabel: ;Fixed hotkey overlap "r and ^r", refactor this
	; Issue with MOI3d, pie menus don't want to show in that application specifically, so this display refresh thing sometimes works.
	; SetUpGDIP(monLeft, monTop, monRight-monLeft, monBottom-monTop, "Hide")
	; SetUpGDIP(monLeft, monTop, monRight-monLeft, monBottom-monTop, "Show")
	
	; Debug logging for pie menu activation
	debugLog("PIE_ACTIVATION", "Pie menu hotkey triggered", "Hotkey: " . A_ThisHotkey . ", PieLaunchedState: " . PieLaunchedState)
	
	;Re-initialize variables
	if (PieLaunchedState == true){
		PressedSliceHotkeyName := A_ThisHotkey ;This line made me feel things again :)
		debugLog("PIE_DUPLICATE", "Pie menu already launched, ignoring duplicate hotkey", "Hotkey: " . A_ThisHotkey)
		;Handle same piekey pressed again?
		return
	}
	else
		hotKeyArray := []
	PieLaunchedState := true
	ActivePieHotkey := A_ThisHotkey


	ActiveProfile := getActiveProfile()
	activeProfileString := getProfileString(ActiveProfile)
	; tooltip % activeProfileString
	if (SubStr(activeProfileString, -3) = "Func")       ;custom context
	{
		fn := Func(activeProfileString)
		Hotkey, If, % fn
	}
	else if (activeProfileString = "ahk_group regApps")   ;default context
	{
		Hotkey, IfWinNotActive, ahk_group regApps
	}
	else                                                ;app specific context
	{
		Hotkey, IfWinActive, % activeProfileString
	}
	
	;Push hotkey to hotkeyArray to be blocked when pie menus are running.
	for k, pieKey in ActiveProfile.pieKeys
	{

		hotKeyArray.Push(pieKey.hotkey)
		; OutputDebug, % pieKey.hotkey
		; if (pieKey.hotkey == ActivePieHotkey)
		; {
		; 	for k2, pieMenu in pieKey.pieMenus
		; 	{
		; 		for k3, func in pieMenu.functions
		; 		{
		; 			if (func.hotkey != "")
		; 			{
		; 				; msgbox, % func.hotkey
		; 				hotKeyArray.Push(func.hotkey)
		; 			}
		; 		}
		; 	}
		; }
	}

	for k, menu in ActiveProfile.pieKeys
	{
		if (menu.hotkey == ActivePieHotkey)
		{
			debugLog("PIE_EXECUTION", "Executing pie menu", "Menu: " . k . ", Hotkey: " . ActivePieHotkey . ", Profile: " . ActiveProfile.name)
			
			blockBareKeys(ActivePieHotkey, hotKeyArray, true)
			funcAddress := runPieMenu(ActiveProfile, k)
			PieLaunchedState := false

			if (ActiveProfile.pieEnableKey.useEnableKey)
				pieEnableKey.modOff()

			blockBareKeys(ActivePieHotkey, hotKeyArray, false)

			;deactivate dummy keys
			ActivePieHotkey := ""
			debugLog("PIE_FUNCTION", "Running pie function", "Function: " . funcAddress.label . ", Address: " . funcAddress)
			; msgbox, % funcAddress.label
			runPieFunction(funcAddress)
			SetUpGDIP(0, 0, 0, 0) ; To Fix white box in screenshare (https://github.com/dumbeau/AutoHotPie/issues/115)
			EmptyMem()
			break
		}
	}
return

togglePieLabel:
	pieEnableKey.modToggle()
return

onPieLabel:
	pieEnableKey.modOn()
; msgbox, On
return

offPieLabel:
	pieEnableKey.modOff()
; msgbox, ActiveProfile
; msgbox, off
return

blockLabel:
	PressedSliceHotkeyName := A_ThisHotkey
; msgbox, % PressedSliceHotkeyName
return

#If DebugMode = true
	{
		escape::
		exitapp
		return
	}

;I hate you so much... windows ink.
;220705 - windows ink still makes me sad.

#IfWinActive, ahk_exe PieMenu.exe
	~LButton up::
		sleep,200
		if WinExist("ahk_exe PieMenu.exe")
			exitapp
	return
	~Enter up::
		sleep,200
		if WinExist("AutoHotPie Uninstall")
			exitapp
	return
#IfWinActive, ahk_exe Un_A.exe
	~LButton up::
		sleep,100
		if WinExist("AutoHotPie Uninstall")
			exitapp
	return
	~Enter up::
		sleep,100
		if WinExist("AutoHotPie Uninstall")
			exitapp
	return
#IfWinActive, AutoHotPie Setup
	~LButton up::
		sleep,100
		if WinExist("AutoHotPie Setup")
			exitapp
	return
	~Enter up::
		sleep,100
		if WinExist("AutoHotPie Setup")
			exitapp
	return

#If (PieLaunchedState == 1)
	LButton::
		LMB.pressed := true
	; PenClicked := true
	;Check pie launched state again?
	Return
	LButton up::
		LMB.pressed := false
	; PenClicked := false
	;Check pie launched state again?
	Return

;For mouseClick function
#If (RemapLButton == "right")
	LButton::RButton
#If (RemapLButton == "middle")
	LButton::MButton
#If ;This ends the context-sensitivity

SliceHotkeyPress:
	SliceHotkey.pressed := true
return
SliceHotkeyRelease:
	SliceHotkey.pressed := false
return
ExitKeyPress:
	ExitKey.pressed := true
return
ExitKeyRelease:
	ExitKey.pressed := false
return

~esc::
	if (settings.global.enableEscapeKeyMenuCancel)
		PieLaunchedState := false
return

;If a display is connected or disconnected
OnMessage(0x7E, "WM_DISPLAYCHANGE")
return
WM_DISPLAYCHANGE(wParam, lParam)
{
	sleep, 200
	if (DebugMode) {
		try {
			debugLog("INFO", "Display change detected, flushing debug logs before reload")
			debugFlushBuffer()
		} catch e {
			OutputDebug, % "Failed to flush debug logs on display change: " . e.message
		}
	}
	Reload
	return
}

Rel:
if (DebugMode) {
    try {
        debugLog("INFO", "Script reloading, flushing debug logs")
        debugFlushBuffer()
    } catch e {
        OutputDebug, % "Failed to flush debug logs on reload: " . e.message
    }
}
Reload
Return

openSettings:
	pie_openSettings()
Return

; Timer label to show settings popup
ShowSettingsPopup:
    ;showSettingsDataPopup()
return

; Function to display all loaded settings data in a popup window
showSettingsDataPopup() {
    try {
        ; Create a formatted string with all settings data
        settingsText := "AutoHotPie Settings Data Loaded:`n`n"
        
        ; Add basic script information
        settingsText .= "Script Information:`n"
        settingsText .= "=================`n"
        settingsText .= "Script Directory: " . A_ScriptDir . "`n"
        settingsText .= "Working Directory: " . A_WorkingDir . "`n"
        settingsText .= "User Data Folder: " . (UserDataFolder ? UserDataFolder : "Not set") . "`n"
        settingsText .= "Is Standalone: " . (IsStandAlone ? "Yes" : "No") . "`n"
        settingsText .= "Debug Mode: " . (DebugMode ? "Enabled" : "Disabled") . "`n`n"
    
    ; Add global settings
    if (Settings && Settings.global) {
        settingsText .= "Global Settings:`n"
        settingsText .= "=================`n"
        
        ; App version
        if (Settings.global.app && Settings.global.app.version) {
            settingsText .= "App Version: " . Settings.global.app.version . "`n"
        }
        
        ; Startup settings
        if (Settings.global.startup) {
            settingsText .= "Run on Startup: " . (Settings.global.startup.runOnStartup ? "Yes" : "No") . "`n"
            settingsText .= "Run AHK Pie Menus: " . (Settings.global.startup.runAHKPieMenus ? "Yes" : "No") . "`n"
            settingsText .= "Always Run on Quit: " . (Settings.global.startup.alwaysRunOnAppQuit ? "Yes" : "No") . "`n"
        } else {
            settingsText .= "Startup settings: Not configured`n"
        }
        
        ; Escape key setting
        if (Settings.global.enableEscapeKeyMenuCancel != "") {
            settingsText .= "Escape Key Menu Cancel: " . (Settings.global.enableEscapeKeyMenuCancel ? "Yes" : "No") . "`n"
        }
        
        ; Debug system settings
        if (Settings.global.debugSystem) {
            settingsText .= "Debug System Enabled: " . (Settings.global.debugSystem.enabled ? "Yes" : "No") . "`n"
            if (Settings.global.debugSystem.logLevel) {
                settingsText .= "Debug Log Level: " . Settings.global.debugSystem.logLevel . "`n"
            }
            if (Settings.global.debugSystem.bufferSize) {
                settingsText .= "Debug Buffer Size: " . Settings.global.debugSystem.bufferSize . "`n"
            }
        }
        
        ; Add debug log directory information
        if (DebugMode) {
            try {
                ; Get the debug log file path from debugHelper
                if (IsFunc("debugGetLogFilePath")) {
                    debugLogPath := debugGetLogFilePath()
                    if (debugLogPath) {
                        SplitPath, debugLogPath, , debugDir
                        settingsText .= "Debug Log Directory: " . debugDir . "`n"
                        settingsText .= "Debug Log File: " . debugLogPath . "`n"
                        settingsText .= "Debug Directory Exists: " . (FileExist(debugDir) ? "Yes" : "No") . "`n"
                        if (FileExist(debugDir)) {
                            ; Check if directory is writable
                            testFile := debugDir . "\test-write.tmp"
                            try {
                                FileDelete, %testFile%
                                FileAppend, test, %testFile%
                                FileDelete, %testFile%
                                settingsText .= "Debug Directory Writable: Yes`n"
                            } catch e {
                                settingsText .= "Debug Directory Writable: No - " . e.message . "`n"
                            }
                        }
                    } else {
                        settingsText .= "Debug Log Directory: Not available`n"
                    }
                } else {
                    ; Fallback: show where we expect the debug folder to be
                    expectedDebugDir := A_ScriptDir . "\debug"
                    settingsText .= "Expected Debug Directory: " . expectedDebugDir . "`n"
                    settingsText .= "Expected Debug Directory Exists: " . (FileExist(expectedDebugDir) ? "Yes" : "No") . "`n"
                    if (FileExist(expectedDebugDir)) {
                        ; Check if directory is writable
                        testFile := expectedDebugDir . "\test-write.tmp"
                        try {
                            FileDelete, %testFile%
                            FileAppend, test, %testFile%
                            FileDelete, %testFile%
                            settingsText .= "Expected Debug Directory Writable: Yes`n"
                        } catch e {
                            settingsText .= "Expected Debug Directory Writable: No - " . e.message . "`n"
                        }
                    }
                }
                
                ; Add debug system function availability check
                settingsText .= "`nDebug System Functions:`n"
                settingsText .= "----------------------`n"
                settingsText .= "debugInit() available: " . (IsFunc("debugInit") ? "Yes" : "No") . "`n"
                settingsText .= "debugLog() available: " . (IsFunc("debugLog") ? "Yes" : "No") . "`n"
                settingsText .= "debugFlushBuffer() available: " . (IsFunc("debugFlushBuffer") ? "Yes" : "No") . "`n"
                settingsText .= "debugGetLogFilePath() available: " . (IsFunc("debugGetLogFilePath") ? "Yes" : "No") . "`n"
                
                ; Add debug system status information
                settingsText .= "`nDebug System Status:`n"
                settingsText .= "-------------------`n"
                if (IsFunc("debugGetLogFilePath")) {
                    try {
                        currentLogPath := debugGetLogFilePath()
                        if (currentLogPath) {
                            SplitPath, currentLogPath, , currentLogDir
                            settingsText .= "Current Log Directory: " . currentLogDir . "`n"
                            settingsText .= "Current Log File: " . currentLogPath . "`n"
                            
                            ; Check if any debug files exist in the directory
                            debugFileCount := 0
                            Loop, Files, %currentLogDir%\*.log, F
                            {
                                debugFileCount++
                            }
                            settingsText .= "Existing Debug Files: " . debugFileCount . " files`n"
                            
                            ; Show the most recent debug file if any exist
                            if (debugFileCount > 0) {
                                Loop, Files, %currentLogDir%\*.log, F
                                {
                                    mostRecentFile := A_LoopFileFullPath
                                    break
                                }
                                if (mostRecentFile) {
                                    FileGetSize, fileSize, %mostRecentFile%
                                    settingsText .= "Most Recent File: " . A_LoopFileName . " (" . fileSize . " bytes)`n"
                                }
                            }
                        }
                    } catch e {
                        settingsText .= "Error getting current debug status: " . e.message . "`n"
                    }
                }
                
                ; Add debug system initialization status
                settingsText .= "`nDebug System Initialization:`n"
                settingsText .= "----------------------------`n"
                settingsText .= "Debug Mode Variable: " . (DebugMode ? "True" : "False") . "`n"
                
                ; Add debug system variable states
                settingsText .= "`nDebug System Variables:`n"
                settingsText .= "------------------------`n"
                if (IsFunc("debugGetLogFilePath")) {
                    try {
                        currentLogPath := debugGetLogFilePath()
                        settingsText .= "debugGetLogFilePath() returns: " . (currentLogPath ? currentLogPath : "Empty/Null") . "`n"
                    } catch e {
                        settingsText .= "debugGetLogFilePath() error: " . e.message . "`n"
                    }
                }
                
                ; Check global variables from debugHelper
                try {
                    ; Try to access global variables directly
                    if (IsFunc("debugGetLogFilePath")) {
                        ; Get the actual debug log file path
                        actualPath := debugGetLogFilePath()
                        if (actualPath) {
                            SplitPath, actualPath, , actualDir
                            settingsText .= "Actual Debug Directory: " . actualDir . "`n"
                            settingsText .= "Actual Debug File: " . actualPath . "`n"
                            
                            ; Check if the actual directory exists and is writable
                            if (FileExist(actualDir)) {
                                settingsText .= "Actual Debug Directory Exists: Yes`n"
                                
                                ; Test write permission to actual directory
                                testFile := actualDir . "\popup-test-write.tmp"
                                try {
                                    FileDelete, %testFile%
                                    FileAppend, popup test, %testFile%
                                    FileDelete, %testFile%
                                    settingsText .= "Actual Debug Directory Writable: Yes`n"
                                } catch e {
                                    settingsText .= "Actual Debug Directory Writable: No - " . e.message . "`n"
                                }
                            } else {
                                settingsText .= "Actual Debug Directory Exists: No`n"
                            }
                        } else {
                            settingsText .= "Actual Debug Directory: Not available`n"
                        }
                    }
                } catch e {
                    settingsText .= "Error checking actual debug path: " . e.message . "`n"
                }
                
                ; Check if debug functions are working
                if (IsFunc("debugLog")) {
                    try {
                        ; Test debug log function
                        debugLog("TEST", "Testing debug log from popup", "Popup test")
                        settingsText .= "debugLog() Test: Success`n"
                    } catch e {
                        settingsText .= "debugLog() Test: Failed - " . e.message . "`n"
                    }
                } else {
                    settingsText .= "debugLog() Test: Function not available`n"
                }
                
                ; Check if debug buffer flush is working
                if (IsFunc("debugFlushBuffer")) {
                    try {
                        debugFlushBuffer()
                        settingsText .= "debugFlushBuffer() Test: Success`n"
                    } catch e {
                        settingsText .= "debugFlushBuffer() Test: Failed - " . e.message . "`n"
                    }
                } else {
                    settingsText .= "debugFlushBuffer() Test: Function not available`n"
                }
                
                ; Test the debug system directly
                if (IsFunc("debugTest")) {
                    try {
                        debugTest()
                        settingsText .= "debugTest() Test: Success`n"
                    } catch e {
                        settingsText .= "debugTest() Test: Failed - " . e.message . "`n"
                    }
                } else {
                    settingsText .= "debugTest() Test: Function not available`n"
                }
                
                ; Show global variable state
                if (IsFunc("debugShowGlobalState")) {
                    try {
                        debugShowGlobalState()
                        settingsText .= "debugShowGlobalState() Test: Success`n"
                    } catch e {
                        settingsText .= "debugShowGlobalState() Test: Failed - " . e.message . "`n"
                    }
                } else {
                    settingsText .= "debugShowGlobalState() Test: Function not available`n"
                }
                
                ; Test file access permissions
                if (IsFunc("debugTestFileAccess")) {
                    try {
                        debugTestFileAccess()
                        settingsText .= "debugTestFileAccess() Test: Success`n"
                    } catch e {
                        settingsText .= "debugTestFileAccess() Test: Failed - " . e.message . "`n"
                    }
                } else {
                    settingsText .= "debugTestFileAccess() Test: Function not available`n"
                }
                
                
                ; Check for all debug-related files in script directory
                settingsText .= "`nDebug Files in Script Directory:`n"
                settingsText .= "--------------------------------`n"
                debugFileCount := 0
                Loop, Files, %A_ScriptDir%\*.log, F
                {
                    debugFileCount++
                    if (debugFileCount <= 5) { ; Show first 5 files
                        FileGetSize, fileSize, %A_LoopFileFullPath%
                        settingsText .= "  " . A_LoopFileName . " (" . fileSize . " bytes)`n"
                    }
                }
                if (debugFileCount > 5) {
                    settingsText .= "  ... and " . (debugFileCount - 5) . " more files`n"
                }
                if (debugFileCount == 0) {
                    settingsText .= "  No .log files found`n"
                }
                
                ; Check for debug subdirectory
                debugSubDir := A_ScriptDir . "\debug"
                if (FileExist(debugSubDir)) {
                    settingsText .= "`nDebug Subdirectory Contents:`n"
                    settingsText .= "----------------------------`n"
                    debugSubFileCount := 0
                    Loop, Files, %debugSubDir%\*.log, F
                    {
                        debugSubFileCount++
                        if (debugSubFileCount <= 5) { ; Show first 5 files
                            FileGetSize, fileSize, %A_LoopFileFullPath%
                            settingsText .= "  " . A_LoopFileName . " (" . fileSize . " bytes)`n"
                        }
                    }
                    if (debugSubFileCount > 5) {
                        settingsText .= "  ... and " . (debugSubFileCount - 5) . " more files`n"
                    }
                    if (debugSubFileCount == 0) {
                        settingsText .= "  No .log files in debug subdirectory`n"
                    }
                } else {
                    settingsText .= "`nDebug Subdirectory: Does not exist`n"
                }
                
            } catch e {
                settingsText .= "Debug Log Directory: Error getting path - " . e.message . "`n"
            }
        }
        
        ; Global appearance settings
        if (Settings.global.globalAppearance) {
            settingsText .= "`nGlobal Appearance:`n"
            settingsText .= "-----------------`n"
            if (Settings.global.globalAppearance.font) {
                settingsText .= "Font: " . Settings.global.globalAppearance.font . "`n"
            }
            if (Settings.global.globalAppearance.fontSize) {
                settingsText .= "Font Size: " . Settings.global.globalAppearance.fontSize . "`n"
            }
        }
        
                settingsText .= "`n"
    } else {
        settingsText .= "Global Settings: Not found`n`n"
    }
    
    ; Add simplified profile information (focus on debug system)
    if (Settings && Settings.appProfiles) {
        settingsText .= "Application Profiles:`n"
        settingsText .= "====================`n"
        settingsText .= "Total Profiles: " . Settings.appProfiles.Length() . "`n"
        settingsText .= "Profile Names: "
        
        ; Just show profile names, not detailed content
        for index, profile in Settings.appProfiles {
            if (index > 1) {
                settingsText .= ", "
            }
            settingsText .= (profile.name ? profile.name : "Unnamed")
        }
        settingsText .= "`n`n"
    } else {
        settingsText .= "Application Profiles: None found`n`n"
    }
    
    ; Add any other settings that might exist
    if (Settings) {
        ; Check for any other top-level settings
        for key, value in Settings {
            if (key != "global" && key != "appProfiles") {
                if (IsObject(value)) {
                    settingsText .= key . " (Object): " . JSON.Dump(value) . "`n"
                } else {
                    settingsText .= key . ": " . value . "`n"
                }
            }
                }
    }
    
    ; Summary removed - focusing on debug system information
    
    ; Show the popup with all settings data
        MsgBox, 64, AutoHotPie Settings Data, %settingsText%
    } catch e {
        ; If there's an error, show a simplified popup
        errorText := "AutoHotPie Settings Data Loaded:`n`n"
        errorText .= "Script Information:`n"
        errorText .= "=================`n"
        errorText .= "Script Directory: " . A_ScriptDir . "`n"
        errorText .= "Working Directory: " . A_WorkingDir . "`n"
        errorText .= "Debug Mode: " . (DebugMode ? "Enabled" : "Disabled") . "`n`n"
        errorText .= "Error displaying full settings: " . e.message . "`n"
        errorText .= "Settings object exists: " . (Settings ? "Yes" : "No") . "`n"
        
        MsgBox, 48, AutoHotPie Settings Data (Error), %errorText%
    }
}

QuitPieMenus:
if (DebugMode) {
    try {
        debugLog("INFO", "Script exiting, flushing debug logs")
        debugFlushBuffer()
    } catch e {
        OutputDebug, % "Failed to flush debug logs on exit: " . e.message
    }
}
exitapp
return
