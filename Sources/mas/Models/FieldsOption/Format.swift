//
// Format.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import Foundation
internal import JSONAST

// MARK: - Format (fields-format.md)

/// A parsed `<format-block>`, `<success-block>`, or `<failure-block>`: either a
/// pipeline of `<*-transform-call>`s or a template. A `<format-block>`'s
/// `<format-transform-pipeline>` is not part of it: it is extracted into
/// `FieldSpec.justification` at parse time.
indirect enum Format: Equatable, Sendable {
	/// A `<*-pipeline>`'s value `<*-transform-call>`s, applied in order to the
	/// value the pipeline formats. Empty iff the pipeline consists solely of a
	/// `<format-transform-pipeline>`.
	case pipeline([TransformCall])
	/// A `<*-template>`'s elements.
	case template([TemplateElement])

	/// The default of an absent block or `<format-block>`: an empty string.
	static var empty: Self {
		.template(.init())
	}

	/// The standard default: `%i`. Fields needing a different one are configured
	/// by their display command, at the `FieldSpec` level, instead.
	// swiftlint:disable:next todo
	// TODO: a per-field, per-context user-configured default, once persisted
	//  fields configs exist
	static func `default`(fieldName _: String) -> Self {
		.template([.placeholder(.unconditional(.input, pipeline: .init()))])
	}
}

/// A `<*-transform-call>`: its `<value-transform>` & its `<coercion>` (or
/// `<number-coercion>`), if any.
struct TransformCall: Equatable { // swiftlint:disable:this one_declaration_per_file
	let transform: Transform
	let coercion: Coercion?
}

/// An element of a `<*-template>`.
enum TemplateElement: Equatable { // swiftlint:disable:this one_declaration_per_file
	/// A `<block-placeholder>`: the enclosing matcher's value, through
	/// `pipeline`.
	case blockPlaceholder(pipeline: [TransformCall])
	/// A `<placeholder>`.
	case placeholder(Placeholder)
	/// A `<template-text>`'s value.
	case text(String)
}

/// A `<placeholder>`.
enum Placeholder: Equatable { // swiftlint:disable:this one_declaration_per_file
	/// A `<nullary-scalar-conditional-placeholder>` or
	/// `<non-nullary-scalar-conditional-placeholder>`.
	case conditional(Matcher, ConditionalForm)
	/// A `<match-placeholder>`.
	case match([Branch], MatchForm)
	/// An `<unconditional-placeholder>`; `pipeline` is empty for a nullary one.
	case unconditional(UnconditionalPredicate, pipeline: [TransformCall])
}

/// An `<unconditional-placeholder>`'s or `<unconditional-branch>`'s predicate,
/// by its nullary letter.
enum UnconditionalPredicate: Character { // swiftlint:disable:this one_declaration_per_file
	case input = "i"
	case label = "l"
	case name = "k"
}

/// A scalar conditional matcher's `<coercion>` & `<predicate>`.
struct Matcher: Equatable { // swiftlint:disable:this one_declaration_per_file
	let predicate: Predicate
	let coercion: Coercion?
}

/// A scalar conditional `<predicate>`, by its nullary letter.
enum Predicate: Character { // swiftlint:disable:this one_declaration_per_file
	// swiftlint:disable sorted_enum_cases
	case boolean = "b"
	case chronologic = "c"
	case empty = "e"
	case `false` = "f"
	case null = "u"
	case number = "n"
	case string = "s"
	case `true` = "t"
	case version = "v"
	case whitespace = "w" // swiftlint:enable sorted_enum_cases
}

/// A `<coercion>`, with its `<number-coercion-arguments>`' values (their
/// defaults absent them, as for a boolean coercion, which has none).
struct Coercion: Hashable { // swiftlint:disable:this one_declaration_per_file
	/// A `<coercion>` without `<number-coercion-arguments>`.
	static let `default` = Self(numberConventions: .canonical, triviaPrefixRegex: .empty, triviaSuffixRegex: .empty)

	/// The conventions a number coercion parses a number's separators & digit
	/// group sizes per.
	let numberConventions: NumberConventions
	let triviaPrefixRegex: TriviaRegex
	let triviaSuffixRegex: TriviaRegex
}

/// A `<trivia-prefix-regex>` or `<trivia-suffix-regex>`, compared by its
/// pattern.
struct TriviaRegex: Hashable, @unchecked Sendable { // swiftlint:disable:this one_declaration_per_file
	/// The default, which matches only an empty string.
	static let empty = Self(pattern: "", regex: .init(/(?:)/))
	/// A regex that matches any string.
	static let any = Self(pattern: ".*", regex: .init(/.*/))

	static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.pattern == rhs.pattern
	}

	let pattern: String
	let regex: Regex<AnyRegexOutput>

	/// The regex for Swift Regex `pattern`, else `nil` iff `pattern` is invalid.
	init?(pattern: String) {
		guard let regex = try? Regex(pattern) else {
			return nil
		}
		self.init(pattern: pattern, regex: regex)
	}

	private init(pattern: String, regex: Regex<AnyRegexOutput>) {
		self.pattern = pattern
		self.regex = regex
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(pattern)
	}
}

/// What a scalar conditional placeholder evaluates to on success & on failure.
enum ConditionalForm: Equatable { // swiftlint:disable:this one_declaration_per_file
	/// Nullary (`%n`) or `<abort-on-failure>` (`%+N…+`): on success, `success`
	/// (the matcher's value iff `nil`, i.e., iff nullary); on failure, formatting
	/// aborts.
	case abortOnFailure(success: Format?)
	/// `<abort-on-success>` (`%-n` / `%-N…+`): on success, formatting aborts; on
	/// failure, `failure`.
	case abortOnSuccess(failure: Format)
	/// Binary (`%N…+…+`): on success, `success`; on failure, `failure`.
	case binary(success: Format, failure: Format)
}

/// What a `<match-placeholder>` evaluates to iff no branch returns a value.
enum MatchForm: Equatable { // swiftlint:disable:this one_declaration_per_file
	/// `%m`: formatting aborts.
	case abortOnNoMatch
	/// `%M`: `failure`.
	case binary(failure: Format)
}

/// A `<branch>`.
enum Branch: Equatable { // swiftlint:disable:this one_declaration_per_file
	/// A `<conditional-branch>`: iff `isNegated`, returns `block` (the field
	/// value iff `nil`, i.e., iff nullary) iff the matcher fails; otherwise,
	/// returns `block` (the matcher's value iff `nil`) iff the matcher succeeds.
	case conditional(Matcher, isNegated: Bool, block: Format?)
	/// An `<unconditional-branch>`, which always returns `block` (its predicate's
	/// value iff `nil`, i.e., iff nullary).
	case unconditional(UnconditionalPredicate, block: Format?)
}

// MARK: - Formatting errors

/// An error reported while formatting a value.
enum FormattingError: Equatable, Error, CustomStringConvertible { // swiftlint:disable:this one_declaration_per_file
	/// A transform without `<coercion>` was applied to an input that is not
	/// already of its input type.
	case transformInputTypeMismatch(transform: Transform, input: String)

	var description: String {
		switch self {
		case let .transformInputTypeMismatch(transform, input):
			"Transform \(transform) requires an input of its input type (<coercion> '.' coerces it): \(input)"
		}
	}
}

// MARK: - Evaluation

extension Format { // swiftlint:disable:this file_types_order
	/// Renders this format against `value` (`nil` iff the field does not exist
	/// for this item), producing the formatted value (fields-format.md "Value
	/// Types"), at its type, for any output format to render: e.g., `%i` renders
	/// `null` as `null`, while `(%i)` renders it as `"()"`. An empty string iff
	/// formatting aborts.
	func rendered(value: JSON.Node?, label: String, name: String) throws(FormattingError) -> JSON.Node {
		try evaluated(in: .init(input: value, label: label, name: name, matched: nil))?.node ?? .string("")
	}

	/// The evaluated value, or `nil` iff formatting aborts.
	fileprivate func evaluated(in context: FormatContext) throws(FormattingError) -> FormatValue? {
		switch self {
		case let .pipeline(calls):
			// A block's pipeline formats the enclosing matcher's value; a
			// `<format-block>`'s, the field value
			return try (context.matched ?? .input(context.input)).applying(calls)
		case let .template(elements):
			// A template that is solely 1 placeholder has that placeholder's value
			if let element = elements.first, elements.count == 1, element.isPlaceholder {
				return try element.evaluated(in: context)
			}
			var result = ""
			for element in elements {
				guard let evaluated = try element.evaluated(in: context) else {
					return nil
				}
				result += evaluated.string
			}
			return .string(result)
		}
	}
}

/// The context a format is evaluated in.
private struct FormatContext { // swiftlint:disable:this one_declaration_per_file
	let input: JSON.Node?
	let label: String
	let name: String
	/// The enclosing matcher's value, for a `<block-placeholder>`.
	let matched: FormatValue?

	func matching(_ matched: FormatValue) -> Self {
		.init(input: input, label: label, name: name, matched: matched)
	}
}

private extension TemplateElement { // swiftlint:disable:this file_types_order
	var isPlaceholder: Bool {
		switch self {
		case .blockPlaceholder, .placeholder:
			true
		case .text:
			false
		}
	}

	func evaluated(in context: FormatContext) throws(FormattingError) -> FormatValue? {
		switch self {
		case let .blockPlaceholder(pipeline):
			try (context.matched ?? .input(context.input)).applying(pipeline)
		case let .placeholder(placeholder):
			try placeholder.evaluated(in: context)
		case let .text(text):
			.string(text)
		}
	}
}

private extension Placeholder { // swiftlint:disable:this file_types_order
	func evaluated(in context: FormatContext) throws(FormattingError) -> FormatValue? {
		switch self {
		case let .conditional(matcher, form):
			let matched = matcher.matched(context.input, block: form.successBlock)
			return switch form {
			case let .abortOnFailure(success):
				if let matched {
					try success.evaluatedBlock(in: context.matching(matched), nullaryValue: matched)
				} else {
					nil
				}
			case let .abortOnSuccess(failure):
				if matched == nil {
					try failure.evaluated(in: context)
				} else {
					nil
				}
			case let .binary(success, failure):
				if let matched {
					try success.evaluated(in: context.matching(matched))
				} else {
					try failure.evaluated(in: context)
				}
			}
		case let .match(branches, form):
			for branch in branches {
				if case let .value(value) = try branch.evaluated(in: context) {
					return value
				}
			}
			return switch form {
			case .abortOnNoMatch:
				nil
			case let .binary(failure):
				try failure.evaluated(in: context)
			}
		case let .unconditional(predicate, pipeline):
			return try predicate.value(in: context).applying(pipeline)
		}
	}
}

/// What a `<branch>` returns.
private enum BranchOutcome { // swiftlint:disable:this one_declaration_per_file
	/// No value, so the next branch is tried.
	case noValue
	/// A value, which is `nil` iff formatting aborts.
	case value(FormatValue?)
}

private extension Branch { // swiftlint:disable:this file_types_order
	func evaluated(in context: FormatContext) throws(FormattingError) -> BranchOutcome {
		switch self {
		case let .conditional(matcher, isNegated, block):
			let matched = matcher.matched(context.input, block: isNegated ? nil : block)
			return if isNegated {
				matched == nil
					? .value(try block.evaluatedBlock(in: context, nullaryValue: .input(context.input)))
					: .noValue
			} else if let matched {
				.value(try block.evaluatedBlock(in: context.matching(matched), nullaryValue: matched))
			} else {
				.noValue
			}
		case let .unconditional(predicate, block):
			let value = predicate.value(in: context)
			return .value(try block.evaluatedBlock(in: context.matching(value), nullaryValue: value))
		}
	}
}

private extension Format? { // swiftlint:disable:this file_types_order
	/// This block's evaluated value, `nullaryValue` iff the enclosing matcher is
	/// nullary (i.e., has no block), or `nil` iff formatting aborts.
	func evaluatedBlock(in context: FormatContext, nullaryValue: FormatValue) throws(FormattingError) -> FormatValue? {
		switch self {
		case let .some(block):
			try block.evaluated(in: context)
		case .none:
			nullaryValue
		}
	}
}

private extension UnconditionalPredicate { // swiftlint:disable:this file_types_order
	func value(in context: FormatContext) -> FormatValue {
		switch self {
		case .input:
			.input(context.input)
		case .label:
			.string(context.label)
		case .name:
			.string(context.name)
		}
	}
}

private extension ConditionalForm { // swiftlint:disable:this file_types_order
	/// The block evaluated on success, iff any.
	var successBlock: Format? {
		switch self {
		case let .abortOnFailure(success):
			success
		case .abortOnSuccess:
			nil
		case let .binary(success, _):
			success
		}
	}
}

private extension Format { // swiftlint:disable:this file_types_order
	/// Whether this block applies `dateOnly` to its enclosing matcher's value.
	var appliesDateOnly: Bool {
		switch self {
		case let .pipeline(calls):
			calls.contains { $0.transform == .dateOnly }
		case let .template(elements):
			elements.contains { element in
				if case let .blockPlaceholder(pipeline) = element {
					pipeline.contains { $0.transform == .dateOnly }
				} else {
					false
				}
			}
		}
	}
}

extension Matcher { // swiftlint:disable:this file_types_order
	/// Whether `value` conforms to this matcher's predicate with its coercion.
	func conforms(_ value: JSON.Node?) -> Bool {
		matched(value, block: nil) != nil
	}

	/// This matcher's value iff it matches `value`, else `nil`. A time-only value
	/// has no date, so it fails a chronologic predicate whose `block` applies
	/// `dateOnly` to it.
	fileprivate func matched(_ value: JSON.Node?, block: Format?) -> FormatValue? {
		switch predicate {
		case .boolean:
			value.boolean(isCoerced: coercion != nil).map { .input(.bool($0)) }
		case .chronologic:
			FormatValue.chronologic(from: value, isCoerced: coercion != nil).flatMap { matched in
				if case .chronologic(.time, _) = matched, block?.appliesDateOnly == true {
					nil
				} else {
					matched
				}
			}
		case .empty:
			value.isNullish || value.jsonString?.isEmpty == true ? .string("") : nil
		case .false:
			value.boolean(isCoerced: coercion != nil) == false ? .input(.bool(false)) : nil
		case .null:
			value.isNullish ? .string("") : nil
		case .number:
			.number(from: value, coercion: coercion)
		case .string:
			value.jsonString.map(FormatValue.string)
		case .true:
			value.boolean(isCoerced: coercion != nil) == true ? .input(.bool(true)) : nil
		case .version:
			value.jsonString.flatMap { isVersion($0) ? .string($0) : nil }
		case .whitespace:
			value.isNullish || value.jsonString?.allSatisfy(\.isWhitespace) == true ? .string("") : nil
		}
	}
}

/// Whether `string` is a version: 1 or more `.`-separated components, each a
/// non-negative integer optionally followed by non-`.` characters.
func isVersion(_ string: String) -> Bool {
	string.split(separator: ".", omittingEmptySubsequences: false).allSatisfy { component in
		component.first.map { $0.isASCII && $0.isWholeNumber } ?? false
	}
}

/// A number & its trivia (both empty unless coerced with a trivia regex).
struct NumberWithTrivia { // swiftlint:disable:this one_declaration_per_file
	let number: DecimalNumber
	/// The number's text: a JSON number's literal, or a coerced number's
	/// canonical form.
	let text: String
	let triviaPrefix: Substring
	let triviaSuffix: Substring
}

/// `value` as a number, per `coercion`: a JSON number; with `coercion`, also a
/// string that `coercion` coerces to a number; else `nil`.
func numberWithTrivia(in value: JSON.Node?, coercion: Coercion?) -> NumberWithTrivia? {
	switch (value, coercion) {
	case let (.number(number), _):
		DecimalNumber("\(number)").map { .init(number: $0, text: "\(number)", triviaPrefix: "", triviaSuffix: "") }
	case let (.string(literal), coercion?):
		coercion.coercedNumber(in: literal.value).flatMap { text, triviaPrefix, triviaSuffix in
			DecimalNumber(text).map { .init(number: $0, text: text, triviaPrefix: triviaPrefix, triviaSuffix: triviaSuffix) }
		}
	default:
		nil
	}
}

extension Coercion { // swiftlint:disable:this file_types_order
	/// `string` coerced to a number: a trivia prefix (the shortest whole match of
	/// `triviaPrefixRegex` that a number succeeds), the longest number there (as
	/// a canonical number) & a trivia suffix (the rest of `string`, which must be
	/// a whole match of `triviaSuffixRegex`); else `nil`. See "Coercion" in
	/// fields-format.md.
	func coercedNumber(in string: String) -> (number: String, triviaPrefix: Substring, triviaSuffix: Substring)? {
		string.indices
			.lazy
			.compactMap { index in
				numberConventions.numberPrefix(of: string[index...]).flatMap { number, end in
					string[..<index].wholeMatch(of: triviaPrefixRegex.regex) == nil ? nil : (index, number, end)
				}
			}
			.first
			.flatMap { index, number, end in
				string[end...].wholeMatch(of: triviaSuffixRegex.regex) == nil
					? nil
					: (number, string[..<index], string[end...])
			}
	}
}

/// A chronologic value, per its form.
enum Chronologic: Equatable { // swiftlint:disable:this one_declaration_per_file
	/// An ISO-8601 date-only, at its start in the system time zone.
	case date(Date)
	/// An ISO-8601 datetime, or a Unix time.
	case datetime(Date)
	/// An ISO-8601 time-only.
	case time(TimeOfDay)
}

/// An ISO-8601 time-only's time of day.
struct TimeOfDay: Equatable { // swiftlint:disable:this one_declaration_per_file
	let hour: Int
	let minute: Int
	let second: Int
	/// Its fractional seconds, truncated to whole milliseconds.
	let millisecond: Int
	/// Its UTC offset's time zone, or `nil` iff it has none (i.e., it is in the
	/// system time zone).
	let timeZone: TimeZone?

	/// Its milliseconds since midnight UTC, normalized to UTC via its UTC offset
	/// (as UTC iff it has none) & wrapped into a single day.
	var utcMillisecondOfDay: Int {
		let millisecondsPerDay = 86_400_000
		let milliseconds =
			((hour * 60 + minute) * 60 + second - (timeZone?.secondsFromGMT() ?? 0)) * 1000 + millisecond
		return (milliseconds % millisecondsPerDay + millisecondsPerDay) % millisecondsPerDay
	}

	/// This time of day on the date `day` (its year, month & day), in its UTC
	/// offset, else in the system time zone; else `nil` iff that does not exist.
	func date(on day: DateComponents) -> Date? {
		DateComponents(
			calendar: .init(identifier: .gregorian),
			timeZone: timeZone ?? Environment.current.systemTimeZone,
			year: day.year,
			month: day.month,
			day: day.day,
			hour: hour,
			minute: minute,
			second: second,
		)
		.date
		.map { $0.addingTimeInterval(Double(millisecond) / 1000) }
	}
}

/// An ISO-8601 chronologic value's form.
enum ISO8601Form: CaseIterable { // swiftlint:disable:this one_declaration_per_file
	case date
	case datetime
	case time
}

/// `value` parsed as chronologic: a string as an ISO-8601 datetime, date-only,
/// or time-only, else, iff `isCoerced`, as a Unix time iff its entire content
/// is a decimal number; a number as a Unix time; else `nil`.
func chronologic(from value: JSON.Node?, isCoerced: Bool) -> Chronologic? {
	switch value {
	case let .number(number):
		DecimalNumber("\(number)").flatMap(unixTimeDate).map(Chronologic.datetime)
	case let .string(literal):
		iso8601ChronologicPrefix(of: literal.value[...], forms: Set(ISO8601Form.allCases))
			.flatMap { chronologic, end in end == literal.value.endIndex ? chronologic : nil }
			?? (isCoerced ? unixTimeDate(in: literal.value[...]).map(Chronologic.datetime) : nil)
	default:
		nil
	}
}

/// The longest ISO-8601 extended-format chronologic value of one of `forms` at
/// the start of `string` (whose every field is in range) & its end: a datetime
/// (its date & time separated by `T`, `t`, or a space, its seconds optional; in
/// its UTC offset, else in the system time zone), a date-only (at its start in
/// the system time zone), or a time-only; fractional seconds are truncated to
/// whole milliseconds. Else `nil`.
func iso8601ChronologicPrefix(of string: Substring, forms: Set<ISO8601Form>)
-> (chronologic: Chronologic, end: Substring.Index)? {
	guard let date = string.prefixMatch(of: unsafe iso8601DateRegex) else {
		return forms.contains(.time)
			? iso8601TimePrefix(of: string).map { time, end in (.time(time), end) }
			: nil
	}
	let day = DateComponents(year: Int(date.1), month: Int(date.2), day: Int(date.3))
	if
		forms.contains(.datetime),
		string[date.range.upperBound...].first.map("Tt ".contains) == true,
		let time = iso8601TimePrefix(of: string[string.index(after: date.range.upperBound)...], isSecondOptional: true),
		dateOnly(on: day, in: time.time.timeZone ?? Environment.current.systemTimeZone) != nil,
		let datetime = time.time.date(on: day)
	{
		return (.datetime(datetime), time.end)
	}
	return forms.contains(.date)
		? dateOnly(on: day, in: Environment.current.systemTimeZone).map { (.date($0), date.range.upperBound) }
		: nil
}

/// The start of `day` (its year, month & day) in `timeZone`, else `nil` iff
/// `day` is out of range.
private func dateOnly(on day: DateComponents, in timeZone: TimeZone) -> Date? {
	let components = DateComponents(
		calendar: .init(identifier: .gregorian),
		timeZone: timeZone,
		year: day.year,
		month: day.month,
		day: day.day,
	)
	return components.isValidDate ? components.date : nil
}

/// The ISO-8601 extended-format complete time (or, iff `isSecondOptional`, time
/// without seconds) at the start of `string` (whose every field is in range) &
/// its end; else `nil`.
private func iso8601TimePrefix(of string: Substring, isSecondOptional: Bool = false)
-> (time: TimeOfDay, end: Substring.Index)? {
	guard
		let match = string.prefixMatch(of: unsafe iso8601TimeRegex),
		let hour = Int(match.1),
		let minute = Int(match.2),
		let second = Int(match.3 ?? (isSecondOptional ? "0" : "")),
		hour < 24,
		minute < 60,
		second < 60
	else {
		return nil
	}
	let timeZone = match.5.flatMap(iso8601UTCOffsetTimeZone)
	guard match.5 == nil || timeZone != nil else {
		return nil
	}
	return (
		.init(
			hour: hour,
			minute: minute,
			second: second,
			millisecond: match.4.flatMap { Int($0.prefix(3).padding(toLength: 3, withPad: "0", startingAt: 0)) } ?? 0,
			timeZone: timeZone,
		),
		match.range.upperBound,
	)
}

private nonisolated(unsafe) let jsonNumberRegex = #/-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][-+]?[0-9]+)?/#
private nonisolated(unsafe) let iso8601DateRegex = #/([0-9]{4})-([0-9]{2})-([0-9]{2})/#
private nonisolated(unsafe) let iso8601TimeRegex =
	#/([0-9]{2}):([0-9]{2})(?::([0-9]{2})(?:[.,]([0-9]+))?)?([Zz]|[+-][0-9]{2}(?::?[0-9]{2})?)?/#

/// The time zone of an ISO-8601 UTC offset (`Z`, `z`, or a sign, a 2-digit hour
/// & an optional, optionally `:`-prefixed 2-digit minute), else `nil` iff it is
/// out of range.
private func iso8601UTCOffsetTimeZone(_ offset: Substring) -> TimeZone? {
	let digits = offset.dropFirst().filter(\.isASCIIDigit)
	let minutes = Int(digits.dropFirst(2)) ?? 0
	return minutes < 60
		? .init(
			secondsFromGMT: // swiftformat:disable:next indent
				(offset.first == "-" ? -1 : 1) * ((.init(digits.prefix(2)).map { $0 * 3600 } ?? 0) + minutes * 60),
		)
		: nil
}

/// `string`'s Unix time date iff its entire content is a decimal number, else
/// `nil`.
func unixTimeDate(in string: Substring) -> Date? {
	(try? /[-+]?(?:[0-9]+(?:\.[0-9]+)?|\.[0-9]+)(?:[eE][-+]?[0-9]+)?/.wholeMatch(in: string)) != nil
		? DecimalNumber(string).flatMap(unixTimeDate)
		: nil
}

/// The Unix time `seconds`' date, truncated to whole milliseconds; else `nil`
/// iff it is out of range.
func unixTimeDate(_ seconds: DecimalNumber) -> Date? {
	seconds.flooredThousandths.map { Date(timeIntervalSince1970: Double($0) / 1000) }
}

// MARK: - Values

/// A value being formatted.
private enum FormatValue { // swiftlint:disable:this one_declaration_per_file
	/// A chronologic value, rendered per `style`.
	case chronologic(Chronologic, style: ChronologicStyle)
	/// The field value, at its original type.
	case input(JSON.Node?)
	/// A number, between its trivia (both empty unless coerced with a trivia
	/// regex).
	case number(String, triviaPrefix: Substring, triviaSuffix: Substring)
	/// A string.
	case string(String)

	/// The value parsed as chronologic, per `isCoerced`; else `nil`.
	static func chronologic(from value: JSON.Node?, isCoerced: Bool) -> Self? {
		mas.chronologic(from: value, isCoerced: isCoerced).map { .chronologic($0, style: .init()) }
	}

	/// The value as a number, per `coercion`; else `nil`.
	static func number(from value: JSON.Node?, coercion: Coercion?) -> Self? {
		numberWithTrivia(in: value, coercion: coercion).map { number in
			.number(number.text, triviaPrefix: number.triviaPrefix, triviaSuffix: number.triviaSuffix)
		}
	}

	/// The value as an output node, at its type iff JSON supports it (a number
	/// iff its text, trivia included, is JSON number syntax), else as a string.
	var node: JSON.Node {
		switch self {
		case .chronologic, .string:
			.string(string)
		case let .input(node):
			node ?? .null
		case .number:
			string.wholeMatch(of: unsafe jsonNumberRegex).map { _ in .number(.fallback(string)) } ?? .string(string)
		}
	}

	/// The rendered value, coerced to a string.
	var string: String {
		switch self {
		case let .chronologic(chronologic, style):
			style.formatted(chronologic)
		case let .input(node):
			node?.stringValue ?? ""
		case let .number(number, triviaPrefix, triviaSuffix):
			triviaPrefix + number + triviaSuffix
		case let .string(string):
			string
		}
	}

	private var isString: Bool {
		switch self {
		case .chronologic, .number:
			false
		case let .input(node):
			node.jsonString != nil
		case .string:
			true
		}
	}

	/// This value transformed by `calls`, or `nil` iff a coercion fails
	/// (formatting aborts).
	func applying(_ calls: [TransformCall]) throws(FormattingError) -> Self? {
		var value = self
		for call in calls {
			guard let transformed = try value.applying(call) else {
				return nil
			}
			value = transformed
		}
		return value
	}

	private func applying(_ call: TransformCall) throws(FormattingError) -> Self? {
		switch call.transform.kind {
		case .chronologic:
			guard case let .chronologic(chronologic, style)? = try coercedChronologic(for: call) else {
				return nil
			}
			// A time-only value has no date, so it does not conform to `dateOnly`'s
			// input type
			guard case .time = chronologic, call.transform == .dateOnly else {
				return .chronologic(chronologic, style: style.applying(call.transform))
			}
			guard call.coercion != nil else {
				throw .transformInputTypeMismatch(transform: call.transform, input: string)
			}
			return nil
		case .number, .numberToString:
			guard case let .number(number, triviaPrefix, triviaSuffix)? = try coercedNumber(for: call) else {
				return nil
			}
			let transformed = call.transform.applied(to: number)
			guard transformed != nil || call.coercion != nil else {
				throw .transformInputTypeMismatch(transform: call.transform, input: string)
			}
			return transformed.map { transformed in
				call.transform.kind == .numberToString
					? .string(triviaPrefix + transformed + triviaSuffix)
					: .number(transformed, triviaPrefix: triviaPrefix, triviaSuffix: triviaSuffix)
			}
		case .string:
			guard call.coercion != nil || isString else {
				throw .transformInputTypeMismatch(transform: call.transform, input: string)
			}
			return call.transform.applied(to: string).map(Self.string)
		}
	}

	/// This value as chronologic iff it conforms to the chronologic predicate,
	/// else `nil` iff `call` has `<coercion>` (formatting aborts).
	private func coercedChronologic(for call: TransformCall) throws(FormattingError) -> Self? {
		if case .chronologic = self {
			return self
		}
		let chronologic = if case let .input(node) = self {
			Self.chronologic(from: node, isCoerced: call.coercion != nil)
		} else {
			Self.chronologic(from: .string(string), isCoerced: call.coercion != nil)
		}
		guard chronologic != nil || call.coercion != nil else {
			throw .transformInputTypeMismatch(transform: call.transform, input: string)
		}
		return chronologic
	}

	/// This value as a number, coerced iff `call` has `<number-coercion>` (`nil`
	/// iff that coercion fails).
	private func coercedNumber(for call: TransformCall) throws(FormattingError) -> Self? {
		switch self {
		case let .input(.number(number)):
			return .number("\(number)", triviaPrefix: "", triviaSuffix: "")
		case .number:
			return self
		default:
			guard let coercion = call.coercion else {
				throw .transformInputTypeMismatch(transform: call.transform, input: string)
			}
			return .number(from: .string(string), coercion: coercion)
		}
	}
}

/// How a chronologic value is rendered: ISO-8601, per input (date-only,
/// datetime, or time-only), in the system time zone, unless modified by
/// chronologic transforms. A date-only input's date ignores time zones; a
/// time-only input is rendered in a time zone as if on a reference date.
private struct ChronologicStyle: Equatable { // swiftlint:disable:this one_declaration_per_file
	/// The current date in the system time zone.
	private static var currentDay: DateComponents {
		var calendar = Calendar(identifier: .gregorian)
		calendar.timeZone = Environment.current.systemTimeZone
		return calendar.dateComponents([.year, .month, .day], from: Environment.current.now())
	}

	/// `date`, which is at a whole millisecond, rendered in `timeZone` as `form`;
	/// a datetime or time-only includes 3-digit fractional seconds iff its
	/// milliseconds are nonzero.
	private static func formatted(_ date: Date, in timeZone: TimeZone, as form: ISO8601Form) -> String {
		let milliseconds = (date.timeIntervalSince1970 * 1000).rounded()
		let includesFractionalSeconds = milliseconds.truncatingRemainder(dividingBy: 1000) != 0
		let style = Date.ISO8601FormatStyle(
			timeZoneSeparator: .colon,
			includingFractionalSeconds: includesFractionalSeconds,
			timeZone: timeZone,
		)
		// `date`'s `Double` may be slightly less than its millisecond, to which
		// `style` truncates, so half a millisecond later is formatted
		let formattedDate = Date(timeIntervalSince1970: (milliseconds + 0.5) / 1000)
		return switch form {
		case .date:
			style.year().month().day().format(formattedDate)
		case .datetime:
			style.format(formattedDate)
		case .time:
			style.time(includingFractionalSeconds: includesFractionalSeconds)
				.timeZone(separator: .colon)
				.format(formattedDate)
		}
	}

	var isDateOnly = false
	var timeZone = TimeZone?.none
	/// The last `timeZone`'s `<reference-date>`, iff any; else the current date
	/// in the system time zone.
	var referenceDate = DateComponents?.none

	/// This style modified by a chronologic `transform`: `dateOnly` renders only
	/// the date; `timeZone` sets the output time zone & the reference date (the
	/// last one wins).
	func applying(_ transform: Transform) -> Self {
		var style = self
		switch transform {
		case .dateOnly:
			style.isDateOnly = true
		case let .timeZone(timeZone, referenceDate):
			style.timeZone = timeZone
			style.referenceDate = referenceDate
		default:
			break
		}
		return style
	}

	/// `chronologic` rendered per this style.
	func formatted(_ chronologic: Chronologic) -> String {
		let systemTimeZone = Environment.current.systemTimeZone
		return switch chronologic {
		case let .date(date):
			Self.formatted(date, in: systemTimeZone, as: .date)
		case let .datetime(date):
			Self.formatted(date, in: timeZone ?? systemTimeZone, as: isDateOnly ? .date : .datetime)
		case let .time(time):
			time.date(on: referenceDate ?? Self.currentDay).map { date in
				Self.formatted(date, in: timeZone ?? systemTimeZone, as: .time)
			}
				?? ""
		}
	}
}

private extension JSON.Node? {
	var isNullish: Bool {
		switch self {
		case nil, .some(.null):
			true
		default:
			false
		}
	}

	/// The string iff this is a JSON string.
	var jsonString: String? {
		if case let .string(literal) = self {
			literal.value
		} else {
			nil
		}
	}

	/// The boolean iff this is a JSON boolean or, iff `isCoerced`, a string that
	/// is `true` or `false`, verbatim.
	func boolean(isCoerced: Bool) -> Bool? { // swiftlint:disable:this discouraged_optional_boolean
		switch self {
		case let .bool(bool):
			bool
		case let .string(literal) where isCoerced:
			["false": false, "true": true][literal.value]
		default:
			nil
		}
	}
}
