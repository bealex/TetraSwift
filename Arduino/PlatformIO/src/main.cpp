#include "Arduino.h"
#include "TroykaMeteoSensor.h"
#include "TroykaOLED.h"

TroykaMeteoSensor meteoSensor;
TroykaOLED oled(0x3C);

void setupMeteoSensor() {
    meteoSensor.begin();
    meteoSensor.heaterOff();
}

void setup() {
    Serial.begin(115200);
    while(!Serial) {}

    setupMeteoSensor();

    oled.begin();
    oled.setBrightness(0.1);
}

void loop() {
    int stateSensor = meteoSensor.read();
    switch (stateSensor) {
        case SHT_OK: {
            float temperature = meteoSensor.getTemperatureC();
            float humidity = meteoSensor.getHumidity();
            char firstLine[20];
            char secondLine[20];

            sprintf(firstLine, "%.2f%cC", temperature, 248);
            sprintf(secondLine, "%.2f%%", humidity);

            oled.clearDisplay();
            oled.setFont(font12x10);
            oled.print(firstLine, 10, 10);
            oled.print(secondLine, 10, 30);
            break;
        }
        case SHT_ERROR_DATA:
            break;
        case SHT_ERROR_CHECKSUM:
            break;
    }
    delay(5000);
}
