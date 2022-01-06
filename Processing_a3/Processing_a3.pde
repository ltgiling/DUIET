//*********************************************************************
// Assignment 3 DUIET
// Lars Giling: l.t.giling@student.tue.nl
//
// Uses linerar NFC-tag tracking to determine change in contents of a
// regular school bag. The bag is fitted with a RC522 NFC reader, each
// bag object is fitted with two NTAG213 NFC stickers placed exactly
// 35mm apart allowing for accurate insert/extract speed measuring.
//
// NFC-processing and display graph code by: Rong-Hao Liang
//*********************************************************************
import processing.serial.*;
import OpenNFCSense4P.*;
Serial port;
OpenNFCSense4P nfcs;

String motionInfo = "";
int b_timer, b_timer_f, obj_num;
  color clr_cal = color(153, 0, 0);
  color clr_ntb = color(153, 0, 0);
  color clr_cmp = color(153, 0, 0);

void setup() {
  size(800, 600, P2D);              //Start a 800x600 px canvas (using P2D renderer)
  nfcs = new OpenNFCSense4P(this, "tagProfile.csv", 300, 500, 2000); //Initialize OpenNFCSense with the tag profiles (*.csv) in /data
  initSerial();                     //Initialize the serial port
}

void draw() {
  nfcs.updateNFCBits();                   //update the features of current bit
  background(255);                  //Refresh the screen
  
  textSize(34);
  fill(0);
  text("Your Bag", 500, 60);
  textSize(24);
  fill(clr_cal);
  text("Calculator", 500, 100);
  fill(clr_ntb);
  text("Notebook", 500, 140);
  fill(clr_cmp);
  text("Component case", 500, 180);

  nfcs.drawMotionModeRecords(50, 2*height/3, 2*width/3, height/3-50); //draw the motion mode record of last second (x,y,width,height)
  b_timer = millis();
  drawLastBit(50, 100);             //draw the basic information of the last NFCBit
  drawInfo(width, height);          //draw the version, read rate, and TTL timer info
  printCurrentTag();                //print the current tag read by the reader
}

/*Initialize the serial port*/
void initSerial() {             
  for (int i = 0; i < Serial.list().length; i++) println("[", i, "]:", Serial.list()[i]); //print the serial port
  port = new Serial(this, Serial.list()[Serial.list().length-1], 115200); //for Mac and Linux 
  // port = new Serial(this, Serial.list()[0], 115200); // for PC
  port.bufferUntil('\n');           // arduino ends each data packet with a carriage return 
  port.clear();                     // flush the Serial buffer
}

/*draw the basic information of the last NFCBit*/
void drawLastBit(int x, int y) { //print the latest tag appearance
  ArrayList<NFCBit> nbitList = nfcs.getNFCBits();       // get all of the recent NFCBits
  String objInfo = "";
  String tagID = "";
  if (nbitList.size()>0) {
    NFCBit nb = nbitList.get(0);                // get the latest NFCBit  
    tagID = "["+nfcs.getIDTable().get(0)+"]";   // get the ID string of the latest tag
    objInfo += nb.getName();

    if (nb.getMode()!=NFCBit.NA) {              // if the feature is ready (mode!=NA=0)     
      if (nb.getModeString() == "moving forward") {
        motionInfo = "Now in the bag!";
        b_timer_f = millis();                   // set current time in ms.
        if(nb.getName().equals("Calculator")){  // track object ID
          clr_cal = color(0, 153, 76);          // set object color
        }
        if(nb.getName().equals("Notebook")){
          clr_ntb = color(0, 153, 76);
        }
        if(nb.getName().equals("Component case")){
          clr_cmp = color(0, 153, 76);
        }
      }
      if (nb.getModeString() == "moving backward") {
        motionInfo = "Taken out of the bag!";
        b_timer_f = millis();
        if(nb.getName().equals("Calculator")){
          clr_cal = color(153, 0, 0);
        }
        if(nb.getName().equals("Notebook")){
          clr_ntb = color(153, 0, 0);
        }
        if(nb.getName().equals("Component case")){
          clr_cmp = color(153, 0, 0);
        }
      }
    }
  }
   //prevent double tag readings from (accidentally) clearing object manipulation message, set custom display length in ms.
  if (b_timer > (b_timer_f + 2000)) {   
    motionInfo = "";
  }
  pushStyle();
  fill(0);
  textSize(40);
  text(objInfo, x, y);
  textSize(32);
  text(motionInfo, x, y+48);
  textSize(16);
  //text(tagID, x, y+48+32);
  popStyle();
}

/*draw the version, read rate, and TTL timer info*/
void drawInfo(int x, int y) { 
  String info = "[Open NFCSense] ver. "+OpenNFCSense4P.version()+"\n"; //get the current library version
  info += "Read rate: "+nf(nfcs.getReadRate(), 0, 0)+" reads/sec\n"; // get the current read rate
  info += "TTL Timer1: "+nf(nfcs.getTimer1(), 0, 0)+" ms\n";         // get the current TTL timer1
  info += "TTL Timer2: "+nf(nfcs.getTimer2(), 0, 0)+" ms";           // get the current TTL timer2
  //set the above parameters in the constructor as indicated in setup();
  pushStyle();
  fill(100);
  textSize(12);
  textAlign(RIGHT, BOTTOM);
  text(info, x-5, y-5);
  popStyle();
}

/*print the extra information of the recent NFCBits in the console*/
void printRecentBits() {
  ArrayList<NFCBit> nbitList = nfcs.getNFCBits(); // get all of the recent NFCBits
  for (int i = 0; i < nbitList.size(); i++) {
    NFCBit nb = nbitList.get(i);                  // get the latest NFCBit at index i
    String tagID = "["+nfcs.getIDTable().get(i)+"]"; //get the ID string of the latest tag
    print("[", i, "]", tagID, nb.getName(), ":", nb.getModeString(), "(mode= ", nb.getMode(), ") ");
    //print the name of tag, the ID, the mode of motion depending on the motion type (mode=0: not ready), determined by the m and n in the algorithm.
    print(nb.getTokenTypeString(), nb.getMotionTypeString(), "|");
    //print the type of token (e.g., z<z*, z>z*, theta>theta*, d_gap>d_gap*)
    //the type of motion (e.g., linear translation, rotation, shm, compound+motion)
    println("V=", nf(nb.getSpeed(), 0, 2), "km/h; f=", nf(nb.getFrequency(), 0, 2), "Hz");
    //the features (speed and frequency)
  }
  println("===");
}

/*print the extra information of the last NFCBit in the console*/
void printLastBit() {
  ArrayList<NFCBit> nbitList = nfcs.getNFCBits(); // get all of the recent NFCBits
  if (nbitList.size()>0) {
    NFCBit nb = nbitList.get(0);                  // get the latest NFCBit 
    String tagID = "["+nfcs.getIDTable().get(0)+"]"; //get the ID string of the latest tag
    print(nb.getName(), tagID, ":", nb.getModeString(), "(mode= ", nb.getMode(), ") "); 
    //print the name of tag, the ID, the mode of motion depending on the motion type (mode=0: not ready), determined by the m and n in the algorithm.  
    print(nb.getTokenTypeString(), nb.getMotionTypeString(), "|");
    //print the type of token (e.g., z<z*, z>z*, theta>theta*, d_gap>d_gap*)
    //the type of motion (e.g., linear translation, rotation, shm, compound, compound+motion)
    println("V=", nf(nb.getSpeed(), 0, 2), "km/h; f=", nf(nb.getFrequency(), 0, 2), "Hz");
    //the features (speed and frequency)
  }
  println("===");
}

/*The serial event handler processes the data from any NFC reader in the String format of 
 // "A[Byte_0]\n, B[Byte_1]\n, C[Byte_2]\n, or D[Byte_3]\n", 
 //where every byte is an unsigned integer ranged between [0-256].  
 //When a tag is present: Byte_i=[0-255]; Otherwise, when a tag is absent: [256].
 //================*/

void serialEvent(Serial port) {   
  String inData = port.readStringUntil('\n');  // read the serial string until seeing a carriage return
  if (inData.charAt(0) >= 'A' && inData.charAt(0) <= 'D') {
    int i = inData.charAt(0)-'A';
    int v = int(trim(inData.substring(1)));
    nfcs.rfid[i] = (v>255?-1:v);
    if (i==3) nfcs.checkTagID();                // process the tag ID when a sequence is collected completely.
  }
  return;
}

//print the current tag read by the reader
void printCurrentTag() {
  if (nfcs.rfid[0]<0) println("No tag");
  else println(nfcs.rfid[0], ",", nfcs.rfid[1], ",", nfcs.rfid[2], ",", nfcs.rfid[3]);
}
