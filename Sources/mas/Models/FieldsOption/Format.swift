//
// Format.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import Foundation
internal import JSONAST

// MARK: - Format (fields-formatting.md)

/// A parsed `<format>`: either a mix of literal text & `<placeholder>`s or a
/// bare `<format-reference>`.
enum Format: Equatable {
	case parts([FormatPart])
	case reference(FormatReference)
	/// `<format>`'s own top-level `<value-transform-pipeline>` (`kind` inferred
	/// at parse time from its 1st `<transform>`; see `parseValueTransform
	/// PipelineThenTemplate(_:namedFormat:terminatorSet:)`), optionally followed
	/// by a `<pipeline-terminator>`-separated template: unlike `.reference`
	/// (used inside a placeholder's own sub-format, where the base value's
	/// `stringValue` never fails to exist), `.number` `kind` first coerces the
	/// field's value iff `coerced` (a doubled leading `.` on the pipeline's own
	/// 1st `<transform>`; never valid for `.string` / `.date` `kind`, so always
	/// `false` for either), mimicking `<placeholder-coercion>` — & mimicking
	/// unhandled placeholder failure (blank) if that coercion fails. `template`
	/// empty means no `<pipeline-terminator>` / template followed; non-empty,
	/// `template` renders against the pipeline's OWN output, not the field's
	/// original value — a `%v` / `%V` (or any other placeholder) inside it reads
	/// the transformed value, not the raw 1, so nothing is duplicated & a
	/// template with no placeholder at all (e.g., a literal unit suffix alone)
	/// simply doesn't include the transformed value at all; write `%v` to
	/// include it.
	case valuePipeline(FormatReference, kind: TransformKind, coerced: Bool, template: [FormatPart])

	/// The standard default: `%v`. Fields needing a different one are configured
	/// by their display command, at the `FieldSpec` level, instead.
	/// TODO: a per-field, per-context user-configured default, once persisted
	///  fields configs exist.
	static func `default`(fieldName _: String) -> Self {
		.parts([.placeholder(.value(success: nil))])
	}

	/// Whether this is exactly the built-in `hidden` named format: excludes the
	/// field spec from display output entirely (its `SortSpec`, if any, still
	/// participates in item sorting), checked once per field spec, not per
	/// rendered value.
	var isHidden: Bool {
		if
			case let .reference(reference) = self,
			reference.namedFormat == hiddenNamedFormatName,
			reference.transforms.isEmpty
		{
			true
		} else {
			false
		}
	}
}

extension Format: CustomStringConvertible { // swiftlint:disable:this file_types_order
	var description: String {
		switch self {
		case let .parts(parts):
			"parts(\(parts))"
		case let .reference(reference):
			"reference(\(reference))"
		case let .valuePipeline(reference, kind, coerced, template):
			"valuePipeline(\(reference), kind: \(kind), coerced: \(coerced), template: \(template))"
		}
	}
}

extension Format { // swiftlint:disable:this file_types_order
	/// Renders this format against `value` (`nil` iff the field doesn't exist for
	/// this item), producing the node to display / embed in output. A lone bare
	/// `%v` / `%V` (the common case: no explicit `<format-modifier>`, or an
	/// explicit one that's just `%v`) passes the original node through unchanged
	/// (so JSON output preserves the value's real type); anything else (literal
	/// text, other placeholders, transforms) necessarily produces a string.
	/// `isHidden` fields are filtered out before this is ever called, so `hidden`
	/// needs no case here.
	func rendered(value: JSON.Node?, label: String, name: String) -> JSON.Node {
		switch self {
		case let .parts(parts):
			if parts.count == 1, case .placeholder(.value(success: nil)) = parts[0] {
				value ?? .null
			} else {
				.string(renderedParts(parts, value: value, label: label, name: name) ?? "")
			}
		case let .reference(reference):
			reference.rendered(value: value)
		case let .valuePipeline(reference, kind, coerced, template):
			if let pipelineString = renderedValuePipeline(reference, kind: kind, coerced: coerced, value: value) {
				// A trailing `<template>` renders against the pipeline's own output,
				// not the field's original value: e.g., `%v` inside it means "the
				// pipeline's result", not "the field's raw value" (see `Format
				// .valuePipeline`'s own doc comment).
				if template.isEmpty {
					.string(pipelineString)
				} else {
					.string(renderedParts(template, value: .string(pipelineString), label: label, name: name) ?? "")
				}
			} else {
				.string("")
			}
		}
	}
}

/// Renders `parts` against `value` / `label` / `name`. `nil` iff an unhandled
/// placeholder failure aborts the whole format (formatting then renders
/// blank; see callers).
private func renderedParts(_ parts: [FormatPart], value: JSON.Node?, label: String, name: String) -> String? {
	var result = ""
	for part in parts {
		switch part {
		case let .text(text):
			result += text
		case let .placeholder(placeholder):
			guard let rendered = placeholder.rendered(value: value, label: label, name: name) else {
				return nil
			}
			result += rendered
		}
	}
	return result
}

/// `Format.valuePipeline`'s own reference: `nil` iff coercing (`.number`
/// `kind` only, & only if `coerced`) `value` to `kind` fails (`.string` never
/// fails: `stringValue` always exists, `nil` becoming `""`; `.date` always
/// parses permissively, so `coerced` is always `false` there — see
/// `Format.valuePipeline`'s own doc comment). `reference.namedFormat` is
/// ignored, same as `FormatReference.rendered(value:)` below (see its own
/// doc comment).
private func renderedValuePipeline(
	_ reference: FormatReference,
	kind: TransformKind,
	coerced: Bool,
	value: JSON.Node?,
) -> String? {
	switch kind {
	case .string:
		reference.transforms.reduce(value?.stringValue ?? "") { string, transform in transform.applied(to: string) }
	case .number:
		isNumber(value, coerced: coerced)
			? reference.transforms.reduce(value?.stringValue ?? "") { string, transform in transform.applied(to: string) }
			: nil
	case .date:
		parsedDate(from: value).map { DateSpec(outputTransforms: reference.transforms).formatted($0) }
	}
}

/// One element of a mixed literal / placeholder format: either a
/// `<placeholder>` or literal (already-unescaped) text.
enum FormatPart: Equatable, CustomStringConvertible { // swiftlint:disable:this one_declaration_per_file
	case placeholder(Placeholder)
	case text(String)

	var description: String {
		switch self {
		case let .text(text):
			"text(\"\(text)\")"
		case let .placeholder(placeholder):
			"placeholder(\(placeholder))"
		}
	}
}

/// A `<format-reference>` / `<*-placeholder-reference>`: an optional named
/// format, optionally followed by a transform pipeline.
struct FormatReference: Equatable { // swiftlint:disable:this one_declaration_per_file
	let namedFormat: String?
	let transforms: [Transform]
}

extension FormatReference: CustomStringConvertible { // swiftlint:disable:this file_types_order
	var description: String {
		"FormatReference(namedFormat: \(namedFormat.map { "\"\($0)\"" } ?? "nil"), transforms: \(transforms))"
	}
}

private extension FormatReference { // swiftlint:disable:this file_types_order
	/// Only the built-in `hidden` named format exists (filtered out before
	/// reaching here) & user-defined named formats are out of scope (they need
	/// persistence), so this only ever has a bare `<string-transform-pipeline>`
	/// to apply to the field's own verbatim value.
	func rendered(value: JSON.Node?) -> JSON.Node { // TODO: user-defined named formats
		.string(transforms.reduce(value?.stringValue ?? "") { string, transform in transform.applied(to: string) })
	}
}

/// A single `<transform-call>`'s `<transform>`. Whether a given case is valid
/// in a particular pipeline (`<string-transform-pipeline>`,
/// `<number-transform-pipeline>`, or `<date-transform-pipeline>`) is enforced
/// at parse time, not by this type.
enum Transform: Hashable { // swiftlint:disable:this one_declaration_per_file
	// swiftlint:disable sorted_enum_cases
	case capitalize
	case lowercase
	case sentenceCase
	case trimWhitespace
	case uppercase

	case absoluteValue
	/// Inserts `separator` into the field's integer part every `digitCount`
	/// digits, counting from the right; a fractional part & leading `-` sign
	/// are left untouched. See `<group>` in fields-formatting.md for full
	/// semantics.
	case group(separator: String, digitCount: Int)
	case round
	/// Divides the field's value by `radix^exponent`, optionally rounds it to
	/// `significantDigits` total `radix` digits, then renders it in positional
	/// notation, base `radix`, with exactly `fractionalDigits` digits after the
	/// radix point. See `<scale>` in fields-formatting.md for full semantics.
	case scale(radix: Int, exponent: Int, significantDigits: Int?, fractionalDigits: Int)

	case iso
	case dateOnly
	case localTimeZone // swiftlint:enable sorted_enum_cases

	static let stringTransformSet = Set([Self.capitalize, .lowercase, .sentenceCase, .trimWhitespace, .uppercase])
	/// `group` & `scale` are parameterized & validated separately; see
	/// `parsed(name:kind:)`.
	static let numberTransformSet = Set([Self.absoluteValue, .round])
	static let dateTransformSet = Set([Self.iso, .dateOnly, .localTimeZone])

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

	/// Applies this transform to a string. `dateOnly` / `iso` / `localTimeZone`
	/// are applied separately, by `DateSpec.rendered(value:label:name:)`, since
	/// they need the field's parsed `Date`, not just its rendered string.
	func applied(to string: String) -> String {
		switch self {
		case .capitalize:
			string.isEmpty ? string : string.prefix(1).uppercased() + string.dropFirst()
		case .lowercase:
			string.lowercased()
		case .sentenceCase:
			string.isEmpty ? string : string.prefix(1).uppercased() + string.dropFirst().lowercased()
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
		case .dateOnly, .iso, .localTimeZone:
			string // Unreachable here; see doc comment above
		}
	}
}

extension Transform { // swiftlint:disable:this file_types_order
	/// Resolves `locale`'s grouping separator & digit count into a `.group`
	/// transform (absent either, per `NumberFormatter`, which shouldn't happen
	/// for a real locale: `,` & `3`, matching the system default locale's own
	/// usual values).
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

private extension Transform { // swiftlint:disable:this file_types_order
	/// The bare (parameter-less) transform names, per fields-formatting.md.
	init?(simpleName name: String) {
		switch name {
		case "initialUppercase":
			self = .capitalize
		case "lowercase":
			self = .lowercase
		case "sentenceCase":
			self = .sentenceCase
		case "trimWhitespace":
			self = .trimWhitespace
		case "uppercase":
			self = .uppercase
		case "absoluteValue":
			self = .absoluteValue
		case "round":
			self = .round
		case "iso":
			self = .iso
		case "dateOnly":
			self = .dateOnly
		case "localTimeZone":
			self = .localTimeZone
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

/// Parses `scale`'s optional `significantDigits` argument: `nil` for an empty `text` (no cap), else a validated
/// positive integer.
private func parsedSignificantDigits(from text: Substring, transformName: String) throws(ParsingError) -> Int? {
	if text.isEmpty {
		nil
	} else if let significantDigits = Int(text), significantDigits >= 1 {
		significantDigits
	} else {
		throw .invalidTransformArguments(name: transformName)
	}
}

/// Renders `rawValue` per `scale`'s semantics (see its doc comment on `Transform.scale`).
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

extension Transform: CustomStringConvertible { // swiftlint:disable:this file_types_order
	var description: String {
		switch self {
		case .capitalize:
			"initialUppercase"
		case .lowercase:
			"lowercase"
		case .sentenceCase:
			"sentenceCase"
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
			scale(radix: \(radix), exponent: \(exponent), significantDigits: \(
				significantDigits.map(String.init) ?? "nil"
			), fractionalDigits: \(fractionalDigits))
			"""
		case .iso:
			"iso"
		case .dateOnly:
			"dateOnly"
		case .localTimeZone:
			"localTimeZone"
		}
	}
}

/// A `<placeholder>`. Concise vs. verbose isn't tracked separately: a `nil`
/// success / failure format means either "concise" (no format slot at all) or
/// "verbose with an absent format" (`[ <standard> ]` omitted), both resolve to
/// the placeholder's default identically, so the distinction carries no
/// semantic weight once parsed.
indirect enum Placeholder: Equatable { // swiftlint:disable:this one_declaration_per_file
	// swiftlint:disable sorted_enum_cases
	/// `%v` / `%V`. Never negated (`<value>` has no defined negated meaning).
	case value(success: Format?)
	/// `%l` / `%L` / `%-l` / `%-L`. Negated: field name. Not negated: field
	/// label.
	case label(negated: Bool, success: Format?)
	/// `%u` / `%U` / `%e` / `%E` / `%w` / `%W` / `%o` / `%O` / `%t` / `%T` / `%f`
	/// / `%F` / `%s` / `%S`, each optionally negated; `coerced` (`%.o` / `%.t` /
	/// `%.f`, & verbose / negated variants) is valid only for `.isBoolean` /
	/// `.isTrue` / `.isFalse`, enforced at parse time.
	// swiftlint:disable:next enum_case_associated_values_count
	case standard(StandardKind, negated: Bool, coerced: Bool, success: Format?, failure: Format?)
	/// `%n` / `%N` / `%-n` / `%-N` / `%.n` / `%.N` / etc.
	case number(negated: Bool, coerced: Bool, success: Format?, failure: Format?)
	/// `%d` / `%D` / `%-d` / `%-D`.
	case date(negated: Bool, success: DateSpec?, failure: Format?)
	/// `%b` / `%B`. Never negated (`<branches>` has no defined negated meaning).
	case branches(Branches, failure: Format?) // swiftlint:enable sorted_enum_cases
}

extension Placeholder: CustomStringConvertible { // swiftlint:disable:this file_types_order
	var description: String {
		switch self {
		case let .value(success):
			"value(success: \(success.map(String.init(describing:)) ?? "nil"))"
		case let .label(negated, success):
			"label(negated: \(negated), success: \(success.map(String.init(describing:)) ?? "nil"))"
		case let .standard(kind, negated, coerced, success, failure):
			"""
			standard(\(kind), negated: \(negated), coerced: \(coerced), success: \(
				success.map(String.init(describing:)) ?? "nil"
			), failure: \(failure.map(String.init(describing:)) ?? "nil"))
			"""
		case let .number(negated, coerced, success, failure):
			"""
			number(negated: \(negated), coerced: \(coerced), success: \(
				success.map(String.init(describing:)) ?? "nil"
			), failure: \(failure.map(String.init(describing:)) ?? "nil"))
			"""
		case let .date(negated, success, failure):
			"""
			date(negated: \(negated), success: \(success.map(String.init(describing:)) ?? "nil"), failure: \(
				failure.map(String.init(describing:)) ?? "nil"
			))
			"""
		case let .branches(branches, failure):
			"branches(\(branches), failure: \(failure.map(String.init(describing:)) ?? "nil"))"
		}
	}
}

private extension Placeholder { // swiftlint:disable:this file_types_order
	/// Returns the evaluated string, or `nil` if this placeholder fails with no
	/// `<failure>` (formatting aborts).
	func rendered(value: JSON.Node?, label: String, name: String) -> String? {
		switch self {
		case let .value(success):
			success?.rendered(value: value, label: label, name: name).stringValue ?? value?.stringValue ?? ""
		case let .label(negated, success):
			success?.rendered(value: value, label: label, name: name).stringValue ?? (negated ? name : label)
		case let .standard(kind, negated, coerced, success, failure):
			(kind.matches(value, coerced: coerced) != negated)
				? success?.rendered(value: value, label: label, name: name).stringValue
					?? kind.defaultValue(value: value, negated: negated)
				: failure?.rendered(value: value, label: label, name: name).stringValue
		case let .number(negated, coerced, success, failure):
			(isNumber(value, coerced: coerced) != negated)
				? success?.rendered(value: value, label: label, name: name).stringValue ?? value?.stringValue ?? ""
				: failure?.rendered(value: value, label: label, name: name).stringValue
		case let .date(negated, success, failure):
			dateRendered(value: value, negated: negated, success: success, failure: failure, label: label, name: name)
		case let .branches(branches, failure):
			branches.branches.lazy.compactMap { $0.rendered(value: value, label: label, name: name) }.first
				?? failure?.rendered(value: value, label: label, name: name).stringValue
		}
	}
}

/// `coerced`: also matches a JSON string that itself parses as a number (see
/// `<placeholder-coercion>` in fields-formatting.md).
private func isNumber(_ value: JSON.Node?, coerced: Bool) -> Bool {
	switch value {
	case .number:
		true
	case let .string(literal):
		coerced && Double(literal.value) != nil
	default:
		false
	}
}

/// `%d` / `%D`'s evaluation: fails (returns `nil`) iff
/// `(parsedDate(from: value) != nil) == negated` & no `failure` is given.
private func dateRendered(
	value: JSON.Node?,
	negated: Bool,
	success: DateSpec?,
	failure: Format?,
	label: String,
	name: String,
) -> String? {
	let date = parsedDate(from: value)
	return (date != nil) != negated
		? date.map { (success ?? .default).formatted($0) } ?? (value?.stringValue ?? "")
		: failure?.rendered(value: value, label: label, name: name).stringValue
}

/// Parses a field's raw value as a date: ISO-8601 datetime, then ISO-8601
/// date-only, then a Unix epoch (seconds) numeric timestamp, in that order.
/// Custom `<input-date-format>`s aren't supported (fields.md defines no
/// pattern language for `<inline-date-format>`), so this is the only input
/// detection `<date>` ever uses.
private func parsedDate(from value: JSON.Node?) -> Date? {
	guard let raw = value?.stringValue else {
		return nil
	}
	return (try? Date(raw, strategy: .iso8601))
		?? (try? Date(raw, strategy: .iso8601.year().month().day()))
		?? Double(raw).map { Date(timeIntervalSince1970: $0) }
}

/// A parsed `<date>`'s output side: `<output-date-format>`, restricted to a
/// bare `<date-transform-pipeline>` (no named-format prefix): a named-format
/// reference needs persistence, & a literal `<inline-date-format>` pattern has
/// no defined syntax in fields.md, so both fall back to `.default` instead.
struct DateSpec: Equatable { // swiftlint:disable:this one_declaration_per_file
	static let `default` = Self(outputTransforms: .init())

	let outputTransforms: [Transform]

	/// Renders `date` per `outputTransforms`. Default (`outputTransforms`
	/// empty) is ISO-8601 datetime in the local time zone; `dateOnly` switches
	/// to just the date; `iso` (absent `localTimeZone`) switches the zone from
	/// local to UTC.
	func formatted(_ date: Date) -> String {
		let style = outputTransforms.contains(.iso) && !outputTransforms.contains(.localTimeZone)
			? Date.ISO8601FormatStyle()
			: Date.ISO8601FormatStyle(timeZone: .current)
		return outputTransforms.contains(.dateOnly) ? style.year().month().day().format(date) : style.format(date)
	}
}

extension DateSpec: CustomStringConvertible { // swiftlint:disable:this file_types_order
	var description: String {
		"DateSpec(outputTransforms: \(outputTransforms))"
	}
}

enum StandardKind: Character { // swiftlint:disable:this one_declaration_per_file
	// swiftlint:disable sorted_enum_cases
	case isNull = "u"
	case isEmpty = "e"
	case isWhitespace = "w"
	case isBoolean = "o"
	case isFalse = "f"
	case isTrue = "t"
	case isString = "s" // swiftlint:enable sorted_enum_cases

	/// Whether `<placeholder-coercion>` is valid on this kind: only the
	/// boolean-ish kinds (fields-formatting.md's "Coercion").
	var isCoercible: Bool {
		switch self {
		case .isBoolean, .isFalse, .isTrue:
			true
		case .isEmpty, .isNull, .isString, .isWhitespace:
			false
		}
	}

	/// `coerced`: for a boolean-ish kind, also matches a JSON string equal to
	/// `"true"` / `"false"` (see `<placeholder-coercion>` in
	/// fields-formatting.md); a no-op for a non-`isCoercible` kind.
	func matches(_ value: JSON.Node?, coerced: Bool) -> Bool {
		switch self {
		case .isNull:
			value.isNullish
		case .isEmpty:
			value.isNullish || value?.as(String.self)?.isEmpty == true
		case .isWhitespace:
			value.isNullish || value?.as(String.self)?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true
		case .isBoolean:
			if case .bool = value {
				true
			} else {
				coerced && (value?.stringValue == "true" || value?.stringValue == "false")
			}
		case .isFalse:
			if case .bool(false) = value {
				true
			} else {
				coerced && value?.stringValue == "false"
			}
		case .isTrue:
			if case .bool(true) = value {
				true
			} else {
				coerced && value?.stringValue == "true"
			}
		case .isString:
			if case .string = value {
				true
			} else {
				false
			}
		}
	}

	/// The placeholder's un-formatted default output, given whether it succeeded
	/// (`matches`, XOR `negated`).
	func defaultValue(value: JSON.Node?, negated: Bool) -> String {
		switch self {
		case .isNull, .isEmpty, .isWhitespace: // swiftformat:disable:this sortSwitchCases
			negated ? (value?.stringValue ?? "") : ""
		case .isBoolean, .isFalse, .isTrue, .isString: // swiftformat:disable:this sortSwitchCases
			value?.stringValue ?? ""
		}
	}
}

extension StandardKind: CustomStringConvertible { // swiftlint:disable:this file_types_order
	var description: String {
		switch self {
		case .isNull:
			"isNull"
		case .isEmpty:
			"isEmpty"
		case .isWhitespace:
			"isWhitespace"
		case .isBoolean:
			"isBoolean"
		case .isFalse:
			"isFalse"
		case .isTrue:
			"isTrue"
		case .isString:
			"isString"
		}
	}
}

/// `<branches>`: 0 or more non-infallible branches followed by exactly 1 final
/// branch (which may be infallible).
struct Branches: Equatable { // swiftlint:disable:this one_declaration_per_file
	let branches: [Branch]
}

extension Branches: CustomStringConvertible { // swiftlint:disable:this file_types_order
	var description: String {
		"Branches(\(branches))"
	}
}

/// A single `<branch>`. `%b` / `%B` may not themselves appear as a branch;
/// that's enforced by the parser (there's no `.branches` case here for it to
/// construct).
enum Branch: Equatable { // swiftlint:disable:this one_declaration_per_file
	case date(negated: Bool, success: DateSpec?)
	case label(negated: Bool, success: Format?)
	case number(negated: Bool, coerced: Bool, success: Format?)
	case standard(StandardKind, negated: Bool, coerced: Bool, success: Format?)
	case value(success: Format?)

	var isInfallible: Bool {
		switch self {
		case .label, .value:
			true
		case .date, .number, .standard:
			false
		}
	}
}

extension Branch: CustomStringConvertible { // swiftlint:disable:this file_types_order
	var description: String {
		switch self {
		case let .date(negated, success):
			"date(negated: \(negated), success: \(success.map(String.init(describing:)) ?? "nil"))"
		case let .label(negated, success):
			"label(negated: \(negated), success: \(success.map(String.init(describing:)) ?? "nil"))"
		case let .number(negated, coerced, success):
			"number(negated: \(negated), coerced: \(coerced), success: \(success.map(String.init(describing:)) ?? "nil"))"
		case let .standard(kind, negated, coerced, success):
			"""
			standard(\(kind), negated: \(negated), coerced: \(coerced), success: \(
				success.map(String.init(describing:)) ?? "nil"
			))
			"""
		case let .value(success):
			"value(success: \(success.map(String.init(describing:)) ?? "nil"))"
		}
	}
}

private extension Branch { // swiftlint:disable:this file_types_order
	/// Returns the evaluated string, or `nil` if this branch fails (the next
	/// branch should be tried).
	func rendered(value: JSON.Node?, label: String, name: String) -> String? {
		switch self {
		case let .value(success):
			success?.rendered(value: value, label: label, name: name).stringValue ?? value?.stringValue ?? ""
		case let .label(negated, success):
			success?.rendered(value: value, label: label, name: name).stringValue ?? (negated ? name : label)
		case let .standard(kind, negated, coerced, success):
			kind.matches(value, coerced: coerced) == negated
				? nil
				: success?.rendered(value: value, label: label, name: name).stringValue
					?? kind.defaultValue(value: value, negated: negated)
		case let .number(negated, coerced, success):
			isNumber(value, coerced: coerced) == negated
				? nil
				: success?.rendered(value: value, label: label, name: name).stringValue ?? value?.stringValue ?? ""
		case let .date(negated, success):
			dateBranchRendered(value: value, negated: negated, success: success)
		}
	}
}

private func dateBranchRendered(value: JSON.Node?, negated: Bool, success: DateSpec?) -> String? {
	let date = parsedDate(from: value)
	return (date != nil) == negated
		? nil
		: date.map { (success ?? .default).formatted($0) } ?? (value?.stringValue ?? "")
}

// MARK: - Format parsers (fields-formatting.md)

/// Parses a `<*-placeholder-reference>` / `<format-reference>`:
/// `[ <named-*-format> ] [ <*-transform-pipeline> ]`, requiring at least 1 of
/// the 2 to be present. Returns `nil` (consuming nothing) if the input doesn't
/// begin with `<name-prefix>` or `<transform-call-prefix>`.
struct FormatReferenceParser { // swiftlint:disable:this one_declaration_per_file
	let kind: TransformKind
	let terminatorSet: Set<Character>

	func parse(_ input: inout Substring) throws(ParsingError) -> FormatReference? {
		let dateSeparatorSet = kind == .date ? Set([dateInputFormatSeparator, dateInputOutputSeparator]) : .init()
		var namedFormat = String?.none
		if input.first == namePrefix {
			input.removeFirst()
			let name =
				try parseEscapedText(&input, terminatorSet: terminatorSet.union([transformCallPrefix]).union(dateSeparatorSet))
			guard knownNamedFormatNameSet.contains(name) else {
				throw .unknownNamedFormat(name)
			}
			namedFormat = name
		}
		var transforms = [Transform]()
		while input.first == transformCallPrefix {
			input.removeFirst()
			// A doubled `<transform-call-prefix>` (`<value-transform-coercion>`) is
			// only ever meaningful on `<format>`'s own top-level pipeline's 1st
			// `<transform>` (see `parseValueTransformPipelineThenTemplate(_:
			// namedFormat:terminatorSet:)`, which strips it there before this
			// function ever sees it) — anywhere else (a later `<transform>` in that
			// same pipeline, or any `<transform>` inside a placeholder's own
			// sub-format), it's syntactically harmless but has no effect, so it's
			// simply skipped, not specially recognized or rejected.
			if input.first == transformCallPrefix {
				input.removeFirst()
			}
			let name = try parseTransformName(&input, terminatorSet: terminatorSet.union(dateSeparatorSet))
			guard let transform = try Transform.parsed(name: name, kind: kind) else {
				throw .invalidTransform(name: name, expectedKind: kind.rawValue)
			}
			transforms.append(transform)
			// A `<terminal-number-transform>` may only ever be last in its
			// `<number-transform-pipeline>`; `input.first == transformCallPrefix` here
			// means the loop is about to try parsing another 1
			guard !transform.isTerminalNumberTransform || input.first != transformCallPrefix else {
				throw .terminalNumberTransformFollowedByMore(name: name)
			}
		}
		return namedFormat != nil || !transforms.isEmpty ? .init(namedFormat: namedFormat, transforms: transforms) : nil
	}
}

/// Parses 1 `<transform-call>`'s `<transform>` name, right after its
/// already-consumed `<transform-call-prefix>`: its `<group-arguments>` /
/// `<scale-arguments>` fence, if present, is included verbatim (exactly as
/// `Transform.parsed(name:kind:)` expects). Unlike a bare `parseEscapedText`
/// scan, `:` always ends the name UNLESS the name scanned so far is `group` /
/// `scale` & is immediately followed by `:` (that transform's own argument
/// fence) — only then does scanning continue through to the fence's own
/// closing `:`. This keeps a bare (argument-less) transform's name from
/// swallowing a subsequent `<pipeline-terminator>` (`::`) or stray `:`, both
/// only meaningful to `<format>`'s own top-level `<value-transform-pipeline>`
/// (every other `<*-transform-pipeline>` site's `terminatorSet` never lets a
/// `:` reach this function in the first place).
func parseTransformName(_ input: inout Substring, terminatorSet: Set<Character>) throws(ParsingError) -> String {
	let name = try parseEscapedText(&input, terminatorSet: terminatorSet.union([transformCallPrefix, colon]))
	var afterOpenFence = input
	guard fenceTakingSimpleNameSet.contains(name), afterOpenFence.first == colon else {
		return name
	}
	afterOpenFence.removeFirst() // the candidate fence's opening ':'
	guard afterOpenFence.first != colon else {
		// An immediately-empty fence is never valid syntax anyway (`group` /
		// `scale` both require nonempty arguments), so this 2nd ':' can't be a
		// fence's own closing 1: it's `<format>`'s `<pipeline-terminator>`
		// (`::`) instead, & the 1st ':' isn't part of this (argument-less)
		// name at all.
		return name
	}
	input = afterOpenFence
	let arguments = try parseEscapedText(&input, terminatorSet: Set([colon]))
	guard input.first == colon else {
		throw .missingEndFence
	}
	input.removeFirst() // the fence's closing ':'
	return name + argumentFence + arguments + argumentFence
}

/// Parses `<standard-format>` / `<failure-format>` / `<number-format>`-shaped
/// content: a mix of literal text & `<placeholder>`s, up to (but not including)
/// 1 of `terminatorSet`.
struct FormatContentParser { // swiftlint:disable:this one_declaration_per_file
	let terminatorSet: Set<Character>

	func parse(_ input: inout Substring) throws(ParsingError) -> Format {
		var parts = [FormatPart]()
		var text = ""
		func flushText() {
			if !text.isEmpty {
				parts.append(.text(text))
				text = ""
			}
		}
		while let char = input.first, !terminatorSet.contains(char) {
			if char == placeholderPrefix {
				flushText()
				parts.append(.placeholder(try PlaceholderParser().parse(&input)))
			} else if char == escapePrefix {
				input.removeFirst()
				if let escaped = input.first {
					text.append(escaped)
					input.removeFirst()
				}
			} else {
				text.append(char)
				input.removeFirst()
			}
		}
		flushText()
		return .parts(parts)
	}
}

/// The kind of transform pipeline expected at a given parse site, per
/// `<date-transform-pipeline>` / `<number-transform-pipeline>` /
/// `<string-transform-pipeline>`.
enum TransformKind: String, CaseIterable { // swiftlint:disable:this one_declaration_per_file
	case date
	case number
	case string

	/// Which kind `name` (a `<transform>`'s own name, `<group-arguments>` /
	/// `<scale-arguments>` included verbatim if present) belongs to: tried by
	/// actually attempting to parse it as each kind in turn (rather than a
	/// separate, duplicated name-shape check), keeping the 1st success. Every
	/// `<transform>` name is unique across kinds, so this is never ambiguous:
	/// trying a "wrong" kind for a given name always fails cleanly (`nil`, not a
	/// thrown error, since `Transform.parsed(name:kind:)` only ever attempts
	/// argument parsing — which is what can throw — once it's already matched
	/// `name`'s own shape to `kind`), so a thrown error (e.g., invalid
	/// `<group-arguments>`) can only come from the kind `name`'s shape actually
	/// belongs to; propagating it immediately, without trying the remaining
	/// kinds, is therefore correct. Used only by `<format>`'s own top-level
	/// `<value-transform-pipeline>`, the 1 site that can't know its kind up
	/// front (see `parseValueTransformPipelineThenTemplate(_:namedFormat:
	/// terminatorSet:)` in `FieldSpec.swift`).
	static func of(transformName name: String) throws(ParsingError) -> Self? {
		for kind in allCases where try Transform.parsed(name: name, kind: kind) != nil {
			return kind
		}
		return nil
	}

	var allowedTransformSet: Set<Transform> {
		switch self {
		case .date:
			Transform.dateTransformSet
		case .number:
			Transform.numberTransformSet
		case .string:
			Transform.stringTransformSet
		}
	}
}

/// Whether `format` (`nil` counts as empty) is a `<template>` with no
/// `<placeholder>` at all, & so would render the same output regardless of
/// the field's value (see `ParsingError.templateLacksPlaceholder`). A bare
/// `.reference` (a transform pipeline with no template) is never flagged: its
/// own output already depends on the field's value.
func formatLacksPlaceholder(_ format: Format?) -> Bool {
	switch format {
	case nil:
		true
	case .reference, .valuePipeline:
		false
	case let .parts(parts):
		!parts.contains { part in
			if case .placeholder = part {
				true
			} else {
				false
			}
		}
	}
}

/// Parses `<format-delimiter>`-suffixed content, i.e., `[ <standard> ]` /
/// `[ <failure> ]` / `[ <number> ]` through & including their closing `+`.
/// Assumes the leading content (if any) has not yet been consumed.
/// `requirePlaceholder` rejects empty / placeholder-less content: pass `true`
/// only for a top-level, standalone infallible placeholder's (`%v` / `%V`,
/// `%l` / `%L`) own success format, which always applies, unlike a fallible
/// placeholder's (e.g., `%n` / `%N`) own success / failure, reached only
/// conditionally — so it'd otherwise render the same output regardless of
/// the field's value, something a bare literal could already do with no
/// placeholder wrapping it at all. A `%v` / `%V` / `%l` / `%L` used as 1 of
/// `%b`'s own `<branches>` is exempt even though it's still infallible: no
/// bare literal could stand in for it there, since it'd lose the "only if
/// every earlier branch failed" ordering the branch itself provides.
func parseDelimitedFormat(_ input: inout Substring, kind: TransformKind, requirePlaceholder: Bool)
throws(ParsingError) -> Format? {
	let terminatorSet = Set([placeholderPrefix, formatDelimiter])
	let value = if let reference = try FormatReferenceParser(kind: kind, terminatorSet: terminatorSet).parse(&input) {
		Format.reference(reference)
	} else if input.first != formatDelimiter {
		try FormatContentParser(terminatorSet: terminatorSet).parse(&input)
	} else {
		Format?.none
	}
	guard input.first == formatDelimiter else {
		throw .missingEndFence
	}
	input.removeFirst()
	guard !requirePlaceholder || !formatLacksPlaceholder(value) else {
		throw .templateLacksPlaceholder
	}
	return value
}

/// Parses `<date>` up to, but not including, its closing `<format-delimiter>`.
/// A custom `<input-date-format>` & a non-bare `<output-date-format>` (a
/// named-format reference or literal pattern text) aren't implemented yet
/// (fields.md defines no pattern language for `<inline-date-format>`, & a
/// named reference needs persistence) — since fields.md's own grammar makes
/// both look like they should do something, using either is a parse error
/// here, rather than silently falling back to `DateSpec.default`.
func parseDateSpec(_ input: inout Substring) throws(ParsingError) -> DateSpec? {
	let terminatorSet = Set([placeholderPrefix, formatDelimiter, dateInputFormatSeparator, dateInputOutputSeparator])
	func parseOneDateFormat() throws(ParsingError) -> Format {
		if let reference = try FormatReferenceParser(kind: .date, terminatorSet: terminatorSet).parse(&input) {
			return .reference(reference)
		}
		return try FormatContentParser(terminatorSet: terminatorSet).parse(&input)
	}

	guard input.first != formatDelimiter else {
		return nil
	}
	let format = try parseOneDateFormat()
	guard input.first != dateInputFormatSeparator, input.first != dateInputOutputSeparator else {
		throw .unsupportedDateInputFormat
	}
	guard case let .reference(reference) = format, reference.namedFormat == nil else {
		throw .unsupportedDateOutputFormat
	}
	return .init(outputTransforms: reference.transforms)
}

/// Parses a single `<placeholder>`, including any `<standard>` / `<failure>` /
/// `<number>` / `<date>` / `<branches>` & nested placeholders within it.
/// Assumes `<placeholder-prefix>` has not yet been consumed.
struct PlaceholderParser { // swiftlint:disable:this one_declaration_per_file
	func parse(_ input: inout Substring) throws(ParsingError) -> Placeholder {
		guard input.first == placeholderPrefix else {
			throw .missingFieldName // Unreachable given the call sites, but keeps this parser self-contained
		}
		input.removeFirst()
		var negated = false
		if input.first == placeholderNegation {
			negated = true
			input.removeFirst()
		}
		var coerced = false
		if input.first == placeholderCoercion {
			coerced = true
			input.removeFirst()
		}
		guard let letter = input.first else {
			throw .missingFieldName
		}
		input.removeFirst()
		let isVerbose = letter.isUppercase
		switch letter {
		case "v", "V":
			guard !negated else {
				throw .invalidLetter(letter) // `<value>` has no defined negated meaning
			}
			guard !coerced else {
				throw .coercionNotSupported(letter)
			}
			return .value(
				success: isVerbose ? try parseDelimitedFormat(&input, kind: .string, requirePlaceholder: true) : nil,
			)
		case "l", "L":
			guard !coerced else {
				throw .coercionNotSupported(letter)
			}
			return .label(
				negated: negated,
				success: isVerbose ? try parseDelimitedFormat(&input, kind: .string, requirePlaceholder: true) : nil,
			)
		case "n", "N":
			return isVerbose
				? .number(
					negated: negated,
					coerced: coerced,
					success: try parseDelimitedFormat(&input, kind: .number, requirePlaceholder: false),
					failure: try parseDelimitedFormat(&input, kind: .string, requirePlaceholder: false),
				)
				: .number(negated: negated, coerced: coerced, success: nil, failure: nil)
		case "d", "D":
			guard !coerced else {
				throw .coercionNotSupported(letter) // Date matching already coerces across string / numeric input
			}
			guard isVerbose else {
				return .date(negated: negated, success: nil, failure: nil)
			}
			let success = try parseDateSpec(&input)
			guard input.first == formatDelimiter else {
				throw .missingEndFence
			}
			input.removeFirst()
			return .date(
				negated: negated,
				success: success,
				failure: try parseDelimitedFormat(&input, kind: .string, requirePlaceholder: false),
			)
		case "b", "B":
			guard !negated else {
				throw .invalidLetter(letter) // `<branches>` has no defined negated meaning
			}
			guard !coerced else {
				throw .coercionNotSupported(letter)
			}
			let branches = try parseBranches(&input)
			guard input.first == formatDelimiter else {
				throw .missingEndFence
			}
			input.removeFirst()
			return .branches(
				branches,
				failure: isVerbose ? try parseDelimitedFormat(&input, kind: .string, requirePlaceholder: false) : nil,
			)
		default:
			guard let kind = StandardKind(rawValue: isVerbose ? Character(letter.lowercased()) : letter) else {
				throw .invalidLetter(letter)
			}
			guard !coerced || kind.isCoercible else {
				throw .coercionNotSupported(letter)
			}
			return isVerbose
				? .standard(
					kind,
					negated: negated,
					coerced: coerced,
					success: try parseDelimitedFormat(&input, kind: .string, requirePlaceholder: false),
					failure: try parseDelimitedFormat(&input, kind: .string, requirePlaceholder: false),
				)
				: .standard(kind, negated: negated, coerced: coerced, success: nil, failure: nil)
		}
	}

	/// Parses `<branches>` up to, but not including, its closing
	/// `<format-delimiter>`.
	private func parseBranches(_ input: inout Substring) throws(ParsingError) -> Branches {
		var branches = [Branch]()
		while let first = input.first, first != formatDelimiter {
			var negated = false
			if input.first == placeholderNegation {
				negated = true
				input.removeFirst()
			}
			var coerced = false
			if input.first == placeholderCoercion {
				coerced = true
				input.removeFirst()
			}
			guard let letter = input.first else {
				throw .missingFieldName
			}
			guard letter != "b", letter != "B" else {
				throw .invalidLetter(letter) // `%b` / `%B` may not themselves be used as branches
			}
			input.removeFirst()
			let isVerbose = letter.isUppercase
			let branch: Branch
			switch letter {
			case "v":
				guard !negated else {
					throw .invalidLetter(letter) // `<value>` has no defined negated meaning
				}
				guard !coerced else {
					throw .coercionNotSupported(letter)
				}
				branch = .value(success: nil)
			case "V":
				guard !negated else {
					throw .invalidLetter(letter) // `<value>` has no defined negated meaning
				}
				guard !coerced else {
					throw .coercionNotSupported(letter)
				}
				branch = .value(success: try parseDelimitedFormat(&input, kind: .string, requirePlaceholder: false))
			case "l", "L":
				guard !coerced else {
					throw .coercionNotSupported(letter)
				}
				branch = .label(
					negated: negated,
					success: isVerbose ? try parseDelimitedFormat(&input, kind: .string, requirePlaceholder: false) : nil,
				)
			case "n", "N":
				branch = .number(
					negated: negated,
					coerced: coerced,
					success: isVerbose ? try parseDelimitedFormat(&input, kind: .number, requirePlaceholder: false) : nil,
				)
			case "d", "D":
				guard !coerced else {
					throw .coercionNotSupported(letter) // Date matching already coerces across string / numeric input
				}
				let success = isVerbose ? try parseDateSpec(&input) : nil
				if isVerbose {
					guard input.first == formatDelimiter else {
						throw .missingEndFence
					}
					input.removeFirst()
				}
				branch = .date(negated: negated, success: success)
			default:
				guard let kind = StandardKind(rawValue: isVerbose ? Character(letter.lowercased()) : letter) else {
					throw .invalidLetter(letter)
				}
				guard !coerced || kind.isCoercible else {
					throw .coercionNotSupported(letter)
				}
				branch = .standard(
					kind,
					negated: negated,
					coerced: coerced,
					success: isVerbose ? try parseDelimitedFormat(&input, kind: .string, requirePlaceholder: false) : nil,
				)
			}
			branches.append(branch)
			guard !branch.isInfallible else {
				break // An infallible branch, if present, must be the last one
			}
		}
		guard !branches.isEmpty else {
			throw .missingFieldName
		}
		guard branches.count > 1 else {
			throw .singleBranch
		}
		return .init(branches: branches)
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
}

// MARK: Constants

let placeholderPrefix = Character("%")
let formatModifierPrefix = Character(":")
let formatDelimiter = Character("+")

private let placeholderNegation = Character("-")
private let placeholderCoercion = Character(".")
let namePrefix = Character(":")
let transformCallPrefix = Character(".")
private let dateInputFormatSeparator = Character(",")
private let dateInputOutputSeparator = Character("_")

let hiddenNamedFormatName = "hidden"
let knownNamedFormatNameSet = Set([hiddenNamedFormatName]) // TODO: union with custom named formats

private let groupSimpleName = "group"
private let groupNamePrefix = groupSimpleName + argumentFence
private let scaleSimpleName = "scale"
private let scaleNamePrefix = scaleSimpleName + argumentFence
private let argumentFence = ":"
private let argumentSeparator = Character(",")
/// The only `<transform>`s whose own grammar defines a `:`-fenced argument
/// list; see `parseTransformName(_:terminatorSet:)`.
private let fenceTakingSimpleNameSet = Set([groupSimpleName, scaleSimpleName])
