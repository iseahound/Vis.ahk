CommandRoot(subroutine := "", admin := "", feedback := "", hide := "") {
   _Path := ""
   if (WinActive("ahk_class CabinetWClass") || WinActive("ahk_class ExploreWClass")) {
      ControlGetText, _Path, toolbarwindow322, ahk_class CabinetWClass
      StringReplace, _Path, _Path, % "Address: ", % ""
   }
   _cmd .= (admin != "")      ? "*RunAs " ComSpec " /K" : ComSpec " /K"
   _cmd .= " " Chr(0x22)
   _cmd .= (_Path != "")      ? "cd /d " _Path          : "cd /d " A_Desktop
   _cmd .= (subroutine != "") ? " && "  subroutine      : ""
   _cmd .= (feedback != "")   ? " && exit"              : ""
   _cmd .= Chr(0x22)
   ; MsgBox % _cmd
   if (feedback != "" && hide != "")
      RunWait % _cmd,, Hide ;If cmd remains open, function will never exit.
   else if (hide != "")
      Run % _cmd,, Hide
   else if (feedback != "")
      RunWait % _cmd
   else
      Run % _cmd
   return 1
}

RunWaitOne(command) {
   dhw := A_DetectHiddenWindows
   DetectHiddenWindows On
   Run %ComSpec% /k,, Hide, pid
   while !(hConsole := WinExist("ahk_pid" pid))
   	Sleep 10
   DllCall("AttachConsole", "UInt", pid)
   DetectHiddenWindows %dhw%
   objShell := ComObjCreate("WScript.Shell")
   objExec := objShell.Exec(ComSpec " /C " command)
   While !objExec.Status
       Sleep 100
   strLine := objExec.StdOut.ReadAll() ;read the output at once
   DllCall("FreeConsole")
   Process Exist, %pid%
   if (ErrorLevel == pid)
   	Process Close, %pid%
   return strLine
}

RunWaitMany(commands) {
    shell := ComObjCreate("WScript.Shell")
    ; Open cmd.exe with echoing of commands disabled
    exec := shell.Exec(ComSpec " /Q /K echo off")
    ; Send the commands to execute, separated by newline
    exec.StdIn.WriteLine(commands "`nexit")  ; Always exit at the end!
    ; Read and return the output of all commands
    return exec.StdOut.ReadAll()
}

ExecScript(Script, Wait:=true)
{
    shell := ComObjCreate("WScript.Shell")
    exec := shell.Exec("AutoHotkey.exe /ErrorStdOut *")
    exec.StdIn.Write(script)
    exec.StdIn.Close()
    if Wait
        return exec.StdOut.ReadAll()
}
