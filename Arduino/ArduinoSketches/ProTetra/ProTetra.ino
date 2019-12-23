#include <pb_common.h>
#include <pb.h>
#include <pb_encode.h>
#include <pb_decode.h>

#include <Wire.h>
#include <TroykaLedMatrix.h>
#include <QuadDisplay2.h>

typedef enum {
    input, servomotor, pwm, digital, quaddisplay, ledmatrix
} pinType;

typedef struct pin {
    pinType type;    //Type of pin
    int state;       //State of an output
};

pin arduinoPins[14]; //Array of struct holding 0-13 pins information
unsigned long lastDataReceivedTime = millis();

QuadDisplay quadDisplay(8);
TroykaLedMatrix ledMatrix;

// 0 — waiting for handshake, 1 - send/receive
int state = 0;

void setup() {
    Serial.begin(115200);
    Serial.flush();
    configurePins();
    resetPins();
}

void loop() {
    static unsigned long timerCheckUpdate = millis();

    if (millis() - timerCheckUpdate >= 10) {
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
    arduinoPins[7].type = ledmatrix; // servomotor
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

    ledMatrix.begin();
    ledMatrix.clear();
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

    ArduinoCommand command = ArduinoCommand_init_zero;
    command.which_data = ArduinoCommand_sensors_tag;

    // send analog sensor values
    for (sensorIndex = 0; sensorIndex < 6; sensorIndex++) {
        Serial.write((byte) ((sensorValues[sensorIndex] >> 8) & B00000011));
        Serial.write((byte) (sensorValues[sensorIndex] & B11111111));
    }
    // send digital sensor values
    Serial.write(digital6);
    Serial.write(digital7);

    command.data.sensors = sensors;
    // TODO: Send
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
    Serial.begin(115200);
    Serial.flush();
    resetPins();

    for (int i = 0; i < 10; i++) {
        digitalWrite(13, HIGH);
        delay(50);
        digitalWrite(13, LOW);
        delay(50);
    }
}

void processByteFromSerialPort() {
    static byte buffer[300 + 3]; // we have not a lot of memory :(
    static int position = 0;

    if (Serial.available()) {
        buffer[position] = Serial.read();
        position += 1;

        // length (1 byte) — [data] — checksum (1 byte) — 0 (1 byte)
        if (position != 0 && buffer[0] != 0 && position == buffer[0] + 3) {
            if (checksum(buffer + 1, position - 3) == buffer[position - 2] && buffer[position - 1] == 0) {
                processPacket(buffer + 1, position - 2);
            }
            position = 0;
        }
        // TODO: Check, if size is more than 300, skip these packet.
    } else if (!Serial) {
        resetPins();
        sendSensorValues();
        position = 0;
        lastDataReceivedTime = millis();
    }
}

byte checksum(byte *array, int size) {
    byte crc = 0xff;
    for (int i = 0; i < size; i++) {
        crc ^= array[i];
    }
    return crc;
}

void processPacket(byte *buffer, int size) {
    if (size >= 0) {
        ClientCommand command = ClientCommand_init_zero;
        pb_istream_t stream = pb_istream_from_buffer(buffer, size);
        bool ok = pb_decode(&stream, ClientCommand_fields, &message);
        if (ok) {
            if (command.which_data == ClientCommand_handshake_tag) {
                // TODO: reply on handshake
            } else if (command.which_data == ClientCommand_actuator_tag) {
                int32_t port = (byte) (command.data.actuator.port & 0xFF);

                // actuator command
                if (command.data.actuator.which_data == ClientCommand_Actuator_integer_tag) {
                    int32_t parameter = command.data.actuator.data.integer.parameter; // is not used for now
                    int32_t value = command.data.actuator.data.integer.value;

                    if (arduinoPins[port] == digital) {
                        if (value == 0) {
                            value = 0;
                        } else {
                            value = 1023;
                        }
                        updatePin(port, value);
                    } else if (arduinoPins[port] == ledmatrix) {
                        if (parameter == 1) { // brightness
                            ledMatrix.setCurrentLimit((byte) (value & 0xFF));
                        }
                    } else if (arduinoPins[port] != input) {
                        updatePin(port, value);
                    }
                } else if (command.data.actuator.which_data == ClientCommand_Actuator_string_tag) {
                    int32_t parameter = command.data.actuator.data.string.parameter; // is not used for now
                    pb_callback_t value = command.data.actuator.data.string.value;

                    // TODO: Process
                } else if (command.data.actuator.which_data == ClientCommand_Actuator_character_tag) {
                    int32_t parameter = command.data.actuator.data.character.parameter; // is not used for now
                    int32_t value = command.data.actuator.data.character.value;

                    if (arduinoPins[port] == ledmatrix) {
                        ledMatrix.setCurrentLimit((byte)(value & 0xFF));
                    }
                } else if (command.data.actuator.which_data == ArduinoCommand_Sensors_Sensor_bytes_tag) {
                    int32_t parameter = command.data.actuator.data.bytes.parameter; // is not used for now
                    byte *value = command.data.actuator.data.bytes.value;
                    int size = command.data.actuator.data.bytes.size;

                    if (arduinoPins[port] == ledmatrix, size == 8) {
                        ledMatrix.drawBitmap(value + 3, false, 8);
                    } else if (arduinoPins[port] == quaddisplay, size == 4) {
                        quadDisplay.displayDigits(value[0], value[1], value[2], value[3]);
                    }
                }
            }
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
