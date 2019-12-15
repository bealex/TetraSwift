//
// MyTetra
// TetraSwift
//
// Created by Alex Babaev on 15 December 2019.
//

import TetraSwift
import Foundation

class MyTetra: Tetra {
    let button2 = Button()
    let button3 = Button()

    let redAnalogLED = AnalogLED(color: .red)
    let greenAnalogLED = AnalogLED(color: .green)

    let redDigitalLED = DigitalLED(color: .red)
    let yellowDigitalLED = DigitalLED(color: .yellow)
    let yellowDigitalOtherLED = DigitalLED(color: .yellow)
    let greenDigitalLED = DigitalLED(color: .green)

    init(serialPort: String) {
        super.init(
            pathToSerialPort: serialPort,
            useTetraProtocol: true,
            sensors: [
                .analog0: LightSensor(),
                .analog1: Potentiometer(),
                .analog2: MagneticSensor(),
                .analog3: TemperatureSensor(),
                .analog4: InfraredSensor(),
                .digital6: button2,
                .digital7: button3,
            ],
            actuators: [
                .digital4: Motor(),
                .digital9: Buzzer(),
                .digital5: greenAnalogLED,
                .digital6: redAnalogLED,
                .digital10: greenDigitalLED,
                .digital11: yellowDigitalLED,
                .digital12: yellowDigitalOtherLED,
                .digital13: redDigitalLED,
                .digital7: LEDMatrixActuator(),
                .digital8: QuadNumericDisplayActuator(),
            ]
        )
    }
}
