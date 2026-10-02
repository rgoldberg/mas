//
// MASTests+URL.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import Foundation
@testable private import mas
internal import Testing

private extension MASTests {
	@Test(arguments: ["http://example.com", "https://example.com", "HTTPS://example.com"])
	func `identifies web URL`(urlString: String) throws {
		#expect(try #require(URL(string: urlString)).isWebURL)
	}

	@Test(arguments: ["file:///nonexistent.app", "macappstore://apps.apple.com", "example.com"])
	func `identifies non-web URL`(urlString: String) throws {
		#expect(try !#require(URL(string: urlString)).isWebURL)
	}
}
