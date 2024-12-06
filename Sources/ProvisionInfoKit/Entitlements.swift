import Foundation

/// `EntitlementsValue` is a value parsed from the entitlements list of a profile.
///
/// `EntitlementsValue` can represent any value found in a property list.
public enum EntitlementValue: Equatable, Sendable {
    case array([EntitlementValue])
    case boolean(Bool)
    case data(Data)
    case date(Date)
    case dictionary(EntitlementsDictionary)
    case double(Double)
    case integer(Int)
    case null
    case string(String)
}

extension EntitlementValue {
    init(value: Any) throws {
        switch value {
        case let array as [Any]:
            let decodedValues = try array.map { entry in
                try EntitlementValue(value: entry)
            }
            self = .array(decodedValues)

        case let bool as Bool:
            self = .boolean(bool)

        case let data as Data:
            self = .data(data)

        case let date as Date:
            self = .date(date)

        case let dict as [String: Any]:
            self = try .init(dict: dict)

        case let int as Int:
            self = .integer(int)

        case let str as String:
            self = .string(str)

        default:
            throw EntitlementsDecodingError()
        }
    }

    init(dict: [String: Any]) throws {
        self = try .dictionary(EntitlementsDictionary(dict: dict))
    }
}

extension EntitlementValue: Encodable {
    public func encode(to encoder: any Encoder) throws {
        var mainContainer = encoder.container(keyedBy: TypedContainerKeys.self)
        switch self {
        case let .array(a):
            var container = mainContainer.nestedUnkeyedContainer(forKey: .value)
            try mainContainer.encode(TypeIdentifier.array, forKey: .type)
            for value in a {
                try container.encode(value)
            }

        case let .boolean(b):
            try mainContainer.encode(TypeIdentifier.boolean, forKey: .type)
            try mainContainer.encode(b, forKey: .value)

        case let .data(d):
            try mainContainer.encode(TypeIdentifier.data, forKey: .type)
            try mainContainer.encode(d, forKey: .value)

        case let .date(d):
            try mainContainer.encode(TypeIdentifier.date, forKey: .type)
            try mainContainer.encode(d, forKey: .value)

        case let .dictionary(d):
            var container = mainContainer.nestedContainer(keyedBy: AnyCodingKey.self, forKey: .value)
            try mainContainer.encode(TypeIdentifier.dictionary, forKey: .type)
            for (key, value) in d {
                try container.encode(value, forKey: AnyCodingKey(stringValue: key))
            }

        case let .double(d):
            try mainContainer.encode(TypeIdentifier.double, forKey: .type)
            try mainContainer.encode(d, forKey: .value)

        case let .integer(i):
            try mainContainer.encode(TypeIdentifier.integer, forKey: .type)
            try mainContainer.encode(i, forKey: .value)

        case .null:
            try mainContainer.encode(TypeIdentifier.null, forKey: .type)

        case let .string(s):
            try mainContainer.encode(TypeIdentifier.string, forKey: .type)
            try mainContainer.encode(s, forKey: .value)
        }
    }
}

extension EntitlementValue: Decodable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: TypedContainerKeys.self)
        let typeIdentifier = try container.decode(TypeIdentifier.self, forKey: .type)

        switch typeIdentifier {
        case .array:
            var arr = [EntitlementValue]()
            var nestedContainer = try container.nestedUnkeyedContainer(forKey: .value)
            while !nestedContainer.isAtEnd {
                let value = try nestedContainer.decode(EntitlementValue.self)
                arr.append(value)
            }
            self = .array(arr)

        case .boolean:
            let value = try container.decode(Bool.self, forKey: .value)
            self = .boolean(value)
            return

        case .data:
            let value = try container.decode(Data.self, forKey: .value)
            self = .data(value)
            return

        case .date:
            let value = try container.decode(Date.self, forKey: .value)
            self = .date(value)
            return

        case .dictionary:
            var dict: [String: EntitlementValue] = [:]
            let nestedContainer = try container.nestedContainer(keyedBy: AnyCodingKey.self, forKey: .value)
            for key in nestedContainer.allKeys {
                let value = try nestedContainer.decode(EntitlementValue.self, forKey: key)
                dict[key.stringValue] = value
            }
            self = .dictionary(dict)
            return

        case .double:
            let value = try container.decode(Double.self, forKey: .value)
            self = .double(value)
            return

        case .integer:
            let value = try container.decode(Int.self, forKey: .value)
            self = .integer(value)
            return

        case .null:
            self = .null

        case .string:
            let value = try container.decode(String.self, forKey: .value)
            self = .string(value)
            return
        }
    }
}

public typealias EntitlementsDictionary = [String: EntitlementValue]

extension EntitlementsDictionary {
    package init(dict: [String: Any]) throws {
        self = try dict.mapValues { try EntitlementValue(value: $0) }
    }
}

/// `EntitlementsDecodingError` is thrown when we encounter an unrecognized value when decoding entitlements.
public struct EntitlementsDecodingError: Error {}

private struct AnyCodingKey: CodingKey {
    public let stringValue: String

    public var intValue: Int?

    public init(stringValue: String) {
        self.stringValue = stringValue
    }

    public init?(intValue: Int) { nil }
}

private enum TypedContainerKeys: String, CodingKey {
    case type
    case value
}

private enum TypeIdentifier: String, Codable {
    case array
    case boolean
    case data
    case date
    case dictionary
    case double
    case integer
    case null
    case string
}
