//
// Transform.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import Foundation

// MARK: - Transforms (fields-format.md)

/// A `<value-transform>`. Whether a given case is valid in a particular
/// pipeline is enforced at parse time, not by this type.
enum Transform: Hashable {
	// swiftlint:disable sorted_enum_cases
	case initialUppercase
	case lowercase
	case trimWhitespace
	case uppercase

	case absoluteValue
	case round
	/// Divides the field's value by `radix^exponent`, optionally rounds it to
	/// `significantDigits` total `radix` digits, then renders it in positional
	/// notation, base `radix`, with exactly `fractionalDigits` digits after the
	/// radix point. See `<scale>` in fields-format.md for full semantics.
	case scale(radix: Int, exponent: Int, significantDigits: Int?, fractionalDigits: Int)

	/// Inserts `digitGroupSeparator` into the field's integer part every
	/// `digitGroupDigitCount` digits, counting from its least significant digit;
	/// a fractional part & leading `-` sign are left untouched. See `<group>` in
	/// fields-format.md for full semantics.
	case group(digitGroupSeparator: String, digitGroupDigitCount: Int)

	case dateOnly
	/// Sets the output time zone; see `<time-zone>` in fields-format.md.
	case timeZone(TimeZone) // swiftlint:enable sorted_enum_cases

	/// This transform's kind, per its `<value-transform>` alternative.
	var kind: TransformKind {
		switch self {
		case .initialUppercase, .lowercase, .trimWhitespace, .uppercase:
			.string
		case .absoluteValue, .round, .scale: // swiftformat:disable:this sortSwitchCases
			.number
		case .group:
			.numberToString
		case .dateOnly, .timeZone:
			.chronologic
		}
	}

	/// Applies this transform to a string. Chronologic transforms are applied
	/// separately, by `ChronologicStyle.applying(_:)`, since they need the
	/// field's parsed `Date`, not just its rendered string.
	func applied(to string: String) -> String {
		switch self {
		case .initialUppercase:
			string.uppercasingFirst
		case .lowercase:
			string.lowercased()
		case .trimWhitespace:
			string.trimmingCharacters(in: .whitespacesAndNewlines)
		case .uppercase:
			string.uppercased()
		case .absoluteValue:
			Double(string).map { numberString(abs($0), matchingIntegerStyleOf: string) } ?? string
		case let .group(digitGroupSeparator, digitGroupDigitCount):
			grouped(string, digitGroupSeparator: digitGroupSeparator, digitGroupDigitCount: digitGroupDigitCount)
		case .round:
			Double(string).map { numberString($0.rounded(), matchingIntegerStyleOf: "") } ?? string
		case let .scale(radix, exponent, significantDigits, fractionalDigits):
			Double(string).map { rawValue in
				radixScaled(
					rawValue,
					radix: radix,
					exponent: exponent,
					significantDigits: significantDigits,
					fractionalDigits: fractionalDigits,
				)
			}
				?? string
		case .dateOnly, .timeZone:
			string // Unreachable here; see doc comment above
		}
	}
}

extension Transform { // swiftlint:disable:this file_types_order
	/// Resolves `locale`'s grouping separator & digit count into a `.group`
	/// transform (absent either, per `NumberFormatter`, which shouldn't happen
	/// for a real locale: `,` & `3`, matching the system locale's own usual
	/// values).
	static func group(locale: Locale) -> Self {
		let formatter = NumberFormatter()
		formatter.locale = locale
		formatter.numberStyle = .decimal
		return .group(
			digitGroupSeparator: formatter.groupingSeparator ?? ",",
			digitGroupDigitCount: max(formatter.groupingSize, 1),
		)
	}
}

/// Applies `<group>`'s grouping to `string`'s integer part (i.e., up to, but
/// not including, a literal `.`, if any): inserts `digitGroupSeparator` every
/// `digitGroupDigitCount` digits, counting from its least significant digit. A
/// leading `-` sign & any fractional part are left untouched.
private func grouped(_ string: String, digitGroupSeparator: String, digitGroupDigitCount: Int) -> String {
	let sign = string.hasPrefix("-") ? "-" : ""
	let unsigned = string.dropFirst(sign.count)
	let integerPart = unsigned.prefix { $0 != "." }
	let fractionalPart = unsigned[integerPart.endIndex...]
	guard integerPart.allSatisfy(\.isNumber), !integerPart.isEmpty else {
		return string
	}
	let grouped = stride(from: integerPart.count, to: 0, by: -digitGroupDigitCount)
		.map { end in
			let start = max(0, end - digitGroupDigitCount)
			return integerPart[integerPart.index(integerPart.startIndex, offsetBy: start)..<integerPart
				.index(integerPart.startIndex, offsetBy: end)]
		}
		.reversed()
		.joined(separator: digitGroupSeparator)
	return sign + grouped + fractionalPart
}

/// The time zone a `<time-zone-code>` identifies: a case-insensitive IANA
/// identifier, abbreviation, UTC offset (e.g., `+05:30`), or `system`; else
/// `nil`.
func timeZone(forCode code: String) -> TimeZone? {
	code.caseInsensitiveCompare("system") == .orderedSame
		? .current
		: TimeZone.knownTimeZoneIdentifiers
			.first { $0.caseInsensitiveCompare(code) == .orderedSame }
			.flatMap(TimeZone.init(identifier:))
			?? .init(abbreviation: code.uppercased())
			?? utcOffsetTimeZone(code)
}

/// A `TimeZone` for a UTC offset `code` (`+HH`, `+HHMM`, or `+HH:MM`, with
/// either sign), else `nil`.
private func utcOffsetTimeZone(_ code: String) -> TimeZone? {
	guard let sign = code.first, sign == "+" || sign == "-" else {
		return nil
	}
	let digits = code.dropFirst().filter(\.isNumber)
	guard digits.count == 2 || digits.count == 4, let hours = Int(digits.prefix(2)) else {
		return nil
	}
	let minutes = Int(digits.dropFirst(2)) ?? 0
	return TimeZone(secondsFromGMT: (sign == "-" ? -1 : 1) * (hours * 3600 + minutes * 60))
}

/// Renders `rawValue` per `scale`'s semantics (see its doc comment on
/// `Transform.scale`).
private func radixScaled(
	_ rawValue: Double,
	radix: Int,
	exponent: Int,
	significantDigits: Int?,
	fractionalDigits: Int,
) -> String {
	let radixDouble = Double(radix)
	var value = rawValue / pow(radixDouble, Double(exponent))
	if let significantDigits, value != 0 {
		let unit = pow(radixDouble, .init(Int(floor(log(abs(value)) / log(radixDouble))) + 1 - significantDigits))
		value = (value / unit).rounded() * unit
	}
	let fractionalScale = pow(radixDouble, Double(fractionalDigits))
	guard abs(value) * fractionalScale < maxExactInteger else {
		return .init(value) // Too large to render in positional notation via `Int`
	}
	let scaledMagnitude = Int((abs(value) * fractionalScale).rounded())
	let divisor = Int(fractionalScale.rounded())
	let integerPart = String(scaledMagnitude / divisor, radix: radix)
	let sign = value < 0 && scaledMagnitude != 0 ? "-" : ""
	let fractionalText = String(scaledMagnitude % divisor, radix: radix)
	return fractionalDigits > 0
		? "\(sign)\(integerPart).\(String(repeating: "0", count: fractionalDigits - fractionalText.count))\(fractionalText)"
		: sign + integerPart
}

/// Formats `value`, printing it as a plain integer (no decimal point) iff
/// `original` (the un-transformed input string) didn't itself have a decimal
/// point & `value` is integral, e.g., `absoluteValue` on `"-5"` yields `"5"`,
/// not `"5.0"`, but on `"-5.0"` yields `"5.0"`.
private func numberString(_ value: Double, matchingIntegerStyleOf original: String) -> String {
	!original.contains(".") && value == value.rounded() && abs(value) < maxExactInteger ? .init(Int(value)) : .init(value)
}

/// The magnitude below which every integral `Double` is exactly an `Int`.
private let maxExactInteger = 9_007_199_254_740_992.0

extension Transform: CustomStringConvertible { // swiftlint:disable:this file_types_order
	var description: String {
		switch self {
		case .initialUppercase:
			"initialUppercase"
		case .lowercase:
			"lowercase"
		case .trimWhitespace:
			"trimWhitespace"
		case .uppercase:
			"uppercase"
		case .absoluteValue:
			"absoluteValue"
		case let .group(digitGroupSeparator, digitGroupDigitCount):
			"group(digitGroupSeparator: \"\(digitGroupSeparator)\", digitGroupDigitCount: \(digitGroupDigitCount))"
		case .round:
			"round"
		case let .scale(radix, exponent, significantDigits, fractionalDigits):
			"""
			scale(radix: \(radix), exponent: \(exponent), significantDigits: \(significantDigits, default: "nil"), \
			fractionalDigits: \(fractionalDigits))
			"""
		case .dateOnly:
			"dateOnly"
		case let .timeZone(timeZone):
			"timeZone:\(timeZone.identifier):"
		}
	}
}

/// A `<value-transform>`'s kind.
enum TransformKind { // swiftlint:disable:this one_declaration_per_file
	case chronologic
	case number
	case numberToString
	case string
}
