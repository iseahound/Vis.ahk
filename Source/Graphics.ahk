#include library\Crypt.ahk
#include library\Gdip_All.ahk
#include library\Math.ahk
#include library\Replacements.ahk
#include library\System.ahk

class Graphics{

   class Area{

      __New(boundcallback, name := "", color := "") {
         ;Make sure to put in the !=. The assignments break without them. Here only.
         ;FileAppend, `nCreated New Object, Aries.txt
         this.boundcallback := boundcallback
         this.color := (color != "") ? color : 0xDDDDDD
         this.name := (name != "") ? name : "SelectArea"

         pToken := Gdip_Startup()
         Gui, SelectArea:+LastFound +AlwaysOnTop -Caption -DPIScale +E0x80000 +ToolWindow
         WinSet, Transparent, 128
         Gui, SelectArea:Color, % this.color
         Gui, SelectArea:Show, x0 y0 w0 h0 NoActivate, % this.name
      }

      Release(){
         ;FileAppend, `nRelease Aries, Aries.txt
         this.isRelease := true
         Gdip_Shutdown(pToken)
         Gui, SelectArea:Destroy
         boundcallback := this.boundcallback
         (%boundcallback%())
         return
      }

      Debug(){
         FileAppend, % "`n Possible: " this.X ", " this.Y ", " this.x_move ", " this.y_move, Aries.txt
         FileAppend, % "`n" this.x1 ", " this.y1 ", " this.x2 ", " this.y2, Aries.txt
      }

      Origin(){
         ;FileAppend, `nAries.Origin, Aries.txt
         CoordMode, Mouse, Screen
         MouseGetPos, X, Y
         this.X := X
         this.Y := Y
      }

      Converge(){                                                                      ; SmartConverge
         this.x1 := (this.x1_beta != "") ? this.x1_beta : this.x1
         this.x2 := (this.x2_beta != "") ? this.x2_beta : this.x2
         this.y1 := (this.y1_beta != "") ? this.y1_beta : this.y1
         this.y2 := (this.y2_beta != "") ? this.y2_beta : this.y2

         this.x1_beta := ""
         this.x2_beta := ""
         this.y1_beta := ""
         this.y2_beta := ""
      }

      PopulateBeta(){                                                                  ; If beta values don't exist initialize them to alpha values.
         this.x1_beta := (this.x1_beta) ? this.x1_beta : this.x1
         this.x2_beta := (this.x2_beta) ? this.x2_beta : this.x2
         this.y1_beta := (this.y1_beta) ? this.y1_beta : this.y1
         this.y2_beta := (this.y2_beta) ? this.y2_beta : this.y2
      }

      Hover(words := ""){
         ;FileAppend, `nAries.Hover, Aries.txt
         CoordMode, Mouse, Screen
         MouseGetPos, X, Y
         this.X := X
         this.Y := Y

         if (X != this.x_last || Y != this.y_last) {
            this.x_last := X, this.y_last := Y
            Tooltip, % words
         }
      }

      Draw(){
         ;FileAppend, `nAries.Draw, Aries.txt
         CoordMode, Mouse, Screen
         MouseGetPos, x_move, y_move

         if (x_move != this.x_last || y_move != this.y_last) {
            this.x_last := x_move, this.y_last := y_move

            this.x1 := (this.X > x_move) ? x_move : this.X
            this.y1 := (this.Y > y_move) ? y_move : this.Y
            this.x2 := (this.X > x_move) ? this.X : x_move
            this.y2 := (this.Y > y_move) ? this.Y : y_move

            ;Tooltip, % "X" this.x1 " Y" this.y1 " W" this.x2-this.x1 " H" this.y2-this.y1
            Gui, SelectArea:Show, % "X" this.x1 " Y" this.y1 " W" this.x2-this.x1 " H" this.y2-this.y1 "NoActivate", % this.name
         }
      }

      Enlarge(){                                                                   ;Like Resize, except works with corners.
         ;FileAppend, `nAries.Enlarge, Aries.txt
         CoordMode, Mouse, Screen
         MouseGetPos, x_move, y_move

         xr := this.X - this.x1 - ((this.x2 - this.x1) / 2)
         yr := this.y1 - this.Y + ((this.y2 - this.y1) / 2)
         dx := x_move - this.X
         dy := y_move - this.Y

         if (x_move != this.x_last || y_move != this.y_last) {
            this.x_last := x_move, this.y_last := y_move

            if (xr < 0 && yr > 0) {
               q := "top left"
               this.x1_beta := this.x1 + dx
               this.y1_beta := this.y1 + dy
            }
            if (xr > 0 && yr > 0) {
               q := "top right"
               this.x2_beta := this.x2 + dx
               this.y1_beta := this.y1 + dy
            }
            if (xr < 0 && yr < 0) {
               q := "bottom left"
               this.x1_beta := this.x1 + dx
               this.y2_beta := this.y2 + dy
            }
            if (xr > 0 && yr < 0) {
               q := "bottom right"
               this.x2_beta := this.x2 + dx
               this.y2_beta := this.y2 + dy
            }

            this.PopulateBeta()
            Gui, SelectArea:Show, % "X" this.x1_beta " Y" this.y1_beta " W" this.x2_beta-this.x1_beta " H" this.y2_beta-this.y1_beta "NoActivate", % this.name
         }
      }

      Resize(){
         ; This works by finding the line equations of the diagonals of the rectangle.
         ; To identify the quadrant the cursor is located in, the while loop compares it's y value
         ; with the function line values f(x) = m * xr and y = -m * xr.
         ; So if yr is below both theoretical y values, then we know it's in the bottom quadrant.
         ; Be careful with this code, it converts the y plane inversely to match the Decartes tradition.

         ; Safety features include checking for past values to prevent flickering
         ; Sleep statements are required in every while loop.

         ;FileAppend, `nAries.Resize, Aries.txt
         CoordMode, Mouse, Screen
         MouseGetPos, x_move, y_move

         q := ""
         m := (this.y1 - this.y2) / (this.x2 - this.x1)
         xr := this.X - this.x1 - ((this.x2 - this.x1) / 2)
         yr := this.y1 - this.Y + ((this.y2 - this.y1) / 2)
         dx := x_move - this.X
         dy := y_move - this.Y

         if (x_move != this.x_last || y_move != this.y_last) {
            this.x_last := x_move, this.y_last := y_move

            if (m * xr > yr && yr > -m * xr)
               q := "left",    this.x1_beta := this.x1 + dx
            if (m * xr < yr && yr > -m * xr)
               q := "top",     this.y1_beta := this.y1 + dy
            if (m * xr < yr && yr < -m * xr)
               q := "right",   this.x2_beta := this.x2 + dx
            if (m * xr > yr && yr < -m * xr)
               q := "bottom",  this.y2_beta := this.y2 + dy

            /* Doesn't work.
            ; If beta values exceed possible dimensions, normalize them. Possible multi-monitor conflict. (2&4)
            this.x1_beta := (this.x1_beta < 0) 0 ? this.x1_beta
            this.x2_beta := (this.x2_beta > A_ScreenWidth) ? A_ScreenWidth - this.x1_beta : this.x2_beta
            this.y1_beta := (this.y1_beta < 0) 0 ? this.y1_beta
            this.y2_beta := (this.y2_beta > A_ScreenHeight) ? A_ScreenHeight - this.y1_beta : this.y2_beta
            */

            this.PopulateBeta()
            ;Tooltip, % "dx: " dx ", dy: " dy "`n" q
            Gui, SelectArea:Show, % "X" this.x1_beta " Y" this.y1_beta " W" this.x2_beta-this.x1_beta " H" this.y2_beta-this.y1_beta  "NoActivate", % this.name
         }
      }

      Move(){
         ;FileAppend, `nAries.Move, Aries.txt
         CoordMode, Mouse, Screen
         MouseGetPos, x_move, y_move

         dx := x_move - this.X
         dy := y_move - this.Y

         if (x_move != this.x_last || y_move != this.y_last) {
            this.x_last := x_move, this.y_last := y_move

            this.x1_beta := this.x1 + dx
            this.x2_beta := this.x2 + dx
            this.y1_beta := this.y1 + dy
            this.y2_beta := this.y2 + dy

            this.PopulateBeta()
            ;Tooltip, % "dx: " dx " dy: " dy "`n`t" this.x1_beta "`t" this.y1_beta "`n`t" this.x2_beta "`t" this.y2_beta
            Gui, SelectArea:Show, % "X" this.x1_beta " Y" this.y1_beta " W" this.x2-this.x1 " H" this.y2-this.y1 "NoActivate", % this.name
         }
      }

      isMouseInside(){
         return (this.X > this.x1 && this.X < this.x2 && this.Y > this.y1 && this.Y < this.y2)
      }

      isMouseOutside(){
         return not (this.X > this.x1 && this.X < this.x2 && this.Y > this.y1 && this.Y < this.y2)
      }

      Screenshot(fileName := "", x1 := "", y1 := "", x2 := "", y2 := ""){
         fileName := (fileName != "") ? fileName : this.fileName
         if (x1 == "")
            x1 := (this.x1_beta != "") ? this.x1_beta : this.x1
         if (y1 == "")
            y1 := (this.y1_beta != "") ? this.y1_beta : this.y1
         if (x2 == "")
            x2 := (this.x2_beta != "") ? this.x2_beta : this.x2
         if (y2 == "")
            y2 := (this.y2_beta != "") ? this.y2_beta : this.y2

         captureRect := x1 "|" y1 "|" x2 - x1 "|" y2 - y1
         pBitmap := Gdip_BitmapFromScreen(captureRect)
         Gdip_SaveBitmapToFile(pBitmap, fileName)
         Gdip_DisposeImage(pBitmap)
         return
      }

      isIdenticalScreenshot(){
         Hash := Crypt.Hash.FileHash(this.fileName, 1)
         if (this.Hash != Hash) {                                            ;Uses MD5 to hash the file, comparing it to the previous hash of a different file.
            this.Hash := Hash                                                ;If the hashes are the same, the image data is the same.
            return false
         }
         return true
      }
   }


   class Image{

      __New(angelic) {
         DeclareGlobal(angelic)
         this.name := angelic . "Image"
         name := this.name
         this.x1 := 0, this.y1 := 0, this.x2 := 0, this.y2 := 0

         Gui, %name%:+LastFound +AlwaysOnTop -Caption -DPIScale +ToolWindow
         Gui, %name%:Margin, 0, 0
         Gui, %name%:Add,Picture, % "v" angelic, media\fox.gif
         Gui, %name%:Show, Hide
      }

      Destroy() {
         name := this.name
         Gui, %name%:Destroy
      }

      Hide() {
         Gui, % this.name ":Show", Hide
      }

      Render(angelic, file) {
         name := this.name
      	GuiControl, %name%:-Redraw, Pic
         GuiControl, %name%:, % angelic, % "*w *h " file
      	GuiControl, %name%:+Redraw, Pic
         Gui, %name%:Show, x0 y0 NoActivate AutoSize
      }
   }


   class Subtitle{

      __New(name, mode := "", fontcolor := "", backgroundcolor := ""){
         this.name := name
         this.mode := (!mode || mode == "static") ? "static" : "dynamic"
         this.backgroundcolor := (backgroundcolor != "") ? backgroundcolor : 0x000000
         this.fontcolor := (fontcolor != "") ? fontcolor : 0xFFFFFF
         this.fontFamily := "Arial"
         this.fontSize := 24
         this.lines := 0
         this.x_margin := 10
         this.y_margin := 10
         this.x1 := 0, this.y1 := 0
         this.x2 := 0, this.y2 := 0
         this.w_max := 0

         this.bkgd := this.name "2"
         bkgd := this.bkgd
         Gui, %bkgd%:+LastFound +AlwaysOnTop -Caption -DPIScale +ToolWindow
         WinSet, Transparent, 200
         Gui, %bkgd%:Color, % this.backgroundcolor
         Gui, %bkgd%:Show, x0 y0 w0 h0 NoActivate, % this.bkgd

         Gui, %name%:+LastFound +AlwaysOnTop -Caption -DPIScale +ToolWindow +Owner%bkgd%
         Gui, %name%:Font, % "c" this.fontcolor " s" this.fontSize, % this.fontFamily
         Gui, %name%:Margin, 10, 10
         Gui, %name%:Color, % this.backgroundcolor
         Winset, Transcolor, % this.backgroundcolor
         Gui, %name%:Show, x0 y0 w0 h0 NoActivate, % this.name
      }

      AddLine(angelic) {
         name := this.name
         DeclareGlobal(angelic)
         this.lines++
         Gui, %name%:Add, Text, % "v" angelic, "Lorem ipsum... you shouldn't be seeing this.!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      }

      Destroy() {
         bkgd := this.bkgd
         name := this.name
         Gui, %bkgd%:Destroy
         Gui, %name%:Destroy
      }

      Font(family := "", size := "", color := "") {
         name := this.name
         this.fontColor := (color != "") ? color : this.fontColor
         this.fontSize := (size != "") ? size : this.size
         this.fontFamily := (family != "") ? family : this.family

         Gui, %name%: Font, % "c" this.fontcolor " s" this.fontsize , % this.fontfamily
      }

      Hide() {
         bkgd := this.bkgd
         name := this.name
         Gui, %bkgd%: Show, Hide
         Gui, %name%: Show, Hide
      }

      Margin(x_margin, y_margin := "") {
         name := this.name
         this.x_margin := x_margin
         this.y_margin := (this.y_margin != "") ? x_margin : y_margin
         Gui, %name%:Margin, % this.x_margin, % this.y_margin
      }

      Position(x1, y1, x2 := "", y2 := "", align := "") {
         this.x1 := x1
         this.y1 := y1
         this.x2 := (x2 == "") ? x1 : x2
         this.y2 := (y2 == "") ? y1 : y2
         this.center := (align == "center" || true) ? true : false
      }

      Progress(p) {
         bkgd := this.bkgd
         if (p == true)
            Gui, %bkgd%:Color, % 0x202020
         else
            Gui, %bkgd%:Color, % this.backgroundcolor
         WinSet, Redraw, , % this.bkgd
      }

      Render(angelic, words) {
         bkgd := this.bkgd
         name := this.name

               ; Black Block bug solved. (Text appears cut off as if words in the middle of sentences are incompletely rendered.)
               ; Solution #1) Use GuiControl Move before Text
               ; Solution #2) Use MoveDraw, which widens the available text area and redraws any text present.

         if (this.mode == "static") {
            W := this.x2 - this.x1
            H := this.y2 - this.y1
            w_background := W + 2*this.x_margin
            h_background := H + 2*this.y_margin

            Gui, %bkgd%:Show, % "Hide X" this.x1 " Y" this.y1 " W" w_background " H" h_background " NoActivate"
            GuiControl, %name%:Move, % angelic, % "W" W " H" H
            GuiControl, %name%:Text, % angelic, % words
            WinSet, Region, % 0 "-" 0 " W" w_background " H" h_background " R" 10 "-" 10, % this.bkgd
            Gui, %bkgd%:Show, % "X" this.x1 " Y" this.y1 " W" w_background " H" h_background " NoActivate"
            Gui, %name%:Show, % "X" this.x1 " Y" this.y1 " W" W " H" H " NoActivate"
         }
         else {
            W := this.simTextSize(words, this.fontSize, this.fontFamily, false)
            H := this.lines * this.simTextSize(words, this.fontSize, this.fontFamily, true)
            this.w_max := (W > this.w_max) ? W : this.w_max
            w_background := this.W_max + 2*this.x_margin
            h_background := H + 2*this.y_margin
            this.x1 := (this.center == true) ? 0.5*(A_ScreenWidth - W) - this.x_margin : this.x1

            ; Seems useless but is used for overlap detection!
            this.x2 := this.x1 + this.w_max
            this.y2 := this.y1 + H

            ; Hiding the background solves the redraw issue where text exceeds the background area.
            Gui, %bkgd%:Show, % "Hide X" this.x1 " Y" this.y1 " W" w_background " H" h_background " NoActivate"
            GuiControl, %name%:Move, % angelic, % "W" this.w_max " H" H
            GuiControl, %name%:Text, % angelic, % words
            WinSet, Region, % 0 "-" 0 " W" w_background " H" h_background " R" 10 "-" 10, % this.bkgd
            Gui, %bkgd%:Show, % "X" this.x1 " Y" this.y1 " W" w_background " H" h_background " NoActivate"
            Gui, %name%:Show, % "X" this.x1 " Y" this.y1 " AutoSize NoActivate"
         }
         return
      }

      RenderFinish(){
         ; So the w_max parameter, which defines how wide the box is based on the size of the largest line, can start with new info.
         this.w_max := 0
      }

      ; From Capture2Text and modified.
      ; Get the size of a text control (in pixels)
      ; Creating a temporary hidden window, add the text, get size, delete window
      ; str    - The string displayed in the text control
      ; size   - The font size of the text
      ; font   - The font of the text
      ; height - 1 = return height as well as width, 0 = return only the width
      simTextSize(str, size, font, height=false) {
         static angelic := "Graphics_Subtitle_simTextSize"
         DeclareGlobal(angelic)
         Gui, TextSizeWindow: -DPIScale
         Gui, TextSizeWindow:Font, % "s" size, % font
         Gui, TextSizeWindow:Add, Text, % "v" angelic, % str
         GuiControlGet outSize, TextSizeWindow:Pos, % angelic
         Gui, TextSizeWindow:Destroy
         return (height) ? outSizeH : outSizeW
      }
   }
}
