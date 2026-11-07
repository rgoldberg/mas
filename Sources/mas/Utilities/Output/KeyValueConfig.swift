//
// KeyValueConfig.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

/// A fully-parsed `--key-value-config`'s value (key-value.md).
struct KeyValueConfig: Equatable {
	static let `default` = Self(
		keyStylingSpecifier: "",
		styling: .supportedOnly,
		stylingSequences: .default,
		leaderPattern: defaultLeaderPattern,
		leadingSpacing: " ",
		trailingSpacing: " ",
		itemSeparatorLine: "",
	)

	/// Styles each key (e.g., with the default `StylingSequences`, `"1"` for
	/// bold, `"1;4"` for bold & underlined); empty means unstyled.
	let keyStylingSpecifier: String
	let styling: Styling
	let stylingSequences: StylingSequences
	/// Repeated (truncating mid-repetition if needed, then space-filling any
	/// remaining width) to fill each leader, aligning an item's values; never
	/// empty; `nil` means no leader, leaving an item's values unaligned.
	let leaderPattern: String?
	/// After each key, before its leader (iff any).
	let leadingSpacing: String
	/// Before each value, after its leader (iff any).
	let trailingSpacing: String
	/// The line between each pair of adjacent items, output as is; empty means a
	/// blank line; `nil` means no line.
	let itemSeparatorLine: String?
}

/// Parses `--key-value-config`'s value, which, iff non-empty, is
/// `key-value.md`'s `<key-value-config>` (`<key-value-setting>+`), last wins
/// per setting. Outer bare whitespace between settings is ignored.
func parseKeyValueConfig(_ value: String) throws(KeyValueConfigParsingError) -> KeyValueConfig {
	var keyStylingSpecifier = KeyValueConfig.default.keyStylingSpecifier
	var styling = KeyValueConfig.default.styling
	var stylingPrefix = KeyValueConfig.default.stylingSequences.prefix
	var stylingSuffix = KeyValueConfig.default.stylingSequences.suffix
	var stylingReset = KeyValueConfig.default.stylingSequences.reset
	var leaderPattern = KeyValueConfig.default.leaderPattern
	var leadingSpacing = String?.none
	var trailingSpacing = KeyValueConfig.default.trailingSpacing
	var itemSeparatorLine = KeyValueConfig.default.itemSeparatorLine
	var input = value[...]
	while case let trimmed = input.drop(while: \.isWhitespace), let setting = trimmed.first {
		input = trimmed.dropFirst()
		switch setting {
		case "k":
			keyStylingSpecifier = ""
		case "K":
			// Unlike `--table-config`'s `H`, `K` requires a `<styling-specifier>`
			let stylingSpecifier = try parseStylingSpecifier(
				&input,
				danglingEscapeError: KeyValueConfigParsingError.danglingEscape,
				invalidStylingSpecifierError: KeyValueConfigParsingError.invalidKeyStylingSpecifier,
			)
			guard !stylingSpecifier.isEmpty else {
				throw .invalidKeyStylingSpecifier(stylingSpecifier)
			}
			keyStylingSpecifier = stylingSpecifier
		case "t":
			styling = .supportedOnly
		case "a":
			styling = .always
		case "p":
			stylingPrefix = KeyValueConfig.default.stylingSequences.prefix
		case "P":
			stylingPrefix = try parseKeyValueSettingText(&input)
		case "x":
			stylingSuffix = KeyValueConfig.default.stylingSequences.suffix
		case "X":
			stylingSuffix = try parseKeyValueSettingText(&input)
		case "o":
			stylingReset = KeyValueConfig.default.stylingSequences.reset
		case "O":
			stylingReset = try parseKeyValueSettingText(&input)
		case "f":
			leaderPattern = nil
		case "F":
			// `<leader-pattern>` is a non-empty variable token: absent, its default
			// `▁` applies
			let pattern = try parseKeyValueSettingText(&input)
			leaderPattern = pattern.isEmpty ? defaultLeaderPattern : pattern
		case "l":
			leadingSpacing = KeyValueConfig.default.leadingSpacing
		case "L":
			leadingSpacing = try parseKeyValueSettingText(&input)
		case "r":
			trailingSpacing = KeyValueConfig.default.trailingSpacing
		case "R":
			trailingSpacing = try parseKeyValueSettingText(&input)
		case "s":
			itemSeparatorLine = nil
		case "S":
			itemSeparatorLine = try parseKeyValueSettingText(&input)
		default:
			throw .invalidSetting(setting)
		}
	}
	return .init(
		keyStylingSpecifier: keyStylingSpecifier,
		styling: styling,
		stylingSequences: .init(prefix: stylingPrefix, suffix: stylingSuffix, reset: stylingReset),
		leaderPattern: leaderPattern,
		// An effective `f` implies a `:` leading spacing, if none is otherwise set
		leadingSpacing: leadingSpacing ?? (leaderPattern == nil ? ":" : KeyValueConfig.default.leadingSpacing),
		trailingSpacing: trailingSpacing,
		itemSeparatorLine: itemSeparatorLine,
	)
}

// swiftlint:disable:next one_declaration_per_file
enum KeyValueConfigParsingError: Equatable, Error, CustomStringConvertible {
	case danglingEscape
	case invalidKeyStylingSpecifier(String)
	case invalidSetting(Character)

	var description: String {
		switch self {
		case .danglingEscape:
			"Escape prefix '\\' at the end of --key-value-config's value"
		case let .invalidKeyStylingSpecifier(stylingSpecifier):
			"""
			Invalid key styling specifier (expected non-empty, escaping each ASCII letter, e.g., \"\\b\"): \
			\(stylingSpecifier)
			"""
		case let .invalidSetting(setting):
			"Invalid --key-value-config <key-value-setting>: \(setting)"
		}
	}
}

/// Parses an uppercase `<key-value-setting>`'s `{string}` payload
/// (`<styling-prefix>`, `<styling-suffix>`, `<styling-reset>`,
/// `<leader-pattern>`, `<leading-spacing>`, `<trailing-spacing>`, or
/// `<item-separator-line>`) through its `<setting-termination>` via
/// `parseOutputConfigSettingPayload`.
private func parseKeyValueSettingText(_ input: inout Substring) throws(KeyValueConfigParsingError) -> String {
	try parseOutputConfigSettingPayload(&input, danglingEscapeError: KeyValueConfigParsingError.danglingEscape)
}

private let defaultLeaderPattern = "▁"
