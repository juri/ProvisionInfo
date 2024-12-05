import Foundation
@testable import ProvisionInfoKit
import Testing

struct ProvisionInfoTests {
    @Test
    func parse() throws {
        let location = Bundle.module.url(forResource: "TestProfile", withExtension: "mobileprovision")!
        let data = try Data(contentsOf: location)
        let rawProfile = try RawProfile(data: data)

        let profile = try Profile(raw: rawProfile)
        let certs = try profile.developerCertificates.map(Certificate.init(data:))

        let validStartComponents = DateComponents(
            calendar: calendar, timeZone: tzUTC, year: 2022, month: 2, day: 14, hour: 19, minute: 47, second: 17
        )
        let validStart = calendar.date(from: validStartComponents)!
        let validEnd = calendar.date(byAdding: .year, value: 1, to: validStart, wrappingComponents: false)!

        #expect(profile.creationDate == validStart)
        #expect(profile.expirationDate == validEnd)
        #expect(profile.name == "DO NOT USE: only for dummy signing")
        #expect(profile.platform == ["iOS"])
        #expect(profile.provisionedDevices == [.init("1234567890123456789012345678901234567890")])
        #expect(profile.teamID == ["SELFSIGNED"])
        #expect(profile.teamName == "Selfsigners united")
        #expect(profile.timeToLive == 365)
        #expect(profile.uuid == UUID(uuidString: "73ECBC99-16D4-4685-961A-2051D6BAEF24")!)
        #expect(profile.version == 1)

        #expect(
            profile.entitlements ==
                [
                    "keychain-access-groups": .array([.string("SELFSIGNED.*")]),
                    "get-task-allow": .boolean(false),
                    "application-identifier": .string("SELFSIGNED.*"),
                    "com.apple.developer.associated-domains": .string("*"),
                    "com.apple.developer.team-identifier": .string("SELFSIGNED"),
                    "aps-environment": .string("production"),
                ] as EntitlementsDictionary
        )

        #expect(certs.count == 1)
        let cert = try #require(certs.first)

        #expect(cert.subjectName == "Example Name")
        #expect(
            cert.fingerprintSHA1.map(hexifyData(_:)) ==
                "E5 FF E3 3F 87 E4 B5 A6 E7 9A CE BD 97 74 89 96 AD 51 97 88"
        )
        #expect(
            cert.fingerprintSHA256.map(hexifyData(_:)) ==
                "A0 38 61 0D A5 2E 9B C6 62 63 CC 8F 63 DB 2A 94 11 70 73 52 09 C9 04 02 66 90 3A 25 E1 5E 9B 9C"
        )
        #expect(cert.issuer == "Example Name")
        #expect(cert.organizationName == "Example Organization")
        #expect(cert.organizationalUnitName == "SELFSIGNED")
        #expect(cert.summary == "Example Name")
        #expect(cert.notValidBefore == validStart)
        #expect(cert.notValidAfter == validEnd)
        #expect(cert.x509Serial == "1")
    }
}

private let calendar = Calendar(identifier: .gregorian)
private let tzUTC = TimeZone(identifier: "UTC")!

/*
 Generating the test profile: https://dkimitsa.github.io/2018/01/04/ios-homemade-provision-profile/
 */
