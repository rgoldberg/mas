//
// Version.swift
// mas
//
// Copyright © 2025 mas-cli. All rights reserved.
//

protocol Version: RawRepresentable<String> {
	var coreElements: [String] { get }
	var prereleaseElements: [String] { get }
	var buildElements: [String] { get } // swiftlint:disable unused_declaration

	var core: String { get }
	var prerelease: String? { get }
	var build: String? { get } // swiftlint:enable unused_declaration
}
