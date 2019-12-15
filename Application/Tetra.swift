//
// MyTetra
// TetraSwift
//
// Created by Alex Babaev on 15 December 2019.
//

import TetraSwift
import Foundation

class Tetra: TetraInterface {
    let button2 = Button()
    let button3 = Button()

    let lightSensor = LightSensor()
    let magneticSensor = MagneticSensor()
    let temperatureSensor = TemperatureSensor()
    let infraredSensor = InfraredSensor()
    let potentiometer = Potentiometer()

    let motor = Motor()
    let buzzer = Buzzer()
    let quadDisplay = QuadNumericDisplayActuator()
    let ledMatrix = LEDMatrixActuator()

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
                .analog0: lightSensor,
                .analog1: potentiometer,
                .analog2: magneticSensor,
                .analog3: temperatureSensor,
                .analog4: infraredSensor,
                .digital6: button2,
                .digital7: button3,
            ],
            actuators: [
                .digital4: motor,
                .digital9: buzzer,
                .digital5: greenAnalogLED,
                .digital6: redAnalogLED,
                .digital10: greenDigitalLED,
                .digital11: yellowDigitalLED,
                .digital12: yellowDigitalOtherLED,
                .digital13: redDigitalLED,
                .digital7: ledMatrix,
                .digital8: quadDisplay,
            ]
        )
    }
}
