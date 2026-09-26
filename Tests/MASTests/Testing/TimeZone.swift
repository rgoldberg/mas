//
// TimeZone.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import Foundation
@testable private import mas
private import Testing

/// `body`'s result, with the time zone that `identifier` identifies as the
/// system time zone.
func inSystemTimeZone<Result>(_ identifier: String, _ body: () throws -> Result) throws -> Result {
	try Environment.$current.withValue(
		.init(systemTimeZone: try #require(TimeZone(identifier: identifier))),
		operation: body,
	)
}
