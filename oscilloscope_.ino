/**** Simple matlab oscilliscope

revision history:
09/01/2016 Mark D. Shattuck <mds> candle.ino
           Demo for P371
           000 mds random brightness
           001 mds measure output on A0
           002 convert to lab4 part II
02/03/2021 000 convert for cantilever lab

****/
const int inPin = A0;  // Analog input pin
const int BUF = 768;   // Number of points per time-series

int n, m, k;  // useful counters       
int pin = 9;  // light output pin

unsigned short vS[BUF];  // Place to store measurents

unsigned long dt;

// function to wait for a specified character from the serial port.
bool waitFor(char in, unsigned int pollTime = 256, unsigned long timeout = 1e6) {
  bool done = false;
  char c;
  unsigned long T;
  T = micros();
  while (!done && (micros() - T < timeout)) {
    delayMicroseconds(pollTime);
    if (Serial.available() > 0) {
      c = Serial.read();
      done = (c == in);
    }
  }
  return done;
}

void setup() {
  pinMode(pin, OUTPUT);     // initialize pin PIN as an output.
  pinMode(13, OUTPUT);      // initialize pin PIN as an output.
  analogWrite(pin,5);       // dim for pictures
  Serial.begin(115200);     // setup serial
  while (!waitFor('?'));    // stop until recieve '?' from serial port
  Serial.println('K');      // respond O('K')
  digitalWrite(13,HIGH);    // visual response
  digitalWrite(pin,HIGH);    // visual response
}

// Wait for commands of the form "g###", where ### is the number of us between acquisitions
// The minimum time to get a measurement is 120us.  The resolution is 4us.  The total
// measurement time is sent over the serial port since there is some variability.
void loop() {
  while (!waitFor('g'));          // wait for command begining 'g'
  long dta=Serial.parseInt();     // get dt
  dta=4*(dta/4-1);                // correct for 4us resolution and overhead
  if(dta<=120-4) dta=0;           // if dt<120 then no need to wait
  digitalWrite(pin,LOW);          // visual indication that acquisition will start 
  delay(100);
  digitalWrite(pin,HIGH);         // set HIGH for acquisition
  delay(70);                      // make sure light is on
  long dt0=micros();              // timed acquisition loop
  for (n = 0, dt = micros(); n < BUF; n++) {
    while (micros() - dt < dta);
    dt = micros();
    vS[n] = analogRead(inPin);
  }
  dt = micros() - dt0;            // Measure total acquisition time  
  for (n = 0; n < BUF; n++) {     // print data to serial 
    Serial.println(vS[n]);         
  }
  Serial.println(dt);             // print total time
}
