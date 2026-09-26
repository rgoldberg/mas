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
/// `<format-transform-pipeline>` isn't part of it: it's extracted into
/// `FieldSpec.justification` at parse time.
indirect enum Format: Equatable {
	/// A `<*-pipeline>`'s value `<*-transform-call>`s, applied in order to the
	/// value the pipeline formats. Empty iff the pipeline consists solely of a
	/// `<format-transform-pipeline>`.
	case pipeline([TransformCall])
	/// A `<*-template>`'s elements.
	case template([TemplateElement])

	/// The standard default: `%i`. Fields needing a different one are configured
	/// by their display command, at the `FieldSpec` level, instead.
	// swiftlint:disable:next todo
	// TODO: a per-field, per-context user-configured default, once persisted
	//  fields configs exist.
	static func `default`(fieldName _: String) -> Self {
		.template([.placeholder(.unconditional(.input, pipeline: .init()))])
	}

	/// A `<format-block>`'s direct default: the nullary placeholder for
	/// `typeDeterminant`'s type & coercion.
	static func nullaryPlaceholder(for typeDeterminant: TypeDeterminant) -> Self {
		.template(
			[
				.placeholder(
					typeDeterminant.type == .any
						? .unconditional(.input, pipeline: .init())
						: .conditional(
							.init(predicate: typeDeterminant.type.nullaryPredicate, coercion: typeDeterminant.coercion),
							.abortOnFailure(success: nil),
						),
				),
			],
		)
	}
}

/// A `<*-transform-call>`: its `<value-transform>` & whether it has
/// `<strict-coercion>`.
struct TransformCall: Equatable { // swiftlint:disable:this one_declaration_per_file
	let transform: Transform
	let isCoerced: Bool
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

/// A `<coercion>`.
enum Coercion: Equatable { // swiftlint:disable:this one_declaration_per_file
	case lenient
	case strict
}

/// What a scalar conditional placeholder evaluates to on success & on
/// failure.
enum ConditionalForm: Equatable { // swiftlint:disable:this one_declaration_per_file
	/// Nullary (`%n`) or `<abort-on-failure>` (`%+N…+`): on success, `success`
	/// (the matcher's value iff `nil`); on failure, formatting aborts.
	case abortOnFailure(success: Format?)
	/// `<abort-on-success>` (`%-n` / `%-N…+`): on success, formatting aborts;
	/// on failure, `failure` (`""` iff `nil`).
	case abortOnSuccess(failure: Format?)
	/// Binary (`%N…+…+`): on success, `success` (the matcher's value iff
	/// `nil`); on failure, `failure` (`""` iff `nil`).
	case binary(success: Format?, failure: Format?)
}

/// What a `<match-placeholder>` evaluates to iff no branch returns a value.
enum MatchForm: Equatable { // swiftlint:disable:this one_declaration_per_file
	/// `%m`: formatting aborts.
	case abortOnNoMatch
	/// `%M`: `failure` (`""` iff `nil`).
	case binary(failure: Format?)
}

/// A `<branch>`.
enum Branch: Equatable { // swiftlint:disable:this one_declaration_per_file
	/// A `<conditional-branch>`: iff `isNegated`, returns `block` (the field
	/// value iff `nil`) iff the matcher fails; otherwise, returns `block` (the
	/// matcher's value iff `nil`) iff the matcher succeeds.
	case conditional(Matcher, isNegated: Bool, block: Format?)
	/// An `<unconditional-branch>`, which always returns `block` (its
	/// predicate's value iff `nil`).
	case unconditional(UnconditionalPredicate, block: Format?)
}

// MARK: - Types

/// A `<predicate>`'s or `<value-transform>`'s type, in ascending specificity.
enum FieldType: Comparable { // swiftlint:disable:this one_declaration_per_file
	case any // swiftlint:disable sorted_enum_cases
	case string
	case boolean
	case number
	case version
	case chronologic // swiftlint:enable sorted_enum_cases
}

/// A field's type determinant's type & coercion.
struct TypeDeterminant: Equatable { // swiftlint:disable:this one_declaration_per_file
	static let any = Self(type: .any, coercion: nil)

	let type: FieldType
	let coercion: Coercion?
}

extension Format { // swiftlint:disable:this file_types_order
	/// This format's type determinant: the 1st matcher or transform of the most
	/// specific type (including every branch), or `.any` iff there's none.
	var typeDeterminant: TypeDeterminant {
		typeDeterminants.reduce(TypeDeterminant.any) { $1.type > $0.type ? $1 : $0 }
	}

	/// Every matcher's & transform's type determinant, in order.
	fileprivate var typeDeterminants: [TypeDeterminant] {
		switch self {
		case let .pipeline(calls):
			calls.map(\.typeDeterminant)
		case let .template(elements):
			elements.flatMap { element in
				switch element {
				case let .blockPlaceholder(pipeline):
					pipeline.map(\.typeDeterminant)
				case let .placeholder(placeholder):
					placeholder.typeDeterminants
				case .text:
					[TypeDeterminant]()
				}
			}
		}
	}
}

private extension Placeholder { // swiftlint:disable:this file_types_order
	var typeDeterminants: [TypeDeterminant] {
		switch self {
		case let .conditional(matcher, form):
			[matcher.typeDeterminant] + form.blocks.flatMap(\.typeDeterminants)
		case let .match(branches, form):
			branches.flatMap(\.typeDeterminants) + form.blocks.flatMap(\.typeDeterminants)
		case let .unconditional(_, pipeline):
			pipeline.map(\.typeDeterminant)
		}
	}
}

private extension ConditionalForm { // swiftlint:disable:this file_types_order
	var blocks: [Format] {
		switch self {
		case let .abortOnFailure(success):
			[success].compactMap(\.self)
		case let .abortOnSuccess(failure):
			[failure].compactMap(\.self)
		case let .binary(success, failure):
			[success, failure].compactMap(\.self)
		}
	}
}

private extension MatchForm { // swiftlint:disable:this file_types_order
	var blocks: [Format] {
		switch self {
		case .abortOnNoMatch:
			.init()
		case let .binary(failure):
			[failure].compactMap(\.self)
		}
	}
}

private extension Branch { // swiftlint:disable:this file_types_order
	var typeDeterminants: [TypeDeterminant] {
		switch self {
		case let .conditional(matcher, _, block):
			[matcher.typeDeterminant] + (block?.typeDeterminants ?? .init())
		case let .unconditional(_, block):
			block?.typeDeterminants ?? .init()
		}
	}
}

private extension Matcher { // swiftlint:disable:this file_types_order
	var typeDeterminant: TypeDeterminant {
		.init(type: predicate.type, coercion: coercion)
	}
}

extension Predicate { // swiftlint:disable:this file_types_order
	/// This predicate's `type:` comment part.
	var type: FieldType {
		switch self {
		case .boolean, .false, .true: // swiftformat:disable:this sortSwitchCases
			.boolean
		case .chronologic:
			.chronologic
		case .empty, .null, .whitespace: // swiftformat:disable:this sortSwitchCases
			.any
		case .number:
			.number
		case .string:
			.string
		case .version:
			.version
		}
	}
}

private extension FieldType { // swiftlint:disable:this file_types_order
	/// The nullary predicate whose type this is; `.any` has none (its nullary
	/// placeholder is `%i`, which is unconditional).
	var nullaryPredicate: Predicate {
		switch self {
		case .any, .string: // swiftformat:disable:this sortSwitchCases
			.string
		case .boolean:
			.boolean
		case .chronologic:
			.chronologic
		case .number:
			.number
		case .version:
			.version
		}
	}
}

private extension TransformCall { // swiftlint:disable:this file_types_order
	/// This call's transform's `type:` comment part, except that a coerced
	/// `<string-transform>` is "any".
	var typeDeterminant: TypeDeterminant {
		switch transform.kind {
		case .chronologic:
			.init(type: .chronologic, coercion: isCoerced ? .strict : nil)
		case .number, .numberToString: // swiftformat:disable:this sortSwitchCases
			.init(type: .number, coercion: isCoerced ? .strict : nil)
		case .string:
			isCoerced ? .any : .init(type: .string, coercion: nil)
		}
	}
}

// MARK: - Formatting errors

/// An error reported while formatting a value.
enum FormattingError: Equatable, Error, CustomStringConvertible { // swiftlint:disable:this one_declaration_per_file
	/// A transform without `<strict-coercion>` was applied to an input that
	/// isn't already of its input type.
	case transformInputTypeMismatch(transform: Transform, input: String)

	var description: String {
		switch self {
		case let .transformInputTypeMismatch(transform, input):
			"Transform \(transform) requires an input of its input type (<strict-coercion> '.' coerces it): \(input)"
		}
	}
}

// MARK: - Evaluation

extension Format { // swiftlint:disable:this file_types_order
	private var isPassthrough: Bool {
		switch self {
		case let .pipeline(calls):
			calls.isEmpty
		case let .template(elements):
			elements == [.placeholder(.unconditional(.input, pipeline: .init()))]
		}
	}

	/// Renders this format against `value` (`nil` iff the field doesn't exist
	/// for this item), producing the node to display / embed in output. A
	/// format that is solely `%i` (or `%I` without a pipeline), or a pipeline
	/// without any value transforms, passes the original node through unchanged
	/// (so JSON output preserves the value's type); anything else produces a
	/// string, which is empty iff formatting aborts.
	func rendered(value: JSON.Node?, label: String, name: String) throws(FormattingError) -> JSON.Node {
		isPassthrough
			? value ?? .null
			: .string(try evaluated(in: .init(input: value, label: label, name: name, matched: nil)) ?? "")
	}

	/// The evaluated string, or `nil` iff formatting aborts.
	fileprivate func evaluated(in context: FormatContext) throws(FormattingError) -> String? {
		switch self {
		case let .pipeline(calls):
			// A block's pipeline formats the enclosing matcher's value; a
			// `<format-block>`'s, the field value
			return try (context.matched ?? .input(context.input)).applying(calls)?.string
		case let .template(elements):
			var result = ""
			for element in elements {
				guard let evaluated = try element.evaluated(in: context) else {
					return nil
				}
				result += evaluated
			}
			return result
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
	func evaluated(in context: FormatContext) throws(FormattingError) -> String? {
		switch self {
		case let .blockPlaceholder(pipeline):
			try (context.matched ?? .input(context.input)).applying(pipeline)?.string
		case let .placeholder(placeholder):
			try placeholder.evaluated(in: context)
		case let .text(text):
			text
		}
	}
}

private extension Placeholder { // swiftlint:disable:this file_types_order
	func evaluated(in context: FormatContext) throws(FormattingError) -> String? {
		switch self {
		case let .conditional(matcher, form):
			let matched = matcher.matched(context.input)
			return switch form {
			case let .abortOnFailure(success):
				if let matched {
					try success?.evaluated(in: context.matching(matched)) ?? matched.string
				} else {
					nil
				}
			case let .abortOnSuccess(failure):
				if matched == nil {
					try failure?.evaluated(in: context) ?? ""
				} else {
					nil
				}
			case let .binary(success, failure):
				if let matched {
					try success?.evaluated(in: context.matching(matched)) ?? matched.string
				} else {
					try failure?.evaluated(in: context) ?? ""
				}
			}
		case let .match(branches, form):
			for branch in branches {
				if let evaluated = try branch.evaluated(in: context) {
					return evaluated
				}
			}
			return switch form {
			case .abortOnNoMatch:
				nil
			case let .binary(failure):
				try failure?.evaluated(in: context) ?? ""
			}
		case let .unconditional(predicate, pipeline):
			return try predicate.value(in: context).applying(pipeline)?.string
		}
	}
}

private extension Branch { // swiftlint:disable:this file_types_order
	/// The branch's value, or `nil` iff it returns none (the next branch is
	/// tried); a branch's block aborting is indistinguishable from no value.
	func evaluated(in context: FormatContext) throws(FormattingError) -> String? {
		switch self {
		case let .conditional(matcher, isNegated, block):
			let matched = matcher.matched(context.input)
			return if isNegated {
				matched == nil ? try block?.evaluated(in: context) ?? FormatValue.input(context.input).string : nil
			} else if let matched {
				try block?.evaluated(in: context.matching(matched)) ?? matched.string
			} else {
				nil
			}
		case let .unconditional(predicate, block):
			let value = predicate.value(in: context)
			return try block?.evaluated(in: context.matching(value)) ?? value.string
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

extension Matcher { // swiftlint:disable:this file_types_order
	/// Whether `value` conforms to this matcher's predicate with its coercion.
	func conforms(_ value: JSON.Node?) -> Bool {
		matched(value) != nil
	}

	/// This matcher's value iff it matches `value`, else `nil`.
	fileprivate func matched(_ value: JSON.Node?) -> FormatValue? {
		switch predicate {
		case .boolean:
			value.boolean(isCoerced: coercion != nil).map { .input(.bool($0)) }
		case .chronologic:
			.chronologic(from: value)
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

/// A number & its trivia (both empty unless leniently coerced).
struct NumberWithTrivia { // swiftlint:disable:this one_declaration_per_file
	let number: Double
	let triviaPrefix: Substring
	let triviaSuffix: Substring
}

/// `value` as a number, per `coercion`: a JSON number; with
/// `<strict-coercion>`, also a string whose entire content parses as a number;
/// with `<lenient-coercion>`, also a string containing exactly 1 number,
/// between trivia; else `nil`.
func numberWithTrivia(in value: JSON.Node?, coercion: Coercion?) -> NumberWithTrivia? {
	switch (value, coercion) {
	case let (.number(number), _):
		Double("\(number)").map { .init(number: $0, triviaPrefix: "", triviaSuffix: "") }
	case let (.string(literal), .lenient):
		lenientNumberRange(in: literal.value).flatMap { range in
			Double(literal.value[range].filter { $0 != "," }).map { number in
				.init(
					number: number,
					triviaPrefix: literal.value[..<range.lowerBound],
					triviaSuffix: literal.value[range.upperBound...],
				)
			}
		}
	case let (.string(literal), .strict):
		decimalNumber(in: literal.value).map { .init(number: $0, triviaPrefix: "", triviaSuffix: "") }
	default:
		nil
	}
}

/// `value` parsed as chronologic: an ISO-8601 datetime, then an ISO-8601
/// date-only (in the system time zone), then a Unix epoch (seconds) numeric
/// timestamp; else `nil`.
func chronologicDate(from value: JSON.Node?) -> Date? {
	chronologicDateAndIsDateOnly(from: value)?.date
}

private func chronologicDateAndIsDateOnly(from value: JSON.Node?) -> (date: Date, isDateOnly: Bool)? {
	switch value {
	case let .number(number):
		Double("\(number)").map { (.init(timeIntervalSince1970: $0), false) }
	case let .string(literal):
		(try? Date(literal.value, strategy: .iso8601)).map { ($0, false) }
			?? (try? Date(
				literal.value,
				strategy: Date.ISO8601FormatStyle(timeZone: Environment.current.systemTimeZone).year().month().day(),
			))
			.map { ($0, true) }
			?? decimalNumber(in: literal.value).map { (.init(timeIntervalSince1970: $0), false) }
	default:
		nil
	}
}

/// `string`'s number iff its entire content is a decimal number, else `nil`.
private func decimalNumber(in string: String) -> Double? {
	(try? /[-+]?(?:\d+(?:\.\d+)?|\.\d+)(?:[eE][-+]?\d+)?/.wholeMatch(in: string)) != nil ? Double(string) : nil
}

/// The range of `string`'s sole number, or `nil` iff `string` doesn't contain
/// exactly 1 number.
private func lenientNumberRange(in string: String) -> Range<String.Index>? {
	let matches = string.matches(of: /[-+]?(?:\d{1,3}(?:,\d{3})+|\d+)(?:\.\d+)?|[-+]?\.\d+/)
	return matches.count == 1 ? matches.first?.range : nil
}

// MARK: - Values

/// A value being formatted.
private enum FormatValue { // swiftlint:disable:this one_declaration_per_file
	/// A chronologic value, rendered per `style`.
	case chronologic(Date, style: ChronologicStyle)
	/// The field value, at its original type.
	case input(JSON.Node?)
	/// A number, between its trivia (both empty unless leniently coerced).
	case number(String, triviaPrefix: Substring, triviaSuffix: Substring)
	/// A string.
	case string(String)

	/// The value parsed as chronologic; else `nil`.
	static func chronologic(from value: JSON.Node?) -> Self? {
		chronologicDateAndIsDateOnly(from: value).map { date, isDateOnly in
			.chronologic(date, style: .init(isInputDateOnly: isDateOnly, isDateOnly: isDateOnly))
		}
	}

	/// The value as a number, per `coercion`; else `nil`.
	static func number(from value: JSON.Node?, coercion: Coercion?) -> Self? {
		switch (value, coercion) {
		case let (.number(number), _):
			.number("\(number)", triviaPrefix: "", triviaSuffix: "")
		case let (.string(literal), .lenient):
			lenientNumberRange(in: literal.value).map { range in
				.number(
					.init(literal.value[range]),
					triviaPrefix: literal.value[..<range.lowerBound],
					triviaSuffix: literal.value[range.upperBound...],
				)
			}
		case let (.string(literal), .strict):
			decimalNumber(in: literal.value).map { .number(numberString($0), triviaPrefix: "", triviaSuffix: "") }
		default:
			nil
		}
	}

	/// The rendered value.
	var string: String {
		switch self {
		case let .chronologic(date, style):
			style.formatted(date)
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
			guard case let .chronologic(date, style)? = try coercedChronologic(for: call) else {
				return nil
			}
			return .chronologic(date, style: style.applying(call.transform))
		case .number, .numberToString: // swiftformat:disable:this sortSwitchCases
			guard case let .number(number, triviaPrefix, triviaSuffix)? = try coercedNumber(for: call) else {
				return nil
			}
			// A number's grouping separators are removed, so it may be transformed
			return .number(
				call.transform.applied(to: number.filter { $0 != "," }),
				triviaPrefix: triviaPrefix,
				triviaSuffix: triviaSuffix,
			)
		case .string:
			guard call.isCoerced || isString else {
				throw .transformInputTypeMismatch(transform: call.transform, input: string)
			}
			return .string(call.transform.applied(to: string))
		}
	}

	/// This value as chronologic iff it conforms to the chronologic predicate,
	/// else `nil` iff `call` has `<strict-coercion>` (formatting aborts).
	private func coercedChronologic(for call: TransformCall) throws(FormattingError) -> Self? {
		if case .chronologic = self {
			return self
		}
		let chronologic = if case let .input(node) = self {
			Self.chronologic(from: node)
		} else {
			Self.chronologic(from: .string(string))
		}
		guard chronologic != nil || call.isCoerced else {
			throw .transformInputTypeMismatch(transform: call.transform, input: string)
		}
		return chronologic
	}

	/// This value as a number, coerced iff `call` has `<strict-coercion>`
	/// (`nil` iff that coercion fails).
	private func coercedNumber(for call: TransformCall) throws(FormattingError) -> Self? {
		switch self {
		case let .input(.number(number)):
			return .number("\(number)", triviaPrefix: "", triviaSuffix: "")
		case .number:
			return self
		default:
			guard call.isCoerced else {
				throw .transformInputTypeMismatch(transform: call.transform, input: string)
			}
			return .number(from: .string(string), coercion: .strict)
		}
	}
}

/// How a chronologic value is rendered: ISO-8601, per input (date-only or
/// datetime), in the system time zone, unless modified by chronologic
/// transforms. A date-only input's date ignores time zones.
private struct ChronologicStyle: Equatable { // swiftlint:disable:this one_declaration_per_file
	/// Whether the input is date-only (parsed as midnight in the system time
	/// zone), so it's always rendered in the system time zone.
	let isInputDateOnly: Bool
	var isDateOnly: Bool
	var timeZone = TimeZone?.none

	/// This style modified by a chronologic `transform`: `dateOnly` renders
	/// only the date; `timeZone` sets the output time zone (the last one wins).
	func applying(_ transform: Transform) -> Self {
		var style = self
		switch transform {
		case .dateOnly:
			style.isDateOnly = true
		case let .timeZone(timeZone):
			style.timeZone = timeZone
		default:
			break
		}
		return style
	}

	/// `date` rendered per this style; a datetime includes 3-digit fractional
	/// seconds iff its milliseconds are nonzero.
	func formatted(_ date: Date) -> String {
		let systemTimeZone = Environment.current.systemTimeZone
		let style = Date.ISO8601FormatStyle(
			timeZoneSeparator: .colon,
			includingFractionalSeconds: // swiftformat:disable:next indent
				(date.timeIntervalSince1970 * 1000).rounded(.down).truncatingRemainder(dividingBy: 1000) != 0,
			timeZone: isInputDateOnly ? systemTimeZone : timeZone ?? systemTimeZone,
		)
		return isDateOnly ? style.year().month().day().format(date) : style.format(date)
	}
}

/// `value`, printed as a plain integer iff it is integral.
private func numberString(_ value: Double) -> String {
	value == value.rounded() && abs(value) < 1e15 ? .init(Int(value)) : .init(value)
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

	/// The boolean iff this is a JSON boolean or, iff `isCoerced`, a string
	/// that is `true` or `false`.
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
