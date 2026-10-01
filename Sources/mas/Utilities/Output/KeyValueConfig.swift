//
// KeyValueConfig.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

/// A fully-parsed `--key-value`'s value (key-value.md).
struct KeyValueConfig: Equatable {
	/// `<key-styling-setting>`: when keys are styled.
	enum KeyStyling: Equatable {
		/// `a`: always, even if standard output is not a terminal.
		case always
		/// `t`: iff standard output is a terminal.
		case terminalOnly
	}

	static let `default` = Self(
		keyStyleSpecifier: "",
		keyStyling: .terminalOnly,
		keyStyleSequences: .default,
		leaderPattern: defaultLeaderPattern,
		leadingSpacing: " ",
		trailingSpacing: " ",
		itemSeparatorPattern: "",
	)

	/// Styles each key (e.g., with the default `StyleSequences`, `"1"` for bold,
	/// `"1;4"` for bold & underlined); empty means unstyled.
	let keyStyleSpecifier: String
	let keyStyling: KeyStyling
	let keyStyleSequences: StyleSequences
	/// Repeated (truncating mid-repetition if needed, never padded) to fill each
	/// leader, aligning an item's values; never empty; `nil` means no leader,
	/// leaving an item's values unaligned.
	let leaderPattern: String?
	/// After each key, before its leader (iff any).
	let leadingSpacing: String
	/// Before each value, after its leader (iff any).
	let trailingSpacing: String
	/// Repeated (truncating mid-repetition if needed, never padded) to fill the
	/// line between each pair of adjacent items; empty means a blank line; `nil`
	/// means no line.
	let itemSeparatorPattern: String?
}

/// Parses `--key-value`'s value (`key-value.md`'s `<key-value-config>`):
/// `[ <key-value-setting>+ ]`, last wins per axis. Outer bare whitespace
/// between settings is ignored.
func parseKeyValueConfig(_ value: String) throws(KeyValueConfigParsingError) -> KeyValueConfig {
	var keyStyleSpecifier = KeyValueConfig.default.keyStyleSpecifier
	var keyStyling = KeyValueConfig.default.keyStyling
	var keyStylePrefix = KeyValueConfig.default.keyStyleSequences.prefix
	var keyStyleSuffix = KeyValueConfig.default.keyStyleSequences.suffix
	var keyStyleReset = KeyValueConfig.default.keyStyleSequences.reset
	var leaderPattern = KeyValueConfig.default.leaderPattern
	var leadingSpacing = String?.none
	var trailingSpacing = KeyValueConfig.default.trailingSpacing
	var itemSeparatorPattern = KeyValueConfig.default.itemSeparatorPattern
	var input = value[...]
	while case let trimmed = input.drop(while: \.isWhitespace), let setting = trimmed.first {
		input = trimmed.dropFirst()
		switch setting {
		case "k":
			keyStyleSpecifier = ""
		case "K":
			// Unlike `--table`'s `H`, `K` requires a `<style-specifier>`
			let styleSpecifier = try parseStyleSpecifier(
				&input,
				danglingEscapeError: KeyValueConfigParsingError.danglingEscape,
				invalidStyleSpecifierError: KeyValueConfigParsingError.invalidKeyStyleSpecifier,
			)
			guard !styleSpecifier.isEmpty else {
				throw .invalidKeyStyleSpecifier(styleSpecifier)
			}
			keyStyleSpecifier = styleSpecifier
		case "t":
			keyStyling = .terminalOnly
		case "a":
			keyStyling = .always
		case "p":
			keyStylePrefix = KeyValueConfig.default.keyStyleSequences.prefix
		case "P":
			keyStylePrefix = try parseKeyValueSettingText(&input)
		case "x":
			keyStyleSuffix = KeyValueConfig.default.keyStyleSequences.suffix
		case "X":
			keyStyleSuffix = try parseKeyValueSettingText(&input)
		case "o":
			keyStyleReset = KeyValueConfig.default.keyStyleSequences.reset
		case "O":
			keyStyleReset = try parseKeyValueSettingText(&input)
		case "f":
			leaderPattern = nil
		case "F":
			// `<leader-pattern>` is a non-empty text token: absent, its default `▁`
			// applies
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
			itemSeparatorPattern = nil
		case "S":
			itemSeparatorPattern = try parseKeyValueSettingText(&input)
		default:
			throw .invalidSetting(setting)
		}
	}
	return .init(
		keyStyleSpecifier: keyStyleSpecifier,
		keyStyling: keyStyling,
		keyStyleSequences: .init(prefix: keyStylePrefix, suffix: keyStyleSuffix, reset: keyStyleReset),
		leaderPattern: leaderPattern,
		// `f` implies a leading spacing of `:`, if none is otherwise set
		leadingSpacing: leadingSpacing ?? (leaderPattern == nil ? ":" : KeyValueConfig.default.leadingSpacing),
		trailingSpacing: trailingSpacing,
		itemSeparatorPattern: itemSeparatorPattern,
	)
}

// swiftlint:disable:next one_declaration_per_file
enum KeyValueConfigParsingError: Equatable, Error, CustomStringConvertible {
	case danglingEscape
	case invalidKeyStyleSpecifier(String)
	case invalidSetting(Character)

	var description: String {
		switch self {
		case .danglingEscape:
			"Escape prefix '\\' at the end of --key-value's value"
		case let .invalidKeyStyleSpecifier(styleSpecifier):
			"Invalid key style specifier (expected non-empty, escaping each ASCII letter, e.g., \"\\b\"): \(styleSpecifier)"
		case let .invalidSetting(setting):
			"Invalid --key-value <key-value-setting>: \(setting)"
		}
	}
}

/// Parses an uppercase `<key-value-setting>`'s `{text}` payload
/// (`<style-prefix>`, `<style-suffix>`, `<style-reset>`, `<leader-pattern>`,
/// `<leading-spacing>`, `<trailing-spacing>`, or `<item-separator-pattern>`)
/// through its `<key-value-setting-termination>` via
/// `parseOutputConfigSettingPayload`.
private func parseKeyValueSettingText(_ input: inout Substring) throws(KeyValueConfigParsingError) -> String {
	try parseOutputConfigSettingPayload(&input, danglingEscapeError: KeyValueConfigParsingError.danglingEscape)
}

private let defaultLeaderPattern = "▁"
