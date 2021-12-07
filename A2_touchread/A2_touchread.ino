#define PIN_NUM 8
#define MICRO_S 33000

long timer = micros(); //timer
int touchRead_pins[PIN_NUM] = {4, 15, 13, 12, 14, 27, 33, 32};
char touchRead_ID[PIN_NUM] = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'};
int data;
int ledOn = 0;

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
}

void loop() {
  if (micros() - timer > MICRO_S) { //Timer: send sensor data in every 2ms
    timer = micros();
    for (int i = 0 ; i < PIN_NUM ; i++) {
      data = (46 - touchRead(touchRead_pins[i]));
      
      //remove data jittering from higher signal travel length.
      if (data < 20){
        data = 0;
      }
      if(data > 50) {
        data = 50;
      }
      sendDataToProcessing(touchRead_ID[i], data);
    }
  }
}

void sendDataToProcessing(char symbol, int data) {
  Serial.print(symbol);  // symbol prefix of data type
  Serial.println(data);  // the integer data with a carriage return
}

void getDataFromProcessing() {
  while (Serial.available()) {
    char inChar = (char)Serial.read();
    if (inChar == 'a') { //when an 'a' charactor is received.
      ledOn = 1 - ledOn;
    }
  }
}
