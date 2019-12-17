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

    let redAnalogLED = AnalogLED()
    let greenAnalogLED = AnalogLED()

    let redDigitalLED = DigitalLED()
    let yellowDigitalLED = DigitalLED()
    let yellowDigitalOtherLED = DigitalLED()
    let greenDigitalLED = DigitalLED()

    init(serialPort: String) {
        super.init(pathToSerialPort: serialPort, useTetraProtocol: true)
        add(sensor: lightSensor, on: .analog0)
        add(sensor: potentiometer, on: .analog1)
        add(sensor: magneticSensor, on: .analog2)
        add(sensor: temperatureSensor, on: .analog3)
        add(sensor: infraredSensor, on: .analog4)
        add(sensor: button2, on: .digital6)
        add(sensor: button3, on: .digital7)
        install(actuators: [
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
        ])
    }
}
