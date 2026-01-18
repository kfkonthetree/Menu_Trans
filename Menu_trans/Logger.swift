import Foundation

class Logger {
    
    enum LogLevel: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        case critical = "CRITICAL"
    }
    
    static let shared = Logger()
    private let dateFormatter = DateFormatter()
    
    private init() {
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    }
    
    // 记录日志
    func log(_ message: String, level: LogLevel = .debug, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let timestamp = dateFormatter.string(from: Date())
        let logMessage = "[\(timestamp)] [\(level.rawValue)] [\(fileName):\(line) \(function)] \(message)"
        
        // 打印到控制台
        print(logMessage)
        
        // 在生产环境中，可以将日志保存到文件或发送到服务器
        #if !DEBUG
        // 可以在这里添加日志持久化或远程日志功能
        #endif
    }
    
    // 便捷方法
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    func error(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        var logMessage = message
        if let error = error {
            logMessage += ": \(error.localizedDescription)"
            // 可以在这里添加错误堆栈信息
            logMessage += "\nStack trace: \(Thread.callStackSymbols.joined(separator: "\n"))"
        }
        log(logMessage, level: .error, file: file, function: function, line: line)
    }
    
    func critical(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        var logMessage = message
        if let error = error {
            logMessage += ": \(error.localizedDescription)"
            // 可以在这里添加错误堆栈信息
            logMessage += "\nStack trace: \(Thread.callStackSymbols.joined(separator: "\n"))"
        }
        log(logMessage, level: .critical, file: file, function: function, line: line)
    }
}
