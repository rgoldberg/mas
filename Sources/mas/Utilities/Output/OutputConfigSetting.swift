//
// OutputConfigSetting.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import Foundation

/// Parses an uppercase output config setting's `{string}` payload (e.g.,
/// table.md's `<separator-pattern>`) through its setting termination via
/// `parseOutputConfigSettingPayloadCharacters`, consuming its outer bare
/// whitespace.
func parseOutputConfigSettingPayload<E: Error>(_ input: inout Substring, danglingEscapeError: E) throws(E) -> String {
	String(
		try parseOutputConfigSettingPayloadCharacters(&input, danglingEscapeError: danglingEscapeError).map(\.character),
	)
}

/// Parses a `<styling-specifier>` payload (table.md) through its setting
/// termination via `parseOutputConfigSettingPayloadCharacters`, ignoring its
/// outer bare whitespace; a bare ASCII letter in it throws
/// `invalidStylingSpecifierError` of the payload's text.
func parseStylingSpecifier<E: Error>(
	_ input: inout Substring,
	danglingEscapeError: E,
	invalidStylingSpecifierError: (String) -> E,
) throws(E) -> String {
	let characters = try parseOutputConfigSettingPayloadCharacters(&input, danglingEscapeError: danglingEscapeError)
	let stylingSpecifier = String(
		characters
			.drop { $0.isBare && $0.character.isWhitespace }
			.reversed()
			.drop { $0.isBare && $0.character.isWhitespace }
			.reversed()
			.map(\.character),
	)
	guard !characters.contains(where: { $0.isBare && $0.character.isASCII && $0.character.isLetter }) else {
		throw invalidStylingSpecifierError(String(characters.map(\.character)))
	}
	return stylingSpecifier
}

/// Wraps `string` in `sequences` around `specifier` iff `specifier` is not
/// empty & either `isAlwaysStyled` or standard output is a terminal (table.md's
/// `<styling-setting>`): `sequences.prefix`, `specifier` & `sequences.suffix`
/// precede `string`; `sequences.reset` follows it.
func styled(_ string: String, specifier: String, sequences: StylingSequences, isAlwaysStyled: Bool) -> String {
	!specifier.isEmpty && (isAlwaysStyled || FileHandle.standardOutput.isTerminal)
		? sequences.prefix + specifier + sequences.suffix + string + sequences.reset
		: string
}

/// Parses an uppercase output config setting's `{string}` payload through its
/// setting termination: up through (& excluding) a bare `:` setting terminator,
/// else through the end of the config (so omitting the terminator anywhere but
/// at the end swallows subsequent settings into this payload). A `\` in it
/// escapes the next character (e.g., `\:`), an escape prefix at the end of the
/// input throwing `danglingEscapeError`. Each character is paired with whether
/// it is bare.
private func parseOutputConfigSettingPayloadCharacters<E: Error>(
	_ input: inout Substring,
	danglingEscapeError: E,
) throws(E) -> [(character: Character, isBare: Bool)] {
	var characters = [(character: Character, isBare: Bool)]()
	while let char = input.first, char != outputConfigSettingTerminator {
		input.removeFirst()
		guard char == escapePrefix else {
			characters.append((char, true))
			continue
		}
		guard let escaped = input.first else {
			throw danglingEscapeError
		}
		input.removeFirst()
		characters.append((escaped, false))
	}
	if input.first == outputConfigSettingTerminator {
		input.removeFirst()
	}
	return characters
}

private let outputConfigSettingTerminator = Character(":")
