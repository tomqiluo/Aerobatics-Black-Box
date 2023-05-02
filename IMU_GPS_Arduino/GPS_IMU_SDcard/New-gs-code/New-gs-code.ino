/* 
EC 464 Senior Design Project II
Maxwell Bakalos, Eli Carroll, Qi Luo, Yanbo Zhu
Some of this code is adapted from the following sources:
https://randomnerdtutorials.com/arduino-mpu-6050-accelerometer-gyroscope/
https://dronebotworkshop.com/sd-card-arduino/
Format: Acceleration (m/s^2): x, y, z | Gyroscope (rad/s): x, y, z | Temperature (°C) | GPS: latitude(°N), longitude (°W), altitude (meters)
*/

// GPS
#include <TinyGPS++.h>
#include <Wire.h> //Needed for I2C to GNSS
#include <SparkFun_u-blox_GNSS_v3.h> //Click here to get the library: http://librarymanager/All#SparkFun_u-blox_GNSS_v3

//#include <SoftwareSerial.h>
// IMU: MPU-6050 sensor: Adafruit_MPU6050 and Adafruit_Sensor
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <Wire.h> //I2C
// SD Card Reader
#include <SPI.h>
#include <SD.h>

SFE_UBLOX_GNSS myGNSS;
// GPS Transmitter & Receiver Pins
//static const int TXPin = 8, RXPin = 3;
// static const uint32_t GPSBaud = 115200;
//static const uint32_t GPSBaud = 9600;

// The TinyGPS++ object
TinyGPSPlus gps;

// The serial connection to the GPS device
//SoftwareSerial ss(RXPin, TXPin);

// Create an Adafruit_MPU6050 object called mpu to handle the sensor
Adafruit_MPU6050 mpu;

// SD Card Reader File
#if defined (ARDUINO_ARCH_SAM)
#define ARDUINO_DUE
#endif
#define myWire Wire1 // Connect using the Wire1 port. Change this if required
#define CSPIN 4
#define gnssAddress 0x42
File myFile;

// Off Button
const int buttonPin = 12;  // the number of the pushbutton pin
int button = 0;

void setup(void) {
  Serial.begin(115200);
  //ss.begin(GPSBaud);
  pinMode(buttonPin, INPUT);
 // Serial.print(F("\nSETUP"));

  setup_SD();

  setup_MPU6050();
  Serial.print("IMU setup complete");

  myWire.begin(); // Start I2C
  //myGNSS.enableDebugging(); // Uncomment this line to enable helpful debug messages on Serial
   while (myGNSS.begin(myWire, gnssAddress) == false) //Connect to the u-blox module using our custom port and address
  {
    Serial.println(F("u-blox GNSS not detected. Retrying..."));
    delay (1000);
  }
  myGNSS.setI2COutput(COM_TYPE_UBX); //Set the I2C port to output UBX only (turn off NMEA noise)
  

  Serial.print(F("\nSetup Complete\n"));
  //delay(100);


}

void loop() {
  // read the state of the pushbutton value:
  button = digitalRead(buttonPin);

  if (button == LOW) {
    //while (ss.available() > 0) {
      //if (gps.encode(ss.read())) {
        
        // if the file opened okay, write to it:
        if (myFile) {
          /* Print out the values */
          // Serial.println();
          // Serial.print(F("Acceleration X: "));
          // Serial.print(a.acceleration.x));
          // Serial.print(F((", Y: "));
          // Serial.print(a.acceleration.y);
          // Serial.print(F((", Z: "));
          // Serial.print(a.acceleration.z);
          // Serial.print(" m/s^2");

          // Serial.print(F(("   Rotation X: "));
          // Serial.print(g.gyro.x);
          // Serial.print(F((", Y: "));
          // Serial.print(g.gyro.y);
          // Serial.print(F((", Z: "));
          // Serial.print(g.gyro.z);
          // Serial.print(F((" rad/s"));

          // Serial.print(F(("   Temperature: "));
          // Serial.print(temp.temperature);
          // Serial.print(F((" degC"));

          IMU_write();

          GPS_write();
          Serial.println("writing...");
          
        } 
        else {
          // if the file didn't open, print an error:
          Serial.println(F("error opening test.txt"));
        }
      }
      

     // if (millis() > 5000 && gps.charsProcessed() < 10)
      //{
        //Serial.println(F("No GPS detected: check wiring."));
        //while(true);
      //}
    //}
  //}
    else {
    // close the file:
     myFile.close();
     Serial.println(F("DONE!"));

    // Exit the Arduino Board
     exit(0);      
  }
}

// Write IMU data to SD card
void IMU_write() {
  /* Get new sensor events with the readings */
  sensors_event_t a, g, temp;
  mpu.getEvent(&a, &g, &temp );
  
  /* Print out the values */
  myFile.println();
  // myFile.print("Acceleration X: ");
  myFile.print(a.acceleration.x);
  Serial.print(a.acceleration.x);
  // myFile.print(", Y: ");
  myFile.print(F(","));
  myFile.print(a.acceleration.y);
  // myFile.print(", Z: ");
  myFile.print(F(","));
  myFile.print(a.acceleration.z);
  Serial.print(a.acceleration.z);
  // myFile.print(" m/s^2");
  myFile.print(F(","));

  // myFile.print("   Rotation X: ");
  myFile.print(g.gyro.x);
  // myFile.print(", Y: ");
  myFile.print(F(","));
  myFile.print(g.gyro.y);
  // myFile.print(", Z: ");
  myFile.print(F(","));
  myFile.print(g.gyro.z);
  // myFile.print(" rad/s");
  myFile.print(F(","));
Serial.println("IMU data written");
  // myFile.print("   Temperature: ");
  //myFile.print(temp.temperature);
  // myFile.print(" degC");
  //myFile.print(F(","));
}

void GPS_write()
{
  // Request (poll) the position, velocity and time (PVT) information.
  // The module only responds when a new position is available. Default is once per second.
  // getPVT() returns true when new data is received.
  if (myGNSS.getPVT() == true)
  {
    int32_t latitude = myGNSS.getLatitude();
   myFile.print(F(","));
    myFile.print(latitude);

    int32_t longitude = myGNSS.getLongitude();
  myFile.print(F(","));
    myFile.print(longitude);
    Serial.print(longitude);
   // myFile.print(F(" (degrees * 10^-7)"));

    int32_t altitude = myGNSS.getAltitudeMSL(); // Altitude above Mean Sea Level
   myFile.print(F(","));
    myFile.print(altitude);
    //myFile.print(F(" (mm)"));
    myFile.print(F(","));
    myFile.print(myGNSS.getYear());
    myFile.print("-");
    myFile.print(myGNSS.getMonth());
    myFile.print("-");
    myFile.print(myGNSS.getDay());
    myFile.print(" ");
    myFile.print(myGNSS.getHour());
    myFile.print(":");
    myFile.print(myGNSS.getMinute());
    myFile.print(":");
    myFile.print(myGNSS.getSecond());

    myFile.println();
    Serial.println("GPS data written");
  }

    //printBuffer(myBuffer); // Uncomment this line to print the data as Hexadecimal bytes
  // myFile.print(F("Location: ")); 
  //if (gps.location.isValid())
  //{
    //myFile.print(gps.location.lat(), 6);  // Latitude (°N)
    //myFile.print(F(","));
    //myFile.print(gps.location.lng(), 6);  // Longitude (°W)
    //myFile.print(F(","));
    // myFile.print(gps.altitude.meters()); // Altitude (meters)
  //}
  // else
  // {
  //   // myFile.print(F("INVALID"));
  // }

  

  //if (gps.altitude.isValid()) {
    //myFile.print(F(","));
    //myFile.print(gps.altitude.meters()); // Altitude (meters)
  //}
  // else
  // {
  //   // myFile.print(F("INVALID"));
  // }

  // Print to Serial Monitor for debugging
  //Serial.println("LAT=");  Serial.println(gps.location.lat(), 6);
  //Serial.print("LONG="); Serial.println(gps.location.lng(), 6);
  //Serial.print("ALT=");  Serial.println(gps.altitude.meters());

  // myFile.print(F("  Date/Time: "));
  // if (gps.date.isValid())
  // {
  //   myFile.print(gps.date.month());
  //   myFile.print(F("/"));
  //   myFile.print(gps.date.day());
  //   myFile.print(F("/"));
  //   myFile.print(gps.date.year());
  // }
  // else
  // {
  //   myFile.print(F("INVALID"));
  // }

  // myFile.print(F(" "));
  // if (gps.time.isValid())
  // {
  //   if (gps.time.hour() < 10) myFile.print(F("0"));
  //     myFile.print(gps.time.hour());
  //     myFile.print(F(":"));
  //   if (gps.time.minute() < 10) myFile.print(F("0"));
  //     myFile.print(gps.time.minute());
  //     myFile.print(F(":"));
  //   if (gps.time.second() < 10) myFile.print(F("0"));
  //     myFile.print(gps.time.second());
  //     myFile.print(F("."));
  //   if (gps.time.centisecond() < 10) myFile.print(F("0"));
  //     myFile.print(gps.time.centisecond());
  // }
  // else
  // {
  //   myFile.print(F("INVALID"));
  // }

  // myFile.println();
}

// void displayInfo()
// {
//   Serial.print(F("Location: ")); 
//   if (gps.location.isValid())
//   {
//     Serial.print(gps.location.lat(), 6);
//     Serial.print(F(","));
//     Serial.print(gps.location.lng(), 6);
//   }
//   else
//   {
//     Serial.print(F("INVALID"));
//   }

//   Serial.print(F("  Date/Time: "));
//   if (gps.date.isValid())
//   {
//     Serial.print(gps.date.month());
//     Serial.print(F("/"));
//     Serial.print(gps.date.day());
//     Serial.print(F("/"));
//     Serial.print(gps.date.year());
//   }
//   else
//   {
//     Serial.print(F("INVALID"));
//   }

//   Serial.print(F(" "));
//   if (gps.time.isValid())
//   {
//     if (gps.time.hour() < 10) Serial.print(F("0"));
//       Serial.print(gps.time.hour());
//       Serial.print(F(":"));
//     if (gps.time.minute() < 10) Serial.print(F("0"));
//       Serial.print(gps.time.minute());
//       Serial.print(F(":"));
//     if (gps.time.second() < 10) Serial.print(F("0"));
//       Serial.print(gps.time.second());
//       Serial.print(F("."));
//     if (gps.time.centisecond() < 10) Serial.print(F("0"));
//       Serial.print(gps.time.centisecond());
//   }
//   else
//   {
//     Serial.print(F("INVALID"));
//   }

//   // Serial.println();
// }


void setup_SD() {
  // Open serial communications and wait for port to open:
  Serial.begin(9600);
  while (!Serial) {
    ; // wait for serial port to connect. Needed for native USB port only
  }
 
 
   Serial.print(F("\nInitializing SD Card..."));
 
  // in "if (!SD.begin(#))", # = pin for CS
  if (!SD.begin(CSPIN)) {
    Serial.println(F("initialization failed!"));
    while (1);
  }
   Serial.println(F("initialization done."));
 
  // open the file. note that only one file can be open at a time,
  // so you have to close this one before opening another.
  myFile = SD.open("test.txt", FILE_WRITE);
  Serial.println("file opened");
}

void setup_MPU6050() {
  while (!Serial)
    delay(10); // will pause Zero, Leonardo, etc until serial console opens

   Serial.println("\nAdafruit MPU6050 test!");

  // Try to initialize!
  if (!mpu.begin()) {
    Serial.println(F("\nFailed to find MPU6050 chip"));
    while (1) {
      delay(10);
    }
  }
  // Serial.println(F("\nMPU6050 Found!"));

  // Set the accelerometer measurement range
  mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
  // Serial.print("Accelerometer range set to: ");
  // switch (mpu.getAccelerometerRange()) {
  // case MPU6050_RANGE_2_G:
  //   Serial.println("+-2G");
  //   break;
  // case MPU6050_RANGE_4_G:
  //   Serial.println("+-4G");
  //   break;
  // case MPU6050_RANGE_8_G:
  //   Serial.println("+-8G");
  //   break;
  // case MPU6050_RANGE_16_G:
  //   Serial.println("+-16G");
  //   break;
  // }
  // Set the gyroscope measurement range
  mpu.setGyroRange(MPU6050_RANGE_500_DEG);
  // Serial.print("Gyro range set to: ");
  // switch (mpu.getGyroRange()) {
  // case MPU6050_RANGE_250_DEG:
  //   Serial.println("+- 250 deg/s");
  //   break;
  // case MPU6050_RANGE_500_DEG:
  //   Serial.println("+- 500 deg/s");
  //   break;
  // case MPU6050_RANGE_1000_DEG:
  //   Serial.println("+- 1000 deg/s");
  //   break;
  // case MPU6050_RANGE_2000_DEG:
  //   Serial.println("+- 2000 deg/s");
  //   break;
  // }

  // Set the filter bandwidth
  mpu.setFilterBandwidth(MPU6050_BAND_5_HZ);
  // Serial.print("Filter bandwidth set to: ");
  // switch (mpu.getFilterBandwidth()) {
  // case MPU6050_BAND_260_HZ:
  //   Serial.println("260 Hz");
  //   break;
  // case MPU6050_BAND_184_HZ:
  //   Serial.println("184 Hz");
  //   break;
  // case MPU6050_BAND_94_HZ:
  //   Serial.println("94 Hz");
  //   break;
  // case MPU6050_BAND_44_HZ:
  //   Serial.println("44 Hz");
  //   break;
  // case MPU6050_BAND_21_HZ:
  //   Serial.println("21 Hz");
  //   break;
  // case MPU6050_BAND_10_HZ:
  //   Serial.println("10 Hz");
  //   break;
  // case MPU6050_BAND_5_HZ:
  //   Serial.println("5 Hz");
  //   break;
  // }
}