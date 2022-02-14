import ArgumentParser
import Foundation
import ProvisionInfoKit

@main
struct ProvisionInfo: ParsableCommand {
    @Option(name: .shortAndLong, help: "Output format")
    var format: Format = .text

    @Argument(help: "Provisioning profile file")
    var file: String

    public func run() throws {
        let path = URL(fileURLWithPath: self.file, isDirectory: false)
        let data = try Data(contentsOf: path)
        let rawProfile = try RawProfile(data: data)
        let profile = Profile(raw: rawProfile)
        let certificates = try profile.developerCertificates.map(Certificate.init(data:))

        switch self.format {
        case .text:
            print(stringify(profile: profile, certificates: certificates))
        case .json:
            let enc = JSONEncoder()
            enc.dataEncodingStrategy = .base64
            enc.dateEncodingStrategy = .iso8601
            enc.keyEncodingStrategy = .convertToSnakeCase

            struct OutputCertificate: Encodable {
                public var fingerprintSHA1: String?
                public var fingerprintSHA256: String?
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

            struct OutputWrapper: Encodable {
                var profile: Profile
                var certificates: [OutputCertificate]
            }

            let outputCerts = certificates.map {
                OutputCertificate(
                    fingerprintSHA1: $0.fingerprintSHA1.map(hexifyData(_:)),
                    fingerprintSHA256: $0.fingerprintSHA256.map(hexifyData(_:)),
                    issuer: $0.issuer,
                    keyID: $0.keyID,
                    notValidAfter: $0.notValidAfter,
                    notValidBefore: $0.notValidBefore,
                    organizationName: $0.organizationName,
                    organizationalUnitName: $0.organizationalUnitName,
                    subjectName: $0.subjectName,
                    summary: $0.summary,
                    x509Serial: $0.x509Serial
                )
            }

            let outputWrapper = OutputWrapper(profile: profile, certificates: outputCerts)
            let data = try enc.encode(outputWrapper)
            guard let str = String(data: data, encoding: .utf8) else {
                fatalError("Failed to convert output to string")
            }
            print(str)
        }
    }
}

public enum Format: String, ExpressibleByArgument {
    case json
    case text
}

private func stringify(profile: Profile, certificates: [Certificate]) -> String {
    var output = FieldsBuilder(fieldWidth: 20)

    if let name = profile.name { output.add(field: "Name", value: name) }
    if let expirationDate = profile.expirationDate { output.add(field: "Expiration date", value: expirationDate) }
    for (number, teamID) in zip(1..., profile.teamID) {
        output.add(field: "Team identifier #\(number)", value: teamID)
    }
    if let teamName = profile.teamName { output.add(field: "Team name", value: teamName) }
    if let uuid = profile.uuid { output.add(field: "UUID", value: uuid) }

    if !profile.provisionedDevices.isEmpty {
        output.addHeading(value: "Devices")
        for device in profile.provisionedDevices {
            output.addValue(device.value)
        }
    }

    for (number, certificate) in zip(1..., certificates) {
        output.addHeading(value: "Certificate #\(number)")
        output.addValue(stringify(cert: certificate))
    }

    return output.joined()
}


private func stringify(cert: Certificate) -> String {
    var output = FieldsBuilder(fieldWidth: 26)

    if let issuer = cert.issuer { output.add(field: "Issuer", value: issuer) }
    if let notValidBefore = cert.notValidBefore { output.add(field: "Not valid before", value: notValidBefore) }
    if let notValidAfter = cert.notValidAfter { output.add(field: "Not valid after", value: notValidAfter) }
    if let keyID = cert.keyID { output.add(field: "Key identifier", value: keyID) }
    if let organizationName = cert.organizationName { output.add(field: "Organization name", value: organizationName) }
    if let unit = cert.organizationalUnitName { output.add(field: "Organizational unit name", value: unit) }
    if let subject = cert.subjectName { output.add(field: "Subject", value: subject) }
    if let serial = cert.x509Serial { output.add(field: "Serial", value: serial) }
    if let fingerprint = cert.fingerprintSHA1 { output.add(field: "Fingerprint SHA-1", value: fingerprint) }
    if let fingerprint = cert.fingerprintSHA256 { output.add(field: "Fingerprint SHA-256", value: fingerprint) }

    return output.joined()
}

private struct FieldsBuilder {
    var fieldWidth = 10
    var output = [String]()

    func padField(_ s: String) -> String { return s.padding(toLength: self.fieldWidth, withPad: " ", startingAt: 0) }
    mutating func addField(_ f: String) { self.output.append(padField("\(f):")) }
    mutating func addValue(_ v: String) {
        self.output.append(v)
        self.output.append("\n")
    }
    mutating func add(field: String, value: String) {
        addField(field)
        addValue(value)
    }
    mutating func add(field: String, value: Date) { add(field: field, value: value.formatted(dateFormat)) }
    mutating func add(field: String, value: Data) { add(field: field, value: hexifyData(value)) }
    mutating func add(field: String, value: UUID) { add(field: field, value: value.uuidString) }

    mutating func addHeading(value: String) {
        output.append("\n==== \(value)\n\n")
    }

    func joined() -> String {
        self.output.joined()
    }
}

private let dateFormat = Date.FormatStyle.dateTime.year().month().day().hour().minute()
