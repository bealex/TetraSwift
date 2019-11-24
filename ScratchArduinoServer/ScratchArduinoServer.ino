// NEW IN VERSION 1.6c (by Jorge Gomez):
// Fixed variable type in pin structure: pin.state should be int, not byte
// Optimized speed of execution while receiving data from computer in readSerialPort()

// NEW IN VERSION 1.6b (by Jorge Gomez):
// Added new structure arduinoPins to hold the pins information:
//  - This makes the code easier to read and modify (IMHO)
//  - Allows to change the type of pin more easily to meet non standard use of S4A
//  - Eliminates the need of having to deal with different kind of index access (ie: states[pin-4])
//  - By using an enum to hold all the possible output pin states the code is now more readable
// Changed all functions using old style pin access: configurePins(), resetPins(), readSerialPort(), updateActuator() and sendUpdateActuator()
// Fixed possible overflow every 70 minutes (2e32 us) in pulse() while using micros(). Changed for delayMicroseconds()
// Some minor coding style fixes

// NEW IN VERSION 1.6a  (by Jorge Gomez):
// Fixed compatibility with Arduino Leonardo by avoiding the use of timers
// readSerialPort() optimized:
//  - created state machine for reading the two bytes of the S4A message
//  - updateActuator() is only called if the state is changed
// Memory use optimization
// Cleaning some parts of code
// Avoid using some global variables

// NEW IN VERSION 1.6:
// Refactored reset pins
// Merged code for standard and CR servos
// Merged patch for Leonardo from Peter Mueller (many thanks for this!)

// NEW IN VERSION 1.5:
// Changed pin 8 from standard servo to normal digital output

// NEW IN VERSION 1.4:
// Changed Serial.print() for Serial.write() in ScratchBoardSensorReport function to make it compatible with latest Arduino IDE (1.0)

// NEW IN VERSION 1.3:
// Now it works on GNU/Linux. Also tested with MacOS and Windows 7.
// timer2 set to 20ms, fixing a glitch that made this period unstable in previous versions.
// readSerialport() function optimized.
// pulse() modified so that it receives pulse width as a parameter instead using a global variable.
// updateServoMotors changes its name as a global variable had the same name.
// Some minor fixes.

#include <QuadDisplay2.h>

typedef enum {
    input, servomotor, pwm, digital
} pinType;

typedef struct pin {
    pinType type;       //Type of pin
    int state;         //State of an output
    //byte value;       //Value of an input. Not used by now. TODO
};

pin arduinoPins[14];  //Array of struct holding 0-13 pins information

unsigned long lastDataReceivedTime = millis();

QuadDisplay quadDisplay(4, 7, 8);

void setup() {
    Serial.begin(38400);
    Serial.flush();
    configurePins();
    resetPins();

    quadDisplay.begin();
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
    arduinoPins[4].type = digital; // servomotor;
    arduinoPins[5].type = pwm;
    arduinoPins[6].type = pwm;
    arduinoPins[7].type = digital; // servomotor;
    arduinoPins[8].type = digital; // servomotor;
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
    quadDisplay.displayClear();
}

void sendSensorValues() {
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

    // send analog sensor values
    for (sensorIndex = 0; sensorIndex < 6; sensorIndex++) {
        ScratchBoardSensorReport(sensorIndex, sensorValues[sensorIndex]);
    }

    // send digital sensor values
    ScratchBoardSensorReport(6, digitalRead(2) ? 1023 : 0);
    ScratchBoardSensorReport(7, digitalRead(3) ? 1023 : 0);
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

void ScratchBoardSensorReport(byte sensor, int value) {
    // PicoBoard protocol, 2 bytes per sensor
    Serial.write(B10000000 | ((sensor & B1111) << 3) | ((value >> 7) & B111));
    Serial.write(value & B1111111);
}

void readSerialPort() {
    byte pinIndex;
    int newValue;

    static byte actuatorHighByte, actuatorLowByte;
    static byte readingSM = 0;

    static byte currentDisplayDigit = 0;
    static byte displayDigit1 = 0;
    static byte displayDigit2 = 0;
    static byte displayDigit3 = 0;
    static byte displayDigit4 = 0;

    if (Serial.available()) {
        if (readingSM == 0) {
            actuatorHighByte = Serial.read();
            if (actuatorHighByte >= 128) {
                readingSM = 1;
            }
        } else if (readingSM == 1) {
            actuatorLowByte = Serial.read();
            if (actuatorLowByte < 128) {
                readingSM = 2;
            } else {
                readingSM = 0;
            }
        }

        if (readingSM == 2) {
            lastDataReceivedTime = millis();
            pinIndex = ((actuatorHighByte >> 3) & B1111);
            newValue = ((actuatorHighByte & B111) << 7) | (actuatorLowByte & B1111111);

            if (pinIndex < 14) {
                if (arduinoPins[pinIndex].state != newValue) {
                    arduinoPins[pinIndex].state = newValue;
                    updateActuator(pinIndex);
                }
            } else {
                if (pinIndex == 14) {
                    if (newValue > 999) {
                        if (newValue == 1023) {
                            quadDisplay.displayDigits(displayDigit1, displayDigit2, displayDigit3, displayDigit4);
                        } else if (newValue == 1000) {
                            displayDigit1 = 255;
                            displayDigit2 = 255;
                            displayDigit3 = 255;
                            displayDigit4 = 255;
                        } else if (newValue == 1001) {
                            currentDisplayDigit = 1;
                        } else if (newValue == 1002) {
                            currentDisplayDigit = 2;
                        } else if (newValue == 1003) {
                            currentDisplayDigit = 3;
                        } else if (newValue == 1004) {
                            currentDisplayDigit = 4;
                        }
                    } else {
                        if (currentDisplayDigit == 1) {
                            displayDigit1 = newValue;
                        } else if (currentDisplayDigit == 2) {
                            displayDigit2 = newValue;
                        } else if (currentDisplayDigit == 3) {
                            displayDigit3 = newValue;
                        } else if (currentDisplayDigit == 4) {
                            displayDigit4 = newValue;
                        }
                    }
                }
            }
            readingSM = 0;
        }
    } else {
        checkScratchDisconnection();
    }
}

void reset() {
    // With xbee module, we need to simulate the setup execution that occurs when a usb connection is opened or
    // closed without this module
    resetPins();        // reset pins
    sendSensorValues(); // protocol handshaking
    lastDataReceivedTime = millis();
    quadDisplay.displayClear();
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
        pulse(pinNumber, (angle * 10) + 600);
    }
}

void pulse(byte pinNumber, unsigned int pulseWidth) {
    digitalWrite(pinNumber, HIGH);
    delayMicroseconds(pulseWidth);
    digitalWrite(pinNumber, LOW);
}

void checkScratchDisconnection() {
    // The reset is necessary when using a wireless arduino board (because we need to ensure that arduino isn't waiting the actuators state
    // from Scratch) or when scratch isn't sending information (because it is how serial port close is detected)
    if (millis() - lastDataReceivedTime > 1000) {
        reset(); //reset state if actuators reception timeout = one second
    }
}
