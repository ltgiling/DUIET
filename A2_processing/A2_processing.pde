//*************************************************************************
// Assignment 2 Interactive Intelligent Products
// Lars Giling: l.t.g****g@student.tue.nl
//
// Allows for audio control (forward,backward, pause/play, volume) through 
// multi-touch gestures via ESP32. Song list can be expanded if mp3 file is 
// declared in setup(), the rest should work as variable. 
//
// ### Gesture controls ###
// Slide up: volume up. Slide down: volume down.
// Slide left: previous song. Slide right: next song.
// Cup hand over sensor: pause / resume current song.
//
// SerialEvent code by: Rong-Hao Liang
//*************************************************************************

import processing.serial.*;
import processing.sound.*;

SoundFile[] songs = new SoundFile[3];
SoundFile file;

//default starting song, volume and volume increments.
int songindex = 0;
float volume = 0.5;
float volumeincr = 0.25;

Serial port;

String msg = "";
int dataNum = 1;
int sensorNum = 8;
int leftstep, rightstep, upstep, downstep, handcup = 0;
int l_m, r_m, u_m, d_m, h_m, msg_timer;
int l_mc, r_mc, u_mc, d_mc, h_mc, msg_timerc;
int[][] rawData = new int[sensorNum][dataNum];
int[][] initData = new int[sensorNum][dataNum];
int[] currData = new int[sensorNum];
int[][] val = new int[4][4];
int dataIndex = 0;

void setup() {
  size(1000, 1000);
  String portName = Serial.list()[0];
  println("connected to: ", portName);
  port = new Serial(this, portName, 115200);
  port.bufferUntil('\n');
  port.clear();
  
  //declare sound files.
  songs[0] = new SoundFile(this, "arctic_monkeys.mp3");
  songs[1] = new SoundFile(this, "of_monsters_and_men.mp3");
  songs[2] = new SoundFile(this, "oasis.mp3");
  
  songs[songindex].amp(volume);
}

void draw() {
  background(0);
  
  for (int i = 0; i < 8; i++) {
    currData[i] = rawData[i][0] - initData[i][0];
    //println(currData[i]);
  }
  
  //check for gesture movements
  LeftSlide();
  RightSlide();
  UpSlide();
  DownSlide();
  Pause();
    textSize(70);
   // fill(0, 408, 612);
    text(msg, 40,190);
  msg_timerc = millis();
  if (msg_timer < (msg_timerc - 3000)) {
    msg = "";
  }
}

void serialEvent(Serial port) {
  // read the serial string until seeing a carriage return
  String inData = port.readStringUntil('\n');
  int dataID = inData.charAt(0) - 'A';
  if (inData.length()>2) {
    rawData[dataID][0] = int(trim(inData.substring(1)));
    if (dataIndex == 0) initData[dataID][0] = rawData[dataID][0];
    if (dataID == sensorNum-1) ++dataIndex;
  }
  return;
}

void LeftSlide() {
  if (currData[3] > 30) {
    l_m = millis();
    leftstep = 1;
  }
  if (currData[2] > 30 && leftstep == 1) {
    leftstep = 2;
  }
  if (currData[1] > 30 && leftstep == 2) {
    leftstep = 3;
  }
  if (currData[0] > 30 && (leftstep == 3) && currData[3] < 30) {
    leftstep = 0;
     if (volume < 1){
    volume += volumeincr;  
    songs[songindex].amp(volume);
    println("Increasing volume to: ", volume);
    msg = ("Increasing volume to: " + volume);
    msg_timer = millis();
    }
    else {
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
  if (currData[0] > 30) {
    r_m = millis();
    rightstep = 1;
  }
  if (currData[1] > 30 && rightstep == 1) {
    rightstep = 2;
  }
  if (currData[2] > 30 && rightstep == 2) {
    rightstep = 3;
  }
  if (currData[3] > 30 && (rightstep == 3) && currData[0] < 30) {
    rightstep = 0;
if (volume > 0){
    volume -= volumeincr;  
    songs[songindex].amp(volume);
    println("Decreasing volume to: " + volume);
    msg = ("Decreasing volume to: " + volume);
    msg_timer = millis();
    }
    else {
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
  if (currData[7] > 30) {
    u_m = millis();
    upstep = 1;
  }
  if (currData[6] > 30 && upstep == 1) {
    upstep = 2;
  }
  if (currData[5] > 30 && upstep == 2) {
    upstep = 3;
  }
  if (currData[4] > 30 && (upstep == 3) && currData[7] < 30) {
    upstep = 0;
   println("Playing next song");
   msg = ("Playing next song ");
   msg_timer = millis();
    songs[songindex].stop();
      //if its the last song in the array; loop back to start.
      if(songindex == (songs.length - 1)){
      songindex = 0;
      }
      else {
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
  if (currData[4] > 30) {
    d_m = millis();
    downstep = 1;
  }
  if (currData[5] > 30 && downstep == 1) {
    downstep = 2;
  }
  if (currData[6] > 30 && downstep == 2) {
    downstep = 3;
  }
  if (currData[7] > 30 && (downstep == 3) && currData[4] < 30) {
    downstep = 0;
      println("Playing previous song");
      msg = ("Playing previous song");
      msg_timer = millis();
      songs[songindex].stop();
      //if its the first song in the array, loop to the back.
      if(songindex == 0){
      songindex = (songs.length - 1);
      }
      else {
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
    if (currData[i] < 30){
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
      text(msg, 120,190);
      h_m = millis();
      delay(1000);
  }
}
