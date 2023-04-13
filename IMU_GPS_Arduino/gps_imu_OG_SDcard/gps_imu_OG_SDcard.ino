// EC 464

// GPS
#include <TinyGPS++.h>
#include <SoftwareSerial.h>

// Include Wire Library for I2C
#include <Wire.h>

// SD Card Reader
#include <SPI.h>
#include <SD.h>

static const int TXPin = 4, RXPin = 3;
// static const uint32_t GPSBaud = 115200;
static const uint32_t GPSBaud = 9600;

// Define I2C Address - change if reqiuired
const int i2c_addr = 0x3F;

// The TinyGPS++ object
TinyGPSPlus gps;

// The serial connection to the GPS device
SoftwareSerial ss(RXPin, TXPin);

//Variables for Gyroscope
int gyro_x, gyro_y, gyro_z;
int temp;
long acc_x, acc_y, acc_z;

// SD card reader
File myFile;

// Off Button
const int buttonPin = 9;  // the number of the pushbutton pin
int button = 0;


void setup()
{
  Serial.begin(115200);
  ss.begin(GPSBaud);

  Serial.println(F("DeviceExample.ino"));
  Serial.println(F("A simple demonstration of TinyGPS++ with an attached GPS module"));
  Serial.print(F("Testing TinyGPS++ library v. ")); Serial.println(TinyGPSPlus::libraryVersion());
  Serial.println(F("by Mikal Hart"));
  Serial.println();

  //Start I2C
  Wire.begin();

  //Setup the registers of the MPU-6050                                                       
  setup_mpu_6050_registers();

  // SD Card Reader ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
  while (!Serial) {
    ; // wait for serial port to connect. Needed for native USB port only
  }
 
  Serial.print("Initializing SD card...");
 
  if (!SD.begin(7)) {
    Serial.println("initialization failed!");
    while (1);
  }
  Serial.println("initialization done.");
 
  // open the file. note that only one file can be open at a time,
  // so you have to close this one before opening another.
  myFile = SD.open("imu_test.txt", FILE_WRITE);

  // initialize the pushbutton pin as an input:
  pinMode(buttonPin, INPUT);
}

void loop()
{
  // read the state of the pushbutton value:
  button = digitalRead(buttonPin);

  if (button == LOW) {
    // This sketch displays information every time a new sentence is correctly encoded.
    while (ss.available() > 0)
      if (gps.encode(ss.read())) {
        // Get data from MPU-6050
        read_mpu_6050_data();

        // if the file opened okay, write to it:
        if (myFile) {
          // Print Data for IMU
          myFile.print("\n");
          myFile.print("Accel: ");         // comment out to write to CSV
          myFile.print(acc_x); myFile.print(",");
          myFile.print(acc_y); myFile.print(",");
          myFile.print(acc_z); myFile.print(",");
          myFile.print("\tTemp: ");        // comment out to write to CSV
          myFile.print(temp); myFile.print(",");
          myFile.print("\tOrientation: "); // comment out to write to CSV
          myFile.print(gyro_x); myFile.print(",");
          myFile.print(gyro_y); myFile.print(",");
          myFile.print(gyro_z);
          myFile.print("\t\t");

          // Display GPS info
          GPS_info_display();
        }

        // Print Data for IMU
        Serial.print("\n");
        Serial.print("Accel: ");         // comment out to write to CSV
        Serial.print(acc_x); Serial.print(",");
        Serial.print(acc_y); Serial.print(",");
        Serial.print(acc_z); Serial.print(",");
        Serial.print("\tTemp: ");        // comment out to write to CSV
        Serial.print(temp); Serial.print(",");
        Serial.print("\tOrientation: "); // comment out to write to CSV
        Serial.print(gyro_x); Serial.print(",");
        Serial.print(gyro_y); Serial.print(",");
        Serial.print(gyro_z);
        Serial.print("\t\t");

        // Display GPS info
        GPS_info_display();
      }
        

    if (millis() > 5000 && gps.charsProcessed() < 10)
    {
      Serial.println(F("No GPS detected: check wiring."));
      while(true);
    }
  }
  else if (button == HIGH) {
    // close the file:
    myFile.close();
    Serial.println("DONE!");

    // Exit the Arduino Board
    exit(0);      
  }

}

void GPS_info_display()
{
  Serial.print(F("Location: ")); 
  if (gps.location.isValid())
  {
    Serial.print(gps.location.lat(), 6);
    Serial.print(F(","));
    Serial.print(gps.location.lng(), 6);
  }
  else
  {
    Serial.print(F("INVALID"));
  }

  Serial.print(F("  Date/Time: "));
  if (gps.date.isValid())
  {
    Serial.print(gps.date.month());
    Serial.print(F("/"));
    Serial.print(gps.date.day());
    Serial.print(F("/"));
    Serial.print(gps.date.year());
  }
  else
  {
    Serial.print(F("INVALID"));
  }

  Serial.print(F(" "));
  if (gps.time.isValid())
  {
    if (gps.time.hour() < 10) Serial.print(F("0"));
      Serial.print(gps.time.hour());
      Serial.print(F(":"));
    if (gps.time.minute() < 10) Serial.print(F("0"));
      Serial.print(gps.time.minute());
      Serial.print(F(":"));
    if (gps.time.second() < 10) Serial.print(F("0"));
      Serial.print(gps.time.second());
      Serial.print(F("."));
    if (gps.time.centisecond() < 10) Serial.print(F("0"));
      Serial.print(gps.time.centisecond());
  }
  else
  {
    Serial.print(F("INVALID"));
  }

  // Serial.println();
}

void GPS_info_write()
{
  myFile.print(F("Location: ")); 
  if (gps.location.isValid())
  {
    myFile.print(gps.location.lat(), 6);
    myFile.print(F(","));
    myFile.print(gps.location.lng(), 6);
  }
  else
  {
    myFile.print(F("INVALID"));
  }

  myFile.print(F("  Date/Time: "));
  if (gps.date.isValid())
  {
    myFile.print(gps.date.month());
    myFile.print(F("/"));
    myFile.print(gps.date.day());
    myFile.print(F("/"));
    myFile.print(gps.date.year());
  }
  else
  {
    myFile.print(F("INVALID"));
  }

  myFile.print(F(" "));
  if (gps.time.isValid())
  {
    if (gps.time.hour() < 10) myFile.print(F("0"));
      myFile.print(gps.time.hour());
      myFile.print(F(":"));
    if (gps.time.minute() < 10) myFile.print(F("0"));
      myFile.print(gps.time.minute());
      myFile.print(F(":"));
    if (gps.time.second() < 10) myFile.print(F("0"));
      myFile.print(gps.time.second());
      myFile.print(F("."));
    if (gps.time.centisecond() < 10) myFile.print(F("0"));
      myFile.print(gps.time.centisecond());
  }
  else
  {
    myFile.print(F("INVALID"));
  }

  // myFile.println();
}

void setup_mpu_6050_registers(){
 
  //Activate the MPU-6050
  
  //Start communicating with the MPU-6050
  Wire.beginTransmission(0x68); 
  //Send the requested starting register                                       
  Wire.write(0x6B);  
  //Set the requested starting register                                                  
  Wire.write(0x00);
  //End the transmission                                                    
  Wire.endTransmission(); 
                                              
  //Configure the accelerometer (+/-8g)
  
  //Start communicating with the MPU-6050
  Wire.beginTransmission(0x68); 
  //Send the requested starting register                                       
  Wire.write(0x1C);   
  //Set the requested starting register                                                 
  Wire.write(0x10); 
  //End the transmission                                                   
  Wire.endTransmission(); 
                                              
  //Configure the gyro (500dps full scale)
  
  //Start communicating with the MPU-6050
  Wire.beginTransmission(0x68);
  //Send the requested starting register                                        
  Wire.write(0x1B);
  //Set the requested starting register                                                    
  Wire.write(0x08); 
  //End the transmission                                                  
  Wire.endTransmission(); 
                                              
}
 
 
void read_mpu_6050_data(){ 
 
  //Read the raw gyro and accelerometer data
 
  //Start communicating with the MPU-6050                                          
  Wire.beginTransmission(0x68);  
  //Send the requested starting register                                      
  Wire.write(0x3B);
  //End the transmission                                                    
  Wire.endTransmission(); 
  //Request 14 bytes from the MPU-6050                                  
  Wire.requestFrom(0x68,14);    
  //Wait until all the bytes are received                                       
  while(Wire.available() < 14);
  
  //Following statements left shift 8 bits, then bitwise OR.  
  //Turns two 8-bit values into one 16-bit value                                       
  acc_x = Wire.read()<<8|Wire.read();                                  
  acc_y = Wire.read()<<8|Wire.read();                                  
  acc_z = Wire.read()<<8|Wire.read();                                  
  temp = Wire.read()<<8|Wire.read();                                   
  gyro_x = Wire.read()<<8|Wire.read();                                 
  gyro_y = Wire.read()<<8|Wire.read();                                 
  gyro_z = Wire.read()<<8|Wire.read();                                 
}