#include <Time.h>
#include <Servo.h> 

////////////////////////////////////////////////////////////////////////////7
// Servo for digital camera operation
// Gustavo Pereyra Irujo - pereyrairujo.gustavo@conicet.gov.ar
// April 2016

Servo myservo;

void setup() {
    myservo.attach(9);             // servo connected to pin 9
    Serial.begin(9600);
    delay(100);
}

int count=0;
int pos=90;

void loop(){

  count++;
  
    myservo.write(90);      // Move the servo to center position
    delay(500);
    myservo.write(140);      // Move the servo to turn camera on  
    delay(500);
    myservo.write(90);       // Move the servo to center position 
    delay(3000);

  for (pos = 90; pos >= 60; pos -= 1) { // goes from center position to shutter position
    myservo.write(pos);
    delay(75);                       // make movement slow to allow focusing
  }
  delay(2000);
  for (pos = 60; pos <= 90; pos += 1) { // goes back to center position
    myservo.write(pos);
    delay(15);         
  }


    myservo.write(90);      // Move the servo to center position
    delay(4000);
    myservo.write(140);      // Move the servo to turn camera off  
    delay(500);
    myservo.write(90);       // Move the servo to center position 
  
  time_t t = now(); // Store the current time in time variable t
  Serial.print(count);  

      Serial.print("\n");
  delay(165000);      // 3 min delay.  Adjust as necessary
}


