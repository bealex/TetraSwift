#include <QuadDisplay2.h>

typedef enum {
    input, servomotor, pwm, digital, quaddisplay
} pinType;

typedef struct pin {
    pinType type;    //Type of pin
    int state;       //State of an output
};

pin arduinoPins[14]; //Array of struct holding 0-13 pins information
unsigned long lastDataReceivedTime = millis();
QuadDisplay quadDisplay(8);

// 0 — waiting for handshake, 1 - send/receive
int state = 0;

void setup() {
    Serial.begin(38400);
    Serial.flush();
    configurePins();
    resetPins();
}

void loop() {
    static unsigned long timerCheckUpdate = millis();

    if (millis() - timerCheckUpdate >= 20) {
        sendUpdateServomotors();
        sendSensorValues();
        timerCheckUpdate = millis();
    }

    readSerialPort();
}

void configurePins() {
    arduinoPins[0].type = input;
    arduinoPins[1].type = input;
    arduinoPins[2].type = input;
    arduinoPins[3].type = input;
    arduinoPins[4].type = servomotor;
    arduinoPins[5].type = pwm;
    arduinoPins[6].type = pwm;
    arduinoPins[7].type = servomotor;
    arduinoPins[8].type = quaddisplay; // servomotor
    arduinoPins[9].type = pwm;
    arduinoPins[10].type = digital;
    arduinoPins[11].type = digital;
    arduinoPins[12].type = digital;
    arduinoPins[13].type = digital;
}

void resetPins() {
    for (byte i = 0; i <= 13; i++) {
        if (arduinoPins[i].type != input) {
            pinMode(i, OUTPUT);
            if (arduinoPins[i].type == servomotor) {
                arduinoPins[i].state = 255;
                servo(i, 255);
            } else {
                arduinoPins[i].state = 0;
                digitalWrite(i, LOW);
            }
        }
    }
    quadDisplay.begin();
    quadDisplay.displayClear();
}

void sendSensorValues() {
    if (state == 0) {
        return;
    }

    unsigned int sensorValues[6], readings[5];
    byte sensorIndex;

    for (sensorIndex = 0; sensorIndex < 6; sensorIndex++) {
        // For analog sensors, calculate the median of 5 sensor readings in order to avoid variability and power surges
        for (byte p = 0; p < 5; p++) {
            readings[p] = analogRead(sensorIndex);
        }
        insertionSort(readings, 5); // sort readings
        sensorValues[sensorIndex] = readings[2]; // select median reading
    }

    byte digital6 = digitalRead(2) ? 255 : 0;
    byte digital7 = digitalRead(3) ? 255 : 0;

    Serial.write(B00000010);
    // send analog sensor values
    for (sensorIndex = 0; sensorIndex < 6; sensorIndex++) {
        Serial.write((byte) ((sensorValues[sensorIndex] >> 8) & B00000011));
        Serial.write((byte) (sensorValues[sensorIndex] & B11111111));
    }
    // send digital sensor values
    Serial.write(digital6);
    Serial.write(digital7);
}

void insertionSort(unsigned int *array, unsigned int n) {
    for (unsigned int i = 1; i < n; i++) {
        for (int j = i; (j > 0) && (array[j] < array[j - 1]); j--) {
            swap(array, j, j - 1);
        }
    }
}

void swap(unsigned int *array, unsigned int a, unsigned int b) {
    unsigned int temp = array[a];
    array[a] = array[b];
    array[b] = temp;
}

void exception() {
    state = 0;
  
    Serial.end();
    Serial.begin(38400);
    Serial.flush();
    resetPins();

    for (int i = 0; i < 10; i++) {
        digitalWrite(13, HIGH);
        delay(50);
        digitalWrite(13, LOW);
        delay(50);
    }
}

void readSerialPort() {
    static byte version = B00000001;

    static byte buffer[255];
    static int max = 255;
    static int position = 0;

    if (Serial.available()) {
        buffer[position] = Serial.read();
        position += 1;
        if (position > max) {
            position = 0;
            exception();
        }
        lastDataReceivedTime = millis();

        if (state == 0) {
            if (position == 2) {
                if (buffer[0] == 0 && buffer[1] == version) {
                    Serial.write((byte) B00000001);
                    Serial.write(version);
                    Serial.write((byte) 18); // ports count
                    // outputs
                    Serial.write((byte) 0); Serial.write((byte) 0b01); // analog
                    Serial.write((byte) 1); Serial.write((byte) 0b01); // analog
                    Serial.write((byte) 2); Serial.write((byte) 0b01); // analog
                    Serial.write((byte) 3); Serial.write((byte) 0b01); // analog
                    Serial.write((byte) 4); Serial.write((byte) 0b01); // analog
                    Serial.write((byte) 5); Serial.write((byte) 0b01); // analog  <- not used, afaik (to check)
                    Serial.write((byte) 6); Serial.write((byte) 0b11); // digital
                    Serial.write((byte) 7); Serial.write((byte) 0b11); // digital
                    // inputs
                    Serial.write((byte) 4); Serial.write((byte) 0b00); // analog, motor
                    Serial.write((byte) 5); Serial.write((byte) 0b00); // analog, led
                    Serial.write((byte) 6); Serial.write((byte) 0b00); // analog, led
                    Serial.write((byte) 7); Serial.write((byte) 0b00); // analog, motor
                    Serial.write((byte) 8); Serial.write((byte) 0b00); // analog, motor
                    Serial.write((byte) 9); Serial.write((byte) 0b00); // analog, buzzer
                    Serial.write((byte) 10); Serial.write((byte) 0b10); // digital, led
                    Serial.write((byte) 11); Serial.write((byte) 0b10); // digital, led
                    Serial.write((byte) 12); Serial.write((byte) 0b10); // digital, led
                    Serial.write((byte) 13); Serial.write((byte) 0b10); // digital, led

                    position = 0;
                    state = 1;
                } else {
                    position = 0;
                    exception();
                }
            }
        } else if (state == 1) {
            if (position > 0) {
                byte command = buffer[0];
                if (command == B00000011) { // single actuator
                    if (position == 3) {
                        byte pinIndex = buffer[1];
                        int value = buffer[2]; updatePin(pinIndex, value);
                        position = 0;
                    }
                } else if (command == B00000100) { // all actuators
                    if (position == 1 + 6 + 4) {
                        int base = 1;
                        int value = 0;
                        value = buffer[base]; updatePin(4, value); base += 1;
                        value = buffer[base]; updatePin(5, value); base += 1;
                        value = buffer[base]; updatePin(6, value); base += 1;
                        value = buffer[base]; updatePin(7, value); base += 1;
                        value = buffer[base]; updatePin(8, value); base += 1;
                        value = buffer[base]; updatePin(9, value); base += 1;
                        value = buffer[base]; if (value == 0) value = 0; else value = 1023; updatePin(10, value); base += 1;
                        value = buffer[base]; if (value == 0) value = 0; else value = 1023; updatePin(11, value); base += 1;
                        value = buffer[base]; if (value == 0) value = 0; else value = 1023; updatePin(12, value); base += 1;
                        value = buffer[base]; if (value == 0) value = 0; else value = 1023; updatePin(13, value); base += 1;
                        position = 0;
                    }
                } else if (command == B00000101) {
                    if (position == 6 && arduinoPins[buffer[1]].type == quaddisplay) {
                        quadDisplay.displayDigits(buffer[2], buffer[3], buffer[4], buffer[5]);
                        position = 0;
                    }
                } else {
                    position = 0;
                    exception();
                }
            }
        }
    } else {
        if (!Serial) {
            resetPins();
            sendSensorValues();
            state = 0;
            position = 0;
            lastDataReceivedTime = millis();
        }
    }
}

void updatePin(byte pinIndex, int value) {
    if (arduinoPins[pinIndex].state != value) {
        arduinoPins[pinIndex].state = value;
        updateActuator(pinIndex);
    }
}

void updateActuator(byte pinNumber) {
    if (arduinoPins[pinNumber].type == digital) {
        digitalWrite(pinNumber, arduinoPins[pinNumber].state);
    } else if (arduinoPins[pinNumber].type == pwm) {
        analogWrite(pinNumber, arduinoPins[pinNumber].state);
    }
}

void sendUpdateServomotors() {
    for (byte p = 0; p < 10; p++) {
        if (arduinoPins[p].type == servomotor) {
            servo(p, arduinoPins[p].state);
        }
    }
}

void servo(byte pinNumber, byte angle) {
    if (angle != 255) {
        digitalWrite(pinNumber, HIGH);
        delayMicroseconds((angle * 10) + 600);
        digitalWrite(pinNumber, LOW);
    }
}
