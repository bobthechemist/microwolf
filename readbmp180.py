#!/usr/bin/env python
import Adafruit_BMP.BMP085 as BMP

sensor = BMP.BMP085()

print('{0:0.2f}, {1:0.0f}'.format(sensor.read_temperature(),sensor.read_pressure()))

