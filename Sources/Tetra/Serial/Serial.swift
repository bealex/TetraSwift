//
// Serial
// TetraCode
//
// Created by Alex Babaev on 21 November 2019.
// Copyright (c) 2019 LonelyBytes. All rights reserved.
//

import Foundation

enum BaudRate {
    case baud0
    case baud50
    case baud75
    case baud110
    case baud134
    case baud150
    case baud200
    case baud300
    case baud600
    case baud1200
    case baud1800
    case baud2400
    case baud4800
    case baud9600
    case baud19200
    case baud38400
    case baud57600
    case baud115200
    case baud230400

    var speedValue: speed_t {
        switch self {
            case .baud0: return speed_t(B0)
            case .baud50: return speed_t(B50)
            case .baud75: return speed_t(B75)
            case .baud110: return speed_t(B110)
            case .baud134: return speed_t(B134)
            case .baud150: return speed_t(B150)
            case .baud200: return speed_t(B200)
            case .baud300: return speed_t(B300)
            case .baud600: return speed_t(B600)
            case .baud1200: return speed_t(B1200)
            case .baud1800: return speed_t(B1800)
            case .baud2400: return speed_t(B2400)
            case .baud4800: return speed_t(B4800)
            case .baud9600: return speed_t(B9600)
            case .baud19200: return speed_t(B19200)
            case .baud38400: return speed_t(B38400)
            case .baud57600: return speed_t(B57600)
            case .baud115200: return speed_t(B115200)
            case .baud230400: return speed_t(B230400)
        }
    }
}

enum DataBitsSize {
    case bits5
    case bits6
    case bits7
    case bits8

    var flagValue: tcflag_t {
        switch self {
            case .bits5: return tcflag_t(CS5)
            case .bits6: return tcflag_t(CS6)
            case .bits7: return tcflag_t(CS7)
            case .bits8: return tcflag_t(CS8)
        }
    }
}

enum ParityType {
    case none
    case even
    case odd

    var parityValue: tcflag_t {
        switch self {
            case .none: return 0
            case .even: return tcflag_t(PARENB)
            case .odd: return tcflag_t(PARENB | PARODD)
        }
    }
}

enum PortError: Int32, Error {
    case failedToOpen = -1 // refer to open()
    case invalidPath
    case mustReceiveOrTransmit
    case mustBeOpen
    case stringsMustBeUTF8
    case unableToConvertByteToCharacter
    case deviceNotConnected
}

protocol SerialPort {
    var isOpened: Bool { get }

    func openPort(toReceive receive: Bool, andTransmit transmit: Bool) throws
    func setSettings(receiveRate: BaudRate,
        transmitRate: BaudRate,
        minimumBytesToRead: Int,
        timeout: Int,
        parityType: ParityType,
        sendTwoStopBits: Bool,
        dataBitsSize: DataBitsSize,
        useHardwareFlowControl: Bool,
        useSoftwareFlowControl: Bool,
        processOutput: Bool
    )
    func closePort()
    func readBytes(into buffer: UnsafeMutablePointer<UInt8>, size: Int) throws -> Int
    func writeBytes(from buffer: UnsafePointer<UInt8>, size: Int) throws -> Int
}

extension SerialPort {
    func openPort() throws {
        try openPort(toReceive: true, andTransmit: true)
    }

    func setSettings(receiveRate: BaudRate,
        transmitRate: BaudRate,
        minimumBytesToRead: Int,
        timeout: Int = 0, /* 0 means wait indefinitely */
        parityType: ParityType = .none,
        sendTwoStopBits: Bool = false, /* 1 stop bit is the default */
        dataBitsSize: DataBitsSize = .bits8,
        useHardwareFlowControl: Bool = false,
        useSoftwareFlowControl: Bool = false,
        processOutput: Bool = false
    ) {
        setSettings(
            receiveRate: receiveRate,
            transmitRate: transmitRate,
            minimumBytesToRead: minimumBytesToRead,
            timeout: timeout,
            parityType: parityType,
            sendTwoStopBits: sendTwoStopBits,
            dataBitsSize: dataBitsSize,
            useHardwareFlowControl: useHardwareFlowControl,
            useSoftwareFlowControl: useSoftwareFlowControl,
            processOutput: processOutput
        )
    }

}

class HardwareSerialPort: SerialPort {
    var path: String
    var fileDescriptor: Int32?

    var isOpened: Bool { fileDescriptor ?? 0 > 0 }

    init(path: String) {
        self.path = path
    }

    func openPort(toReceive receive: Bool, andTransmit transmit: Bool) throws {
        guard !path.isEmpty else { throw PortError.invalidPath }
        guard receive || transmit else { throw PortError.mustReceiveOrTransmit }

        var readWriteParam: Int32
        switch (receive, transmit) {
            case (true, true):   readWriteParam = O_RDWR
            case (true, false):  readWriteParam = O_RDONLY
            case (false, true):  readWriteParam = O_WRONLY
            case (false, false): fatalError()
        }

        fileDescriptor = open(path, readWriteParam | O_NOCTTY | O_EXLOCK | O_NONBLOCK)

        // Throw error if open() failed
        if fileDescriptor == PortError.failedToOpen.rawValue {
            print("Error opening port, errno: \(errno)")
            throw PortError.failedToOpen
        }
    }

    func setSettings(receiveRate: BaudRate,
        transmitRate: BaudRate,
        minimumBytesToRead: Int,
        timeout: Int = 0, /* 0 means wait indefinitely */
        parityType: ParityType = .none,
        sendTwoStopBits: Bool = false, /* 1 stop bit is the default */
        dataBitsSize: DataBitsSize = .bits8,
        useHardwareFlowControl: Bool = false,
        useSoftwareFlowControl: Bool = false,
        processOutput: Bool = false
    ) {
        guard let fileDescriptor = fileDescriptor else { return }

        // Set up the control structure
        var settings = termios()

        // Get options structure for the port
        tcgetattr(fileDescriptor, &settings)

        // Set baud rates
        cfsetispeed(&settings, receiveRate.speedValue)
        cfsetospeed(&settings, transmitRate.speedValue)

        // Enable parity (even/odd) if needed
        settings.c_cflag |= parityType.parityValue

        // Set stop bit flag
        if sendTwoStopBits {
            settings.c_cflag |= tcflag_t(CSTOPB)
        } else {
            settings.c_cflag &= ~tcflag_t(CSTOPB)
        }

        // Set data bits size flag
        settings.c_cflag &= ~tcflag_t(CSIZE)
        settings.c_cflag |= dataBitsSize.flagValue

        // Set hardware flow control flag
        if useHardwareFlowControl {
            settings.c_cflag |= tcflag_t(CRTS_IFLOW)
            settings.c_cflag |= tcflag_t(CCTS_OFLOW)
        } else {
            settings.c_cflag &= ~tcflag_t(CRTS_IFLOW)
            settings.c_cflag &= ~tcflag_t(CCTS_OFLOW)
        }

        // Set software flow control flags
        let softwareFlowControlFlags = tcflag_t(IXON | IXOFF | IXANY)
        if useSoftwareFlowControl {
            settings.c_iflag |= softwareFlowControlFlags
        } else {
            settings.c_iflag &= ~softwareFlowControlFlags
        }

        // Turn on the receiver of the serial port, and ignore modem control lines
        settings.c_cflag |= tcflag_t(CREAD | CLOCAL)

        // Turn off canonical mode
        settings.c_lflag &= ~tcflag_t(ICANON | ECHO | ECHOE | ISIG)

        // Set output processing flag
        if processOutput {
            settings.c_oflag |= tcflag_t(OPOST)
        } else {
            settings.c_oflag &= ~tcflag_t(OPOST)
        }

        // Special characters
        // We do this as c_cc is a C-fixed array which is imported as a tuple in Swift.
        // To avoid hard coding the VMIN or VTIME value to access the tuple value, we use the typealias instead
        typealias SpecialCharactersTuple = (
            VEOF: cc_t, VEOL: cc_t, VEOL2: cc_t, VERASE: cc_t, VWERASE: cc_t, VKILL: cc_t, VREPRINT: cc_t,
            spare1: cc_t, VINTR: cc_t, VQUIT: cc_t, VSUSP: cc_t, VDSUSP: cc_t, VSTART: cc_t, VSTOP: cc_t, VLNEXT: cc_t, VDISCARD: cc_t,
            VMIN: cc_t, VTIME: cc_t, VSTATUS: cc_t, spare: cc_t
        )
        var specialCharacters: SpecialCharactersTuple = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0) // NCCS = 20

        specialCharacters.VMIN = cc_t(minimumBytesToRead)
        specialCharacters.VTIME = cc_t(timeout)
        settings.c_cc = specialCharacters

        // Commit settings
        tcsetattr(fileDescriptor, TCSANOW, &settings)
    }

    func closePort() {
        if let fileDescriptor = fileDescriptor {
            close(fileDescriptor)
        }
        fileDescriptor = nil
    }

    func readBytes(into buffer: UnsafeMutablePointer<UInt8>, size: Int) throws -> Int {
        guard let fileDescriptor = fileDescriptor else { throw PortError.mustBeOpen }

        var statistics: stat = stat()
        fstat(fileDescriptor, &statistics)
        if statistics.st_nlink != 1 {
            throw PortError.deviceNotConnected
        }

        return read(fileDescriptor, buffer, size)
    }

    func writeBytes(from buffer: UnsafePointer<UInt8>, size: Int) throws -> Int {
        guard let fileDescriptor = fileDescriptor else { throw PortError.mustBeOpen }

        return write(fileDescriptor, buffer, size)
    }
}
