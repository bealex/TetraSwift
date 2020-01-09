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

    // Some comment
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

    init(pathToSerialPort: String) {
        let serialPort = SerialPort(path: pathToSerialPort, rate: .baud115200)
        super.init(serialPort: serialPort, useTetraProtocol: true)
        add(sensor: lightSensor, on: .analog0)
        add(sensor: potentiometer, on: .analog1)
        add(sensor: magneticSensor, on: .analog2)
        add(sensor: temperatureSensor, on: .analog3)
        add(sensor: infraredSensor, on: .analog4)
        add(sensor: button2, on: .digital6)
        add(sensor: button3, on: .digital7)

        add(actuator: motor, on: .digital4)
        add(actuator: buzzer, on: .digital9)
        add(actuator: greenAnalogLED, on: .digital5)
        add(actuator: redAnalogLED, on: .digital6)
        add(actuator: greenDigitalLED, on: .digital10)
        add(actuator: yellowDigitalLED, on: .digital11)
        add(actuator: yellowDigitalOtherLED, on: .digital12)
        add(actuator: redDigitalLED, on: .digital13)
        add(actuator: ledMatrix, on: .digital7)
        add(actuator: quadDisplay, on: .digital8)
    }
}
