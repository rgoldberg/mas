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
	/// Sets the output time zone & the `<reference-date>` (`nil` iff absent); see
	/// `<time-zone>` in fields-format.md.
	case timeZone(TimeZone, referenceDate: CivilDate?) // swiftlint:enable sorted_enum_cases

	/// This transform's kind, per its `<value-transform>` alternative.
	var kind: TransformKind {
		switch self {
		case .initialTitlecase, .lowercase, .trimWhitespace, .uppercase:
			.string
		case .absoluteValue, .round, .scale:
			.number
		case .numberFormat:
			.numberToString
		case .dateOnly, .timeZone:
			.date
		}
	}

	/// Applies this transform to a string; `nil` iff the string does not conform
	/// to this transform's input type (e.g., a number too large for `scale`).
	/// Date transforms are applied separately, by
	/// `ChronologicStyle.applying(_:)`, because they need the parsed chronologic
	/// value, not just its rendered string.
	func applied(to string: String) -> String? {
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
			DecimalNumber(string).flatMap { number in
				radixScaled(
					number,
					isPlusSigned: string.hasPrefix("+"),
					radix: radix,
					exponent: exponent,
					significantDigits: significantDigits,
					fractionalDigits: fractionalDigits,
				)
			}
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
		let exponent = BigInt(match.5 ?? "0")
	else {
		return nil
	}
	// |value| = significand × 10^scale; |result| = digits × 10^power, computed
	// without 10^|scale|, which a huge exponent makes too large: an integer value
	// is the result & a value less than 0.1 rounds to 0
	let scale = exponent - BigInt(match.3?.count ?? 0)
	let significandDigits = significand.description
	let (digits, power) = if significand == 0 || scale >= 0 {
		(significandDigits, significand == 0 ? 0 : scale)
	} else if -scale > significandDigits.count {
		("0", BigInt(0))
	} else {
		(roundedQuotient(significand, BigInt(10).power(Int(-scale))).description, BigInt(0))
	}
	return (match.1 == "-" && digits != "0" ? "-" : match.1 == "+" ? "+" : "") + (
		match.4.map { exponentIndicator in
			scientificNotation(
				of: digits,
				timesPowerOf10: power,
				exponentIndicator: exponentIndicator,
				isExponentPlusSigned: match.5?.first == "+",
			)
		}
			?? digits
	)
}

/// The non-negative decimal integer `digits` × 10^`power` in normalized
/// scientific notation (e.g., `15` × 10^2 as `1.5e3`), with `exponentIndicator`
/// before the exponent, which is preceded by `+` iff `isExponentPlusSigned`.
private func scientificNotation(
	of digits: String,
	timesPowerOf10 power: BigInt,
	exponentIndicator: Substring,
	isExponentPlusSigned: Bool,
) -> String {
	let significandDigits = digits.prefix(1) + digits.dropFirst().reversed().drop { $0 == "0" }.reversed()
	let fraction = significandDigits.count > 1 ? "." + significandDigits.dropFirst() : ""
	return """
		\(significandDigits.prefix(1))\(fraction)\(exponentIndicator)\(isExponentPlusSigned ? "+" : "")\
		\(BigInt(digits.count - 1) + power)
		"""
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
/// prefix, a sign, then either a 2-digit hour & a 2-digit minute, or a 1- or
/// 2-digit hour & an optional `:`-prefixed 2-digit minute; case-insensitive),
/// else `nil`.
private func utcOffsetTimeZone(_ code: String) -> TimeZone? {
	guard
		let match = code.wholeMatch(of: unsafe utcOffsetRegex),
		let hours = Int(match.2 ?? match.4 ?? "0"),
		let minutes = Int(match.3 ?? match.5 ?? "00"),
		minutes < 60
	else {
		return nil
	}
	return TimeZone(secondsFromGMT: (match.1 == "-" ? -1 : 1) * (hours * 3600 + minutes * 60))
}

private nonisolated(unsafe) let utcOffsetRegex =
	/(?i)z|(?:utc|gmt)?([+-])(?:([0-9]{2})([0-9]{2})|([0-9]{1,2})(?::([0-9]{2}))?)/

/// `number` rendered per `scale`'s semantics (see its doc comment on
/// `Transform.scale`), computed exactly, a leading `+` retained iff
/// `isPlusSigned` & a leading `-` iff the result is nonzero; `nil` iff the
/// rendering would have more than `maxScaledIntegerDigitCount` digits before
/// the radix point.
private func radixScaled(
	_ number: DecimalNumber,
	isPlusSigned: Bool,
	radix: Int,
	exponent: Int,
	significantDigits: Int?,
	fractionalDigits: Int,
) -> String? {
	// log_radix(|number| / radix^exponent), from |number| being at least
	// 10^(number.exponent - 1) & less than 10^number.exponent, to within `error`,
	// so that a result that is too large, or that renders as 0, is known without
	// computing it. Clamping number.exponent keeps the estimate finite without
	// changing either outcome
	let radixDigitsPerDecimalDigit = log(10) / log(Double(radix))
	let decimalMagnitude = min(max(Double(number.exponent), -1e300), 1e300)
	let estimate = (decimalMagnitude - 0.5) * radixDigitsPerDecimalDigit - Double(exponent)
	let error = 0.5 * radixDigitsPerDecimalDigit + 1 + (abs(decimalMagnitude) * 4 + Double(exponent)) * 1e-15
	guard estimate - error < Double(maxScaledIntegerDigitCount) else {
		return nil
	}
	let magnitude = ScaledMagnitude(
		number,
		dividedByRadix: radix,
		toThe: exponent,
		digitCount: maxScaledIntegerDigitCount + fractionalDigits + (significantDigits ?? 0) + 16,
	)
	let isZero = number.digits.isEmpty || estimate + error < Double(-2 - fractionalDigits)
	// The 1st rounding is to a multiple of radix^-unitExponent: per
	// `significantDigits`, else per `fractionalDigits`
	let unitExponent = isZero
		? fractionalDigits
		: significantDigits.map { $0 - 1 - magnitude.radixMagnitude(atLeast: Int((estimate - error).rounded(.down))) }
			?? fractionalDigits
	let roundedMagnitude = isZero ? 0 : BigInt(magnitude.rounded(timesRadixToThe: BigInt(unitExponent)))
	let radix = BigInt(radix)
	let (integerPart, fractionalPart) = (
		fractionalDigits >= unitExponent
			? roundedMagnitude * radix.power(fractionalDigits - unitExponent)
			: roundedQuotient(roundedMagnitude, radix.power(unitExponent - fractionalDigits)),
	)
	.quotientAndRemainder(dividingBy: radix.power(fractionalDigits))
	let integerDigits = String(integerPart, radix: Int(radix))
	let integerText = (number.isNegative && (integerPart != 0 || fractionalPart != 0) ? "-" : isPlusSigned ? "+" : "")
		+ integerDigits
	let fractionalText = String(fractionalPart, radix: Int(radix))
	return integerDigits.count > maxScaledIntegerDigitCount
		? nil
		: fractionalDigits > 0
			? "\(integerText).\(String(repeating: "0", count: fractionalDigits - fractionalText.count))\(fractionalText)"
			: integerText
}

/// The most digits that `scale` renders before the radix point.
private let maxScaledIntegerDigitCount = 100

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
		case let .timeZone(timeZone, referenceDate):
			"""
			timeZone:\(timeZone.identifier),\
			\(referenceDate?.iso8601Text ?? ""):
			"""
		}
	}
}

/// A `<value-transform>`'s kind.
enum TransformKind { // swiftlint:disable:this one_declaration_per_file
	case date
	case number
	case numberToString
	case string
}
