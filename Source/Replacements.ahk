;A set of commands turned into functions.

DeclareGlobal(angelic) {
   global
   (%angelic%)
   return  ; angelic is omnipresent. Deref angelic and make her a global var.
}

Null() {
   return
}

FileDelete(Filename) {
   FileDelete, %Filename%
}

FileRead(Filename) {
   FileRead, v, %Filename%
   Return, v
}

FileReadLine(Filename, LineNum) {
   FileReadLine, v, %Filename%, %LineNum%
   Return, v
}
