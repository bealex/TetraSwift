//
// SerialPort
// TetraSwift
//
// Created by Alex Babaev on 17 December 2019.
//

import Foundation

/// This is simplified implementation, with parameters that are required for the Tetra.
public class SerialPort: DevicePort {
    public enum Errors: Error {
        case invalidPath
        case failedToOpen
        case mustBeOpen
        case deviceNotConnected
        case noData
    }

    public enum Rate {
        case baud1200
        case baud2400
        case baud4800
        case baud9600
        case baud19200
        case baud38400
        case baud57600
        case baud115200
        case baud230400

        func apply(to settings: inout termios) {
            let rate: speed_t
            switch self {
                case .baud1200: rate = speed_t(B1200)
                case .baud2400: rate = speed_t(B2400)
                case .baud4800: rate = speed_t(B4800)
                case .baud9600: rate = speed_t(B9600)
                case .baud19200: rate = speed_t(B19200)
                case .baud38400: rate = speed_t(B38400)
                case .baud57600: rate = speed_t(B57600)
                case .baud115200: rate = speed_t(B115200)
                case .baud230400: rate = speed_t(B230400)
            }

            cfsetispeed(&settings, rate)
            cfsetospeed(&settings, rate)
        }
    }

    public enum DataSize {
        case bits5
        case bits6
        case bits7
        case bits8

        func apply(to settings: inout termios) {
            let size: tcflag_t
            switch self {
                case .bits5: size = tcflag_t(CS5)
                case .bits6: size = tcflag_t(CS6)
                case .bits7: size = tcflag_t(CS7)
                case .bits8: size = tcflag_t(CS8)
            }

            settings.c_cflag &= ~tcflag_t(CSIZE)
            settings.c_cflag |= size
        }
    }

    public enum Parity {
        case none
        case even
        case odd

        func apply(to settings: inout termios) {
            switch self {
                case .none:
                    break
                case .even:
                    settings.c_cflag |= tcflag_t(PARENB)
                case .odd:
                    settings.c_cflag |= tcflag_t(PARENB | PARODD)
            }
        }
    }

    public enum StopBits {
        case one
        case two

        func apply(to settings: inout termios) {
            switch self {
                case .one:
                    settings.c_cflag &= ~tcflag_t(CSTOPB)
                case .two:
                    settings.c_cflag |= tcflag_t(CSTOPB)
            }
        }
    }

    private var path: String

    private var dataRate: Rate
    private var parity: Parity
    private var stopBits: StopBits
    private var dataSize: DataSize

    private var fileDescriptor: Int32?

    public var isOpened: Bool { fileDescriptor ?? 0 > 0 }

    public init(
        path: String,
        rate: Rate,
        parityType: Parity = .none,
        stopBits: StopBits = .one,
        dataBitsSize: DataSize = .bits8
    ) {
        self.path = path
        self.dataRate = rate
        self.parity = parityType
        self.stopBits = stopBits
        self.dataSize = dataBitsSize
    }

    #if os(Linux)
    private let fileOpenParameters: Int32 = O_RDWR | O_NOCTTY
    #else
    private let fileOpenParameters: Int32 = O_RDWR | O_NOCTTY | O_EXLOCK | O_NONBLOCK
    #endif

    public func open() throws {
        guard !path.isEmpty else { throw DevicePortError.open(Errors.invalidPath) }

        fileDescriptor = Darwin.open(path, fileOpenParameters)
        guard fileDescriptor != -1 else { throw DevicePortError.open(Errors.failedToOpen) }

        setup()
    }

    private func setup() {
        guard let fileDescriptor = fileDescriptor, fileDescriptor != -1 else { return }

        var settings = termios() // Set up the control structure
        tcgetattr(fileDescriptor, &settings) // Get options structure for the port
        dataRate.apply(to: &settings)
        parity.apply(to: &settings)
        stopBits.apply(to: &settings)

        // Disable Hardware flow control
        #if os(Linux)
        settings.c_cflag &= ~tcflag_t(CRTSCTS)
        #else
        settings.c_cflag &= ~tcflag_t(CRTS_IFLOW)
        settings.c_cflag &= ~tcflag_t(CCTS_OFLOW)
        #endif

        settings.c_iflag &= ~tcflag_t(IXON | IXOFF | IXANY) // Disable software flow control flags
        settings.c_cflag |= tcflag_t(CREAD | CLOCAL) // Turn on the receiver of the serial port, and ignore modem control lines
        settings.c_lflag &= ~tcflag_t(ICANON | ECHO | ECHOE | ISIG) // Turn off canonical mode
        settings.c_oflag &= ~tcflag_t(OPOST) // Set output processing flag

        // Special characters (termios.c_cc) all are 0, do not configure them
        // Commit settings
        tcsetattr(fileDescriptor, TCSANOW, &settings)
    }

    public func close() {
        _ = fileDescriptor.map { Darwin.close($0) }
        fileDescriptor = nil
    }

    private var buffer: [UInt8] = []

    public func readBytes(exact count: Int) throws -> [UInt8] {
        var readBuffer: [UInt8] = Array(repeating: 0, count: 32)
        while buffer.count < count {
            let readCount = try readBytes(into: &readBuffer, size: 32)
            buffer.append(contentsOf: readBuffer.prefix(readCount))
        }

        if buffer.count >= count {
            let result = buffer.prefix(count)
            buffer = buffer.suffix(max(0, buffer.count - count))
            return Array(result)
        } else {
            throw DevicePortError.read(Errors.noData)
        }
    }

    public func readBytes(upTo count: Int) throws -> [UInt8] {
        let toRead = count - buffer.count
        if toRead > 0 {
            var readBuffer: [UInt8] = Array(repeating: 0, count: toRead)
            let readCount = try readBytes(into: &readBuffer, size: toRead)
            buffer.append(contentsOf: readBuffer.prefix(readCount))
        }

        let result = buffer.prefix(count)
        buffer = buffer.suffix(max(0, buffer.count - count))
        return Array(result)
    }

    func readBytes(into buffer: UnsafeMutablePointer<UInt8>, size: Int) throws -> Int {
        guard let fileDescriptor = fileDescriptor else {
            throw DevicePortError.read(Errors.mustBeOpen)
        }

        var statistics: stat = stat()
        fstat(fileDescriptor, &statistics)
        if statistics.st_nlink != 1 {
            throw DevicePortError.read(Errors.deviceNotConnected)
        }

        return read(fileDescriptor, buffer, size)
    }

    public func writeBytes(_ data: [UInt8]) throws {
        var bytes = data
        while !bytes.isEmpty {
            let sent = try writeBytes(from: bytes, size: bytes.count)
            bytes = Array(bytes.dropFirst(sent))
        }
    }

    private func writeBytes(from buffer: UnsafePointer<UInt8>, size: Int) throws -> Int {
        guard let fileDescriptor = fileDescriptor else {
            throw DevicePortError.write(Errors.mustBeOpen)
        }

        return write(fileDescriptor, buffer, size)
    }
}
