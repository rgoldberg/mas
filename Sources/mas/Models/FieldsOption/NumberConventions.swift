//
// NumberConventions.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import Foundation
private import Synchronization

// MARK: - Number conventions (fields-format.md)

/// A number's digit group separator, digit group sizes & decimal separator, per
/// `<number-format-arguments>`.
struct NumberConventions: Hashable {
	/// fields.md's canonical number formatting: a `.` decimal separator, a `,`
	/// digit group separator & a digit group size of 3.
	static let canonical = Self(
		digitGroupSeparator: ",",
		digitGroupSize: 3,
		secondaryDigitGroupSize: 0,
		decimalSeparator: ".",
	)

	let digitGroupSeparator: String
	/// The primary digit group's size; `0` inserts no separators (& accepts digit
	/// groups of any size).
	let digitGroupSize: Int
	/// Each secondary digit group's size; `0` uses `digitGroupSize`.
	let secondaryDigitGroupSize: Int
	let decimalSeparator: String

	/// The size of each secondary digit group.
	private var effectiveSecondaryDigitGroupSize: Int {
		secondaryDigitGroupSize > 0 ? secondaryDigitGroupSize : digitGroupSize
	}
}

extension NumberConventions {
	/// `locale`'s conventions (absent either separator, per `NumberFormatter`,
	/// which should not happen for a real locale: the canonical one).
	init(locale: Locale) {
		self = numberConventionsByLocale.withLock { conventionsByLocale in
			if let conventions = conventionsByLocale[locale] {
				return conventions
			}
			let formatter = NumberFormatter()
			formatter.locale = locale
			formatter.numberStyle = .decimal
			let conventions = Self(
				digitGroupSeparator: formatter.groupingSeparator ?? Self.canonical.digitGroupSeparator,
				digitGroupSize: formatter.groupingSize,
				secondaryDigitGroupSize: formatter.secondaryGroupingSize,
				decimalSeparator: formatter.decimalSeparator ?? Self.canonical.decimalSeparator,
			)
			conventionsByLocale[locale] = conventions
			return conventions
		}
	}

	/// `number`, a canonical number (an optional sign, ASCII digits, an optional
	/// `.` & fractional part & an optional exponent), with `digitGroupSeparator`
	/// between its integer part's digit groups & its `.` replaced by
	/// `decimalSeparator`. See `numberFormat` in fields-format.md.
	func formatted(_ number: String) -> String {
		let sign = number.first.map { $0 == "-" || $0 == "+" } == true ? number.prefix(1) : ""
		let unsigned = number.dropFirst(sign.count)
		let integerPart = unsigned.prefix(while: \.isASCIIDigit)
		let rest = unsigned[integerPart.endIndex...]
		return sign + grouped(integerPart) + (rest.first == "." ? decimalSeparator + rest.dropFirst() : rest)
	}

	/// The canonical form & end of the longest number at the start of `string`
	/// (an optional sign, an integer part, an optional `decimalSeparator` &
	/// fractional part & an optional exponent; the integer part may be omitted
	/// iff the fractional part is present); else `nil`. The canonical form has no
	/// `+` sign (neither leading nor in its exponent), no `-` sign for 0, no
	/// leading `0`s in its integer part (except a sole `0`), no trailing `0`s in
	/// its fractional part & no `.` without a fractional part, but retains any
	/// exponent.
	func numberPrefix(of string: Substring) -> (number: String, end: Substring.Index)? {
		var rest = string
		let sign = rest.first.flatMap { $0 == "-" || $0 == "+" ? $0 : nil }
		if sign != nil {
			rest.removeFirst()
		}
		let integerPart = integerPart(of: rest)
		if let integerPart {
			rest = rest[integerPart.end...]
		}
		let fractionalPart = fractionalPart(of: rest)
		if let fractionalPart {
			rest = rest[fractionalPart.endIndex...]
		}
		guard integerPart != nil || fractionalPart != nil else {
			return nil
		}
		let integerDigits = integerPart.map { String($0.digits.drop { $0 == "0" }) } ?? ""
		let fractionalDigits = fractionalPart.map { String($0.reversed().drop { $0 == "0" }.reversed()) } ?? ""
		var number = (sign == "-" && !(integerDigits.isEmpty && fractionalDigits.isEmpty) ? "-" : "")
			+ (integerDigits.isEmpty ? "0" : integerDigits)
			+ (fractionalDigits.isEmpty ? "" : "." + fractionalDigits)
		if let exponent = exponent(of: rest) {
			number += exponent.filter { $0 != "+" }
			rest = rest[exponent.endIndex...]
		}
		return (number, rest.startIndex)
	}

	/// The value & end of the grouped number at the start of `string` (a run of
	/// digits split into digit groups by `digitGroupSeparator`, optionally
	/// followed by `decimalSeparator` & a fractional part, then optionally by an
	/// exponent); else `nil`. See `<grouped-numeric>` in fields.md.
	func groupedNumberPrefix(of string: Substring) -> (number: DecimalNumber, end: Substring.Index)? {
		integerPart(of: string).flatMap { integerPart in
			let fractionalPart = fractionalPart(of: string[integerPart.end...])
			let exponent = exponent(of: string[(fractionalPart?.endIndex ?? integerPart.end)...])
			return DecimalNumber(integerPart.digits + (fractionalPart.map { "." + $0 } ?? "") + (exponent ?? ""))
				.map { number in (number, exponent?.endIndex ?? fractionalPart?.endIndex ?? integerPart.end) }
		}
	}

	/// `digits` with `digitGroupSeparator` between its digit groups, counting
	/// from its least significant digit.
	private func grouped(_ digits: Substring) -> String {
		guard digitGroupSize > 0 else {
			return .init(digits)
		}
		var groups = [Substring]()
		var end = digits.endIndex
		var size = digitGroupSize
		while digits.distance(from: digits.startIndex, to: end) > size {
			let start = digits.index(end, offsetBy: -size)
			groups.append(digits[start..<end])
			end = start
			size = effectiveSecondaryDigitGroupSize
		}
		groups.append(digits[..<end])
		return groups.reversed().joined(separator: digitGroupSeparator)
	}

	/// The digits (without separators) & end of the longest integer part at the
	/// start of `string`, whose digit groups may be separated by
	/// `digitGroupSeparator` only between digit groups of the given sizes; else
	/// `nil`.
	private func integerPart(of string: Substring) -> (digits: String, end: Substring.Index)? {
		let firstGroup = string.prefix(while: \.isASCIIDigit)
		guard !firstGroup.isEmpty else {
			return nil
		}
		var integerPart = (digits: String(firstGroup), end: firstGroup.endIndex)
		guard digitGroupSize == 0 || firstGroup.count <= effectiveSecondaryDigitGroupSize else {
			return integerPart
		}
		var digits = integerPart.digits
		var rest = string[firstGroup.endIndex...]
		while !digitGroupSeparator.isEmpty, rest.hasPrefix(digitGroupSeparator) {
			let group = rest.dropFirst(digitGroupSeparator.count).prefix(while: \.isASCIIDigit)
			guard !group.isEmpty else {
				break
			}
			digits += group
			rest = rest[group.endIndex...]
			if digitGroupSize == 0 || group.count == digitGroupSize {
				integerPart = (digits, group.endIndex)
			}
			guard digitGroupSize == 0 || group.count == effectiveSecondaryDigitGroupSize else {
				break
			}
		}
		return integerPart
	}

	/// The exponent (an `e` or `E` exponent indicator, an optional sign & digits)
	/// iff `string` starts with one, else `nil`.
	private func exponent(of string: Substring) -> Substring? {
		guard let exponentIndicator = string.first, exponentIndicator == "e" || exponentIndicator == "E" else {
			return nil
		}
		let exponentSign = string.dropFirst().prefix { $0 == "-" || $0 == "+" }.prefix(1)
		let exponentDigits = string[exponentSign.endIndex...].prefix(while: \.isASCIIDigit)
		return exponentDigits.isEmpty ? nil : string[..<exponentDigits.endIndex]
	}

	/// The fractional part's digits iff `string` starts with `decimalSeparator`
	/// followed by digits, else `nil`.
	private func fractionalPart(of string: Substring) -> Substring? {
		guard string.hasPrefix(decimalSeparator) else {
			return nil
		}
		let digits = string.dropFirst(decimalSeparator.count).prefix(while: \.isASCIIDigit)
		return digits.isEmpty ? nil : digits
	}
}

private let numberConventionsByLocale = Mutex([Locale: NumberConventions]())

// MARK: - Arguments (fields-format.md)

/// Parses an argument list's `count` arguments, up to (but not including) its
/// `terminator` (e.g., its closing `<argument-fence>`), or the end of the
/// input. Each argument ignores its outer bare whitespace & is absent (`nil`)
/// iff it is then empty; trailing `<argument-separator>`s whose succeeding
/// arguments are all absent may be omitted.
///
/// - Parameters:
///   - isLastArgumentSeparatorTerminated: Whether an `<argument-separator>`
///     terminates the last argument (reporting `invalidArgumentsError`) instead
///     of being part of it.
///   - invalidArgumentsError: The error reported for too many arguments.
func parseArguments(
	_ input: inout Substring,
	count: Int,
	terminator: Character,
	isLastArgumentSeparatorTerminated: Bool,
	invalidArgumentsError: ParsingError,
) throws(ParsingError) -> [String?] {
	var arguments = [String?]()
	while true {
		let text = try parseEscapedText(
			&input,
			terminatorSet: arguments.count == count - 1 && !isLastArgumentSeparatorTerminated
				? [terminator]
				: [argumentSeparator, terminator],
		)
		arguments.append(text.isEmpty ? nil : text)
		guard input.first == argumentSeparator else {
			break
		}
		guard arguments.count < count else {
			throw invalidArgumentsError
		}
		input.removeFirst()
	}
	return arguments + [String?](repeating: nil, count: count - arguments.count)
}

/// `argument` as a `{non-negative integer}`, else `nil`.
func nonNegativeInteger(_ argument: String) -> Int? {
	argument.allSatisfy(\.isASCIIDigit) ? .init(argument) : nil
}

/// The conventions that `<number-format-arguments>`' `arguments` (absent ones
/// being `nil`) give: each absent argument defaults to the base conventions:
/// those of the locale that `<locale-identifier>` identifies, or, absent it,
/// `defaultBaseConventions`.
///
/// - Throws: `invalidArgumentsError` for an invalid argument, or iff the digit
///   group separator equals the decimal separator.
func numberConventions(
	from arguments: ArraySlice<String?>,
	defaultBaseConventions: NumberConventions,
	invalidArgumentsError: ParsingError,
) throws(ParsingError) -> NumberConventions {
	let arguments = Array(arguments)
	let baseConventions = try arguments[0].map { identifier throws(ParsingError) in
		NumberConventions(locale: try locale(forIdentifier: identifier))
	}
		?? defaultBaseConventions
	func size(at index: Int, default: Int) throws(ParsingError) -> Int {
		guard let argument = arguments[index] else {
			return `default`
		}
		guard let size = nonNegativeInteger(argument) else {
			throw invalidArgumentsError
		}
		return size
	}
	let conventions = NumberConventions(
		digitGroupSeparator: arguments[1] ?? baseConventions.digitGroupSeparator,
		digitGroupSize: try size(at: 2, default: baseConventions.digitGroupSize),
		secondaryDigitGroupSize: try size(at: 3, default: baseConventions.secondaryDigitGroupSize),
		decimalSeparator: arguments[4] ?? baseConventions.decimalSeparator,
	)
	guard conventions.digitGroupSeparator != conventions.decimalSeparator else {
		throw invalidArgumentsError
	}
	return conventions
}

/// The locale that a `<locale-identifier>` (ICU or BCP 47) identifies: the
/// system locale for `system`.
func locale(forIdentifier identifier: String) throws(ParsingError) -> Locale {
	guard identifier != systemLocaleIdentifier else {
		return .current
	}
	let icuIdentifier = Locale.identifier(.icu, from: identifier)
	guard Locale.availableIdentifiers.contains(icuIdentifier) else {
		throw .invalidLocaleIdentifier(identifier)
	}
	return .init(identifier: icuIdentifier)
}

extension Character {
	var isASCIIDigit: Bool {
		isASCII && isWholeNumber
	}
}

// MARK: - Constants

let argumentFence = Character(":")
let argumentSeparator = Character(",")

private let systemLocaleIdentifier = "system"
