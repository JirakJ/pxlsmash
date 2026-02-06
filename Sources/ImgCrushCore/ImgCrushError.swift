import Foundation

/// Errors thrown by imgcrush with associated exit codes.
public enum ImgCrushError: Error, CustomStringConvertible {
    /// General processing error.
    case generalError(String)
    /// Invalid input (file not found, unsupported format).
    case invalidInput(String)
    /// Permission denied.
    case permissionDenied(String)
    /// Disk full or write failure.
    case diskFull(String)
    /// License invalid or expired.
    case licenseInvalid(message: String)

    /// Human-readable error message.
    public var message: String {
        switch self {
        case .generalError(let msg): return msg
        case .invalidInput(let msg): return msg
        case .permissionDenied(let msg): return msg
        case .diskFull(let msg): return msg
        case .licenseInvalid(let msg): return msg
        }
    }

    /// Process exit code.
    public var exitCode: Int32 {
        switch self {
        case .generalError: return 1
        case .invalidInput: return 2
        case .permissionDenied: return 3
        case .diskFull: return 1
        case .licenseInvalid: return 4
        }
    }

    public var description: String { message }
}
