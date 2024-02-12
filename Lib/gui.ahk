#Requires AutoHotkey v2.0
cliplimits := ['15 Minutes','30 Minutes','1 Hour','12 Hour','1 Day','1 Week','1 Month'] ; ,'1 Year','All'
headers := ['Time','ms','Window title','Program','Len','Clipboard Content']
Widths := Map(
	"Time"          , 150 ,
	"ms"            ,   0 ,
	'Window title'  , 200 ,
	"Program"       , 120 ,
	"Len"           ,  70 ,
	"Clipboard Content", 400
)
mGui := Gui(,'Clip History')
mGui.OnEvent('Close', (*) => mGui.Hide())
mGui.SetFont('s10')
mGui.MarginX := 1
totalWidth := 0
for cue in headers
{	
	w := Widths[cue]
	totalWidth += w
	Switch cue
	{
		Case "Time"   :
			cue .= ' Filter'
			opt := "x10 y10 " . 'vFilter' a_index . ' w' w ; ' Choose3'
			; ctrl := 'DateTime'
			; Value := 'yyyy-MM-dd HH:mm'
			EM_SETCUEBANNER := 0x1703
			ctrl := 'ddl'
			Value := cliplimits.Clone()
			Value.InsertAt(1,'')
		Case 'Window title'  :
			cue .= ' Filter'
			opt := "x+m " . 'vFilter' a_index . ' w' w     ' h25'
			ctrl := 'Edit'
			EM_SETCUEBANNER := 0x1501
			Value := ''
		Case "Program":
			cue .= ' Filter'
			opt := "x+m " . 'vFilter' a_index . ' w' w
			ctrl := 'ComboBox'
			Value := ['null']
			EM_SETCUEBANNER := 0x1703
		Case "Len"    :
			cue .= ' Filter'
			opt := "x+m " . 'vFilter' a_index . ' w' w     ' h25'
			ctrl := 'Edit'
			EM_SETCUEBANNER := 0x1501
			Value := ''
		Case "Clipboard Content":
			cue .= ' Filter'
			opt := "x+m " . 'vFilter' a_index . ' w' w     ' h25'
			ctrl := 'Edit'
			EM_SETCUEBANNER := 0x1501
			Value := ''
		Default:Continue
	}
	mGui.Add(ctrl,opt,Value).OnEvent('Change',FilterLV)
	strBuff := Buffer(StrPut(cue , "UTF-16"))
	StrPut(cue, strBuff, "UTF-16")
	SendMessage(EM_SETCUEBANNER, true, strBuff.ptr, mGui['Filter' a_index ].hwnd) 
}
ClipLV := mGui.AddListView('xm+10 w' totalWidth  + 10 ' r12 checked +LV0x4400 ',headers)
ClipLV.OnEvent('ItemCheck', PinClip)
ResetLVCol()
mGui.AddButton('xm+10' ' w100', 'Delete').OnEvent('click',DeleteSelected)
mGui.AddCheckbox('x+m+10 w200 yp+7 vUIFilter', 'Apply filter to suggestions').OnEvent('click', ApplyFilters)
mGui.AddCheckbox('x+m w200 vClipWatchToggle +checked', 'Watch clipboard').OnEvent('click', ToggleClipWatch)
mGui.UiFilter := false
mGui.AddButton('x+m+' totalWidth -700 ' yp-7 w100', 'Preference').OnEvent('click', (*) => (mGui.Opt('+OwnDialogs'),ConfigGui.show()))
mGui.AddButton('x+m w100', 'Close').OnEvent('click', (*) => mGui.Hide())

mGui.Show('w' totalWidth + 30 DSstats )

line .= 'Toggle ClipWatch Press		' HKToString(IniRead(script.config,'Hotkeys','ClipWatchtoggle','^+s')) '`n'
line .= 'Toggle Clip Suggestions Press	' HKToString(IniRead(script.config,'Hotkeys','CStoggle','^+a')) '`n'
line .= 'Show ClipHistory UI Press	' HKToString(IniRead(script.config,'Hotkeys','ShowHotKey','^+Home'))
; Notify.show({HDText: 'Clip History started',BDText: line ,GenDuration:4}) ;We need a way to disable this



ApplyFilters(*) ; apply filter to suggestions
{
	if mGui['UIFilter'].value
	{
		LV.Opt('Background55efc4')
		mGui.UiFilter := true
		Notify.show({BDText:'Filter Applied to Suggestions',GenBGcolor:'55efc4',HDFontColor:'Black',GenDuration:2})
	}
	else
	{
		LV.Opt('BackgroundDefault')
		mGui.UiFilter := false
		Notify.show({BDText:'Filter Removed'})
	}
}


PinClip(*)
{
	row := 0
	IniDelete(Script.config,'Pinned')
	mGui.pinned := Map()
	loop
	{
		row := ClipLV.GetNext(row,'Checked')
		if !row
			break
		clipid := ClipLV.GetText(row,2)
		mGui.pinned[clipid] := true
		IniWrite(true,Script.config,'Pinned',clipid)
	}
}

DeleteSelected(*)
{
	Deletedclipids := Map()
	row := 0
	loop
	{
		row := ClipLV.GetNext(row)
		if !row
			break
		clipid := ClipLV.GetText(row,2)
		Deletedclipids[clipid] := true
		if mGui.pinned.has(clipid)
			continue
		ClipLV.Delete(row)
	}
	
	DeletefromClipFile(Deletedclipids)
	BuildClipLV()
}	

DeletefromClipFile(ClipIDs)
{
	
	cliplines := ''
	for i, data in mGui.ClipArray
	{
		clipid := data['Time'] sep data['ms']
		if !mGui.pinned.has(clipid)
		&& ClipIDs.has(clipid) ; removed using Clip ID
		{
			mGui.ClipArray.Delete(i) ; removing clipid from ClipArray
			Continue ; this will skip so it will be deleted from clip file
		}
		else if mGui.pinned.has(clipid)
		&& ClipIDs.has(clipid)
				Notify.show('Please Uncheck the Pinned Row to Delete it')

		Contents := StrReplace(data['Contents'], '`n', '¶') ; conevert new line with symbol

	    cliplines := data['Time'] sep data['ms'] sep data['Title'] sep data['Program'] sep data['Len'] sep Contents '`n' cliplines
	}

	FileObj := FileOpen(ClipPath, "w",'utf-8')
	FileObj.Write(Trim(cliplines,'`n'))
	FileObj.close()
}


ResetLVCol()
{
	for cue in headers
	{
		ClipLV.ModifyCol(a_index, w := Widths[cue])
	}
}


FilterLV(*)
{
	ClipLV.Delete()
	mGui.ClipFilteredData := ''
	cData := UpdateClipData()
	for i, data in cData
	{
		Time     := mGui['Filter1'].Text

		; exclude pinned items from filtering
		check := IniRead(script.config,'Pinned',data['Time'] sep data['ms'],false)
		if check
		{
			ClipLV.Add(check?'+check':'-check',data['LVTime'],data['Time'] sep data['ms'] ,data['Title'], data['Program'], data['Len'], data['Contents'])
			mGui.ClipFilteredData .= data['Contents'] '`n'
			continue
		}

		switch Time, 0
		{
			Case "15 Minutes":
				if DateDiff(A_Now, data['Time'], "Seconds") >= 15*60   ;(A_Now - data['Time']) >= 15*60
					continue
			Case "30 Minutes":
				if DateDiff(A_Now, data['Time'], "Seconds") >= 30*60
					continue
			Case "1 Hour":
				if DateDiff(A_Now, data['Time'], "Seconds") >= 60*60
					continue
			Case "12 Hour":
				if DateDiff(A_Now, data['Time'], "Seconds") >= 12*60*60
					continue
			Case "1 Day":
				if DateDiff(A_Now, data['Time'], "Seconds") >= 24*60*60
					continue
			Case "1 Week":
				if DateDiff(A_Now, data['Time'], "Seconds") >= 7*24*60*60
					continue
			Case "1 Month":
				if DateDiff(A_Now, data['Time'], "Seconds") >= 30*24*60*60
					continue
			Case "1 Year":
				if DateDiff(A_Now, data['Time'], "Seconds") >= 365*24*60*60
					continue
		}

		title    := mGui['Filter3'].Value
		Program  := mGui['Filter4'].Text
		len      := mGui['Filter5'].Value
		contents := mGui['Filter6'].Value

		if title
		&& !instr(data['Title'],title)
			continue
		if Program
		&& Program != data['Program']
			continue
		if Len
		&& Len < data['Len']
			continue
		if Contents
		&& !instr(data['Contents'],Contents)
			continue
		
		ClipLV.Add(check?'+check':'-check',data['LVTime'],data['Time'] sep data['ms'] ,data['Title'], data['Program'], data['Len'], data['Contents'])
		mGui.ClipFilteredData .= data['Contents'] '`n'
	}
	ResetLVCol()
}
