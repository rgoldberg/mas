//
// UniversalSemVer.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import Foundation

struct UniversalSemVer: SemVerSyntax, ExpressibleByStringLiteral {
	let coreElements: [String]
	let prereleaseElements: [String]
	let buildElements: [String]
	let rawValue: String

	init(rawValue: String) {
		guard let match = rawValue.wholeMatch(of: universalSemVerRegex) else {
			preconditionFailure("Failed to match regex \(universalSemVerRegex)")
		}
		coreElements = match.1.elements
		prereleaseElements = match.2.elements
		buildElements = match.3.elements
		self.rawValue = rawValue
	}

	init(stringLiteral value: String) {
		self.init(rawValue: value)
	}
}

struct UniversalSemVerInt: SemVerSyntaxInteger { // swiftlint:disable:this one_declaration_per_file
	let coreIntegers: [Int]
	let prereleaseElements: [String]
	let buildElements: [String]
	let rawValue: String

	var majorInteger: Int {
		coreIntegers[0]
	}

	var minorInteger: Int {
		coreIntegers[1]
	}

	var patchInteger: Int {
		coreIntegers[2]
	}

	init(
		coreIntegers: [Int],
		prereleaseElements: [String] = .init(),
		buildElements: [String] = .init(),
	) { // periphery:ignore
		self.init(
			coreIntegers: coreIntegers,
			prereleaseElements: prereleaseElements,
			buildElements: buildElements,
			rawValue: """
				\(Self.core(from: Self.coreElements(from: coreIntegers)))\
				\(Self.prerelease(from: prereleaseElements).map { "-\($0)" } ?? "")\
				\(Self.build(from: buildElements).map { "+\($0)" } ?? "")
				""",
		)
	}

	init?(rawValue: String) {
		do {
			guard let match = rawValue.wholeMatch(of: universalSemVerRegex) else {
				preconditionFailure("Failed to match regex \(universalSemVerRegex)")
			}
			self = .init(
				coreIntegers: try match.1.elements.map { coreElement in
					try .init(coreElement) ?? { throw MASError.error(coreElement) }()
				},
				prereleaseElements: match.2.elements,
				buildElements: match.3.elements,
				rawValue: rawValue,
			)
		} catch {
			return nil
		}
	}

	private init(
		coreIntegers: [Int],
		prereleaseElements: [String],
		buildElements: [String],
		rawValue: String,
	) {
		self.coreIntegers = coreIntegers.padding(toCount: 3, with: 0)
		self.prereleaseElements = prereleaseElements
		self.buildElements = buildElements
		self.rawValue = rawValue
	}
}

private extension Substring? {
	var elements: [String] {
		map { $0.split(separator: ".") }?.map(String.init) ?? .init()
	}
}

private let universalSemVerRegex = /([^-+]*+)?+(?:-([^+]*+))?+(?:\+(.*+))?+/
