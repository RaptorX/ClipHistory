#Requires AutoHotkey v2.0
#SingleInstance Force


ConfigGui := Gui()
ConfigGui.Options := 'oc' ; filter default option
ConfigGui.Toggle := true  ; onoff  default toggle
ConfigGui.ClipToggle := true  ; onoff  Clip recording
ConfigGui.AddGroupBox(' x10 w300 h' 40 * 2, 'Search Settings')
ConfigGui.AddText('xp+10 yp+25 w60 Section right' ,'Match Type')
ConfigGui.AddDropDownList( 'x+m yp-3 w70 Choose1 vOption', ['Fuzzy','Exact','Left','Right']).onEvent('change',eventhandler)

ConfigGui.AddText('x+m w50 yp+3 right' ,'Font Size')
ConfigGui.AddComboBox('x+m yp-3 w70 Choose5 vLVFont',[8,9,10,11,12,13,14]).onEvent('change',eventhandler)
ConfigGui.AddText('xs w60 right','Max Results')
ConfigGui.AddComboBox('x+m yp-3 w70 Choose2 vMaxSugCount',[5,10,15,20]).onEvent('change',eventhandler)
ConfigGui.AddText('x+m w50 yp+3 right','Trigger at')
ConfigGui.AddComboBox('x+m yp-3 w70 Choose3 vMinTrigger',
					['1 Char','2 Chars','3 Chars','4 Chars','5 Chars','6 Chars','7 Chars','8 Chars','9 Chars']
					).onEvent('change',eventhandler)

; Watch Clipboards
ConfigGui.WatchClipHK := IniRead(script.config,'Hotkeys','ClipWatchtoggle','^+s')
WatchClipCheck := (instr(ConfigGui.WatchClipHK,'#')? ' +Checked':' -Checked')


ConfigGui.AddGroupBox(' xm w300 h' 40 * 1.3 , 'Watch Clipboard')
ConfigGui.AddCheckBox("xp+10 yp+25 vClipWatchWK" WatchClipCheck, "Win") ;.onEvent('click',eventhandler)
ConfigGui.AddHotkey( "x+5 yp-3 vClipWatchHK",StrReplace(ConfigGui.WatchClipHK,'#')) ;.onEvent('change',eventhandler)
ConfigGui.AddCheckbox( 'x+m yp+3 +Center vClipWatchToggle +Checked', 'On').onEvent('click',ToggleClipWatch)

hotkey ConfigGui.WatchClipHK, ToggleClipWatch, 'on'

; clipshitory show hide
ConfigGui.OldShowHK := IniRead(script.config,'Hotkeys','ShowHotKey','^+Home')
SWinCheck := (instr(ConfigGui.OldShowHK,'#')? ' +Checked':' -Checked')

ConfigGui.AddGroupBox(' xm w300 h' 40 * 1.3, 'Show ClipHistory Gui')
ConfigGui.AddCheckBox("xs yp+25 vWinShow" SWinCheck , "Win") ;.onEvent('click',eventhandler)
ConfigGui.AddHotkey( "x+5 yp-3 vHKShow",StrReplace(ConfigGui.OldShowHK,'#')) ;.onEvent('change',eventhandler)
hotkey ConfigGui.OldShowHK, ShowClipHistory, 'on'

; clip suggestion on off 
ConfigGui.OldCSHK := IniRead(script.config,'Hotkeys','CStoggle','^+a')
CSCheck := (instr(ConfigGui.OldCSHK,'#')? ' +Checked':' -Checked')


ConfigGui.AddGroupBox(' xm w300 h' 40 * 1.3 , 'Clipboard Suggestions')
ConfigGui.AddCheckBox("xp+10 yp+25 vonoffWK" CSCheck, "Win") ;.onEvent('click',eventhandler)
ConfigGui.AddHotkey( "x+5 yp-3 vonoffHK",StrReplace(ConfigGui.OldCSHK,'#')) ;.onEvent('change',eventhandler)
ConfigGui.AddCheckbox( 'x+m yp+3 Section +Center vToggle +Checked', 'Show Suggestions').onEvent('click',eventhandler)

hotkey ConfigGui.OldCSHK, onofftoggle, 'on'

; clip limit
limit := IniRead(script.config,'Settings','ClipLimit',4)
ConfigGui.AddGroupBox(' xm w300 h' 40 * 1.30, 'Keep Clipboard History for Last:')
ConfigGui.AddDropDownList( 'xp+10 yp+20 w200 Choose' limit ' vClipLimit', cliplimits).onEvent('change',eventhandler)
ConfigGui.AddButton('x+m w70', 'Delete All').OnEvent('click',DeleteClipboardHistory)

; Display on Start
DScheck := (IniRead(script.config,'Settings','DisplayStart',1)? ' +Checked':' -Checked')
ConfigGui.AddGroupBox(' xm w300 h' 45, 'Display on Start')
ConfigGui.AddCheckbox( 'xp+10 yp+20 +Center vDStart ' DScheck, 'Display ClipHistory on start').onEvent('click',eventhandler)

; Apply and Close
ConfigGui.AddButton('xm' 300 -145 ' w70', 'Apply').onEvent('click',EnableNewHotkeys)
ConfigGui.AddButton('x+m w70', 'Close').onEvent('click',(*) => ConfigGui.Hide())
;ConfigGui.Show()


ToggleClipWatch(*)
{
	ConfigGui.ClipToggle := !ConfigGui.ClipToggle
	switch ConfigGui.ClipToggle
	{
		Case 1: 
			OnClipboardChange(WatchClipboard,1)
			tray.check('Watch Clipboard')
			ConfigGui['ClipWatchToggle'].value := 1
			mGui['ClipWatchToggle'].value      := 1
			Notify.show({BDText:'On',HDFontColor:'Green',HDText:'Storing Clips'})
		Case 0:
			tray.Uncheck('Watch Clipboard')
			OnClipboardChange(WatchClipboard,0)
			ConfigGui['ClipWatchToggle'].value := 0
			mGui['ClipWatchToggle'].value      := 0
			Notify.show({BDText:'Off',HDFontColor:'Red',HDText:'Storing Clips'})
	}
}

onofftoggle(*)
{
	ConfigGui.Toggle := !ConfigGui.Toggle
	switch ConfigGui.Toggle
	{
		Case 1: 
			ConfigGui['toggle'].value := 1
			tray.check('Show Suggestions')
			Prompt.start() ; start input hook
			Notify.show({BDText:'On',HDFontColor:'Green'})
		Case 0:
			ConfigGui['toggle'].value := 0
			tray.Uncheck('Show Suggestions')
			Prompt.stop() ; stop input hook
			main.hide()   ; hide suggetion
			LV.Delete()   ; reset suggetion list
			Notify.show({BDText:'Off',HDFontColor:'Red'})
	}
}

EnableNewHotkeys(*)
{
	ctrl := ConfigGui.Submit()
	; clipshistory on off
	hotkey ConfigGui.WatchClipHK, ToggleClipWatch, 'off'
	ConfigGui.WatchClipHK := ''
	if ctrl.ClipWatchWK
		ConfigGui.WatchClipHK := '#'
	ConfigGui.WatchClipHK .= ctrl.ClipWatchHK
	IniWrite(ConfigGui.WatchClipHK,script.config,'Hotkeys','ClipWatchtoggle')
	hotkey ConfigGui.WatchClipHK, ToggleClipWatch, 'on'
	
	; show hide hotkey
	hotkey ConfigGui.OldShowHK, ShowClipHistory, 'off'
	ConfigGui.OldShowHK := ''
	if ctrl.WinShow
		ConfigGui.OldShowHK := '#'
	ConfigGui.OldShowHK .= ctrl.HKShow
	IniWrite(ConfigGui.OldShowHK,script.config,'Hotkeys','ShowHotKey')
	hotkey ConfigGui.OldShowHK, ShowClipHistory, 'on'


	; clip suggestion on off 
	hotkey ConfigGui.OldCSHK, ShowClipHistory, 'off'
	ConfigGui.OldCSHK := ''
	if ctrl.onoffWK
		ConfigGui.OldCSHK := '#'
	ConfigGui.OldCSHK .= ctrl.onoffHK
	IniWrite(ConfigGui.OldCSHK,script.config,'Hotkeys','CStoggle')
	Hotkey ConfigGui.OldCSHK, onofftoggle, 'on'

	tray.Rename(ConfigGui.TrayClipWatch ,ConfigGui.TrayClipWatch := 'Toggle ClipWatch Press			' HKToString(ConfigGui.WatchClipHK))
	tray.Rename(ConfigGui.TrayClipSugg  ,ConfigGui.TrayClipSugg  := 'Toggle Clip Suggestions Press	' HKToString(ConfigGui.OldShowHK))
	tray.Rename(ConfigGui.TrayClipUI    ,ConfigGui.TrayClipUI    := 'Show ClipHistory UI Press		' HKToString(ConfigGui.OldCSHK))

}


eventhandler(aCtrl,*)
{
	Global FontSize, MaxResults, MinChar
	ctrl := ConfigGui.Submit(0)
	
	IniWrite(ctrl.Dstart,script.config,'Settings','DisplayStart')

	; clip limit
	IniWrite(ConfigGui['ClipLimit'].value,script.config,'Settings','ClipLimit')

	Switch(ConfigGui['Option'].value)
	{
		Case 1  : ConfigGui.Options := 'OC' ; FUZZY
		Case 2  : ConfigGui.Options := 'IN'
		Case 3  : ConfigGui.Options := 'LEFT' ;'LEFT'
		Case 4  : ConfigGui.Options := 'RIGHT'
	}	

	Switch(ctrl.Toggle)
	{
		Case 1:
			ConfigGui.Toggle := true
			Prompt.start() ; start input hook
			tray.check('Show Suggestions')
			state := 'off', color := 'Green'
		Case 0:
			ConfigGui.Toggle := false
			Prompt.stop() ; stop input hook
			main.hide()   ; hide suggetion
			LV.Delete()   ; reset suggetion list
			tray.Uncheck('Show Suggestions')
			state := 'on', color := 'Red'
	}
	if aCtrl.hwnd = ConfigGui['Toggle'].hwnd
		Notify.show({BDText:state,HDFontColor:color})
}

DeleteClipboardHistory(*)
{
	;Delete Clipboard History and ignores the Checked one 
	count := ClipLV.GetCount()
	if Count = 0
	{
		Notify.show('No clipboard history to Delete')
		return
	}

	; delete all except the pinned ones
	lines := strsplit(ReWriteFilteredClipFile('',DeleteAll:=true),'`n')
	if lines.Length = 0
		Notify.show('Deleted all clipboard history')
	else
		Notify.show('Deleted all clipboard history except the Pinned ones')
	BuildClipLV()
}


HKToString(hk)
{
	; removed logging due to performance issues
	; Log.Add(DEBUG_ICON_INFO, A_Now, A_ThisFunc, 'started', 'none')

	if !hk
		return

	temphk := []

	if InStr(hk, '#')
		temphk.Push('Win+')
	if InStr(hk, '^')
		temphk.Push('Ctrl+')
	if InStr(hk, '+')
		temphk.Push('Shift+')
	if InStr(hk, '!')
		temphk.Push('Alt+')

	hk := RegExReplace(hk, '[#^+!]')
	for mod in temphk
		fixedMods .= mod

	; Log.Add(DEBUG_ICON_INFO, A_Now, A_ThisFunc, 'ended', 'none')
	return (fixedMods ?? '') StrUpper(hk)
}