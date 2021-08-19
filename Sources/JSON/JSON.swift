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

  public var numberValue: Double? {
    get {
      switch self {
      case .number(let value): return value
      default: return nil
      }
    }

    set {
      self = newValue.map(JSON.number) ?? .null
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

extension JSON: ExpressibleByBooleanLiteral {
  public init(booleanLiteral value: Bool) {
    self = .bool(value)
  }
}

extension JSON {
  /// Returns a JSON formatted string.
  /// - Parameter options: Formatting options, for example `[.prettyPrinted, .sortedKeys]`.
  /// - Returns: JSON string.
  public func formatted(options: JSONEncoder.OutputFormatting = []) -> String {
    do {
      let encoder = JSONEncoder()
      encoder.outputFormatting = options
      let data = try encoder.encode(self)
      return String(data: data, encoding: .utf8) ?? ""
    } catch {
      return ""
    }
  }
}

extension JSON {
  public func codableValue<T: Codable>() throws -> T {
    let data = try JSONEncoder().encode(self)
    return try JSONDecoder().decode(T.self, from: data)
  }

  public init(data: Data, decoder: JSONDecoder = JSONDecoder()) throws {
    self = try decoder.decode(JSON.self, from: data)
  }

  public func asData(encoder: JSONEncoder = JSONEncoder()) throws -> Data {
    try encoder.encode(self)
  }

  private enum JSONError: Error {
    case unknown
    case nonJSONType(type: String)
  }

  public init(value: Any) throws {
    switch value {
    case _ as NSNull:
      self = .null
    case let number as NSNumber:
      if number.isBool() {
        self = .bool(number.boolValue)
      } else {
        self = .number(number.doubleValue)
      }

    case nil:
      self = .null
    case let url as URL:
      self = .string(url.absoluteString)
    case let string as String:
      self = .string(string)
    case let bool as Bool:
      self = .bool(bool)
    case let array as [Any]:
      self = .array(try array.map(JSON.init))
    case let object as [String: Any]:
      self = .object(try object.mapValues(JSON.init))
    default:
      throw JSONError.nonJSONType(type: "\(value.self)")
    }
  }

  public var rawValue: Any {
    switch self {
    case let .array(array):
      return array.map(\.rawValue)
    case let .object(object):
      return object.mapValues(\.rawValue)
    case let .bool(bool):
      return bool
    case .null:
      return NSNull()
    case let .number(double):
      return double
    case let .string(string):
      return string
    }
  }
}

// MARK: - Helpers
extension NSNumber {
  fileprivate static let trueValue = NSNumber(value: true)
  fileprivate static let trueObjCType = trueValue.objCType
  fileprivate static let falseValue = NSNumber(value: false)
  fileprivate static let falseObjCType = falseValue.objCType

  fileprivate func isBool() -> Bool {
    let type = self.objCType
    if (compare(NSNumber.trueValue) == .orderedSame && type == NSNumber.trueObjCType)
      || (compare(NSNumber.falseValue) == .orderedSame && type == NSNumber.falseObjCType)
    {
      return true
    }
    return false
  }
}
