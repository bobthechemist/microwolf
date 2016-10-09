# microwolf
MoP device based on the RPi zero

# Notes
Make sure that oled.py works for your display.  The script is hardwired for the 128x32 display from Adafruit; however it can be adjusted easily.  In principle, it will work with SPI devices as well.

Access to X is required since *Mathematica* wants the GUI front end to Export graphics.  Presently, I do this with an SSH client that has an X server (MobaXterm on the PC).  

The wolfram package is started with `<<oled\`` and and you can create simple text with oledText[*str*] and plots with oledPlot[fun,{var,min,max}].

