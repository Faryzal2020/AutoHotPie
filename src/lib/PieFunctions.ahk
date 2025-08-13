;To set the function to call from the JSON settings file, type in the
;part of the function after "pie_"

;Special function allowing submenus
pie_submenu(pieMenuAddress) {
	return
}

pie_sendKey(keyObject)
{
	; Debug logging for function call
	debugLogFunctionCall("pie_sendKey", keyObject, "Starting sendKey operation")
	
	if (keyObject.delayKeyRelease){		
		newKeyArray := []
		; msgbox, % keyObject.keys[0] . " " . keyObject.keys[1] . " " . keyObject.keys[2] . " " . keyObject.keys[3]
		for keyIndex, key in keyObject.keys
		{	
			bareKey := removeCharacters(key, "+^!#")
			
			; Debug logging for key processing
			debugLogKeyPress(bareKey, key, "Processing key " . keyIndex . " of " . keyObject.keys.Length())
			
			startModifierString := ""                
			endModifierString := ""
			If (InStr(key,"#")){
				startModifierString := startModifierString . "{LWin down}"
				endModifierString := endModifierString . "{LWin up}"
				debugLogModifierPress("Win", "Key: " . key)
			}
			If (InStr(key,"+")){                    
				startModifierString := startModifierString . "{shift down}"
				endModifierString := endModifierString . "{shift up}"
				debugLogModifierPress("Shift", "Key: " . key)
			}
			If (InStr(key,"^")){
				startModifierString := startModifierString . "{ctrl down}"
				endModifierString := endModifierString . "{ctrl up}"
				debugLogModifierPress("Ctrl", "Key: " . key)
			}
			If (InStr(key,"!")){
				startModifierString := startModifierString . "{alt down}"
				endModifierString := endModifierString . "{alt up}"
				debugLogModifierPress("Alt", "Key: " . key)
			}
			newKeyArray.Push(startModifierString . "{" . bareKey . " down}")				
			newKeyArray.Push("{" . bareKey . " up}" . endModifierString)
		}
		sendKeyArray := newKeyArray
		for keyIndex, key in sendKeyArray
		{
			if (keyIndex != 1) {
				sleep, % keyObject.keyDelay+1
			}
			debugLog("KEY_SEND", "Sending key: " . key, "Key " . keyIndex . " of " . sendKeyArray.Length())
			send, % key
		}
	} else {		
		sendKeyArray := keyObject.keys
		for keyIndex, key in sendKeyArray
		{ 
			if (keyIndex != 1) {
				sleep, % keyObject.keyDelay
			}
			bareKey := removeCharacters(key, "+^!#")
			keyToSend := StrReplace(key, bareKey, "{" .  bareKey . "}")
			debugLog("KEY_SEND", "Sending key: " . keyToSend, "Key " . keyIndex . " of " . sendKeyArray.Length())
			send, % keyToSend
		}
	}
	return	
}

pie_sendKeyWithHeldModifiers(keyObject)
{
	; Debug logging for function call
	debugLogFunctionCall("pie_sendKeyWithHeldModifiers", keyObject, "Starting sendKeyWithHeldModifiers operation")
	
	; Extract held modifiers and keys with error handling
	try {
		heldModifiers := keyObject.heldModifiers
		if (!heldModifiers)
			heldModifiers := ""
		keys := keyObject.keys
		if (!keys)
			keys := []
		keyDelay := keyObject.keyDelay
		if (!keyDelay)
			keyDelay := 30
		modifierHoldDelay := keyObject.modifierHoldDelay
		if (!modifierHoldDelay)
			modifierHoldDelay := 40
		
		keyCount := keys.Length()
	} catch e {
		debugLogError("Failed to extract parameters: " . e.message, "keyObject: " . JSON.Dump(keyObject))
		return
	}
	
	; Send modifiers down first
	if (InStr(heldModifiers, "#")) {
		send, {LWin down}
		debugLogModifierPress("Win", "Holding modifier for key sequence")
	}
	if (InStr(heldModifiers, "+")) {
		send, {shift down}
		debugLogModifierPress("Shift", "Holding modifier for key sequence")
	}
	if (InStr(heldModifiers, "^")) {
		send, {ctrl down}
		debugLogModifierPress("Ctrl", "Holding modifier for key sequence")
	}
	if (InStr(heldModifiers, "!")) {
		send, {alt down}
		debugLogModifierPress("Alt", "Holding modifier for key sequence")
	}
	
	; Optional delay after pressing modifiers
	if (modifierHoldDelay > 0) {
		debugLogSleep(modifierHoldDelay, "Delay after pressing modifiers", "Holding modifiers before sending keys")
		sleep, % modifierHoldDelay
	}
	
	; Send each key while modifiers are held
	for keyIndex, key in keys
	{
		if (keyIndex > 1) {
			debugLogSleep(keyDelay, "Delay between keystrokes", "Key " . keyIndex . " of " . keys.Length())
			sleep, % keyDelay
		}
			
		; Remove any modifiers from individual keys (they should be bare)
		bareKey := removeCharacters(key, "+^!#")
		debugLogKeyPress(bareKey, "Held modifiers: " . heldModifiers, "Key " . keyIndex . " of " . keys.Length())
		send, {%bareKey% down}
		debugLogKeyRelease(bareKey, "Held modifiers: " . heldModifiers, "Key " . keyIndex . " of " . keys.Length())
		send, {%bareKey% up}
	}
	
	; Delay after last keystroke before releasing modifiers (same as modifierHoldDelay)
	if (modifierHoldDelay > 0) {
		sleep, % modifierHoldDelay
	}
	
	; Release modifiers in reverse order
	if (InStr(heldModifiers, "!")) {
		send, {alt up}
		debugLogModifierRelease("Alt", "Releasing held modifier")
	}
	if (InStr(heldModifiers, "^")) {
		send, {ctrl up}
		debugLogModifierRelease("Ctrl", "Releasing held modifier")
	}
	if (InStr(heldModifiers, "+")) {
		send, {shift up}
		debugLogModifierRelease("Shift", "Releasing held modifier")
	}
	if (InStr(heldModifiers, "#")) {
		send, {LWin up}
		debugLogModifierRelease("Win", "Releasing held modifier")
	}
	
	return
}

	; msgbox, % keyObject.keys[1]	
	; msgbox, % keyObject.keys[2]	
	; msgbox, % keyObject.keys[3]	
	; msgbox, % keyObject.keys[4]	
	

pie_sendText(params) {
	; Debug logging for function call
	debugLogFunctionCall("pie_sendText", params, "Starting sendText operation")
	
	for index, txt in params.text
	{
		; msgbox pie_sendText`n%txt%
		if (index = 1) ; just incase someone malforms the json
			SendInput, {Text}%txt%
	}
}



pie_mouseClick(params){
	; Debug logging for function call
	debugLogFunctionCall("pie_mouseClick", params, "Starting mouseClick operation")
	
	; MouseButton - str, Shift - bool, Ctrl - bool, Alt - bool, Drag - bool
	;["LButton",1,0,0,0,0]
	RemapLButton := params.button
	modsDown := ""
	modsUp := ""
	mouseButton := params.button
	if(params.shift == true){
		modsDown := modsDown . "{shift down}"
		modsUp := modsUp . "{shift up}"
		debugLogModifierPress("Shift", "Mouse click operation")
	}
	if(params.ctrl == true){
		modsDown := modsDown . "{ctrl down}"
		modsUp := modsUp . "{ctrl up}"
		debugLogModifierPress("Ctrl", "Mouse click operation")
	}
	if(params.alt == true){
		modsDown := modsDown . "{alt down}"
		modsUp := modsUp . "{alt up}"
		debugLogModifierPress("Alt", "Mouse click operation")
	}
	send, %modsDown%		
	if (params.drag == true){
		debugLog("MOUSE_DRAG", "Starting mouse drag operation", "Button: " . mouseButton . ", Position: " . PieOpenLocX . "," . PieOpenLocY)
		lButtonWait(mouseButton)			
	} else {			
		debugLog("MOUSE_CLICK", "Performing mouse click", "Button: " . mouseButton . ", Position: " . PieOpenLocX . "," . PieOpenLocY)
		MouseClick, %mouseButton%, PieOpenLocX, PieOpenLocY, ,0
	}
	send, %modsUp%
	debugLog("MOUSE_COMPLETE", "Mouse operation completed", "Button: " . mouseButton)
	RemapLButton := ""
	return
}
pie_runScript(script) {
    ; Debug logging for function call
    debugLogFunctionCall("pie_runScript", script, "Starting runScript operation")
    
    script := script.filepath
    Try {
        If (SubStr(script, 1, 14) = "%A_WorkingDir%") {
            script := A_WorkingDir . SubStr(script, 15)
        }
        script := StrReplace(script, "%PieOpenLocX%", PieOpenLocX)
        script := StrReplace(script, "%PieOpenLocX%", PieOpenLocY)
        debugLog("SCRIPT_RUN", "Executing script", "Script: " . script . ", Position: " . PieOpenLocX . "," . PieOpenLocY)
        Run, % script
        return
    }
    catch e {
        MsgBox, % "Cannot run the script at:`n`n" . script
        return
    }
}
pie_openFolder(params) {
	; Debug logging for function call
	debugLogFunctionCall("pie_openFolder", params, "Starting openFolder operation")
	
	directory := params.filePath	
	if (FileExist(directory)){
		Run, %directory%
	} else {
		msgbox, % "Cannot find directory:`n" + directory
	}
}
pie_focusApplication(applications) {
	; Need to add this function to UI
	return
}

pie_eyedropper(mode) {
	; Debug logging for function call
	debugLogFunctionCall("pie_eyedropper", mode, "Starting eyedropper operation")
	
	PixelGetColor, pixelcol, PieOpenLocX, PieOpenLocY, RGB
	pixelcol := SubStr(pixelcol, 3, 6)
	clipboard = %pixelcol%
	Return		
}

pie_multiClipboard() {
	;Windows already has this so who cares
	return
}

pie_repeatLastFunction(timeOut) { ;special function
	return
}
pie_openSettings() {
	; Debug logging for function call
	debugLogFunctionCall("pie_openSettings", "", "Starting openSettings operation")
	
	;Different location for compiled version
	if (IsStandAlone){
		msgbox, "Cannot open AutoHotPie settings from standalone"
		return false
	}
	try {
		SplitPath, A_ScriptDir,, dir1
		SplitPath, dir1,, dir2
		run, % dir2 . "\AutoHotPie.exe"
		exitapp	
		return
	} catch e {
		msgbox, Cannot find AutoHotPie.exe
		return false
	}
}

pie_resizeWindow() { ;make this work thorugh here
	; Debug logging for function call
	debugLogFunctionCall("pie_resizeWindow", "", "Starting resizeWindow operation")
	
	; msgbox, % PieMenuPosition[1]
	xPos := PieOpenLocX
	yPos := PieOpenLocY
	WinGetPos, winX, winY, width, height, A
	if (xPos < winX){ ;to left of origin
		if (yPos > winY){ ;below origin
			WinMove, A,,xPos,, width+(winX-xPos), (yPos-winY)
		}else{ ;above origin
			WinMove, A,, xPos, yPos, width+(winX-xPos), height+(winY-yPos)		
		}	
	}else{ ;right of origin
		if (yPos > winY){ ;mouse below origin
			WinMove, A,,,, (xPos-winX), (yPos-winY)
		} else { ;mouse above origin
			WinMove, A,,,yPos, (xPos-winX), height+(winY-yPos)
		}	
	}
	Return
}

pie_moveWindow() { ;make this work thorugh here
	; Debug logging for function call
	debugLogFunctionCall("pie_moveWindow", "", "Starting moveWindow operation")
	
	WinGetPos, winX, winY, width, height, A
	WinMove, A, , PieOpenLocX-(width/2), PieOpenLocY-(width/3)
	return
}
pie_openURL(params){
	; Debug logging for function call
	debugLogFunctionCall("pie_openURL", params, "Starting openURL operation")
	
	url := params.url
	Try
	{
	run, % url
	return
	} catch e {
		msgbox, % "Cannot open URL at:`n`n" . url
	return
	}
}
pie_selectMenuItem(menuItems){
	; Debug logging for function call
	debugLogFunctionCall("pie_selectMenuItem", menuItems, "Starting selectMenuItem operation")
	
	WinMenuSelectItem, A, , menuItems[1], menuItems[2], menuItems[3], menuItems[4], menuItems[5], menuItems[6] 	
}
pie_switchApplication(params){
	; Debug logging for function call
	debugLogFunctionCall("pie_switchApplication", params, "Starting switchApplication operation")
	
	exePath := params.filePath
	multipleInstances := params.multipleInstanceApplication
	SplitPath, % params.filePath, ahkHandle
	ahkHandle := appendAHKTag(ahkHandle)
	If (multipleInstances) {
        groupName := StrReplace(SubStr(ahkHandle, InStr(ahkHandle," ")+1),".","")
        If (GetKeyState("Ctrl", "P"))
        {            
            Run, %exePath%            
            GroupAdd, %groupName%, %ahkHandle%
        } Else {            
            If !(WinExist(ahkHandle))
                {
                Run, %exePath%
                GroupAdd, %groupName%, %ahkHandle%
                Return
                }
            GroupAdd, %groupName%, %ahkHandle%
            if WinActive(ahkHandle)
                {
                GroupActivate, %groupName%, r
                sleep, 3
                }
            else
                WinActivate, %ahkHandle%
        }                 
    } Else {
        If !WinExist(ahkHandle) {
            Run, %exePath%
        } Else {
            WinActivate, %ahkHandle%
        }             
    }	
}
pie_afterfx_cursorToPlayhead() {
	; Debug logging for function call
	debugLogFunctionCall("pie_afterfx_cursorToPlayhead", "", "Starting afterfx_cursorToPlayhead operation")
	
	return
}

pie_afterfx_runPieScript() {
	; Debug logging for function call
	debugLogFunctionCall("pie_afterfx_runPieScript", "", "Starting afterfx_runPieScript operation")
	
	return
}


pie_Photoshop_cycleTool(cycleTools) { ;cycle through array of tools.  The array can have only one value as well.
	; Debug logging for function call
	debugLogFunctionCall("pie_Photoshop_cycleTool", cycleTools, "Starting Photoshop cycleTool operation")
	
	; photoshopTools := ["moveTool","artboardTool","marqueeRectTool","marqueeEllipTool","marqueeSingleRowTool","marqueeSingleColumnTool","lassoTool","polySelTool","magneticLassoTool","quickSelectTool","magicWandTool","cropTool","perspectiveCropTool","sliceTool","sliceSelectTool","framedGroupTool","eyedropperTool","3DMaterialSelectTool","colorSamplerTool","rulerTool","textAnnotTool","countTool","spotHealingBrushTool","magicStampTool","patchSelection","recomposeSelection","redEyeTool","paintbrushTool","pencilTool","colorReplacementBrushTool","wetBrushTool","cloneStampTool","patternStampTool","historyBrushTool","artBrushTool","eraserTool","backgroundEraserTool","magicEraserTool","gradientTool","bucketTool","3DMaterialDropTool","blurTool","sharpenTool","smudgeTool","dodgeTool","burnInTool","saturationTool","penTool","freeformPenTool","curvaturePenTool","addKnotTool","deleteKnotTool","convertKnotTool","typeCreateOrEditTool","typeVerticalCreateOrEditTool","typeVerticalCreateMaskTool","typeCreateMaskTool","pathComponentSelectTool","directSelectTool","rectangleTool","roundedRectangleTool","ellipseTool","polygonTool","lineTool","customShapeTool","handTool","rotateTool","zoomTool"]			
	appRef := ComObjActive( "Photoshop.Application" )
	; msgbox, % cycleTools.Length() "  " appRef.CurrentTool "  " cycleTools[1]
	if cycleTools.Length() = 1
		{
		appRef.CurrentTool := cycleTools[1]
		return
		}
	for tool in cycleTools
		{
		if appRef.CurrentTool == cycleTools[tool]
			{
			; msgbox, % cycleTools[tool] " and " appRef.CurrentTool
			if appRef.CurrentTool = cycleTools[cycleTools.Length()]
				{
				appRef.CurrentTool := cycleTools[1]
				return
				; break
				}
			appRef.CurrentTool := cycleTools[tool+1]
			return
				; break
			}
		}
	appRef.CurrentTool := cycleTools[1]
	return
}

pie_Photoshop_sampleColor() {
	; Debug logging for function call
	debugLogFunctionCall("pie_Photoshop_sampleColor", "", "Starting Photoshop sampleColor operation")
	
	appRef := ComObjActive( "Photoshop.Application" )
	prevTool := appRef.CurrentTool
	appRef.CurrentTool := "eyedropperTool"
	MouseClick, Left, , , , 0
	sleep,5
	appRef.CurrentTool := prevTool
	return
}


pie_Photoshop_toggleLayerByName(layerNames) { ; toggles on/off a layer by name
	; Debug logging for function call
	debugLogFunctionCall("pie_Photoshop_toggleLayerByName", layerNames, "Starting Photoshop toggleLayerByName operation")
	
	appRef := ComObjActive( "Photoshop.Application" )
    ref := ComObjCreate( "Photoshop.ActionReference" )
    for layerName in layerNames
	{		
		ref.putName( appRef.stringIDToTypeID("layer"), layerNames[layerName] )
    	desc := ComObjCreate( "Photoshop.ActionDescriptor" )
    	desc.putReference( appRef.stringIDToTypeID( "null" ), ref )

		if appRef.executeActionGet(ref).getBoolean( appRef.stringIDToTypeID( "visible" )) == -1
    	    appRef.executeAction( appRef.charIDToTypeID( "Hd  " ), desc, 3 )
    	else
    	    appRef.executeAction( appRef.charIDToTypeID( "Shw " ), desc, 3 )
	}
	return
}

; name should be in quotes ex.: "roundbrush"
pie_Photoshop_cycleBrush(brushNames) {
	; Debug logging for function call
	debugLogFunctionCall("pie_Photoshop_cycleBrush", brushNames, "Starting Photoshop cycleBrush operation")
	
    appRef := ComObjActive( "Photoshop.Application" )
    desc := ComObjCreate( "Photoshop.ActionDescriptor" )
	ref := ComObjCreate( "Photoshop.ActionReference" )
	if brushNames.Length() = 1
		{		
    	ref.putName( appRef.charIDToTypeID( "Brsh" ), brushNames[1])
    	desc.putReference( appRef.charIDToTypeID( "null" ), ref )
    	appRef.executeAction( appRef.charIDToTypeID( "slct" ), desc, 3 )	
		}
	else
		{
		
		}
    ref.putName( appRef.charIDToTypeID( "Brsh" ), brushNames[1])
    desc.putReference( appRef.charIDToTypeID( "null" ), ref )
    appRef.executeAction( appRef.charIDToTypeID( "slct" ), desc, 3 )
    return
}

pie_customFunction(functionObject){
	; Debug logging for function call
	debugLogFunctionCall("pie_customFunction", functionObject, "Starting customFunction operation")
	
	Try
	{
		p_funcName := "customFunc_" . functionObject.id
		p_funcParams := functionObject.params		
		%p_funcName%(p_funcParams)
	} catch e {
		msgbox, %e%
		return
	}
}


