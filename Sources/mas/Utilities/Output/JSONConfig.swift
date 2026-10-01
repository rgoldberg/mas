//
// JSONConfig.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

/// A fully-parsed `--json`'s value (json.md).
struct JSONConfig: Equatable {
	/// `<non-ascii-setting>`: how each non-ASCII character is rendered.
	enum NonASCIIRendering: Equatable {
		/// `e`: as a JSON `\uXXXX` escape sequence (a UTF-16 surrogate pair of them
		/// for a character outside the Basic Multilingual Plane).
		case escaped
		/// `v`: verbatim, encoded as UTF-8.
		case verbatim
	}

	/// `<top-level-structure-setting>`: how items are structured at the top
	/// level.
	enum TopLevelStructure: Equatable {
		/// `a`: every item is an element of a single top-level JSON array.
		case itemArray
		/// `s`: each item is a top-level JSON object.
		case itemStream
	}

	static let `default` = Self(indentation: nil, topLevelStructure: .itemStream, nonASCIIRendering: .verbatim)

	/// The indentation per nesting level of pretty-printed output; only spaces &
	/// tabs; never empty; `nil` means compact output.
	let indentation: String?
	let topLevelStructure: TopLevelStructure
	let nonASCIIRendering: NonASCIIRendering
}

/// Parses `--json`'s value (`json.md`'s `<json-config>`):
/// `[ <json-setting>+ ]`, last wins per axis. Outer bare whitespace between
/// settings is ignored.
func parseJSONConfig(_ value: String) throws(JSONConfigParsingError) -> JSONConfig {
	var indentation = JSONConfig.default.indentation
	var topLevelStructure = JSONConfig.default.topLevelStructure
	var nonASCIIRendering = JSONConfig.default.nonASCIIRendering
	var input = value[...]
	while case let trimmed = input.drop(while: \.isWhitespace), let setting = trimmed.first {
		input = trimmed.dropFirst()
		switch setting {
		case "p":
			indentation = nil
		case "P":
			// `<indentation>` is a non-empty text token: absent, its default (2
			// spaces) applies
			let text = try parseOutputConfigSettingPayload(&input, danglingEscapeError: JSONConfigParsingError.danglingEscape)
			guard text.allSatisfy({ $0 == " " || $0 == "\t" }) else {
				throw .invalidIndentation(text)
			}
			indentation = text.isEmpty ? defaultIndentation : text
		case "s":
			topLevelStructure = .itemStream
		case "a":
			topLevelStructure = .itemArray
		case "v":
			nonASCIIRendering = .verbatim
		case "e":
			nonASCIIRendering = .escaped
		default:
			throw .invalidSetting(setting)
		}
	}
	return .init(indentation: indentation, topLevelStructure: topLevelStructure, nonASCIIRendering: nonASCIIRendering)
}

// swiftlint:disable:next one_declaration_per_file
enum JSONConfigParsingError: Equatable, Error, CustomStringConvertible {
	case danglingEscape
	case invalidIndentation(String)
	case invalidSetting(Character)

	var description: String {
		switch self {
		case .danglingEscape:
			"Escape prefix '\\' at the end of --json's value"
		case let .invalidIndentation(indentation):
			"Invalid indentation (expected only spaces & tabs): \(indentation)"
		case let .invalidSetting(setting):
			"Invalid --json <json-setting>: \(setting)"
		}
	}
}

private let defaultIndentation = "  "
