#HotIf !WinActive(suggestions)
&& prompt.Input
&& LV.GetCount()
Down::
up::
{
	LV.Modify(2,'+select +focus')
	suggestions.show()
	suggestions.show()
}

#HotIf !WinActive(suggestions)
&& prompt.Input
~backspace::CheckPrompt(Prompt, 'BS')


~^BackSpace::
~*Left::
~*Right::
~*Home::
~*End::
~*Enter::
~*Tab::
{
	hideSuggest()
}

#HotIf WinActive(suggestions) ;LV.Visible
Enter::
Tab::
{
	OnClipboardChange(WatchClipboard,0)
	send '{enter up}'
	send '{control up}'
	send '{shift up}'

	Prompt.stop()
	row := LV.GetNext(0,'F')
	
	clipsave := A_Clipboard
	A_Clipboard := ''
	; if !ClipWait(1)
	; 	msgbox 'unable to empty clicpboard'

	A_Clipboard := InputNewLInes(LV.GetText(row,1)) . ' ' 
	; ToolTip Text
	if !ClipWait(1)
		msgbox 'unable to set clicpboard'

	suggestions.hide()
	LV.Delete()
	if !row
	{
		Prompt.Start()
		return
	}
	WinActivate(LV.LastTitle) ; waiting for last active title 
	WinWaitActive(LV.LastTitle,,5)
	; This 15ms delay fixes issues with notepad and MS Office programs
	; because they process every keystroke and when backspacing
	; they dont receive the paste command below
	SetKeyDelay 20
	SendEvent '{BS ' StrLen(RegexReplace(Prompt.input, "\R+")) '}'
	sleep 20
	Send '^v'

	sleep 500
	A_Clipboard := clipsave
	Prompt.Start()
	OnClipboardChange(WatchClipboard,1)
}

InputNewLInes(str) ; '¶'
{
	return str := StrReplace(str,'¶','`n')
}

~Esc::
~BackSpace::
{
	hideSuggest()
}
#Hotif


ShowClipHistory(*) => mGui.Show()

