//    import Foundation
//
//    let path = "/dev/tty.usbmodem14801"
//    var fileDescriptor: Int32?
//
//    func lsDev() {
//        let fileManager = FileManager.default
//        let documentsURL = FileManager.default.urls(for: .applicationDirectory, in: .userDomainMask)[0]
//        do {
//            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
//            fileURLs.forEach {
//                print("\($0)")
//            }
//        } catch {
//            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
//        }
//    }
//
//    func openPort() {
//        fileDescriptor = open(path, O_RDWR | O_NOCTTY | O_EXLOCK | O_NONBLOCK)
//        if fileDescriptor == -1 {
//            print("Bad file descriptor")
//        }
//    }
//
//    func setSettings() {
//        guard let fileDescriptor = fileDescriptor else { return }
//
//        var settings = termios()
//
//        tcgetattr(fileDescriptor, &settings)
//
//        cfsetispeed(&settings, UInt(B38400))
//        cfsetospeed(&settings, UInt(B38400))
//        settings.c_cflag &= ~tcflag_t(CSTOPB)
//        settings.c_cflag &= ~tcflag_t(CSIZE)
//        settings.c_cflag |= tcflag_t(CS8)
//        settings.c_cflag &= ~tcflag_t(CRTS_IFLOW)
//        settings.c_cflag &= ~tcflag_t(CCTS_OFLOW)
//        let softwareFlowControlFlags = tcflag_t(IXON | IXOFF | IXANY)
//        settings.c_iflag &= ~softwareFlowControlFlags
//        settings.c_cflag |= tcflag_t(CREAD | CLOCAL)
//        settings.c_lflag &= ~tcflag_t(ICANON | ECHO | ECHOE | ISIG)
//        settings.c_oflag &= ~tcflag_t(OPOST)
//
//        typealias SpecialCharactersTuple = (
//            VEOF: cc_t, VEOL: cc_t, VEOL2: cc_t, VERASE: cc_t, VWERASE: cc_t, VKILL: cc_t, VREPRINT: cc_t,
//            spare1: cc_t, VINTR: cc_t, VQUIT: cc_t, VSUSP: cc_t, VDSUSP: cc_t, VSTART: cc_t, VSTOP: cc_t, VLNEXT: cc_t, VDISCARD: cc_t,
//            VMIN: cc_t, VTIME: cc_t, VSTATUS: cc_t, spare: cc_t
//        )
//        var specialCharacters: SpecialCharactersTuple = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0) // NCCS = 20
//
//        specialCharacters.VMIN = cc_t(0)
//        specialCharacters.VTIME = cc_t(0)
//        settings.c_cc = specialCharacters
//
//        tcsetattr(fileDescriptor, TCSANOW, &settings)
//    }
//
//    lsDev()
//    openPort()
//    setSettings()
