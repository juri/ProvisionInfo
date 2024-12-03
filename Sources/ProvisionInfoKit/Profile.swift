import Foundation

/// `Profile` contains fields extracted from a `RawProfile`.
public struct Profile: Codable {
    public var creationDate: Date?
    public var derEncodedProfile: Data?
    public var developerCertificates: [Data]
    public var entitlements: [String: String]
    public var expirationDate: Date?
    public var name: String?
    public var platform: [String]
    public var provisionedDevices: [DeviceID]
    public var teamID: [String]
    public var teamName: String?
    public var timeToLive: Int?
    public var uuid: UUID?
    public var version: Int?
}

extension Profile {
    /// Initializes a `Profile` with a `RawProfile`.
    public init(raw: RawProfile) {
        let creationDate = raw.fields["CreationDate"] as? Date
        let derEncodedProfile = raw.fields["DER-Encoded-Profile"] as? Data
        let developerCertificates = raw.fields["DeveloperCertificates"] as? [Data] ?? []
        let entitlements = raw.fields["Entitlements"] as? [String: String] ?? [:]
        let expirationDate = raw.fields["ExpirationDate"] as? Date
        let name = raw.fields["Name"] as? String
        let platform = raw.fields["Platform"] as? [String] ?? []
        let provisionedDevices = raw.fields["ProvisionedDevices"] as? [String] ?? []
        let teamID = raw.fields["TeamIdentifier"] as? [String] ?? []
        let teamName = raw.fields["TeamName"] as? String
        let timeToLive = raw.fields["TimeToLive"] as? Int
        let uuidString = raw.fields["UUID"] as? String
        let uuid = uuidString.flatMap(UUID.init(uuidString:))
        let version = raw.fields["Version"] as? Int

        self.init(
            creationDate: creationDate,
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

/// `DeviceID` wraps a device identifier string.
public struct DeviceID: Equatable {
    public var value: String
}

extension DeviceID {
    public init(_ value: String) {
        self.value = value
    }
}

extension DeviceID: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        try self.init(value: container.decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.value)
    }
}
