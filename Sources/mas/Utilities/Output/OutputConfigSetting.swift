//
// OutputConfigSetting.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import Foundation

/// Parses an uppercase output config setting's payload (e.g., table.md's
/// `<separator-pattern>`) through its setting termination: up through (&
/// excluding) a `:` setting terminator, else through the end of the config (so
/// omitting the terminator anywhere but at the end swallows subsequent settings
/// into this payload). If `supportsEscapeSequences`, the payload is a `{text}`
/// token: it consumes its outer bare whitespace, and a `\` in it escapes the
/// next character (e.g., `\:`), an escape prefix at the end of the input
/// throwing `danglingEscapeError`; otherwise, a `\` is an ordinary character.
func parseOutputConfigSettingPayload<E: Error>(
	_ input: inout Substring,
	supportsEscapeSequences: Bool,
	danglingEscapeError: E,
) throws(E) -> String {
	var text = ""
	while let char = input.first, char != outputConfigSettingTerminator {
		input.removeFirst()
		guard char == escapePrefix, supportsEscapeSequences else {
			text.append(char)
			continue
		}
		guard let escaped = input.first else {
			throw danglingEscapeError
		}
		input.removeFirst()
		text.append(escaped)
	}
	if input.first == outputConfigSettingTerminator {
		input.removeFirst()
	}
	return text
}

/// Normalizes `<sgr-parameters>` text (table.md): `;`-separated non-negative
/// integers, ignoring the outer bare whitespace around each `<sgr-parameter>`;
/// empty text normalizes to empty. `nil` iff `text` is invalid.
func normalizedSGRParameters(_ text: String) -> String? {
	let sgrParameters = text.split(separator: ";", omittingEmptySubsequences: false)
		.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
	return sgrParameters == [""] || sgrParameters.allSatisfy { !$0.isEmpty && $0.allSatisfy(\.isASCIIDigit) }
		? sgrParameters.joined(separator: ";")
		: nil
}

/// Wraps `string` in the ANSI SGR escape sequences for `sgrParameters` iff
/// `sgrParameters` isn't empty & either `isAlwaysStyled` or standard output is
/// a terminal (table.md's `<header-styling-setting>`).
func styled(_ string: String, sgrParameters: String, isAlwaysStyled: Bool) -> String {
	!sgrParameters.isEmpty && (isAlwaysStyled || FileHandle.standardOutput.isTerminal)
		? "\u{1B}[\(sgrParameters)m\(string)\u{1B}[0m"
		: string
}

private let outputConfigSettingTerminator = Character(":")
