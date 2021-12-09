//*************************************************************************
// Assignment 2 DUIET
// Lars Giling: l.t.giling@student.tue.nl
//
// Allows for audio control (forward,backward, pause/play, volume) through 
// multi-touch gestures. Song list can be expanded if mp3 file is declared 
// in setup(), the rest should work as variable. 
//
// ### Gesture controls ###
// Slide up: volume up. Slide down: volume down.
// Slide left: previous song. Slide right: next song.
// Cup hand over sensor: pause / resume current song.
//*************************************************************************

/***************************************************
 This is a library for the Multi-Touch Kit
 Designed and tested to work with Arduino Uno, MEGA2560, LilyPad(ATmega 328P)
 
 For details on using this library see the tutorial at:
 ----> https://hci.cs.uni-saarland.de/multi-touch-kit/
 
 Written by Jan Dickmann, Narjes Pourjafarian, Juergen Steimle (Saarland University), Anusha Withana (University of Sydney), Joe Paradiso (MIT)
 MIT license, all text above must be included in any redistribution
 ****************************************************/

import gab.opencv.*;
import MultiTouchKitUI.*;
import processing.serial.*;
import blobDetection.*;
import processing.sound.*;

//declare amount of songs in playlist
int songcount = 3;
SoundFile[] songs = new SoundFile[songcount];
SoundFile file;

//default starting song, default volume and volume increments.
int songindex = 0;
float volume = 0.5;
float volumeincr = 0.25;

String msg = "";
int leftstep, rightstep, upstep, downstep, handcup = 0;
int l_m, r_m, u_m, d_m, h_m, msg_timer;
int l_mc, r_mc, u_mc, d_mc, h_mc, msg_timerc;
int[] touchData = new int[8];

int tx = 4;               //number of transmitter lines (rx)
int rx = 4;               //number of receiver lines (rx)
int serialPort = 0;       //serial port that the Arduino is connected to

Serial myPort;
MultiTouchKit mtk;

int maxInputRange = 50;  // set the brightness of touch points
float threshold = 0.75f;  // set the threshold for blob detection

int[][] values;           // values used for visualization
int[][] rawvalues;        // raw values recieved from serial port
long[][] baseline;        // baseline values saved for calibartion

Table tableRaw;           // table for recording raw values
Table tableAdj;           // table for recording values used for visualization
Table tableBas;           // table for recording baseline values



void setup() {
  size(1000, 1000);
  background(255);
  mtk = new MultiTouchKit(this, tx, rx, serialPort);
  mtk.autoDraw(true);
  mtk.setMaxInputRange(maxInputRange);
  mtk.setThresh(threshold);

  //declare sound files.
  songs[0] = new SoundFile(this, "arctic_monkeys.mp3");
  songs[1] = new SoundFile(this, "of_monsters_and_men.mp3");
  songs[2] = new SoundFile(this, "oasis.mp3");
  
  songs[songindex].amp(volume);
}

void draw() {
  //calculate values used for calibration and visualization from raw serial values
  rawvalues = mtk.getRawValues();   
  baseline = mtk.getBaseLine();              
  values = mtk.getAdjustedValues();
  
  //preprocess grid values
  for (int i = 0; i < 4; i++) {
    touchData[i] = values[0][i];
  }    
  for (int i = 4; i < 8; i++) {
    touchData[i] = values[i-4][0];
  }
     
  //check for touch control inputs
  LeftSlide();
  RightSlide();
  UpSlide();
  DownSlide();
  Pause();
  
  //print control input on screen
  textSize(70);
  text(msg, 40,190);
  msg_timerc = millis();
  if (msg_timer < (msg_timerc - 3000)) {
    msg = "";
  }

  //print values in console for debugging purposes
  println("values: ");
  for (int i = 0; i < tx; i++) {
    print("tx "+i+" :");
    for (int j = 0; j < rx; j++) {
      print(" "+values[i][j]);
    }
    println();
  }
  println("------------------------------------------");
}

void LeftSlide() {
  if (touchData[3] > 30) {
    l_m = millis();
    leftstep = 1;
  }
  if (touchData[2] > 30 && leftstep == 1) {
    leftstep = 2;
  }
  if (touchData[1] > 30 && leftstep == 2) {
    leftstep = 3;
  }
  if (touchData[0] > 30 && (leftstep == 3) && touchData[3] < 30) {
    leftstep = 0;
    if (volume < 1) {
      volume += volumeincr;
      songs[songindex].amp(volume);
      println("Increasing volume to: ", volume);
      msg = ("Increasing volume to: " + volume);
      msg_timer = millis();
    } else {
      println("Already at max volume!");
      msg = ("Already at max volume!");
    }
  }
  l_mc = millis();
  if (l_m < (l_mc - 300)) {
    leftstep = 0;
  }
}

void RightSlide() {
  if (touchData[0] > 30) {
    r_m = millis();
    rightstep = 1;
  }
  if (touchData[1] > 30 && rightstep == 1) {
    rightstep = 2;
  }
  if (touchData[2] > 30 && rightstep == 2) {
    rightstep = 3;
  }
  if (touchData[3] > 30 && (rightstep == 3) && touchData[0] < 30) {
    rightstep = 0;
    if (volume > 0) {
      volume -= volumeincr;
      songs[songindex].amp(volume);
      println("Decreasing volume to: " + volume);
      msg = ("Decreasing volume to: " + volume);
      msg_timer = millis();
    } else {
      println("Already at minimal volume!");
      msg = ("Already at minimal volume!");
    }
  }
  r_mc = millis();
  if (r_m < (r_mc - 300)) {
    rightstep = 0;
  }
}
void UpSlide() {
  if (touchData[7] > 30) {
    u_m = millis();
    upstep = 1;
  }
  if (touchData[6] > 30 && upstep == 1) {
    upstep = 2;
  }
  if (touchData[5] > 30 && upstep == 2) {
    upstep = 3;
  }
  if (touchData[4] > 30 && (upstep == 3) && touchData[7] < 30) {
    upstep = 0;
    println("Playing next song");
    msg = ("Playing next song ");
    msg_timer = millis();
    songs[songindex].stop();
    //if its the last song in the array; loop back to start.
    if (songindex == (songs.length - 1)) {
      songindex = 0;
    } else {
      songindex += 1;
    }
    songs[songindex].amp(volume);
    songs[songindex].play();
  }
  u_mc = millis();
  if (u_m < (u_mc - 300)) {
    upstep = 0;
  }
}

void DownSlide() {
  if (touchData[4] > 30) {
    d_m = millis();
    downstep = 1;
  }
  if (touchData[5] > 30 && downstep == 1) {
    downstep = 2;
  }
  if (touchData[6] > 30 && downstep == 2) {
    downstep = 3;
  }
  if (touchData[7] > 30 && (downstep == 3) && touchData[4] < 30) {
    downstep = 0;
    println("Playing previous song");
    msg = ("Playing previous song");
    msg_timer = millis();
    songs[songindex].stop();
    //if its the first song in the array, loop to the back.
    if (songindex == 0) {
      songindex = (songs.length - 1);
    } else {
      songindex -= 1;
    }
    songs[songindex].amp(volume);
    songs[songindex].play();
  }
  d_mc = millis();
  if (d_m < (d_mc - 300)) {
    downstep = 0;
  }
}

void Pause() {
  handcup = 1;
  h_mc = millis();
  for (int i = 0; i < 8; i++) {
    if (touchData[i] < 30) {
      handcup = 0;
    }
  }
  while (handcup == 1 && (h_m < (h_mc - 1000))) {
    //leftstep = rightstep = upstep = downstep = handcup = 0;
    if (songs[songindex].isPlaying()) {
      songs[songindex].pause();
    } else {
      songs[songindex].play();
    }
    println("Pause / Play");
    msg = "Pausing / Playing current song";
    msg_timer = millis();
    text(msg, 120, 190);
    h_m = millis();
    delay(1000);
  }
}
