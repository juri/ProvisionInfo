import CustomDump
import Foundation
@testable import ProvisionInfoKit
import Testing

struct EntitlementsCodableTests {
    @Test
    func roundtripping() throws {
        let entitlements: EntitlementsDictionary = [
            "key1": .array([
                .string("e0"),
                .string("e1"),
                .boolean(true),
                .integer(3),
                .null,
                .array([
                    .string("ee0"),
                    .string("ee1"),
                ]),
            ]),
            "key2": .boolean(false),
            "key3": .data(Data("foo".utf8)),
            "key4": .dictionary([
                "kkey1": .string("value1"),
                "kkey2": .string("value2"),
            ]),
            "key5": .double(5.2),
            "key6": .integer(9),
            "key7": .null,
            "key8": .string("value1"),
        ]

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let data = try encoder.encode(entitlements)

        let decodedEntitlements = try JSONDecoder().decode(EntitlementsDictionary.self, from: data)
        expectNoDifference(entitlements, decodedEntitlements)
    }
}
