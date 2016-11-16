#include library\Exec.ahk

ChangeDisplaySettings( cD, sW, sH, rR ) {
   VarSetCapacity(dM,156,0), NumPut(156,2,&dM,36)
   DllCall( "EnumDisplaySettingsA", UInt,0, UInt,-1, UInt,&dM ), NumPut(0x5c0000,dM,40)
   NumPut(cD,dM,104),  NumPut(sW,dM,108),  NumPut(sH,dM,112),  NumPut(rR,dM,120)
   Return DllCall( "ChangeDisplaySettingsA", UInt,&dM, UInt,0 )
}

MoveBrightness(IndexMove) {

	VarSetCapacity(SupportedBrightness, 256, 0)
	VarSetCapacity(SupportedBrightnessSize, 4, 0)
	VarSetCapacity(BrightnessSize, 4, 0)
	VarSetCapacity(Brightness, 3, 0)

	hLCD := DllCall("CreateFile"
	, Str, "\\.\LCD"
	, UInt, 0x80000000 | 0x40000000 ;Read | Write
	, UInt, 0x1 | 0x2  ; File Read | File Write
	, UInt, 0
	, UInt, 0x3  ; open any existing file
	, UInt, 0
	  , UInt, 0)

	if hLCD != -1
	{

		DevVideo := 0x00000023, BuffMethod := 0, Fileacces := 0
		  NumPut(0x03, Brightness, 0, "UChar")   ; 0x01 = Set AC, 0x02 = Set DC, 0x03 = Set both
		  NumPut(0x00, Brightness, 1, "UChar")      ; The AC brightness level
		  NumPut(0x00, Brightness, 2, "UChar")      ; The DC brightness level
		DllCall("DeviceIoControl"
		  , UInt, hLCD
		  , UInt, (DevVideo<<16 | 0x126<<2 | BuffMethod<<14 | Fileacces) ; IOCTL_VIDEO_QUERY_DISPLAY_BRIGHTNESS
		  , UInt, 0
		  , UInt, 0
		  , UInt, &Brightness
		  , UInt, 3
		  , UInt, &BrightnessSize
		  , UInt, 0)

		DllCall("DeviceIoControl"
		  , UInt, hLCD
		  , UInt, (DevVideo<<16 | 0x125<<2 | BuffMethod<<14 | Fileacces) ; IOCTL_VIDEO_QUERY_SUPPORTED_BRIGHTNESS
		  , UInt, 0
		  , UInt, 0
		  , UInt, &SupportedBrightness
		  , UInt, 256
		  , UInt, &SupportedBrightnessSize
		  , UInt, 0)

		ACBrightness := NumGet(Brightness, 1, "UChar")
		ACIndex := 0
		DCBrightness := NumGet(Brightness, 2, "UChar")
		DCIndex := 0
		BufferSize := NumGet(SupportedBrightnessSize, 0, "UInt")
		MaxIndex := BufferSize-1

		Loop, %BufferSize%
		{
		ThisIndex := A_Index-1
		ThisBrightness := NumGet(SupportedBrightness, ThisIndex, "UChar")
		if ACBrightness = %ThisBrightness%
			ACIndex := ThisIndex
		if DCBrightness = %ThisBrightness%
			DCIndex := ThisIndex
		}

		if DCIndex >= %ACIndex%
		  BrightnessIndex := DCIndex
		else
		  BrightnessIndex := ACIndex

		BrightnessIndex += IndexMove

		if BrightnessIndex > %MaxIndex%
		   BrightnessIndex := MaxIndex

		if BrightnessIndex < 0
		   BrightnessIndex := 0

		NewBrightness := NumGet(SupportedBrightness, BrightnessIndex, "UChar")

		NumPut(0x03, Brightness, 0, "UChar")   ; 0x01 = Set AC, 0x02 = Set DC, 0x03 = Set both
        NumPut(NewBrightness, Brightness, 1, "UChar")      ; The AC brightness level
        NumPut(NewBrightness, Brightness, 2, "UChar")      ; The DC brightness level

		DllCall("DeviceIoControl"
			, UInt, hLCD
			, UInt, (DevVideo<<16 | 0x127<<2 | BuffMethod<<14 | Fileacces) ; IOCTL_VIDEO_SET_DISPLAY_BRIGHTNESS
			, UInt, &Brightness
			, UInt, 3
			, UInt, 0
			, UInt, 0
			, UInt, 0
			, Uint, 0)

		DllCall("CloseHandle", UInt, hLCD)

	}

}

/*
Modified by: Edison Hua
Original Author: rbrtryn


Script Function:
Show/Hide hidden folders, files and extensions in Windows XP and Windows 7

All of these system settings are found in the Windows Registry at:
Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced

The specific values are:
    Hidden              Show hidden files?      ( 2 = no , 1 = yes )
    HideFileExt         Show file extensions?   ( 1 = no , 0 = yes )
    ShowSuperHidden     Show system files?      ( 0 = no , 1 = yes )

In order to show protected system files Windows requires that both
the ShowSuperHidden and the hidden settings be set to yes, i.e. both set to 1
*/




ToggleHiddenFiles(){
    `(GetRegValue( "Hidden" ) = 1 ) ? SetRegValue( "Hidden" , 2 ) : SetRegValue( "Hidden" , 1 )
    UpdateWindows()
}


ToggleSystemFiles(){
    GetRegValue( "ShowSuperHidden" ) ? SetRegValue( "ShowSuperHidden" , 0 ) : SetRegValue( "ShowSuperHidden" , 1 )
    UpdateWindows()
}


ToggleFileExt(){
    GetRegValue( "HideFileExt" ) ? SetRegValue( "HideFileExt" , 0 ) : SetRegValue( "HideFileExt" , 1 )
    UpdateWindows()
}


GetRegValue( ValueName )
{
    SubKey := "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    RegRead Value , HKCU , %SubKey% , %ValueName%
    Return Value
}

SetRegValue( ValueName , Value )
{
    SubKey := "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    RegWrite REG_DWORD , HKCU , %SubKey% , %ValueName% , %Value%
}

UpdateWindows()
{
    Code := ( InStr( "WIN_2003,WIN_XP,WIN_2000" , A_OSVERSION ) ) ? 28931 : 41504
    SetTitleMatchMode RegEx
    WinGet WindowList , List , ahk_class ExploreWClass|CabinetWClass|Progman
    Loop %WindowList%
        PostMessage 0x111 , %Code% ,  ,  , % "ahk_id" WindowList%A_Index%
    SetTitleMatchMode 1
}





SetEnvironmentVariable(name, value, option := "") {
   if (option == "")
      RegWrite, REG_SZ, HKEY_CURRENT_USER\Environment, % name, % value
   else if (option ~= "i)del(ete)?")
      RegDelete, HKEY_CURRENT_USER\Environment, % name
   else
   {
      RegRead, registry, HKEY_CURRENT_USER\Environment, % name

      if (option ~= "i)(add|append)") {
         registry .= (registry ~= "(;$|^$)") ? "" : ";"
         value := registry . value
         RegWrite, REG_SZ, HKEY_CURRENT_USER\Environment, % name, % value
      }
      else if (option ~= "i)(sub(tract)?|rem(ove)?)") {
         if ErrorLevel
            return
         Loop, parse, registry, `;
         {
            if (A_LoopField != value) {
               output .= (A_Index > 1 && output != "") ? ";" : ""
               output .= A_LoopField
            }
         }
         RegWrite, REG_SZ, HKEY_CURRENT_USER\Environment, % name, % output
      }
      else {
          if ErrorLevel
             return
          Loop, parse, registry, `;
          {
             if (A_LoopField == value)
                return 1
          }
      }
   }
   RefreshEnvironment()
   EnvUpdate
   SendMessage, 0x1A,0,"Environment",, ahk_id 0xFFFF ; 0x1A is WM_SETTINGCHANGE
   return 1
}

RefreshEnvironment()
{
	Path := ""
	PathExt := ""
	RegKeys := "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment,HKCU\Environment"
	Loop, Parse, RegKeys, CSV
	{
		Loop, Reg, %A_LoopField%, V
		{
			RegRead, Value
			If (A_LoopRegType == "REG_EXPAND_SZ" && !ExpandEnvironmentStrings(Value))
				Continue
			If (A_LoopRegName = "PATH")
				Path .= Value . ";"
			Else If (A_LoopRegName = "PATHEXT")
				PathExt .= Value . ";"
			Else
				EnvSet, %A_LoopRegName%, %Value%
		}
	}
	EnvSet, PATH, %Path%
	EnvSet, PATHEXT, %PathExt%
}

ExpandEnvironmentStrings(ByRef vInputString)
{
   ; get the required size for the expanded string
   vSizeNeeded := DllCall("ExpandEnvironmentStrings", "Str", vInputString, "Int", 0, "Int", 0)
   If (vSizeNeeded == "" || vSizeNeeded <= 0)
      return False ; unable to get the size for the expanded string for some reason

   vByteSize := vSizeNeeded + 1
   If (A_PtrSize == 8) { ; Only 64-Bit builds of AHK_L will return 8, all others will be 4 or blank
      vByteSize *= 2 ; need to expand to wide character sizes
   }
   VarSetCapacity(vTempValue, vByteSize, 0)

   ; attempt to expand the environment string
   If (!DllCall("ExpandEnvironmentStrings", "Str", vInputString, "Str", vTempValue, "Int", vSizeNeeded))
      return False ; unable to expand the environment string
   vInputString := vTempValue

   ; return success
   Return True
}

; Modified: AbsolutePath
RPath_Absolute(AbsolutPath, RelativePath, s="\") {

    len := InStr(AbsolutPath, s, "", InStr(AbsolutPath, s . s) + 2) - 1   ;get server or drive string length
    pr := SubStr(AbsolutPath, 1, len)                                     ;get server or drive name
    AbsolutPath := SubStr(AbsolutPath, len + 1)                           ;remove server or drive from AbsolutPath
    If InStr(AbsolutPath, s, "", 0) = StrLen(AbsolutPath)                 ;remove last \ from AbsolutPath if any
        StringTrimRight, AbsolutPath, AbsolutPath, 1

    If InStr(RelativePath, s) = 1                                         ;when first char is \ go to AbsolutPath of server or drive
        AbsolutPath := "", RelativePath := SubStr(RelativePath, 2)        ;set AbsolutPath to nothing and remove one char from RelativePath
    Else If InStr(RelativePath,"." s) = 1                                 ;when first two chars are .\ add to current AbsolutPath directory
        RelativePath := SubStr(RelativePath, 3)                           ;remove two chars from RelativePath
    Else If InStr(RelativePath,".." s) = 1 {                              ;otherwise when first 3 char are ..\
        StringReplace, RelativePath, RelativePath, ..%s%, , UseErrorLevel     ;remove all ..\ from RelativePath
        Loop, %ErrorLevel%                                                    ;for all ..\
            AbsolutPath := SubStr(AbsolutPath, 1, InStr(AbsolutPath, s, "", 0) - 1)  ;remove one folder from AbsolutPath
    } Else                                                                ;relative path does not need any substitution
        pr := "", AbsolutPath := "", s := ""                              ;clear all variables to just return RelativePath

    Return, pr . AbsolutPath . s . RelativePath                           ;concatenate server + AbsolutPath + separator + RelativePath
}


SetSystemCursor( Cursor = "", cx = 0, cy = 0 ) {
   BlankCursor := 0, SystemCursor := 0, FileCursor := 0 ; init

   SystemCursors = 32512IDC_ARROW,32513IDC_IBEAM,32514IDC_WAIT,32515IDC_CROSS
   ,32516IDC_UPARROW,32640IDC_SIZE,32641IDC_ICON,32642IDC_SIZENWSE
   ,32643IDC_SIZENESW,32644IDC_SIZEWE,32645IDC_SIZENS,32646IDC_SIZEALL
   ,32648IDC_NO,32649IDC_HAND,32650IDC_APPSTARTING,32651IDC_HELP

   If Cursor = "" ; empty, so create blank cursor
   {
      VarSetCapacity( AndMask, 32*4, 0xFF ), VarSetCapacity( XorMask, 32*4, 0 )
      BlankCursor := 1 ; flag for later
   }
   Else If SubStr( Cursor,1,4 ) = "IDC_" ; load system cursor
   {
      Loop, Parse, SystemCursors, `,
      {
         CursorName := SubStr( A_Loopfield, 6, 15 ) ; get the cursor name, no trailing space with substr
         CursorID := SubStr( A_Loopfield, 1, 5 ) ; get the cursor id
         SystemCursor := 1
         If ( CursorName = Cursor )
         {
            CursorHandle := DllCall( "LoadCursor", Uint,0, Int,CursorID )
            Break
         }
      }
      If CursorHandle = ""; invalid cursor name given
      {
         Msgbox,, SetCursor, Error: Invalid cursor name
         CursorHandle := Error
      }
   }
   Else If FileExist( Cursor )
   {
      SplitPath, Cursor,,, Ext ; auto-detect type
      If Ext = ico
         uType := 0x1
      Else If Ext in cur,ani
         uType := 0x2
      Else ; invalid file ext
      {
         Msgbox,, SetCursor, Error: Invalid file type
         CursorHandle := Error
      }
      FileCursor := 1
   }
   Else
   {
      Msgbox,, SetCursor, Error: Invalid file path or cursor name
      CursorHandle := Error ; raise for later
   }
   If CursorHandle != Error
   {
      Loop, Parse, SystemCursors, `,
      {
         If BlankCursor = 1
         {
            Type = BlankCursor
            %Type%%A_Index% := DllCall( "CreateCursor"
            , Uint,0, Int,0, Int,0, Int,32, Int,32, Uint,&AndMask, Uint,&XorMask )
            CursorHandle := DllCall( "CopyImage", Uint,%Type%%A_Index%, Uint,0x2, Int,0, Int,0, Int,0 )
            DllCall( "SetSystemCursor", Uint,CursorHandle, Int,SubStr( A_Loopfield, 1, 5 ) )
         }
         Else If SystemCursor = 1
         {
            Type = SystemCursor
            CursorHandle := DllCall( "LoadCursor", Uint,0, Int,CursorID )
            %Type%%A_Index% := DllCall( "CopyImage"
            , Uint,CursorHandle, Uint,0x2, Int,cx, Int,cy, Uint,0 )
            CursorHandle := DllCall( "CopyImage", Uint,%Type%%A_Index%, Uint,0x2, Int,0, Int,0, Int,0 )
            DllCall( "SetSystemCursor", Uint,CursorHandle, Int,SubStr( A_Loopfield, 1, 5 ) )
         }
         Else If FileCursor = 1
         {
            Type = FileCursor
            %Type%%A_Index% := DllCall( "LoadImageA"
            , UInt,0, Str,Cursor, UInt,uType, Int,cx, Int,cy, UInt,0x10 )
            DllCall( "SetSystemCursor", Uint,%Type%%A_Index%, Int,SubStr( A_Loopfield, 1, 5 ) )
         }
      }
   }
}

RestoreCursor() {
   SPI_SETCURSORS := 0x57
   DllCall( "SystemParametersInfo", UInt,SPI_SETCURSORS, UInt,0, UInt,0, UInt,0 )
}

wlanAutoConfig() {
   AutoConfig := RunWaitOne("netsh wlan show settings | find /I ""Auto configuration logic""")
   wifi := RegExReplace(AutoConfig, "s).*""(.*?)"".*", "$1")

   if (RegExMatch(AutoConfig, "enabled"))
      CommandRoot("netsh wlan set autoconfig enabled=no interface=""" . wifi . """ && exit", "admin", "wait", "hide")

   if (RegExMatch(AutoConfig, "disabled"))
      CommandRoot("netsh wlan set autoconfig enabled=yes interface=""" . wifi . """ && exit", "admin", "wait", "hide")

   Run, explorer shell:::{38A98528-6CBF-4CA9-8DC0-B1E1D10F7B1B}
   return
}
