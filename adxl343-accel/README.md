# I2C Adafruit ADXL343 Example

We took the ESP32 I2C example and reworked it to control the Adafruit ADXL343 accelerometer.

Connect the computer's serial port to ESP32, and find the port, which in my case is COM4

Then, run

`idf.py -p COM4 build flahs monitor`

And you will be able to see the result in console.

![accel](images/accel.jpg)