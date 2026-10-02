//
// KeyValueConfig.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

/// A fully-parsed `--key-value`'s value (key-value.md).
struct KeyValueConfig: Equatable {
	/// `<key-styling-setting>`: when `keySGRParameters` are applied.
	enum KeyStyling: Equatable {
		/// `a`: always, even if standard output is not a terminal.
		case always
		/// `t`: iff standard output is a terminal.
		case terminalOnly
	}

	static let `default` = Self(
		keySGRParameters: "",
		keyStyling: .terminalOnly,
		leaderPattern: defaultLeaderPattern,
		keyValueSpacing: " ",
		itemSeparatorPattern: "",
	)

	/// Raw ANSI SGR parameters styling each key (e.g., `"1"` for bold, `"1;4"`
	/// for bold & underlined); empty means unstyled.
	let keySGRParameters: String
	let keyStyling: KeyStyling
	/// Repeated (truncating mid-repetition if needed, never padded) to fill each
	/// leader, aligning an item's values; never empty; `nil` means no leader,
	/// leaving an item's values unaligned.
	let leaderPattern: String?
	/// On each side of the leader (or once between the key & the value, iff there
	/// is no leader).
	let keyValueSpacing: String
	/// Repeated (truncating mid-repetition if needed, never padded) to fill the
	/// line between each pair of adjacent items; empty means a blank line; `nil`
	/// means no line.
	let itemSeparatorPattern: String?
}

/// Parses `--key-value`'s value (`key-value.md`'s `<key-value-config>`):
/// `<key-value-setting>+`, last wins per axis. Outer bare whitespace between
/// settings is ignored.
func parseKeyValueConfig(_ value: String) throws(KeyValueConfigParsingError) -> KeyValueConfig {
	var keySGRParameters = KeyValueConfig.default.keySGRParameters
	var keyStyling = KeyValueConfig.default.keyStyling
	var leaderPattern = KeyValueConfig.default.leaderPattern
	var keyValueSpacing = KeyValueConfig.default.keyValueSpacing
	var itemSeparatorPattern = KeyValueConfig.default.itemSeparatorPattern
	var input = value[...]
	while case let trimmed = input.drop(while: \.isWhitespace), let setting = trimmed.first {
		input = trimmed.dropFirst()
		switch setting {
		case "k":
			keySGRParameters = ""
		case "K":
			// `<sgr-parameters>` is not a `{text}` token, so it supports no escape
			// sequences; unlike `--table`'s `H`, `K` requires it
			let text = try parseOutputConfigSettingPayload(
				&input,
				supportsEscapeSequences: false,
				danglingEscapeError: KeyValueConfigParsingError.danglingEscape,
			)
			guard let sgrParameters = normalizedSGRParameters(text), !sgrParameters.isEmpty else {
				throw .invalidKeyStyle(text)
			}
			keySGRParameters = sgrParameters
		case "t":
			keyStyling = .terminalOnly
		case "a":
			keyStyling = .always
		case "l":
			leaderPattern = nil
		case "L":
			// `<leader-pattern>` is a non-empty text token: absent, its default `▁`
			// applies
			let pattern = try parseKeyValueSettingText(&input)
			leaderPattern = pattern.isEmpty ? defaultLeaderPattern : pattern
		case "c":
			keyValueSpacing = KeyValueConfig.default.keyValueSpacing
		case "C":
			keyValueSpacing = try parseKeyValueSettingText(&input)
		case "s":
			itemSeparatorPattern = nil
		case "S":
			itemSeparatorPattern = try parseKeyValueSettingText(&input)
		default:
			throw .invalidSetting(setting)
		}
	}
	return .init(
		keySGRParameters: keySGRParameters,
		keyStyling: keyStyling,
		leaderPattern: leaderPattern,
		keyValueSpacing: keyValueSpacing,
		itemSeparatorPattern: itemSeparatorPattern,
	)
}

// swiftlint:disable:next one_declaration_per_file
enum KeyValueConfigParsingError: Equatable, Error, CustomStringConvertible {
	case danglingEscape
	case invalidKeyStyle(String)
	case invalidSetting(Character)

	var description: String {
		switch self {
		case .danglingEscape:
			"Escape prefix '\\' at the end of --key-value's value"
		case let .invalidKeyStyle(sgrParameters):
			"Invalid key style (expected ANSI SGR parameters, e.g., \"1\" or \"1;4\"): \(sgrParameters)"
		case let .invalidSetting(setting):
			"Invalid --key-value <key-value-setting>: \(setting)"
		}
	}
}

/// Parses an uppercase `<key-value-setting>`'s `{text}` payload
/// (`<leader-pattern>`, `<key-value-spacing>`, or `<item-separator-pattern>`)
/// through its `<key-value-setting-termination>` via
/// `parseOutputConfigSettingPayload`.
private func parseKeyValueSettingText(_ input: inout Substring) throws(KeyValueConfigParsingError) -> String {
	try parseOutputConfigSettingPayload(
		&input,
		supportsEscapeSequences: true,
		danglingEscapeError: KeyValueConfigParsingError.danglingEscape,
	)
}

private let defaultLeaderPattern = "▁"
