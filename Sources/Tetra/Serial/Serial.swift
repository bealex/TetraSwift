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

enum PortError: Error {
    case failedToOpen
    case invalidPath
    case mustReceiveOrTransmit
    case mustBeOpen
    case deviceNotConnected
}

protocol SerialPort {
    var isOpened: Bool { get }

    func openPort(toReceive receive: Bool, andTransmit transmit: Bool) throws
    func closePort()
    func readBytes(into buffer: UnsafeMutablePointer<UInt8>, size: Int) throws -> Int
    func writeBytes(from buffer: UnsafePointer<UInt8>, size: Int) throws -> Int
}

extension SerialPort {
    func openPort() throws {
        try openPort(toReceive: true, andTransmit: true)
    }
}

class HardwareSerialPort: SerialPort {
    private var path: String

    private var receiveRate: BaudRate
    private var transmitRate: BaudRate
    private var minimumBytesToRead: Int
    private var timeout: Int
    private var parityType: ParityType
    private var sendTwoStopBits: Bool
    private var dataBitsSize: DataBitsSize
    private var useHardwareFlowControl: Bool
    private var useSoftwareFlowControl: Bool
    private var processOutput: Bool

    private var fileDescriptor: Int32?
    var isOpened: Bool { fileDescriptor ?? 0 > 0 }

    init(
        path: String,
        receiveRate: BaudRate,
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
        self.path = path
        self.receiveRate = receiveRate
        self.transmitRate = transmitRate
        self.minimumBytesToRead = minimumBytesToRead
        self.timeout = timeout
        self.parityType = parityType
        self.sendTwoStopBits = sendTwoStopBits
        self.dataBitsSize = dataBitsSize
        self.useHardwareFlowControl = useHardwareFlowControl
        self.useSoftwareFlowControl = useSoftwareFlowControl
        self.processOutput = processOutput
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

        #if os(Linux)
        fileDescriptor = open(path, readWriteParam | O_NOCTTY)
        #else
        fileDescriptor = open(path, readWriteParam | O_NOCTTY | O_EXLOCK | O_NONBLOCK)
        #endif

        // Throw error if open() failed
        if fileDescriptor == -1 {
            print("Error opening port, errno: \(errno)")
            throw PortError.failedToOpen
        }

        updatePortSettings()
    }

    private func updatePortSettings() {
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

        #if os(Linux)
        if useHardwareFlowControl {
            settings.c_cflag |= tcflag_t(CRTSCTS)
        } else {
            settings.c_cflag &= ~tcflag_t(CRTSCTS)
        }
        #else
        if useHardwareFlowControl {
            settings.c_cflag |= tcflag_t(CRTS_IFLOW)
            settings.c_cflag |= tcflag_t(CCTS_OFLOW)
        } else {
            settings.c_cflag &= ~tcflag_t(CRTS_IFLOW)
            settings.c_cflag &= ~tcflag_t(CCTS_OFLOW)
        }
        #endif

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
        #if os(Linux)
        typealias SpecialCharactersTuple = (
            VINTR: cc_t, VQUIT: cc_t, VERASE: cc_t, VKILL: cc_t, VEOF: cc_t, VTIME: cc_t, VMIN: cc_t,
            VSWTC: cc_t, VSTART: cc_t, VSTOP: cc_t, VSUSP: cc_t, VEOL: cc_t, VREPRINT: cc_t, VDISCARD: cc_t, VWERASE: cc_t,
            VLNEXT: cc_t, VEOL2: cc_t, spare1: cc_t, spare2: cc_t, spare3: cc_t, spare4: cc_t, spare5: cc_t, spare6: cc_t,
            spare7: cc_t, spare8: cc_t, spare9: cc_t, spare10: cc_t, spare11: cc_t, spare12: cc_t, spare13: cc_t,
            spare14: cc_t, spare15: cc_t
        )
        var specialCharacters: SpecialCharactersTuple = (
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        ) // NCCS = 32
        #else
        typealias SpecialCharactersTuple = (
            VEOF: cc_t, VEOL: cc_t, VEOL2: cc_t, VERASE: cc_t, VWERASE: cc_t, VKILL: cc_t, VREPRINT: cc_t,
            spare1: cc_t, VINTR: cc_t, VQUIT: cc_t, VSUSP: cc_t, VDSUSP: cc_t, VSTART: cc_t, VSTOP: cc_t, VLNEXT: cc_t, VDISCARD: cc_t,
            VMIN: cc_t, VTIME: cc_t, VSTATUS: cc_t, spare: cc_t
        )
        var specialCharacters: SpecialCharactersTuple = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0) // NCCS = 20
        #endif

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
