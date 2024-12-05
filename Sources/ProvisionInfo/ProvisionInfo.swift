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
        let profile = try Profile(raw: rawProfile)
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

public enum Format: String, ExpressibleByArgument, Sendable {
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

    if !profile.entitlements.isEmpty {
        output.addHeading(value: "Entitlements")

        var entitlementsLines = [String]()

        func quoteString(_ string: String) -> String {
            let escaped = String(string.flatMap { character in
                switch character {
                case #"\"#: #"\\"#
                case #"""#: #"\\""#
                case "\n": #"\\#n"#
                default: String(character)
                }
            })
            return #""\#(escaped)""#
        }

        func addPlainValue(value: EntitlementValue, level: Int = 0) {
            let indent = String(repeating: "  ", count: level)
            switch value {
            case let .array(array):
                entitlementsLines.append("\(indent)[Array]:")
                for entry in array {
                    addPlainValue(value: entry, level: level + 1)
                }

            case let .boolean(bool):
                entitlementsLines.append("\(indent)\(bool)")

            case let .data(data):
                entitlementsLines.append("\(indent)\(hexifyData(data))")

            case let .date(date):
                entitlementsLines.append("\(indent)\(date)")

            case let .double(double):
                entitlementsLines.append("\(indent)\(double)")

            case let .dictionary(dict):
                entitlementsLines.append("\(indent)[Dictionary]:")
                addDictionary(dict, level: level + 1)

            case let .integer(int):
                entitlementsLines.append("\(indent)\(int)")

            case .null:
                entitlementsLines.append("\(indent)null")

            case let .string(str):
                entitlementsLines.append("\(indent)\(quoteString(str))")
            }
        }

        func addDictionary(_ dict: EntitlementsDictionary, level: Int = 0) {
            let indent = String(repeating: "  ", count: level)
            for (key, value) in dict {
                let keyLabel = "\(indent)\(key)"
                switch value {
                case let .array(array):
                    entitlementsLines.append("\(keyLabel): [Array]:")
                    addArray(array, level: level + 1)

                case let .boolean(bool):
                    entitlementsLines.append("\(keyLabel): \(bool)")

                case let .data(data):
                    entitlementsLines.append("\(keyLabel): Data(\(hexifyData(data)))")

                case let .date(date):
                    entitlementsLines.append("\(keyLabel): \(date)")

                case let .double(double):
                    entitlementsLines.append("\(keyLabel): \(double)")

                case let .dictionary(dict):
                    entitlementsLines.append(keyLabel)
                    addDictionary(dict, level: level + 1)

                case let .integer(int):
                    entitlementsLines.append("\(keyLabel): \(int)")

                case .null:
                    entitlementsLines.append("\(keyLabel): null")

                case let .string(str):
                    entitlementsLines.append("\(keyLabel): \(quoteString(str))")
                }
            }
        }

        func addArray(_ array: [EntitlementValue], level: Int = 0) {
            for value in array {
                addPlainValue(value: value, level: level + 1)
            }
        }

        addDictionary(profile.entitlements)
        output.addFormatted(text: entitlementsLines.joined(separator: "\n") + "\n")
    }

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

    func padField(_ s: String) -> String { s.padding(toLength: self.fieldWidth, withPad: " ", startingAt: 0) }
    mutating func addField(_ f: String) { self.output.append(self.padField("\(f):")) }
    mutating func addValue(_ v: String) {
        self.output.append(v)
        self.output.append("\n")
    }

    mutating func add(field: String, value: String) {
        self.addField(field)
        self.addValue(value)
    }

    mutating func add(field: String, value: Date) { self.add(field: field, value: value.formatted(dateFormat)) }
    mutating func add(field: String, value: Data) { self.add(field: field, value: hexifyData(value)) }
    mutating func add(field: String, value: UUID) { self.add(field: field, value: value.uuidString) }

    mutating func addHeading(value: String) {
        self.output.append("\n==== \(value)\n\n")
    }

    mutating func addFormatted(text: String) {
        self.output.append(text)
    }

    func joined() -> String {
        self.output.joined()
    }
}

private let dateFormat = Date.FormatStyle.dateTime.year().month().day().hour().minute()
