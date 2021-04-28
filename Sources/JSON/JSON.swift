import Foundation

@dynamicMemberLookup
public enum JSON: Hashable {
    case object([String: JSON])
    case array([JSON])
    case number(Double)
    case string(String)
    case bool(Bool)
    case null

    public var stringValue: String? {
        get {
            if case .string(let value) = self {
                return value
            }

            return nil
        }
        set {
            self = newValue.map(JSON.string) ?? .null
        }
    }

    public var arrayValue: [JSON]? {
        get {
            if case .array(let array) = self {
                return array
            }

            return nil
        }

        set {
            self = newValue.map(JSON.array) ?? .null
        }
    }

    public var objectValue: [String: JSON]? {
        get {
            if case .object(let object) = self {
                return object
            }

            return nil
        }

        set {
            self = newValue.map(JSON.object) ?? .null
        }
    }

    public var boolValue: Bool? {
        get {
            if case .bool(let bool) = self {
                return bool
            }

            return nil
        }

        set {
            self = newValue.map(JSON.bool) ?? .null
        }
    }

    public subscript(index: Int) -> JSON? {
        get { arrayValue?[index] }
        set {
            guard let newValue = newValue else {
                preconditionFailure("newValue must not be nil")
            }

            arrayValue?[index] = newValue
        }
    }

    public subscript(key: String) -> JSON? {
        get { objectValue?[key] }
        set { objectValue?[key] = newValue }
    }

    public subscript(dynamicMember member: String) -> JSON? {
        get { self[member] }
        set { self[member] = newValue }
    }
}

extension JSON: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let object = try? container.decode([String: JSON].self) {
            self = .object(object)
        } else if let array = try? container.decode([JSON].self) {
            self = .array(array)
        } else if let number = try? container.decode(Double.self) {
            self = .number(number)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Could not decode JSON type.")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .null:
            try container.encodeNil()
        case .object(let object):
            try container.encode(object)
        case .array(let array):
            try container.encode(array)
        case .number(let number):
            try container.encode(number)
        case .string(let string):
            try container.encode(string)
        case .bool(let bool):
            try container.encode(bool)
        }
    }
}

extension JSON: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}

extension JSON: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: JSON...) {
        self = .array(elements)
    }
}

extension JSON: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, JSON)...) {
        self = .object(Dictionary(uniqueKeysWithValues: elements))
    }
}

extension JSON: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .number(value)
    }
}

extension JSON: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension JSON: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .number(Double(value))
    }
}
