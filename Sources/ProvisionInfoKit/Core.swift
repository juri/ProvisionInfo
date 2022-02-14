import Foundation
import Security

public struct RawProfile {
    public var fields: [String: Any]
}

extension RawProfile {
    public init(data: Data) throws {
        let decoded = try decodeProfile(data: data)
        self.init(fields: decoded)
    }
}

public struct Profile {
    public var derEncodedProfile: Data?
    public var developerCertificates: [Data]
    public var entitlements: [String: String]
    public var expirationDate: Date?
    public var name: String?
    public var platform: String?
    public var provisionedDevices: [DeviceID]
    public var teamID: [String]
    public var teamName: String?
    public var timeToLive: Int?
    public var uuid: UUID?
    public var version: Int?
}

extension Profile {
    public init(raw: RawProfile) {
        let derEncodedProfile = raw.fields["DER-Encoded-Profile"] as? Data
        let developerCertificates = raw.fields["DeveloperCertificates"] as? [Data] ?? []
        let entitlements = raw.fields["Entitlements"] as? [String: String] ?? [:]
        let expirationDate = raw.fields["ExpirationDate"] as? Date
        let name = raw.fields["Name"] as? String
        let platform = raw.fields["Platform"] as? String
        let provisionedDevices = raw.fields["ProvisionedDevices"] as? [String] ?? []
        let teamID = raw.fields["TeamIdentifier"] as? [String] ?? []
        let teamName = raw.fields["TeamName"] as? String
        let timeToLive = raw.fields["TimeToLive"] as? Int
        let uuidString = raw.fields["UUID"] as? String
        let uuid = uuidString.flatMap(UUID.init(uuidString:))
        let version = raw.fields["Version"] as? Int

        self.init(
            derEncodedProfile: derEncodedProfile,
            developerCertificates: developerCertificates,
            entitlements: entitlements,
            expirationDate: expirationDate,
            name: name,
            platform: platform,
            provisionedDevices: provisionedDevices.map(DeviceID.init(_:)),
            teamID: teamID,
            teamName: teamName,
            timeToLive: timeToLive,
            uuid: uuid,
            version: version
        )
    }
}

public struct DeviceID: Equatable {
    public var value: String
}

extension DeviceID {
    public init(_ value: String) {
        self.value = value
    }
}

public struct Certificate {
    public var fingerprintSHA1: Data?
    public var fingerprintSHA256: Data?
    public var issuer: String?
    public var keyID: Data?
    public var notValidAfter: Date?
    public var notValidBefore: Date?
    public var organizationName: String?
    public var organizationalUnitName: String?
    public var subjectName: String?
    public var summary: String
    public var x509Serial: String?
}

extension Certificate {
    public init(data: Data) throws {
        guard let cert = SecCertificateCreateWithData(nil, data as CFData) else {
            throw ProvisionInfoError.certificateReadFailure
        }
        guard let summary = SecCertificateCopySubjectSummary(cert).map({ $0 as String }) else {
            throw ProvisionInfoError.summaryReadFailure
        }
        var error: Unmanaged<CFError>?

        let values = SecCertificateCopyValues(cert, nil, &error)
        guard let dictionary = values as? [CFString: Any] else {
            throw ProvisionInfoError.certificateCopyDataFailure(nil)
        }

        let serialDict = dictionary[kSecOIDX509V1SerialNumber] as? [String: Any]
        let serial = serialDict?["value"] as? String

        let certArrayValue = { topKey, subKey in
            certificateValueArrayValue(values: dictionary, topKey: topKey, subKey: subKey)
        }

        let issuerName = certArrayValue(kSecOIDX509V1IssuerName, kSecOIDCommonName) as? String

        let notValidBeforeDict = dictionary[kSecOIDX509V1ValidityNotBefore] as? [String: Any]
        let notValidBefore = (notValidBeforeDict?["value"] as? TimeInterval).map(Date.init(timeIntervalSinceReferenceDate:))

        let notValidAfterDict = dictionary[kSecOIDX509V1ValidityNotAfter] as? [String: Any]
        let notValidAfter = (notValidAfterDict?["value"] as? TimeInterval).map(Date.init(timeIntervalSinceReferenceDate:))

        let subjectName = certArrayValue(kSecOIDX509V1SubjectName, kSecOIDCommonName) as? String
        let organizationName = certArrayValue(kSecOIDX509V1SubjectName, kSecOIDOrganizationName) as? String
        let organizationalUnitName = certArrayValue(kSecOIDX509V1SubjectName, kSecOIDOrganizationalUnitName) as? String

        let keyID = certArrayValue(kSecOIDAuthorityKeyIdentifier, "Key Identifier" as CFString).flatMap { $0 as? Data }

        let fingerprintSHA256 = certArrayValue("Fingerprints" as CFString, "SHA-256" as CFString).flatMap { $0 as? Data }
        let fingerprintSHA1 = certArrayValue("Fingerprints" as CFString, "SHA-1" as CFString).flatMap { $0 as? Data }

        self.init(
            fingerprintSHA1: fingerprintSHA1,
            fingerprintSHA256: fingerprintSHA256,
            issuer: issuerName,
            keyID: keyID,
            notValidAfter: notValidAfter,
            notValidBefore: notValidBefore,
            organizationName: organizationName,
            organizationalUnitName: organizationalUnitName,
            subjectName: subjectName,
            summary: summary,
            x509Serial: serial
        )
    }
}

public func hexifyData(_ data: Data) -> String {
    data
        .map {
            let hex = String($0, radix: 16, uppercase: true)
            return $0 < 0x10 ? "0\(hex)" : hex
        }
        .joined(separator: " ")
}

private func decodeProfile(data: Data) throws -> [String: Any] {
    var decoder: CMSDecoder?
    var status: OSStatus = errSecSuccess

    status = CMSDecoderCreate(&decoder)
    guard status == errSecSuccess, let decoder = decoder else {
        throw ProvisionInfoError.cmsDecoderCreationFailure(status)
    }

    status = data.withUnsafeBytes { ptr in
        CMSDecoderUpdateMessage(decoder, ptr.baseAddress!, data.count)
    }
    guard status == errSecSuccess else {
        throw ProvisionInfoError.cmsDecoderUpdateFailure(status)
    }

    status = CMSDecoderFinalizeMessage(decoder)
    guard status == errSecSuccess else {
        throw ProvisionInfoError.cmsDecoderFinalizeFailure(status)
    }

    var decodedCFData: CFData?
    status = CMSDecoderCopyContent(decoder, &decodedCFData)
    guard status == errSecSuccess, let decodedCFData = decodedCFData else {
        throw ProvisionInfoError.cmsDecoderCopyFailure(status)
    }

    let decodedData = decodedCFData as Data
    guard let dict = try PropertyListSerialization.propertyList(
        from: decodedData, options: [], format: nil
    ) as? [String: Any] else {
        throw ProvisionInfoError.profileDeserializationFailure
    }

    return dict
}

private func certificateValueArrayValue(values: [CFString: Any], topKey: CFString, subKey: CFString) -> Any? {
    guard let topValue = values[topKey] as? [String: Any] else { return nil }
    guard let valuesArray = topValue["value"] as? [[String: Any]] else { return nil }
    let subValueDict = valuesArray.first(where: {
        if let label = $0["label"] as CFTypeRef?,
           CFGetTypeID(label) == CFStringGetTypeID(),
           label as! CFString == subKey
        {
            return true
        }
        return false
    })
    let subValue = subValueDict?["value"]
    return subValue
}

public enum ProvisionInfoError: Error {
    case certificateReadFailure
    case certificateCopyDataFailure(Error?)
    case cmsDecoderCreationFailure(OSStatus)
    case cmsDecoderCopyFailure(OSStatus)
    case cmsDecoderFinalizeFailure(OSStatus)
    case cmsDecoderUpdateFailure(OSStatus)
    case profileDeserializationFailure
    case summaryReadFailure
}
