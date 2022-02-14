import Foundation
import ProvisionInfoKit

@main
public enum ProvisionInfo {
    public static func main() throws {
        let path = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: false)
        let data = try Data(contentsOf: path)
        let rawProfile = try RawProfile(data: data)
        let profile = Profile(raw: rawProfile)
        let certInfos = try profile.developerCertificates.map(Certificate.init(data:))

        print(stringify(profile: profile, certificates: certInfos))
    }
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
