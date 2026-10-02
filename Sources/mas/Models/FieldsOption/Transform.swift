//
// Transform.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import BigInt
internal import Foundation

// MARK: - Transforms (fields-format.md)

/// A `<value-transform>`. Whether a given case is valid in a particular
/// pipeline is enforced at parse time, not by this type.
enum Transform: Hashable {
	// swiftlint:disable sorted_enum_cases
	case initialTitlecase
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

	/// Inserts the conventions' digit group separator between the digit groups of
	/// the field's integer part & replaces its `.` with the conventions' decimal
	/// separator. See `<number-format>` in fields-format.md for full semantics.
	case numberFormat(NumberConventions)

	case dateOnly
	/// Sets the output time zone; see `<time-zone>` in fields-format.md.
	case timeZone(TimeZone) // swiftlint:enable sorted_enum_cases

	/// This transform's kind, per its `<value-transform>` alternative.
	var kind: TransformKind {
		switch self {
		case .initialTitlecase, .lowercase, .trimWhitespace, .uppercase:
			.string
		case .absoluteValue, .round, .scale: // swiftformat:disable:this sortSwitchCases
			.number
		case .numberFormat:
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
		case .initialTitlecase:
			initialTitlecased(string)
		case .lowercase:
			string.lowercased()
		case .trimWhitespace:
			string.trimmingCharacters(in: .whitespacesAndNewlines)
		case .uppercase:
			string.uppercased()
		case .absoluteValue:
			string.hasPrefix("-") || string.hasPrefix("+") ? .init(string.dropFirst()) : string
		case let .numberFormat(conventions):
			conventions.formatted(string)
		case .round:
			rounded(string) ?? string
		case let .scale(radix, exponent, significantDigits, fractionalDigits):
			DecimalNumber(string)
				.flatMap { number in
					radixScaled(
						number,
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

/// `string` with its initial character titlecased: its 1st letter (excluding
/// uncased modifier letters), number, symbol, or private-use character, per
/// ICU's default titlecasing index adjustment. See `<initial-titlecase>` in
/// fields-format.md.
private func initialTitlecased(_ string: String) -> String {
	string.unicodeScalars.firstIndex(where: \.isInitialTitlecaseCandidate).map { index in
		var scalars = string.unicodeScalars
		scalars.replaceSubrange(index...index, with: scalars[index].properties.titlecaseMapping.unicodeScalars)
		return String(scalars)
	}
		?? string
}

private extension Unicode.Scalar { // swiftlint:disable:this file_types_order
	/// Whether ICU's default titlecasing index adjustment stops at this scalar.
	var isInitialTitlecaseCandidate: Bool {
		properties.generalCategory == .modifierLetter
			? properties.isCased
			: initialTitlecaseCandidateCategorySet.contains(properties.generalCategory)
	}
}

/// The general categories, other than modifier letter, at which ICU's default
/// titlecasing index adjustment stops: letters, numbers, symbols & private use.
private let initialTitlecaseCandidateCategorySet = Set([
	Unicode.GeneralCategory.currencySymbol,
	.decimalNumber,
	.letterNumber,
	.lowercaseLetter,
	.mathSymbol,
	.modifierSymbol,
	.otherLetter,
	.otherNumber,
	.otherSymbol,
	.privateUse,
	.titlecaseLetter,
	.uppercaseLetter,
])

/// `string`, a finite decimal number, rounded exactly to the nearest integer
/// (halves away from 0), in `string`'s notation: positional, or normalized
/// scientific with `string`'s exponent indicator & positive exponent sign
/// style. A leading `+` is retained; `-` is retained iff the result is nonzero.
/// Else `nil`.
private func rounded(_ string: String) -> String? {
	guard
		DecimalNumber(string) != nil,
		let match = string.wholeMatch(of: unsafe decimalNumberRegex),
		let significand = BigInt(match.2 + (match.3 ?? "")),
		let exponent = Int(match.5 ?? "0")
	else {
		return nil
	}
	let scale = exponent - (match.3?.count ?? 0) // |value| = significand × 10^scale
	let divisor = BigInt(10).power(max(-scale, 0))
	let (quotient, remainder) = significand.quotientAndRemainder(dividingBy: divisor)
	let digits = (quotient * BigInt(10).power(max(scale, 0)) + (2 * remainder >= divisor ? 1 : 0)).description
	return (match.1 == "-" && digits != "0" ? "-" : match.1 == "+" ? "+" : "") + (
		match.4.map { scientificNotation(of: digits, exponentIndicator: $0, isExponentPlusSigned: match.5?.first == "+") }
			?? digits
	)
}

/// The non-negative decimal integer `digits` in normalized scientific notation
/// (e.g., `1500` as `1.5e3`), with `exponentIndicator` before the exponent,
/// which is preceded by `+` iff `isExponentPlusSigned`.
private func scientificNotation(of digits: String, exponentIndicator: Substring, isExponentPlusSigned: Bool) -> String {
	let significandDigits = digits.prefix(1) + digits.dropFirst().reversed().drop { $0 == "0" }.reversed()
	let fraction = significandDigits.count > 1 ? "." + significandDigits.dropFirst() : ""
	return
		"\(significandDigits.prefix(1))\(fraction)\(exponentIndicator)\(isExponentPlusSigned ? "+" : "")\(digits.count - 1)"
}

private nonisolated(unsafe) let decimalNumberRegex = /([+-]?)([0-9]*)(?:\.([0-9]*))?(?:([eE])([+-]?[0-9]+))?/

/// The time zone a `<time-zone-code>` identifies: a case-insensitive IANA Time
/// Zone Database identifier, Foundation time zone abbreviation, UTC offset, or
/// `system`; else `nil`.
func timeZone(forCode code: String) -> TimeZone? {
	code.caseInsensitiveCompare("system") == .orderedSame
		? Environment.current.systemTimeZone
		: TimeZone.abbreviationDictionary[code.uppercased()].flatMap(TimeZone.init(identifier:))
			?? (FileManager.default.subpaths(atPath: "/usr/share/zoneinfo") ?? [])
			.first { $0.caseInsensitiveCompare(code) == .orderedSame }
			.flatMap(TimeZone.init(identifier:))
			?? utcOffsetTimeZone(code)
}

/// A `TimeZone` for a UTC offset `code` (`Z`, or an optional `UTC` / `GMT`
/// prefix, a sign, a 1- or 2-digit hour & an optional `:`-prefixed 2-digit
/// minute; case-insensitive), else `nil`.
private func utcOffsetTimeZone(_ code: String) -> TimeZone? {
	guard
		let match = code.wholeMatch(of: unsafe utcOffsetRegex),
		let hours = Int(match.2 ?? "0"),
		let minutes = Int(match.3 ?? "00"),
		minutes < 60
	else {
		return nil
	}
	return TimeZone(secondsFromGMT: (match.1 == "-" ? -1 : 1) * (hours * 3600 + minutes * 60))
}

private nonisolated(unsafe) let utcOffsetRegex = /(?i)z|(?:utc|gmt)?([+-])([0-9]{1,2})(?::([0-9]{2}))?/

/// `number` rendered per `scale`'s semantics (see its doc comment on
/// `Transform.scale`), computed exactly; `nil` iff `number`'s exponent is too
/// large to compute with.
private func radixScaled(
	_ number: DecimalNumber,
	radix: Int,
	exponent: Int,
	significantDigits: Int?,
	fractionalDigits: Int,
) -> String? {
	number.magnitudeFraction.map { numerator, denominator in
		let radix = BigInt(radix)
		var numerator = numerator
		var denominator = denominator * radix.power(exponent)
		if let significantDigits, numerator != 0 {
			// The rounding unit is `radix^unitExponent`
			let unitExponent = radixMagnitude(numerator, denominator, radix: radix) + 1 - significantDigits
			(numerator, denominator) = unitExponent >= 0
				? (roundedQuotient(numerator, denominator * radix.power(unitExponent)) * radix.power(unitExponent), 1)
				: (roundedQuotient(numerator * radix.power(-unitExponent), denominator), radix.power(-unitExponent))
		}
		let fractionalScale = radix.power(fractionalDigits)
		let (integerPart, fractionalPart) =
			roundedQuotient(numerator * fractionalScale, denominator).quotientAndRemainder(dividingBy: fractionalScale)
		let integerText = (number.isNegative && (integerPart != 0 || fractionalPart != 0) ? "-" : "")
			+ String(integerPart, radix: Int(radix))
		let fractionalText = String(fractionalPart, radix: Int(radix))
		return fractionalDigits > 0
			? "\(integerText).\(String(repeating: "0", count: fractionalDigits - fractionalText.count))\(fractionalText)"
			: integerText
	}
}

/// `floor(log_radix(numerator / denominator))`, for a positive fraction.
private func radixMagnitude(_ numerator: BigInt, _ denominator: BigInt, radix: BigInt) -> Int {
	let quotient = numerator / denominator
	guard quotient == 0 else {
		return String(quotient, radix: Int(radix)).count - 1
	}
	var magnitude = -1
	var scaled = numerator * radix
	while scaled < denominator {
		magnitude -= 1
		scaled *= radix
	}
	return magnitude
}

/// `numerator / denominator`, both non-negative, rounded to the nearest
/// integer, halves away from 0.
private func roundedQuotient(_ numerator: BigInt, _ denominator: BigInt) -> BigInt {
	let (quotient, remainder) = numerator.quotientAndRemainder(dividingBy: denominator)
	return quotient + (2 * remainder >= denominator ? 1 : 0)
}

extension Transform: CustomStringConvertible { // swiftlint:disable:this file_types_order
	var description: String {
		switch self {
		case .initialTitlecase:
			"initialTitlecase"
		case .lowercase:
			"lowercase"
		case .trimWhitespace:
			"trimWhitespace"
		case .uppercase:
			"uppercase"
		case .absoluteValue:
			"absoluteValue"
		case let .numberFormat(conventions):
			"""
			numberFormat(digitGroupSeparator: "\(conventions.digitGroupSeparator)", digitGroupSize: \
			\(conventions.digitGroupSize), secondaryDigitGroupSize: \(conventions.secondaryDigitGroupSize), \
			decimalSeparator: "\(conventions.decimalSeparator)")
			"""
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
