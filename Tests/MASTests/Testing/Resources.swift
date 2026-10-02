//
// Resources.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import Foundation
internal import JSONDecoding
private import JSONParsing

// swiftlint:disable:next function_default_parameter_at_end
func decode<T: JSONDecodable>(_: T.Type = T.self, fromResource resource: String) throws -> T {
	try .init(json: .init(parsing: Data(fromResource: resource).bytes))
}

// swiftlint:disable:next function_default_parameter_at_end
func decode<T: JSONDecodable>(_: T.Type = T.self, fromJSON json: String) throws -> T {
	try .init(json: .init(parsing: Data(json.utf8).bytes))
}
