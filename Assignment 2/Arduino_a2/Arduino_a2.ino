/***************************************************
 This is a library for the Multi-Touch Kit
 Designed and tested to work with Arduino Uno, MEGA2560, LilyPad(ATmega 328P)
 Note: Please remind to disconnect AREF pin from AVCC on Lilypad
 
 For details on using this library see the tutorial at:
 ----> https://hci.cs.uni-saarland.de/multi-touch-kit/
 
 Written by Narjes Pourjafarian, Jan Dickmann, Juergen Steimle (Saarland University), 
            Anusha Withana (University of Sydney), Joe Paradiso (MIT)
 MIT license, all text above must be included in any redistribution
 ****************************************************/

#include <MultiTouchKit.h>

//----- Multiplexer input pins (for UNO) -----
int s0 = 7;
int s1 = 8;
int s2 = 9;
int s3 = 10;

int muxPins[4] = {s3, s2, s1, s0};

//----- Number of receiver (RX) and transmitter (TX) lines -----
int RX_num = 4;
int TX_num = 4;

//----- Receive raw capacitance data or touch up/down states -----
boolean raw_data = false;  // true: receive raw capacitance data, false: receive touch up/down states
int threshold = 30;  // Threshold for detecting touch down state (only required if raw_data = false). 
                    // Change this variable based on your sensor. (for more info. check the tutorial)

MultiTouchKit mtk;

void setup() {
  //Serial connection, make sure to use the same baud rate in the processing sketch
  Serial.begin(115200);

  //setup the Sensor
  mtk.setup_sensor(RX_num,TX_num,muxPins,raw_data,threshold);
}

void loop() {
  //Continuously writes multi-touch data to Serial.
  //Each row represents all RX values read from one TX line seperated by "," (the first value is TX ID)
  mtk.read();
}
