#!/usr/bin/env python
import sys
import argparse
import time
import Adafruit_SSD1306

from PIL import Image
from PIL import ImageDraw
from PIL import ImageFont

# Set up arguments
parser = argparse.ArgumentParser()
parser.add_argument("-i", "--image", help="image to be drawn")
parser.add_argument("-t", "--text", help="text to be drawn")
parser.add_argument("-k", "--keep", help="don't clear the display on start", action="store_true")
parser.add_argument("-c", "--clear", help="clear display and exit", action="store_true")

args = parser.parse_args()
 
# Pin configuration
RST = 24
disp = Adafruit_SSD1306.SSD1306_128_32(rst=RST)

#Initialize and clear display
disp.begin()
if args.clear:
  disp.clear()
  disp.display()
  sys.exit(0)

if not args.keep:
  disp.clear()
  disp.display()

# Create blank image for drawing
width = disp.width
height = disp.height
image = Image.new('1', (width, height))
draw = ImageDraw.Draw(image)

# Load default font
font = ImageFont.load_default()
#draw.text((0,2),'BoB', font=font, fill=255)

# Default to text first, then image
if args.text:
  # Text will require parsing for size.
  draw.text((0,2),args.text, font=font, fill=255)
elif args.image:
  image = Image.open(args.image).convert('1')
  
#Display image
disp.image(image)
disp.display()


