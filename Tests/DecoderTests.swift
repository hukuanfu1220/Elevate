//
//  ElevateTests.swift
//  ElevateTests
//
//  Created by Eric Appel on 7/13/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Elevate
import Foundation
import XCTest

class ValidDecoder: Decoder {
    func decodeObject(object: AnyObject) throws -> Any {
        return try Parser.parseProperties(json: object) { make in
            make.propertyForKeyPath("subUInt", type: .UInt)
            make.propertyForKeyPath("subInt", type: .Int)
            make.propertyForKeyPath("subString", type: .String)
        }
    }
}

class InvalidDecoder: Decoder {
    func decodeObject(object: AnyObject) throws -> Any {
        return try Parser.parseProperties(json: object) { make in
            make.propertyForKeyPath("subUInt", type: .String)
            make.propertyForKeyPath("missingSubInt", type: .Int)
        }
    }
}

// MARK: -

class DecoderTestCase: BaseTestCase {
    func testThatItDecodesObject() {
        // Given
        let decoder = ValidDecoder()

        let data = loadJSONDataForFileNamed("PropertyTypesTest")
        let json = try! NSJSONSerialization.JSONObjectWithData(
            data,
            options: NSJSONReadingOptions(rawValue: 0)
        ) as! [String: AnyObject]

        // When
        do {
            if let properties = try decoder.decodeObject(json["sub-object"]!) as? [String: Any] {
                // Then
                XCTAssertEqual(properties["subUInt"] as! UInt, UInt(1), "Parsed UInt value did not equal value from json file.")
                XCTAssertEqual(properties["subInt"] as! Int, -1, "Parsed Int value did not equal value from json file.")
                XCTAssertEqual(properties["subString"] as! String, "sub test string", "Parsed String value did not equal value from json file.")
            } else {
                XCTFail("Parser did not return the expected type")
            }
        } catch {
            XCTFail("Parser unexpectedly returned an error")
        }
    }

    func testThatItAggregatesErrorsWhenUsingInvalidDecoder() {
        // Given
        let data = loadJSONDataForFileNamed("PropertyTypesTest")

        do {
            // When
            let _ = try Parser.parseProperties(data: data) { make in
                make.propertyForKeyPath("sub-object", type: .Dictionary, decoder: InvalidDecoder())
            }

            XCTFail("ErroneousTestObjectParser unexpectedly succeeded")
        } catch let error as ParserError {
            // Then
            let actualValue = error.description
            let expectedValue = (
                "Parser Validation Error - Value for key path [subUInt] is of incorrect type\n" +
                "Required key path [missingSubInt] was missing or null"
            )
            XCTAssertEqual(actualValue, expectedValue, "ErroneousTestObjectParser error did not match expected value")
        } catch {
            XCTFail("Parser error was of incorrect type")
        }
    }
}
