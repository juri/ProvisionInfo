import Foundation
import Security

/// `Certificate` represents the information parsed from certificate information
/// embedded in a provisioning profile in the `DeveloperCertificates` field (available
/// in ``Profile/developerCertificates``).
public struct Certificate: Codable {
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
    /// Initialize a `Certificate` with the data of a `DeveloperCertificates` array entry.
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
