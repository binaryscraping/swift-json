import XCTest
import JSON

final class JSONTests: XCTestCase {

    func test_JSON_SetValueToJSONObject() {
        var json = JSON.object([:])
        json.name = "Guilherme"

        XCTAssertEqual(json.objectValue, ["name": "Guilherme"])
    }

    func test_JSON_SetValueToJSONArray() {
        var json: JSON = [1]
        json[0] = 2

        XCTAssertEqual(json.arrayValue, [2])
    }

    func test_JSON_AppendValueToJSONArray() {
        var json: JSON = [1]
        json.arrayValue?.append(2)
        json.arrayValue?.append("string")

        XCTAssertEqual(json.arrayValue, [1, 2, "string"])
    }

    func test_JSON_SetValueToNull() {
        var json: JSON = ["id": "uuid"]
        json.id = nil

        XCTAssertEqual(json.objectValue, [:])
    }
}
