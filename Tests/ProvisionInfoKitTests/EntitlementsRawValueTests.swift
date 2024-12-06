import CustomDump
import Foundation
@testable import ProvisionInfoKit
import Testing

struct EntitlementsRawValueTests {
    @Test
    func rawValue() throws {
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
            "key9": .date(Date(timeIntervalSinceReferenceDate: 755_112_800.0)),
        ]
        let rawValue = EntitlementValue.rawValue(dict: entitlements)
        let key1Array = try #require(rawValue["key1"] as? [Any?])
        #expect(key1Array[0] as? String == "e0")
        #expect(key1Array[1] as? String == "e1")
        #expect(key1Array[2] as? Bool == true)
        #expect(key1Array[3] as? Int == 3)
        #expect(key1Array[4] == nil)
        #expect(key1Array[5] as? [String] == ["ee0", "ee1"])
        #expect(rawValue["key2"] as? Bool == false)
        #expect(rawValue["key3"] as? Data == Data("foo".utf8))
        #expect(rawValue["key4"] as? [String: String] == ["kkey1": "value1", "kkey2": "value2"])
        #expect(rawValue["key5"] as? Double == 5.2)
        #expect(rawValue["key6"] as? Int == 9)
        #expect(rawValue["key7"] == nil)
        #expect(rawValue["key8"] as? String == "value1")
        #expect(rawValue["key9"] as? Date == Date(timeIntervalSinceReferenceDate: 755_112_800.0))
    }
}
