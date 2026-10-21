//
// KeyValueConfig.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

/// A fully-parsed `--key-value-config`'s value (key-value.md).
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
	/// Repeated (truncating mid-repetition if needed, then space-filling any
	/// remaining width) to fill each leader, aligning an item's values; never
	/// empty; `nil` means no leader, leaving an item's values unaligned.
	let leaderPattern: String?
	/// After each key, before its leader (iff any).
	let leadingSpacing: String
	/// Before each value, after its leader (iff any).
	let trailingSpacing: String
	/// Repeated (truncating mid-repetition if needed, then space-filling any
	/// remaining width) to fill the line between each pair of adjacent items;
	/// empty means a blank line; `nil` means no line.
	let itemSeparatorPattern: String?
}

/// Parses `--key-value-config`'s value, which, iff non-empty, is
/// `key-value.md`'s `<key-value-config>` (`<key-value-setting>+`), last wins
/// per axis. Outer bare whitespace between settings is ignored.
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
			// Unlike `--table-config`'s `H`, `K` requires a `<style-specifier>`
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
			keyStylePrefix = try parseStyleSequence(
				&input,
				danglingEscapeError: KeyValueConfigParsingError.danglingEscape,
				invalidStyleSequenceError: KeyValueConfigParsingError.invalidKeyStylePrefix,
			)
		case "x":
			keyStyleSuffix = KeyValueConfig.default.keyStyleSequences.suffix
		case "X":
			keyStyleSuffix = try parseStyleSequence(
				&input,
				danglingEscapeError: KeyValueConfigParsingError.danglingEscape,
				invalidStyleSequenceError: KeyValueConfigParsingError.invalidKeyStyleSuffix,
			)
		case "o":
			keyStyleReset = KeyValueConfig.default.keyStyleSequences.reset
		case "O":
			keyStyleReset = try parseStyleSequence(
				&input,
				danglingEscapeError: KeyValueConfigParsingError.danglingEscape,
				invalidStyleSequenceError: KeyValueConfigParsingError.invalidKeyStyleReset,
			)
		case "f":
			leaderPattern = nil
		case "F":
			// `<leader-pattern>` is a non-empty text token: absent, its default `▁`
			// applies
			let pattern = try parseKeyValueSettingText(&input)
			guard !pattern.contains(where: \.isNewline) else {
				throw .invalidLeaderPattern(pattern)
			}
			leaderPattern = pattern.isEmpty ? defaultLeaderPattern : pattern
		case "l":
			leadingSpacing = KeyValueConfig.default.leadingSpacing
		case "L":
			let spacing = try parseKeyValueSettingText(&input)
			guard !spacing.contains(where: \.isNewline) else {
				throw .invalidLeadingSpacing(spacing)
			}
			leadingSpacing = spacing
		case "r":
			trailingSpacing = KeyValueConfig.default.trailingSpacing
		case "R":
			let spacing = try parseKeyValueSettingText(&input)
			guard !spacing.contains(where: \.isNewline) else {
				throw .invalidTrailingSpacing(spacing)
			}
			trailingSpacing = spacing
		case "s":
			itemSeparatorPattern = nil
		case "S":
			let pattern = try parseKeyValueSettingText(&input)
			guard !pattern.contains(where: \.isNewline) else {
				throw .invalidItemSeparatorPattern(pattern)
			}
			itemSeparatorPattern = pattern
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
	case invalidItemSeparatorPattern(String)
	case invalidKeyStylePrefix(String)
	case invalidKeyStyleReset(String)
	case invalidKeyStyleSpecifier(String)
	case invalidKeyStyleSuffix(String)
	case invalidLeaderPattern(String)
	case invalidLeadingSpacing(String)
	case invalidSetting(Character)
	case invalidTrailingSpacing(String)

	var description: String {
		switch self {
		case .danglingEscape:
			"Escape prefix '\\' at the end of --key-value-config's value"
		case let .invalidItemSeparatorPattern(pattern):
			"""
			Invalid item separator pattern (a line terminator would split the item separator line): \
			\(pattern.debugDescription)
			"""
		case let .invalidKeyStylePrefix(stylePrefix):
			"Invalid key style prefix (a line terminator would split each row): \(stylePrefix.debugDescription)"
		case let .invalidKeyStyleReset(styleReset):
			"Invalid key style reset (a line terminator would split each row): \(styleReset.debugDescription)"
		case let .invalidKeyStyleSpecifier(styleSpecifier):
			"""
			Invalid key style specifier (expected non-empty, with no line terminator, escaping each ASCII letter, e.g., \
			"\\b"): \(styleSpecifier)
			"""
		case let .invalidKeyStyleSuffix(styleSuffix):
			"Invalid key style suffix (a line terminator would split each row): \(styleSuffix.debugDescription)"
		case let .invalidLeaderPattern(pattern):
			"Invalid leader pattern (a line terminator would split each row): \(pattern.debugDescription)"
		case let .invalidLeadingSpacing(spacing):
			"Invalid leading spacing (a line terminator would split each row): \(spacing.debugDescription)"
		case let .invalidSetting(setting):
			"Invalid --key-value-config <key-value-setting>: \(setting)"
		case let .invalidTrailingSpacing(spacing):
			"Invalid trailing spacing (a line terminator would split each row): \(spacing.debugDescription)"
		}
	}
}

/// Parses an uppercase `<key-value-setting>`'s `{text}` payload
/// (`<leader-pattern>`, `<leading-spacing>`, `<trailing-spacing>`, or
/// `<item-separator-pattern>`) through its `<key-value-setting-termination>`
/// via `parseOutputConfigSettingPayload`.
private func parseKeyValueSettingText(_ input: inout Substring) throws(KeyValueConfigParsingError) -> String {
	try parseOutputConfigSettingPayload(&input, danglingEscapeError: KeyValueConfigParsingError.danglingEscape)
}

private let defaultLeaderPattern = "▁"
