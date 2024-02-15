#Requires AutoHotkey v2.0

FontName           := 'Book Antiqua'
FontSize           := 12 ; suggestion size calculated by font size and and works fine with different DPIs tested on 125% 150%

;************************************* suggester *************************************
; Listview
main := Gui('-Caption +ToolWindow +AlwaysOnTop +LastFound')
main.oldHwnd := 0
main.SetFont('s' FontSize,FontName)

LV := main.AddListView('x0 y0 -HDR AltSubmit' ,['suggestion'])
LV.SetFont('s' FontSize)
LV.OnEvent('ItemSelect',SkipFirstSuggestions)

main.MarginX := main.MarginY := 0
;LV.OnEvent('DoubleClick',CompleteWord)
main.Show('hide')

Prompt := InputHook('V')
Prompt.OnChar := CheckPrompt
Prompt.Start()

DllCall 'RegisterShellHookWindow', 'UInt', Main.hwnd
MsgNum := DllCall('RegisterWindowMessage', 'Str','SHELLHOOK')
OnMessage(MsgNum, changeWinfocus)


SkipFirstSuggestions(ctrl, index, selected)
{
	if index = 1
	{
		LV.Modify(1,'-select -focus')
		LV.Modify(2,'+select +focus')
	}
}


RunwithStartup(*)
{
	Global autostartup
	script.Autostart(autostartup := !autostartup)
	IniWrite(autostartup,script.config,'Auto','Startup')
	tray.ToggleCheck('Run with Start up')
}

changeWinfocus(wParam, lParam, msg, hwnd)
{
	static WS_VISIBLE := 0x10000000
	static WM_ACTIVATE := 49193
	switch msg
	{
		Case WM_ACTIVATE: ; activated window
		if  WinGetStyle(main) & WS_VISIBLE
			&& !WinActive(main)
		{
			hideSuggest()
		}
		Default: return
	}
}

; SetTimer GetSuggestion, 400 ; watching inputhook
CheckPrompt(Prompt, Char)
{
	static searching := false
	static WS_VISIBLE := 0x10000000
 	Critical 'on'
	if winactive(mgui)
		return
	; DllCall("QueryPerformanceFrequency", "Int64*", &freq := 0)
	; DllCall("QueryPerformanceCounter", "Int64*", &CounterBefore := 0)
	if Prompt.Input ~= '^\s'
	|| Prompt.Input ~= '^\t'
	{
		hideSuggest(true)
		return
	}

	switch Char
	{
		case '`n',Chr(27):
		hideSuggest()
		default:
		if StrLen(Prompt.Input) < MinChar
		&& WinGetStyle(main) & WS_VISIBLE = false
		{
			OutputDebug 'less than 3 and not visible`n'
			return
		}

		if Prompt.Input = ""
		{
			hideSuggest()
			return
		}

		try ; this try statement avoids catastrophic backtracking if the string is too long
		{
			if  !result := BuildResult()
			{
				hideSuggest(Prompt.Input ~= '\s$'?true:false)
				return
			}
		}
		catch
		{
			hideSuggest(false)
			return
		}

		BuildLV(Result)
		;main.Show('NA')
		;if WinGetStyle(main) & WS_VISIBLE = false
		if Prompt.Input ~= '\s\s$'
			hideSuggest(true)
		else
			ShowSuggest()
		LV.LastTitle := WinExist("A")
		; DllCall("QueryPerformanceCounter", "Int64*", &CounterAfter := 0)
		; OutputDebug "Elapsed QPC time is " . (CounterAfter - CounterBefore) / freq * 1000 " ms`n"
		;Critical 'off'
	}
}

BuildResult()
{
	Critical 'on'
	result := ''
	result .= Sift_Regex((mGui.UiFilter?mGui.ClipFilteredData:mGui.ClipData),Prompt.Input, ConfigGui.Options)
	return Trim(result)
}

BuildLV(Result)
{
	LV.Opt('-redraw')
	LV.Delete()
	i := 1
	main.MaxStrLen := 0
	main.MaxStr := ""
	LV.Add(,Prompt.input)
	for index, str in StrSplit(Result,'`n','`r')
	{
		if a_index > MaxResults
			break
		if main.MaxStrLen < StrLen(str)
		{
			main.MaxStr := str
			main.MaxStrLen := StrLen(str)
		}
		LV.Add(,StrReplace(str,'`t',' '))
		++i
	}
	LV.ModifyCol(1, 'Auto')
	LV.Opt('+redraw')
	return i
}

ShowSuggest()
{
	if Prompt.Input = ""
		return
	OutputDebug Prompt.Input '`n' main.MaxStr '`n'
	rows := LV.GetCount()
	width := TextWidth(main.MaxStr,FontName,FontSize) + 30
	LV.Move(0,0, width > 900 ? width := 900 : width, Height := Round(rows * FontSize * ( rows>=5 ? 2.07: 3))) ; main.MaxStrLen * FontSize * 0.71 + 24
	CoordMode 'Caret', 'Screen'
	CaretGetPos(&x,&y)
	OutputDebug 'caret: ' x ' ' y '`n'
	if x && y
	{
		OutputDebug 'widthxheight: ' width 'x' Height '`n'
	}
	else
	{
		CoordMode 'mouse', 'Screen'
		MouseGetPos(&x,&y)
		OutputDebug 'mouse: ' x ' ' y '`n'
		OutputDebug 'width: ' width '`n'
	}
	CorrectPos(x,y+OffsetY,width,Height,OffsetX,OffsetY)
}

CorrectPos(x,y,w,h:=0,offsetx:=8,offsety:=8)
{
	static TPM_WORKAREA := 0x10000

	windowRect := Buffer(16), windowSize := windowRect.ptr + 8

	; resizing window for DLLCall
	main.Show('hide x' x  + OffsetX ' y' y + OffsetY  ' w' w ' h' h )
	DllCall("GetClientRect", "ptr", main.hwnd, "ptr", windowRect)
	CoordMode 'Caret', 'Screen'
	;MouseGetPos &x, &y

	; ToolTip normally shows at an offset of 16,16 from the cursor.
	anchorPt := Buffer(8)
	NumPut "int", x+offsetx, "int", y+offsety, anchorPt

	; Avoid the area around the mouse pointer.
	excludeRect := Buffer(16)
	NumPut "int", x-offsetx, "int", y-offsety, "int", x+offsetx, "int", y+offsety, excludeRect

	; Windows 7 permits overlap with the taskbar, whereas Windows 10 requires the
	; tooltip to be within the work area (WinMove can subvert that, so this is just
	; for consistency with the normal behaviour).
	outRect := Buffer(16)
	DllCall "CalculatePopupWindowPosition",
		"ptr" , anchorPt,
		"ptr" , windowSize,
		"uint", VerCompare(A_OSVersion, "6.2") < 0 ? 0 : TPM_WORKAREA, ; flags
		"ptr" , excludeRect,
		"ptr" , outRect

	x := NumGet(outRect, 0, 'int')
	y := NumGet(outRect, 4, 'int')

	OutputDebug 'corrected: ' x ' ' y '`n'
	main.Show('NoActivate x' x ' y' y ' w' w ' h' h )

}


hideSuggest(restartinput:=1)
{
	main.hide()
	LV.Delete()
	if restartinput
	{
		Prompt.stop()
		Prompt.start()
	}
}

getCurrentDisplayPathByMouse()
{
	CoordMode("Mouse","Screen")
	MouseGetPos(&mx,&my)
	Loop MonitorGetCount()
	{
		MonitorGet(a_index, &Left, &Top, &Right, &Bottom)
		if (Left <= mx && mx <= Right && Top <= my && my <= Bottom)
			Return MonitorGetName(a_index) ; DisplayPath[MonitorGetName(a_index)]
	}
	Return 1
}


TextWidth(String,Typeface,Size)
{
	static hDC, hFont := 0, Extent
	OutputDebug String '`n' main.MaxStr  '`n' Typeface " " Size "`n"
	If !hFont
	{
		hDC := DllCall("GetDC","UPtr",0,"UPtr")
		Height := -DllCall("MulDiv","Int",Size,"Int",DllCall("GetDeviceCaps","UPtr",hDC,"Int",90),"Int",72)
		hFont := DllCall("CreateFont","Int",Height,"Int",0,"Int",0,"Int",0,"Int",400,"UInt",False,"UInt",False,"UInt",False,"UInt",0,"UInt",0,"UInt",0,"UInt",0,"UInt",0,"Str",Typeface)
		hOriginalFont := DllCall("SelectObject","UPtr",hDC,"UPtr",hFont,"UPtr")
		Extent := Buffer(8)
	}
	DllCall("GetTextExtentPoint32","Ptr",hDC,"Str",String,"Int",StrLen(String),"Ptr",Extent)
	Return NumGet(Extent,0,'Int')
}

; *********************************************************************************************************************

BuildClipLV()
{
	ClipLV.Delete()
	mGui.ClipData := ''
	cData := UpdateClipData()
	progs := Map()
	mGui.pinned := Map()
	for i, data in cData
	{
		ClipID := data['Time'] 'Җ' Data['ms']
		progs[data['Program']] := 'null' ; map key dedupe for dropdownload array
		pinned := IniRead(script.config,'pinned',ClipID, false) ; check if clip is pinned
		if pinned
			mGui.pinned[clipid] := true
		ClipLV.Add((pinned?'+Check':'-Check'),data['LVTime'],data['Time'] sep Data['ms'], data['Title'], data['Program'], data['Len'], data['Contents'])
		mGui.ClipData .= data['Contents'] '`n'
	}
	programs := []
	mGui['Filter4'].Delete()
	programs.Push('')
	for key, progName in progs
	{
		programs.Push(key)
	}
	mGui['Filter4'].add(programs)
	mGui.ClipFilteredData := mGui.ClipData
	ResetLVCol()
}

UpdateClipData()
{
	mGui.ClipArray := []
	fileObj := FileOpen(ClipPath, 'rw `n','utf-8')
	lines := StrSplit(fileObj.Read(), '`n','`r')
	fileObj.Close()
	i := lines.Length + 1
	loop lines.Length
	{
		Data := Map()
		clip := StrSplit(lines[--i], 'Җ')
		str := StrReplace(clip[6], '¶', '`n')
		Data['Time'] := clip[1]
		Data['LVTime'] := GetLVTime(clip[1])
		Data['ms'] := clip[2]
		Data['Title'] := clip[3]
		Data['Program'] := clip[4]
		Data['Len'] := StrLen(str)
		Data['Contents'] := str
		mGui.ClipArray.Push(Data)
	}
	return mGui.ClipArray
}

GetLVTime(time)
{
	date := FormatTime(time, 'yyyyMMdd')
	today := FormatTime(A_Now, 'yyyyMMdd')
	yesterDay := FormatTime(DateAdd(today,-1,'Days'),'yyyyMMdd')
	if date = today
		return 'Today ' FormatTime(time, 'hh:mm tt')
	else if date = yesterDay
		return 'Yesterday ' FormatTime(time, 'hh:mm tt')
	else
		return FormatTime(time, 'MMMM dd')
}

WatchClipboard(DataType)
{
	if DataType = 1
	{
		StoreClip(A_Clipboard,WinActive('a'))
	}
}

StoreClip(str,hwnd)
{
	local clipline
	Title := WinGetTitle('ahk_id' hwnd)
	Exe := WinGetProcessName('ahk_id' hwnd)
	clip := StrReplace(str, '`r`n','`n')
	clip := StrReplace(clip, '`n', '¶')
	sleep 100
	clipline := a_now sep A_MSec sep Title sep Exe sep StrLen(str) sep clip

	if mGui.HasProp('ClipArray')
		ReWriteFilteredClipFile(clipline)
	else
		AddlineClipFile(clipline)

	BuildClipLV()
}

; *************** clip limit filtering ***************

AddlineClipFile(clipline)
{
	fileobj := FileOpen(ClipPath, 'a-w','utf-8')
	fileobj.Write('`n' clipline)
	fileobj.Close()
}

ReWriteFilteredClipFile(clipline,DeleteAll:=false)
{
	fileobj := FileOpen(ClipPath, 'w','utf-8')
	fileobj.Write(lines := Trim(GetClipLines(DeleteAll) '`n' clipline,'`n'))
	fileobj.Close()
	return lines
}

GetClipLines(DeleteAll:=false) ; get cliplines filtered by clip time limit
{
	clipline := ''
	for i, data in mGui.ClipArray
	{
		if !CheckLimit(data['Time'], data['ms'],DeleteAll)
			continue
		Contents := StrReplace(data['Contents'], '`n', '¶') ; conevert new line with symbol
		clipline := data['Time'] sep data['ms'] sep data['Title'] sep data['Program'] sep data['Len'] sep Contents '`n' clipline
	}
	return Trim(clipline,'`n')
}

CheckLimit(time,ms,DeleteAll:=false)
{
	if IniRead(script.config,'Pinned',time sep ms,false)
		return true
	if DeleteAll
		return false
	switch x := cliplimits[ConfigGui['ClipLimit'].value], 0
	{
		Case "15 Minutes":
		if DateDiff(A_Now, time, "Seconds") >= 15*60   ;(A_Now - data['Time']) >= 15*60
			return false
		Case "30 Minutes":
		if DateDiff(A_Now, time, "Seconds") >= 30*60
			return false
		Case "1 Hour":
		if DateDiff(A_Now, time, "Seconds") >= 60*60
			return false
		Case "12 Hour":
		if DateDiff(A_Now, time, "Seconds") >= 12*60*60
			return false
		Case "1 Day":
		if DateDiff(A_Now, time, "Seconds") >= 24*60*60
			return false
		Case "1 Week":
		if DateDiff(A_Now, time, "Seconds") >= 7*24*60*60
			return false
		Case "1 Month":
		if DateDiff(A_Now, time, "Seconds") >= 30*24*60*60
			return false
		Case "1 Year":
		if DateDiff(A_Now, time, "Seconds") >= 365*24*60*60
			return false
	}
	return true
}