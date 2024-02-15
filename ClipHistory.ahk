/*
This work by the-Automator.com is licensed under CC BY 4.0

Attribution — You must give appropriate credit , provide a link to the license,
and indicate if changes were made.
You may do so in any reasonable manner, but not in any way that suggests the licensor
endorses you or your use.
No additional restrictions — You may not apply legal terms or technological measures that
legally restrict others from doing anything the license permits.
*/

#SingleInstance
#Requires AutoHotkey v2.0

;@Ahk2Exe-SetVersion     0.3.0
;@Ahk2Exe-SetMainIcon    res\ClipHistory.ico
;@Ahk2Exe-SetProductName ClipHistory
;@Ahk2Exe-SetDescription ClipHistory Suggestor

#include <sift>
#include <NotifyV2>

Notify.Default.HDText := "ClipHistory Suggestor"
Notify.Default.BDFontSize := 18
Notify.Default.BDFont := 'Arial Black'

#Include <main>
#Include <ScriptObject\ScriptObject>
script := {
	        base : ScriptObj(),
	     version : '0.3.0',
	      author : "the-Automator",
	       email : "joe@the-automator.com",
	      config : A_ScriptDir "\settings.ini",
	    iconfile : A_ScriptDir "\res\ClipHistory.ico",
	   resfolder : A_ScriptDir "\res",
	     crtdate : '',
	     moddate : '',
	homepagetext : "the-automator.com/ClipHistory",
	homepagelink : "the-automator.com/ClipHistory?src=app",
}

ScriptObj.eddID := 96962
if !ScriptObj.GetLicense()
	return

#include <gui>
#include <ConfigGui>
#Include <HotKeys>

script.Hwnd := mGui.Hwnd
; if autostartup := IniRead(script.config,'Auto','Startup',false)
; 	tray.check('Run with Start up')
;script.Autostart(autostartup+0)

ConfigGui.TrayClipWatch := 'Watch Clipboard     ' HKToString(ConfigGui.WatchClipHK)
ConfigGui.TrayClipSugg  := 'Toggle Suggestions  ' HKToString(ConfigGui.OldShowHK)
ConfigGui.TrayClipUI    := 'Show Main GUI       ' HKToString(ConfigGui.OldCSHK)

TraySetIcon(script.iconfile)

tray := A_TrayMenu
tray.Delete()
tray.Add("About",(*) => Script.About())
;tray.Add("Donate",(*) => Run(script.donateLink))
tray.Add()

tray.add(ConfigGui.TrayClipWatch , (*) => ConfigGui.Show())
tray.add(ConfigGui.TrayClipSugg  , (*) => ConfigGui.Show())
tray.add(ConfigGui.TrayClipUI    , (*) => ConfigGui.Show())

tray.Add()
tray.Add('Watch Clipboard',ToggleClipWatch)
tray.check('Watch Clipboard')
tray.Add('Show Suggestions',onofftoggle)
tray.Check('Show Suggestions')
tray.Add()

tray.Add('Show ClipHistory',(*) => mGui.show())
tray.Add('Preference' , (*) => ConfigGui.show())
tray.default := 'Show ClipHistory'
tray.ClickCount := 1 ; how many clicks (1 or 2) to trigger the default action above
tray.Add()
tray.Add("Exit",(*) => Exit())
;tray.AddStandard()

exit(*){
	ExitApp
}

ClipData := []
ClipDATAFolder := A_ScriptDir '\DATA'
if !FileExist(ClipDATAFolder)
	DirCreate(ClipDATAFolder)
ClipPath := ClipDATAFolder '\ClipList.txt'
BuildClipLV()
OnClipboardChange(WatchClipboard,1)

