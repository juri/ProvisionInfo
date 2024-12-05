import Foundation

public enum EntitlementValue: Equatable {
    case array([EntitlementValue])
    case boolean(Bool)
    case data(Data)
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
        switch self {
        case let .array(a):
            var container = encoder.unkeyedContainer()
            for value in a {
                try container.encode(value)
            }

        case let .boolean(b):
            var container = encoder.singleValueContainer()
            try container.encode(b)

        case let .data(d):
            var container = encoder.singleValueContainer()
            try container.encode(d)

        case let .dictionary(d):
            var container = encoder.container(keyedBy: AnyCodingKey.self)
            for (key, value) in d {
                try container.encode(value, forKey: AnyCodingKey(stringValue: key))
            }

        case let .double(d):
            var container = encoder.singleValueContainer()
            try container.encode(d)

        case let .integer(i):
            var container = encoder.singleValueContainer()
            try container.encode(i)

        case .null:
            var container = encoder.singleValueContainer()
            try container.encodeNil()

        case let .string(s):
            var container = encoder.singleValueContainer()
            try container.encode(s)
        }
    }
}

extension EntitlementValue: Decodable {
    public init(from decoder: any Decoder) throws {
        do {
            var dict = [String: EntitlementValue]()
            let container = try decoder.container(keyedBy: AnyCodingKey.self)
            for key in container.allKeys {
                let value = try container.decode(EntitlementValue.self, forKey: key)
                dict[key.stringValue] = value
            }
            self = .dictionary(dict)
            return
        } catch {}

        do {
            var arr = [EntitlementValue]()
            var container = try decoder.unkeyedContainer()
            while !container.isAtEnd {
                let value = try container.decode(EntitlementValue.self)
                arr.append(value)
            }
            self = .array(arr)
            return
        } catch {}

        let container = try decoder.singleValueContainer()
        do {
            let bool = try container.decode(Bool.self)
            self = .boolean(bool)
            return
        } catch {}

        do {
            let data = try container.decode(Data.self)
            self = .data(data)
            return
        } catch {}

        do {
            let int = try container.decode(Int.self)
            self = .integer(int)
            return
        } catch {}

        do {
            let double = try container.decode(Double.self)
            self = .double(double)
            return
        } catch {}

        do {
            let string = try container.decode(String.self)
            self = .string(string)
            return
        } catch {}

        if container.decodeNil() {
            self = .null
            return
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "No valid EntitlementValue found to decode"
            )
        )
    }
}

public typealias EntitlementsDictionary = [String: EntitlementValue]

extension EntitlementsDictionary {
    package init(dict: [String: Any]) throws {
        self = try dict.mapValues { try EntitlementValue(value: $0) }
    }
}

struct EntitlementsDecodingError: Error {}

private struct AnyCodingKey: CodingKey {
    public let stringValue: String

    public var intValue: Int?

    public init(stringValue: String) {
        self.stringValue = stringValue
    }

    public init?(intValue: Int) { nil }
}
