//
// Transform.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import Foundation

// MARK: - Transforms (fields-format.md)

/// A single `<transform-call>`'s `<transform>`. Whether a given case is valid
/// in a particular pipeline (`<string-transform-pipeline>`,
/// `<number-transform-pipeline>`, or `<date-transform-pipeline>`) is enforced
/// at parse time, not by this type.
enum Transform: Hashable {
	// swiftlint:disable sorted_enum_cases
	case capitalize
	case lowercase
	case trimWhitespace
	case uppercase

	case absoluteValue
	/// Inserts `separator` into the field's integer part every `digitCount`
	/// digits, counting from the right; a fractional part & leading `-` sign
	/// are left untouched. See `<group>` in fields-format.md for full
	/// semantics.
	case group(separator: String, digitCount: Int)
	case round
	/// Divides the field's value by `radix^exponent`, optionally rounds it to
	/// `significantDigits` total `radix` digits, then renders it in positional
	/// notation, base `radix`, with exactly `fractionalDigits` digits after the
	/// radix point. See `<scale>` in fields-format.md for full semantics.
	case scale(radix: Int, exponent: Int, significantDigits: Int?, fractionalDigits: Int)

	case dateOnly
	/// Sets the output time zone; see `<time-zone>` in fields-format.md.
	case timeZone(TimeZone) // swiftlint:enable sorted_enum_cases

	static let stringTransformSet = Set([Self.capitalize, .lowercase, .trimWhitespace, .uppercase])
	/// `group` & `scale` are parameterized & validated separately; see
	/// `parsed(name:kind:)`.
	static let numberTransformSet = Set([Self.absoluteValue, .round])
	static let dateTransformSet = Set([Self.dateOnly])

	/// Parses a bare `<transform>` `name` (its `<group-arguments>` /
	/// `<scale-arguments>`, for `group` / `scale`, included verbatim) valid for
	/// `kind`. Returns `nil` if `name` isn't a known transform for `kind`.
	static func parsed(name: String, kind: TransformKind) throws(ParsingError) -> Self? {
		if name == groupSimpleName {
			kind == .number ? .group(locale: .current) : nil
		} else if name.hasPrefix(groupNamePrefix), name.hasSuffix(argumentFence) {
			kind == .number ? try groupTransform(name: name) : nil
		} else if name.hasPrefix(scaleNamePrefix), name.hasSuffix(argumentFence) {
			kind == .number ? try scaleTransform(name: name) : nil
		} else if name.hasPrefix(timeZoneNamePrefix), name.hasSuffix(argumentFence) {
			kind == .date ? try timeZoneTransform(name: name) : nil
		} else {
			.init(simpleName: name).flatMap { kind.allowedTransformSet.contains($0) ? $0 : nil }
		}
	}

	/// Whether this is a `<terminal-number-transform>` (currently just `group`):
	/// its own output isn't itself a value another `<non-terminal-number-
	/// transform>` could meaningfully operate on, so the parser (`Format
	/// ReferenceParser.parse(_:)`) rejects anything following it in the same
	/// `<number-transform-pipeline>`.
	var isTerminalNumberTransform: Bool {
		if case .group = self {
			true
		} else {
			false
		}
	}

	/// Applies this transform to a string. `dateOnly` / `timeZone` are applied
	/// separately, by `DateSpec.formatted(_:)`, since they need the field's
	/// parsed `Date`, not just its rendered string.
	func applied(to string: String) -> String {
		switch self {
		case .capitalize:
			string.uppercasingFirst
		case .lowercase:
			string.lowercased()
		case .trimWhitespace:
			string.trimmingCharacters(in: .whitespacesAndNewlines)
		case .uppercase:
			string.uppercased()
		case .absoluteValue:
			Double(string).map { numberString(abs($0), matchingIntegerStyleOf: string) } ?? string
		case let .group(separator, digitCount):
			grouped(string, separator: separator, digitCount: digitCount)
		case .round:
			Double(string).map { .init(Int($0.rounded())) } ?? string
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

extension Transform {
	/// Resolves `locale`'s grouping separator & digit count into a `.group`
	/// transform (absent either, per `NumberFormatter`, which shouldn't happen
	/// for a real locale: `,` & `3`, matching the system locale's own usual
	/// values).
	static func group(locale: Locale) -> Self {
		let formatter = NumberFormatter()
		formatter.locale = locale
		formatter.numberStyle = .decimal
		return .group(separator: formatter.groupingSeparator ?? ",", digitCount: max(formatter.groupingSize, 1))
	}
}

/// Applies `<group>`'s grouping to `string`'s integer part (i.e., up to, but
/// not including, a literal `.`, if any): inserts `separator` every
/// `digitCount` digits, counting from the right. A leading `-` sign & any
/// fractional part are left untouched.
private func grouped(_ string: String, separator: String, digitCount: Int) -> String {
	let sign = string.hasPrefix("-") ? "-" : ""
	let unsigned = string.dropFirst(sign.count)
	let integerPart = unsigned.prefix { $0 != "." }
	let fractionalPart = unsigned[integerPart.endIndex...]
	guard integerPart.allSatisfy(\.isNumber), !integerPart.isEmpty else {
		return string
	}
	let grouped = stride(from: integerPart.count, to: 0, by: -digitCount)
		.map { end in
			let start = max(0, end - digitCount)
			return integerPart[integerPart.index(integerPart.startIndex, offsetBy: start)..<integerPart
				.index(integerPart.startIndex, offsetBy: end)]
		}
		.reversed()
		.joined(separator: separator)
	return sign + grouped + fractionalPart
}

private extension Transform {
	/// The bare (parameter-less) transform names, per fields-format.md.
	init?(simpleName name: String) {
		switch name {
		case "initialUppercase":
			self = .capitalize
		case "lowercase":
			self = .lowercase
		case "trimWhitespace":
			self = .trimWhitespace
		case "uppercase":
			self = .uppercase
		case "absoluteValue":
			self = .absoluteValue
		case "round":
			self = .round
		case "dateOnly":
			self = .dateOnly
		default:
			return nil
		}
	}
}

/// Parses `group`'s `<group-arguments>` (fenced by `argumentFence`) from
/// `name`, which must already carry both: either a bare locale name (no
/// `argumentSeparator`), or `groupSeparator,groupDigitCount` (exactly 1).
/// Neither `<group-locale-name>` nor `<group-separator>` support escaping
/// `argumentSeparator` / `argumentFence` (unlike most other `{text}` values in
/// this file): by the time a `<transform-call>`'s name reaches here, any
/// backslash escapes in it have already been resolved by the caller's
/// `parseEscapedText`, so there's no way to tell an escaped `,` from a literal
/// 1 this far downstream.
private func groupTransform(name: String) throws(ParsingError) -> Transform {
	let arguments = name.dropFirst(groupNamePrefix.count).dropLast(argumentFence.count)
	let parts = arguments.split(separator: argumentSeparator, omittingEmptySubsequences: false)
	switch parts.count {
	case 1 where !parts[0].isEmpty:
		return .group(locale: .init(identifier: .init(parts[0])))
	case 2:
		guard let digitCount = Int(parts[1]), digitCount >= 1 else {
			throw .invalidTransformArguments(name: name)
		}
		return .group(separator: .init(parts[0]), digitCount: digitCount)
	default:
		throw .invalidTransformArguments(name: name)
	}
}

/// Parses `timeZone`'s `<time-zone-arguments>` (`<time-zone-code>`, fenced by
/// `argumentFence`) from `name`: a case-insensitive IANA identifier,
/// abbreviation, UTC offset (e.g., `+05:30`), or `system`.
private func timeZoneTransform(name: String) throws(ParsingError) -> Transform {
	let code = String(name.dropFirst(timeZoneNamePrefix.count).dropLast(argumentFence.count))
	let identifier = TimeZone.knownTimeZoneIdentifiers.first { $0.caseInsensitiveCompare(code) == .orderedSame }
	let timeZone = code.caseInsensitiveCompare("system") == .orderedSame
		? .current
		: identifier
			.flatMap(TimeZone.init(identifier:)) ?? .init(abbreviation: code.uppercased()) ?? utcOffsetTimeZone(code)
	guard let timeZone else {
		throw .invalidTransformArguments(name: name)
	}
	return .timeZone(timeZone)
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

/// Parses `scale`'s `<scale-arguments>`
/// (`radix,exponent,[significantDigits],fractionalDigits`, fenced by
/// `argumentFence`) from `name`, which must already carry both.
private func scaleTransform(name: String) throws(ParsingError) -> Transform {
	let arguments = name.dropFirst(scaleNamePrefix.count)
		.dropLast(argumentFence.count)
		.split(separator: argumentSeparator, omittingEmptySubsequences: false)
	guard
		arguments.count == 4,
		let radix = Int(arguments[0]), (2...36).contains(radix),
		let exponent = Int(arguments[1]), exponent >= 0,
		let fractionalDigits = Int(arguments[3]), fractionalDigits >= 0
	else {
		throw .invalidTransformArguments(name: name)
	}
	return .scale(
		radix: radix,
		exponent: exponent,
		significantDigits: try parsedSignificantDigits(from: arguments[2], transformName: name),
		fractionalDigits: fractionalDigits,
	)
}

/// Parses `scale`'s optional `significantDigits` argument: `nil` for an empty
/// `text` (no cap), else a validated positive integer.
private func parsedSignificantDigits(from text: Substring, transformName: String) throws(ParsingError) -> Int? {
	if text.isEmpty {
		nil
	} else if let significantDigits = Int(text), significantDigits >= 1 {
		significantDigits
	} else {
		throw .invalidTransformArguments(name: transformName)
	}
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
	!original.contains(".") && value == value.rounded() ? .init(Int(value)) : .init(value)
}

extension Transform: CustomStringConvertible {
	var description: String {
		switch self {
		case .capitalize:
			"initialUppercase"
		case .lowercase:
			"lowercase"
		case .trimWhitespace:
			"trimWhitespace"
		case .uppercase:
			"uppercase"
		case .absoluteValue:
			"absoluteValue"
		case let .group(separator, digitCount):
			"group(separator: \"\(separator)\", digitCount: \(digitCount))"
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

let groupSimpleName = "group"
let groupNamePrefix = groupSimpleName + argumentFence
let scaleSimpleName = "scale"
let scaleNamePrefix = scaleSimpleName + argumentFence
let timeZoneSimpleName = "timeZone"
let timeZoneNamePrefix = timeZoneSimpleName + argumentFence
let argumentFence = ":"
let argumentSeparator = Character(",")
/// The only `<transform>`s whose own grammar defines a `:`-fenced argument
/// list; see `parseTransformName(_:terminatorSet:)`.
let fenceTakingSimpleNameSet = Set([groupSimpleName, scaleSimpleName, timeZoneSimpleName])
