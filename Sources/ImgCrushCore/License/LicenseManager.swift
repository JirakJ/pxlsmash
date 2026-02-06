import Foundation
import CommonCrypto

/// License key format: IMGC-XXXX-XXXX-XXXX-XXXX
/// Tiers: personal, team, enterprise
public enum LicenseTier: String, Codable {
    case trial
    case personal
    case team
    case enterprise
}

public struct LicenseInfo: Codable {
    public let key: String
    public let tier: LicenseTier
    public let email: String
    public let activatedAt: Date
    public let expiresAt: Date?

    public var isExpired: Bool {
        if let exp = expiresAt {
            return Date() > exp
        }
        return false
    }
}

public struct TrialInfo: Codable {
    public let startedAt: Date
    public let durationDays: Int

    public var expiresAt: Date {
        Calendar.current.date(byAdding: .day, value: durationDays, to: startedAt) ?? startedAt
    }

    public var isExpired: Bool {
        Date() > expiresAt
    }

    public var daysRemaining: Int {
        let remaining = Calendar.current.dateComponents([.day], from: Date(), to: expiresAt).day ?? 0
        return max(0, remaining)
    }
}

public final class LicenseManager {
    public static let shared = LicenseManager()

    private let fileManager = FileManager.default
    private let licenseFileName = ".imgcrush-license"
    private let trialFileName = ".imgcrush-trial"
    private let keyPrefix = "IMGC"

    private var licensePath: String {
        let home = fileManager.homeDirectoryForCurrentUser.path
        return "\(home)/\(licenseFileName)"
    }

    private var trialPath: String {
        let home = fileManager.homeDirectoryForCurrentUser.path
        return "\(home)/\(trialFileName)"
    }

    private init() {}

    // MARK: - License Key Validation

    /// Validate license key format: IMGC-XXXX-XXXX-XXXX-XXXX
    public func isValidKeyFormat(_ key: String) -> Bool {
        let parts = key.split(separator: "-")
        guard parts.count == 5, parts[0] == keyPrefix else { return false }
        for i in 1...4 {
            guard parts[i].count == 4,
                  parts[i].allSatisfy({ $0.isUppercase || $0.isNumber }) else {
                return false
            }
        }
        // Checksum: last 2 chars of part 5 must match hash of parts 1-4
        let payload = parts[0...3].joined()
        let hash = checksumHash(payload)
        let expected = String(hash.prefix(2)).uppercased()
        let actual = String(parts[4].suffix(2))
        return expected == actual
    }

    /// Generate a license key for a given email and tier
    public static func generateKey(email: String, tier: LicenseTier) -> String {
        let seed = "\(email):\(tier.rawValue):\(Date().timeIntervalSince1970)"
        let hash = sha256(seed)
        let chars = Array(hash.uppercased())

        func segment(_ start: Int) -> String {
            String(chars[start..<start+4])
        }

        let p1 = segment(0)
        let p2 = segment(4)
        let p3 = segment(8)
        let payload = "IMGC\(p1)\(p2)\(p3)"
        let checkHash = checksumHashStatic(payload)
        let checkChars = String(checkHash.prefix(2)).uppercased()
        let p4First2 = String(chars[12..<14])
        let p4 = p4First2 + checkChars

        return "IMGC-\(p1)-\(p2)-\(p3)-\(p4)"
    }

    // MARK: - Activation

    public func activate(key: String, email: String) throws -> LicenseInfo {
        guard isValidKeyFormat(key) else {
            throw ImgCrushError.licenseInvalid(message: "Invalid license key format")
        }

        let tier = tierFromKey(key)
        let info = LicenseInfo(
            key: key,
            tier: tier,
            email: email,
            activatedAt: Date(),
            expiresAt: nil
        )

        let data = try JSONEncoder().encode(info)
        try data.write(to: URL(fileURLWithPath: licensePath))
        return info
    }

    public func deactivate() throws {
        if fileManager.fileExists(atPath: licensePath) {
            try fileManager.removeItem(atPath: licensePath)
        }
    }

    // MARK: - License Check

    public func currentLicense() -> LicenseInfo? {
        guard let data = fileManager.contents(atPath: licensePath) else { return nil }
        return try? JSONDecoder().decode(LicenseInfo.self, from: data)
    }

    public func isLicensed() -> Bool {
        if let license = currentLicense() {
            return !license.isExpired
        }
        return false
    }

    // MARK: - Trial

    public func startTrial() -> TrialInfo {
        if let existing = currentTrial() {
            return existing
        }

        let trial = TrialInfo(startedAt: Date(), durationDays: 14)
        if let data = try? JSONEncoder().encode(trial) {
            try? data.write(to: URL(fileURLWithPath: trialPath))
        }
        return trial
    }

    public func currentTrial() -> TrialInfo? {
        guard let data = fileManager.contents(atPath: trialPath) else { return nil }
        return try? JSONDecoder().decode(TrialInfo.self, from: data)
    }

    public func isTrialActive() -> Bool {
        guard let trial = currentTrial() else { return false }
        return !trial.isExpired
    }

    // MARK: - Access Check

    public enum AccessStatus {
        case licensed(LicenseInfo)
        case trial(TrialInfo)
        case expired
        case none
    }

    public func checkAccess() -> AccessStatus {
        if let license = currentLicense(), !license.isExpired {
            return .licensed(license)
        }
        if let trial = currentTrial() {
            if trial.isExpired {
                return .expired
            }
            return .trial(trial)
        }
        return .none
    }

    public func trialExpirationMessage() -> String {
        """
        ⚠️  Your imgcrush trial has expired.
        
        Purchase a license:
          🌐 https://imgcrush.dev/pricing
          🛒 https://htmeta.gumroad.com
          🧡 https://www.etsy.com/shop/htmeta
        
        Activate with: imgcrush --activate <LICENSE-KEY> --email <EMAIL>
        """
    }

    // MARK: - Helpers

    private func tierFromKey(_ key: String) -> LicenseTier {
        let parts = key.split(separator: "-")
        guard parts.count >= 2 else { return .personal }
        let first = parts[1].first ?? "0"
        switch first {
        case "A"..."F": return .personal
        case "G"..."M": return .team
        case "N"..."Z": return .enterprise
        default: return .personal
        }
    }

    private func checksumHash(_ input: String) -> String {
        LicenseManager.checksumHashStatic(input)
    }

    private static func checksumHashStatic(_ input: String) -> String {
        sha256(input)
    }

    private static func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
