; Reticule v0.1 - opicr0n 2016 xJ
;
; code gathered from various sources
; other hacking and improvements by: opicr0n

; greetings in no particular order:
;
; big thanks to the ahk guys on the official forums!
; meraple, dieboard, zulaji, anders, thomaze, ran, rocket, soad, kopra, 
; diox, memag, miscellaneous, pandabaron, alvaro
; whoever i forgot, you know who you are ^^

; FULLSCREEN or WINDOWED

; true: Reticule will use direct3d dll inject to overlay crosshair (detectable)
; false: Reticule will use default overlay for crosshair (non detectable)

fullscreen := true

; add your game window class here

;
; WINDOWED MODE 
;

ProgWinTitle1 = ahk_class LaunchUnrealUWindowsClient ; Dirty Bomb / Hawken
;ProgWinTitle2 = ahk_class IW5          ;COD 8: MW3
;ProgWinTitle3 = ahk_class CoDBlackOps  ;COD 7: BO
;ProgWinTitle4 = ahk_class IW4          ;COD 6: MW2
;ProgWinTitle5 = ahk_class CoD-WaW      ;COD 5: WAW
;ProgWinTitle6 = ahk_class CoD4         ;COD 4: MW

;
; FULLSCREEN MODE
;

ProgFileName1 = ahk_exe HawkenGame-Win32-Shipping.exe ; Hawken
ProgFileName2 = ahk_exe ShooterGame-Win32-Shipping.exe ; DirtyBomb

;
; DO NOT CHANGE CODE UNDERNEATH!
;

#NoEnv
#Persistent ; keep running due to timers
#SingleInstance, Force
#Include, Gdip.ahk ; windowed mode
#include bin\overlay_improved.ahk ; fullscreen mode
#MaxHotkeysPerInterval 200
#HotkeyInterval 2000

SetTitleMatchMode, 3 ; A window's title must exactly match WinTitle to be a match.

;
; System Tray
;

Menu, Tray, Icon, reticule.ico, 0 
Menu, Tray, NoStandard
Menu, Tray, Add, Disable Crosshair, m_hide
Menu, Tray, Add, Enable Crosshair, _create
Menu, Tray, Add, &Reload, _reload
Menu, Tray, Add, E&xit, _exit

;
; Get Primary monitor information
;

;SysGet, MonitorName, MonitorName, 1
SysGet, Monitor, Monitor, 1 ; get primary monitor
SysGet, MonitorWorkArea, MonitorWorkArea, 1 ; get resolution
Center_X := MonitorRight / 2 ; set center
Center_Y := MonitorBottom / 2 ; set center


;
; Load crosshair files
;

global FileList = []
maxFiles := 0
Loop, Files, gfx\*.png
{
   FileList[maxFiles] := A_LoopFileName
   maxFiles ++
}

;
; default init
;

x_file  := "Default.png"
PosX    := 0
PosY    := 0
x_alpha := 1
x_id    := 0

ScriptName := A_ScriptName
StringReplace, ScriptName, ScriptName, .ahk,, All
StringReplace, ScriptName, ScriptName, .exe,, All

; 
; Main
;

_start:
  IfNotExist, %ScriptName%.ini
    Gosub, _firstrun
  else
    Gosub, _read
  SetTimer, LabelCheckTrigger, 100 ; check active window every 100ms
  Return ; return so we do not create the reticule in desktop

_create:
  fileName := "gfx\" . x_file 
  if (fullscreen)
  {
    pToken := Gdip_Startup()

    x_Bitmap  := Gdip_CreateBitmapFromFile(fileName)                                                             ; rZr
    x_Width   := Gdip_GetImageWidth(x_Bitmap)                                                                    ; rZr
    x_Height  := Gdip_GetImageHeight(x_Bitmap)                                                                   ; rZr
    
    OCX := Center_X + PosX - (x_Width / 2)
    OCY := Center_Y + PosY- (x_Height / 2)
    
    ;tooltip %OCX% %OCY%
    SetCalculationRatio(1920,1080)
    fullName := RelToAbs(A_ScriptDir, fileName)
    ImageCreate(fullName, OCX, OCY, 0, 1, true)

    ;ImageCreate("d:\Code\AHK\Reticule_full\DX9-Overlay-API-master\samples\AHK\Default2.png", 832, 412, 0, 1, true)       
    ;ImageCreate("d:\Code\AHK\Reticule\gfx\red dot gray diagonal.png", 832, 412, 0, 0, true)        
  }
  Else
  {
    Gui, +LastFound -Caption +E0x80000 +E0x20 +E0x8 +Owner
    hGui := WinExist()
    pToken := Gdip_Startup()

    ;fileName := "gfx\" . x_file

    x_Bitmap  := Gdip_CreateBitmapFromFile(fileName)                                                             ; rZr
    x_Width   := Gdip_GetImageWidth(x_Bitmap)                                                                    ; rZr
    x_Height  := Gdip_GetImageHeight(x_Bitmap)                                                                   ; rZr
    nWidth    := x_Width
    nHeight   := x_Height

    OCX := Center_X + PosX - (nWidth / 2)
    OCY := Center_Y + PosY- (nHeight / 2)

    hbm := CreateDIBSection(nWidth,nHeight)
    hdc := CreateCompatibleDC()
    obm := SelectObject(hdc, hbm)
    pGraphics := Gdip_GraphicsFromHDC(hdc)

    Gui, Show, X%OCX% Y%OCY% NoActivate
    UpdateLayeredWindow(hGui, hdc, OCX,OCY,nWidth,nHeight)                                                       ; rZr
    Gdip_SetCompositingMode(pGraphics,1)

    pBrush := Gdip_BrushCreateSolid(0x0000000)
    Gdip_FillRectangle(pGraphics, pBrush, 0, 0, nWidth, nHeight)

    this_X := Round( (nWidth - x_Width) / 2)
    this_Y := Round( (nHeight - x_Height) / 2)

    Gdip_DrawImage(pGraphics, x_Bitmap, this_X, this_Y, x_Width, x_Height,"","","","",x_alpha)                   ; rZr
    UpdateLayeredWindow(hGui, hdc)
    Gdip_DeleteBrush(pBrush)
  }
  Return

#PgUp UP::
  x_alpha := x_alpha - 0.1
  if (x_alpha < 0.3)
  {
     x_alpha := 1
  }
  Gosub m_hide
  Gosub _create
  Return

RAlt & End UP::
  if (x_id == -1) ;there was no reticule, create new
  {
    x_id := 0
    x_file = % FileList[x_id]
    Gosub _create
  }
  else if (x_id = maxFiles-1) ; max number reached, remove reticule
  {
     ;Gui, Destroy
     Gosub m_hide
     x_id := -1
  }
  else 
  {
     x_id++
     x_file = % FileList[x_id]
     ;Gui, Destroy
     Gosub m_hide
     Gosub _readxhair
     Gosub _create
  } 
  Send, {blind}{end}
  Return

RAlt & Up::
    PosY -= 1
    Gosub m_hide
    Gosub _write
    GoSub, showch
    Return

RAlt & Down::
    PosY += 1
    Gosub m_hide
    Gosub _write
    GoSub, showch
    Return

RAlt & Left::
    PosX -= 1
    Gosub m_hide
    Gosub _write
    GoSub, showch
    Return

RAlt & Right::
    PosX += 1
    Gosub m_hide
    Gosub _write
    GoSub, showch
    Return


RAlt & Home::  
  Gosub _write
  Send, {blind}{home}
  Return


m_hide:
   if (x_id != -1)
   {
      if (fullscreen)
      {
        DestroyAllVisual()
      }
      else
      {
        Gui, Destroy
      }
   }
Return

showch:
  if (x_id != -1)
  {
    Gosub _create
  }
return

_write:
  IniWrite, %x_file%, %ScriptName%.ini, Main, x_file
  IniWrite, %x_alpha%, %ScriptName%.ini, %x_file%, x_alpha
  IniWrite, %PosX%, %ScriptName%.ini, %x_file%, PosX
  IniWrite, %PosY%, %ScriptName%.ini, %x_file%, PosY
Return

_read:
  IniRead, x_file, %ScriptName%.ini, Main, x_file, %x_file%
  IniRead, Center_X, %ScriptName%.ini, Main, Center_X, %Center_X%
  IniRead, Center_Y, %ScriptName%.ini, Main, Center_Y, %Center_Y%  
  IniRead, x_alpha, %ScriptName%.ini, %x_file%, x_alpha, %x_alpha%
  IniRead, PosX, %ScriptName%.ini, %x_file%, PosX, %PosX%
  IniRead, PosY, %ScriptName%.ini, %x_file%, PosY, %PosY%
  
  ; find x_id from list of files, else 0
  for index, element in FileList
  {
    StringGetPos, pos, element, %x_file%
    if pos >= 0
      x_id := index
  }

  OCX := Center_X + PosX
  OCY := Center_Y + PosY
Return

_readxhair:
  ; for defaults
  IniRead, x_alpha, %ScriptName%.ini, Main, x_alpha, %x_alpha%
  IniRead, PosX, %ScriptName%.ini, Main, PosX, %PosX%
  IniRead, PosY, %ScriptName%.ini, Main, PosY, %PosY%

  ; specific for xhair# else default
  IniRead, x_alpha, %ScriptName%.ini, %x_file%, x_alpha, %x_alpha%
  IniRead, PosX, %ScriptName%.ini, %x_file%, PosX, %PosX%
  IniRead, PosY, %ScriptName%.ini, %x_file%, PosY, %PosY%
  
Return

_firstrun:
  ;defaults
  IniWrite, %PosX%, %ScriptName%.ini, Main, PosX
  IniWrite, %PosY%, %ScriptName%.ini, Main, PosY
  IniWrite, %x_alpha%, %ScriptName%.ini, Main, x_alpha
  IniWrite, %x_file%, %ScriptName%.ini, Main, x_file
  IniWrite, %Center_X%, %ScriptName%.ini, Main, Center_X
  IniWrite, %Center_Y%, %ScriptName%.ini, Main, Center_Y
  GoSub, _start
Return

_exit:
  ;if (fullscreen) ; must test if windowed mode could m_hide onexit
  ;{
  Gosub m_hide
  ;}
  ExitApp
Return

_reload:
  Gosub m_hide
  Reload
Return

LabelCheckTrigger:
 
  if (fullscreen)
  {
    While ( ProgFileName%A_Index% != "" ) ; onlt trigger active
      if ( !ProgRunning%A_Index% != !WinExist( ProgFileName := ProgFileName%A_Index% ) ) ; only active
      {
        StringTrimLeft, ProcessFileName, ProgFileName%A_Index%, 8
        SetParam("process", ProcessFileName) ; is this required? yes it is!
        GoSubSafe( "LabelTriggerO" ( (ProgRunning%A_Index% := !ProgRunning%A_Index%) ? "n" : "ff" ) ) ; removed index
      }
  }
  Else
  {
    While ( ProgWinTitle%A_Index% != "" ) ; onlt trigger active
      if ( !ProgRunning%A_Index% != !WinActive( ProgWinTitle := ProgWinTitle%A_Index% ) ) ; only active
        GoSubSafe( "LabelTriggerO" ( (ProgRunning%A_Index% := !ProgRunning%A_Index%) ? "n" : "ff" ) ) ; removed index
  }

Return

GoSubSafe(mySub)
{
  if IsLabel(mySub)
    GoSub %mySub%
}

LabelTriggerOn:
  Gosub showch
  return

LabelTriggerOff:
  Gosub m_hide
  Return

; 2016 - opicr0n 
