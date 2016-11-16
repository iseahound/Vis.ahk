# Vis.ahk
Real-time Optical Character Recognition (OCR) Wrapper in AHK. 

![static image of OCR on myfonts.com](http://i.imgur.com/isL4NCr.jpg)

## What does it do:

OCR is optical character recognition meaning it translates the image it sees on screen into text. The benefits of using OCR occur when there is text in video or images that need to be extracted, but on a more practical level can be used to extract text in applications that cannot be highlighted. Vis.ahk saves the day. 

## Download

Clone or download the folder titled distribution.


### How do I run it?

Press the Start Vis.bat file (Located in "Distribution"). Then press Windows + C. Now click and drag a rectangle. When you let go, the text shown in the black and white caption bar will have been copied to your clipboard. Open your text editor and paste (Ctrl+V) to see your highlighted text!

### Advanced Mode

While the Left Mouse Button is held down, press the control key. You should see a confirmation message displaying "Advanced Mode". Let go of the Left Click Button and the Control key, and the rectange will now be permanently located on your screen. 

* To move the rectangle, simply Left Click + Drag. 
* To Resize, hold Control + Left Click + Drag the corner. 
* To Resize the length of the box, hold Shift + Left Click + Drag the edge. 

### Is it really real-time?

That depends on the speed of your CPU. To prevent lag on older devices, there is a 100ms delay between each image to text conversion. The smaller the size of your rectangle, the quicker it will process. Larger images take time. 

![Helvetica - Short &amp; Lossy](http://i.imgur.com/88iTGUf.gif)
