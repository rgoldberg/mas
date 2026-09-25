//
// FormatParser.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import Foundation

// MARK: - Format parsing (fields-format.md)

/// Parses a `<format-modifier>`'s optional `<format-block>`, from immediately
/// after its `<format-modifier-prefix>` up to (but not including) a
/// `<sort-modifier-prefix>`, a `<field-spec-separator>`, or the end of the
/// input.
///
/// - Parameter existing: The working fields config's format, whose type
///   determinant selects the direct default for an absent `<format-block>`.
/// - Returns: The format & the justification from its
///   `<format-transform-pipeline>`, which is `nil` iff the working fields
///   config's justification is retained (i.e., the
///   `<format-transform-pipeline>` is transitively absent).
func parseFormatBlock(_ input: inout Substring, existing: Format)
throws(ParsingError) -> (format: Format, justification: Justification?) {
	var parser = FormatParser(input: input)
	defer {
		input = parser.input
	}
	return try parser.parseFormatBlock(existing: existing)
}

/// A recursive-descent parser for fields-format.md's syntax.
private struct FormatParser {
	/// A `<*-transform-call>`'s transform: a `<value-transform>` or a
	/// `<format-transform>`.
	private enum ParsedTransformCall {
		case format(Justification)
		case value(TransformCall)
	}

	var input: Substring

	/// Whether the input is at the end of a `<format-block>`.
	private var isAtFormatBlockEnd: Bool {
		input.first.map(formatBlockTerminatorSet.contains) ?? true
	}

	mutating func parseFormatBlock(existing: Format) throws(ParsingError)
	-> (format: Format, justification: Justification?) {
		skipWhitespace() // `<format-modifier-prefix>` ignores succeeding whitespace
		let parsed: (format: Format, justification: Justification?) =
			if isAtFormatBlockEnd {
				// Directly absent: the nullary placeholder for the field's type
				// determinant's type & coercion
				(.nullaryPlaceholder(for: existing.typeDeterminant), nil)
			} else if input.first == namePrefix || input.first == transformCallPrefix {
				try parseFormatBlockPipeline()
			} else {
				(.template(try parseFormatTemplate()), nil)
			}
		skipWhitespace()
		guard isAtFormatBlockEnd else {
			throw .unexpectedCharacter(input.first ?? " ")
		}
		return parsed
	}

	/// Parses a `<format-block>`'s `<pipeline>`.
	private mutating func parseFormatBlockPipeline()
	throws(ParsingError) -> (format: Format, justification: Justification?) {
		try parseNamedFormatIfPresent(terminatorSet: formatBlockNameTerminatorSet)
		var justification = Justification?.none
		var calls = [TransformCall]()
		while skipWhitespace(), input.first == transformCallPrefix {
			switch try parseTransformCall() {
			case let .format(parsed):
				guard calls.isEmpty else {
					throw .invalidPipeline("<pipeline>")
				}
				justification = parsed // `<format-transform-pipeline>` is `(* last wins *)`
			case let .value(call):
				calls.append(call)
			}
		}
		guard calls.isEmpty || valueTransformPipelineShapeSet.contains(where: calls.hasShape) else {
			throw .invalidPipeline("<value-transform-pipeline>")
		}
		// A directly absent `<format-transform-pipeline>` preceding a
		// `<value-transform-pipeline>` defaults to `<start-justify>`
		return (.pipeline(calls), justification ?? (calls.isEmpty ? nil : .start))
	}

	/// Parses a block's `<*-pipeline>`, whose kind `kind` selects the valid
	/// transforms.
	private mutating func parseBlockPipeline(kind: BlockKind) throws(ParsingError) -> [TransformCall] {
		try parseNamedFormatIfPresent(terminatorSet: blockNameTerminatorSet)
		var calls = [TransformCall]()
		while skipWhitespace(), input.first == transformCallPrefix {
			guard case let .value(call) = try parseTransformCall() else {
				throw .invalidPipeline(kind.pipelineName)
			}
			calls.append(call)
		}
		guard kind.pipelineShapeSet.contains(where: calls.hasShape) else {
			throw .invalidPipeline(kind.pipelineName)
		}
		return calls
	}

	/// Parses a `<named-format-reference>`, if present. No named formats exist
	/// yet, so any reference reports an error, per fields-format.md.
	private mutating func parseNamedFormatIfPresent(terminatorSet: Set<Character>) throws(ParsingError) {
		guard input.first == namePrefix else {
			return
		}
		input.removeFirst()
		try forbidWhitespace(after: namePrefix)
		// swiftlint:disable:next todo
		// TODO: once persisted named formats exist, resolve the name to its
		//  format, checking that its output has the input type of any succeeding
		//  `<transform-pipeline>`
		throw .unknownNamedFormat(try parseText(terminatorSet: terminatorSet, leading: .ignored, trailing: .ignored))
	}

	/// Parses a `<*-transform-call>`, including its `<transform-call-prefix>`.
	private mutating func parseTransformCall() throws(ParsingError) -> ParsedTransformCall {
		input.removeFirst()
		try forbidWhitespace(after: transformCallPrefix)
		let isCoerced = input.first == strictCoercionPrefix
		if isCoerced {
			input.removeFirst()
			try forbidWhitespace(after: strictCoercionPrefix)
		}
		let name = transformNames.filter { input.hasPrefix($0) }.max { $0.count < $1.count }
		guard let name else {
			throw .unknownTransform(.init(input.prefix(while: \.isLetter)))
		}
		input.removeFirst(name.count)
		if let justification = justificationByName[name] {
			guard !isCoerced else {
				throw .coercionNotSupported(strictCoercionPrefix)
			}
			return .format(justification)
		}
		let transform: Transform =
			switch name {
			case groupName:
				try parseGroupArgumentsIfPresent()
			case scaleName:
				try parseScaleArguments()
			case timeZoneName:
				try parseTimeZoneArguments()
			default:
				valueTransformByName[name]! // swiftlint:disable:this force_unwrapping
			}
		return .value(.init(transform: transform, isCoerced: isCoerced))
	}

	/// Parses `group`'s optional `<group-arguments>`, which default to the
	/// system locale's.
	private mutating func parseGroupArgumentsIfPresent() throws(ParsingError) -> Transform {
		var afterWhitespace = input.drop(while: \.isWhitespace)
		guard afterWhitespace.first == argumentFence else {
			return .group(locale: .current)
		}
		afterWhitespace.removeFirst()
		input = afterWhitespace
		// `<locale-identifier>` & `<digit-group-separator>` consume their outer
		// bare whitespace
		let text = try parseText(terminatorSet: [argumentSeparator, argumentFence], leading: .consumed, trailing: .consumed)
		let transform: Transform
		if input.first == argumentSeparator {
			input.removeFirst()
			skipWhitespace()
			guard
				!text.isEmpty,
				let digitGroupDigitCount = parseUInt64(&input).flatMap(Int.init(exactly:)),
				digitGroupDigitCount >= 1
			else {
				throw .invalidTransformArguments(name: groupName)
			}
			transform = .group(digitGroupSeparator: text, digitGroupDigitCount: digitGroupDigitCount)
		} else {
			guard Locale.availableIdentifiers.contains(text) else {
				throw .invalidTransformArguments(name: groupName)
			}
			transform = .group(locale: .init(identifier: text))
		}
		try parseArgumentFence(for: groupName)
		return transform
	}

	/// Parses `scale`'s `<scale-arguments>`.
	private mutating func parseScaleArguments() throws(ParsingError) -> Transform {
		try parseArgumentFence(for: scaleName)
		func parseArgument(isOptional: Bool = false) throws(ParsingError) -> Int? {
			skipWhitespace()
			let digits = parseUInt64(&input)
			skipWhitespace()
			guard let digits else {
				guard isOptional else {
					throw .invalidTransformArguments(name: scaleName)
				}
				return nil
			}
			guard let argument = Int(exactly: digits) else {
				throw .invalidTransformArguments(name: scaleName)
			}
			return argument
		}
		func parseArgumentSeparator() throws(ParsingError) {
			guard input.first == argumentSeparator else {
				throw .invalidTransformArguments(name: scaleName)
			}
			input.removeFirst()
		}
		let radix = try parseArgument()
		try parseArgumentSeparator()
		let exponent = try parseArgument()
		try parseArgumentSeparator()
		let significantDigits = try parseArgument(isOptional: true)
		try parseArgumentSeparator()
		let fractionalDigits = try parseArgument()
		try parseArgumentFence(for: scaleName)
		guard
			let radix, (2...36).contains(radix),
			let exponent,
			significantDigits != 0,
			let fractionalDigits
		else {
			throw .invalidTransformArguments(name: scaleName)
		}
		return .scale(
			radix: radix,
			exponent: exponent,
			significantDigits: significantDigits,
			fractionalDigits: fractionalDigits,
		)
	}

	/// Parses `timeZone`'s `<time-zone-arguments>`.
	private mutating func parseTimeZoneArguments() throws(ParsingError) -> Transform {
		try parseArgumentFence(for: timeZoneName)
		let code = try parseText(terminatorSet: [argumentFence], leading: .ignored, trailing: .ignored)
		try parseArgumentFence(for: timeZoneName)
		guard let timeZone = timeZone(forCode: code) else {
			throw .invalidTransformArguments(name: timeZoneName)
		}
		return .timeZone(timeZone)
	}

	private mutating func parseArgumentFence(for transformName: String) throws(ParsingError) {
		skipWhitespace()
		guard input.first == argumentFence else {
			throw .invalidTransformArguments(name: transformName)
		}
		input.removeFirst()
	}

	/// Parses a `<format-template>`, which contains at least 1 placeholder.
	private mutating func parseFormatTemplate() throws(ParsingError) -> [TemplateElement] {
		var elements = [TemplateElement]()
		while !isAtFormatBlockEnd {
			if input.first == placeholderPrefix {
				elements.append(.placeholder(try parsePlaceholder()))
			} else {
				let text = try parseText(
					terminatorSet: formatTemplateTextTerminatorSet,
					leading: elements.isEmpty ? .ignored : .consumed,
					trailing: .consumedBefore(placeholderPrefix),
				)
				if !text.isEmpty {
					elements.append(.text(text))
				}
			}
		}
		guard elements.contains(where: \.isPlaceholder) else {
			throw .templateLacksPlaceholder
		}
		return elements
	}

	/// Parses an optional block of kind `kind`, then its `<block-terminator>`.
	///
	/// - Parameter enclosingPredicate: The enclosing matcher's predicate, which
	///   selects the valid `<block-placeholder>`s.
	private mutating func parseBlock(kind: BlockKind, enclosingPredicate: Predicate?) throws(ParsingError) -> Format? {
		skipWhitespace() // A block's optional ignores preceding whitespace
		let block: Format? =
			if input.first == blockTerminator {
				nil
			} else if input.first == namePrefix || input.first == transformCallPrefix {
				.pipeline(try parseBlockPipeline(kind: kind))
			} else {
				.template(try parseBlockTemplate(kind: kind, enclosingPredicate: enclosingPredicate))
			}
		skipWhitespace()
		guard input.first == blockTerminator else {
			throw .missingBlockTerminator
		}
		input.removeFirst()
		return block
	}

	/// Parses an optional pipeline of kind `kind`, without a template, then its
	/// `<block-terminator>`.
	private mutating func parsePipelineBlock(kind: BlockKind) throws(ParsingError) -> [TransformCall] {
		skipWhitespace() // A block's optional ignores preceding whitespace
		let calls = input.first == blockTerminator ? .init() : try parseBlockPipeline(kind: kind)
		skipWhitespace()
		guard input.first == blockTerminator else {
			throw .missingBlockTerminator
		}
		input.removeFirst()
		return calls
	}

	/// Parses a `<*-template>` of a block of kind `kind`, up to its
	/// `<block-terminator>`.
	private mutating func parseBlockTemplate(kind: BlockKind, enclosingPredicate: Predicate?)
	throws(ParsingError) -> [TemplateElement] {
		var elements = [TemplateElement]()
		while let first = input.first, first != blockTerminator {
			if first == placeholderPrefix {
				elements.append(try parseBlockTemplatePlaceholder(kind: kind, enclosingPredicate: enclosingPredicate))
			} else {
				let text = try parseText(
					terminatorSet: blockTemplateTextTerminatorSet,
					leading: elements.isEmpty ? .ignored : .consumed,
					trailing: .consumedBefore(placeholderPrefix),
				)
				if !text.isEmpty {
					elements.append(.text(text))
				}
			}
		}
		return elements
	}

	/// Parses a placeholder in a block's `<*-template>`: an
	/// `<unconditional-placeholder>` or a `<block-placeholder>` for
	/// `enclosingPredicate`.
	private mutating func parseBlockTemplatePlaceholder(kind: BlockKind, enclosingPredicate: Predicate?)
	throws(ParsingError) -> TemplateElement {
		input.removeFirst()
		try forbidWhitespace(after: placeholderPrefix)
		guard let letter = input.first else {
			throw .missingPredicate
		}
		input.removeFirst()
		let lowercaseLetter = Character(letter.lowercased())
		if let predicate = UnconditionalPredicate(rawValue: lowercaseLetter) {
			return .placeholder(
				.unconditional(
					predicate,
					pipeline: letter.isUppercase ? try parseUnconditionalPipelineBlock(predicate) : .init(),
				),
			)
		}
		guard
			kind.hasBlockPlaceholders,
			let enclosingPredicate,
			enclosingPredicate == Predicate(rawValue: lowercaseLetter)
		else {
			throw .invalidLetter(letter)
		}
		return .blockPlaceholder(
			pipeline: letter.isUppercase ? try parsePipelineBlock(kind: kind.blockPlaceholderPipelineKind) : .init(),
		)
	}

	/// Parses a `<non-nullary-unconditional-placeholder>`'s optional pipeline &
	/// its `<block-terminator>`.
	private mutating func parseUnconditionalPipelineBlock(_ predicate: UnconditionalPredicate)
	throws(ParsingError) -> [TransformCall] {
		try parsePipelineBlock(kind: predicate == .input ? .unconditional : .string)
	}

	/// Parses a `<format-template>`'s `<placeholder>`.
	private mutating func parsePlaceholder() throws(ParsingError) -> Placeholder {
		input.removeFirst()
		try forbidWhitespace(after: placeholderPrefix)
		let abortModifier = try parseModifier(in: abortModifierSet)
		let coercion = try parseCoercion()
		guard let letter = input.first else {
			throw .missingPredicate
		}
		input.removeFirst()
		let lowercaseLetter = Character(letter.lowercased())
		let isNonNullary = letter.isUppercase
		if let predicate = UnconditionalPredicate(rawValue: lowercaseLetter) {
			guard abortModifier == nil, coercion == nil else {
				throw .invalidModifier(letter)
			}
			return .unconditional(
				predicate,
				pipeline: isNonNullary ? try parseUnconditionalPipelineBlock(predicate) : .init(),
			)
		}
		if lowercaseLetter == nullaryMatch {
			guard abortModifier == nil, coercion == nil else {
				throw .invalidModifier(letter)
			}
			let branches = try parseBranches()
			return .match(
				branches,
				isNonNullary
					? .binary(failure: try parseBlock(kind: .unconditional, enclosingPredicate: nil))
					: .abortOnNoMatch,
			)
		}
		let matcher = try parseMatcher(letter: letter, coercion: coercion)
		return switch (abortModifier, isNonNullary) {
		case (abortOnSuccess, false):
			// A nullary `<abort-on-success>` placeholder's failure is the field value
			.conditional(matcher, .abortOnSuccess(failure: .default(fieldName: "")))
		case (abortOnSuccess, true):
			.conditional(matcher, .abortOnSuccess(failure: try parseBlock(kind: .unconditional, enclosingPredicate: nil)))
		case (abortOnFailure, false):
			throw .invalidModifier(letter)
		case (abortOnFailure, true):
			.conditional(matcher, .abortOnFailure(success: try parseSuccessBlock(for: matcher)))
		case (_, false):
			.conditional(matcher, .abortOnFailure(success: nil))
		case (_, true):
			.conditional(
				matcher,
				.binary(
					success: try parseSuccessBlock(for: matcher),
					failure: try parseBlock(kind: .unconditional, enclosingPredicate: nil),
				),
			)
		}
	}

	/// Parses `matcher`'s optional `<success-block>` & its
	/// `<block-terminator>`.
	private mutating func parseSuccessBlock(for matcher: Matcher) throws(ParsingError) -> Format? {
		try parseBlock(kind: .init(successBlockFor: matcher.predicate), enclosingPredicate: matcher.predicate)
	}

	/// Parses a scalar conditional `<predicate>` `letter`, validating that
	/// `coercion` is supported by it.
	private func parseMatcher(letter: Character, coercion: Coercion?) throws(ParsingError) -> Matcher {
		guard let predicate = Predicate(rawValue: Character(letter.lowercased())) else {
			throw .invalidLetter(letter)
		}
		guard coercion == nil || predicate.supportedCoercionSet.contains(coercion) else {
			throw .coercionNotSupported(letter)
		}
		return .init(predicate: predicate, coercion: coercion)
	}

	/// Parses an optional `<coercion>`.
	private mutating func parseCoercion() throws(ParsingError) -> Coercion? {
		switch try parseModifier(in: [strictCoercionPrefix, lenientCoercionPrefix]) {
		case strictCoercionPrefix:
			.strict
		case lenientCoercionPrefix:
			.lenient
		default:
			nil
		}
	}

	/// Parses an optional modifier in `modifierSet`, which forbids succeeding
	/// whitespace.
	private mutating func parseModifier(in modifierSet: Set<Character>) throws(ParsingError) -> Character? {
		guard let modifier = input.first, modifierSet.contains(modifier) else {
			return nil
		}
		input.removeFirst()
		try forbidWhitespace(after: modifier)
		return modifier
	}

	/// Parses a `<match-placeholder>`'s `<branches>` & its
	/// `<block-terminator>`.
	private mutating func parseBranches() throws(ParsingError) -> [Branch] {
		var branches = [Branch]()
		while skipWhitespace(), let first = input.first, first != blockTerminator {
			if case .unconditional = branches.last {
				throw .unconditionalBranchNotLast
			}
			branches.append(try parseBranch())
		}
		guard !input.isEmpty else {
			throw .missingBlockTerminator
		}
		input.removeFirst()
		guard branches.count >= 2 else {
			throw .singleBranch
		}
		guard case .conditional = branches[branches.count - 2] else {
			throw .unconditionalBranchNotLast
		}
		return branches
	}

	/// Parses a `<branch>`.
	private mutating func parseBranch() throws(ParsingError) -> Branch {
		let isNegated = try parseModifier(in: [branchNegation]) != nil
		let coercion = try parseCoercion()
		guard let letter = input.first else {
			throw .missingPredicate
		}
		input.removeFirst()
		let lowercaseLetter = Character(letter.lowercased())
		let isNonNullary = letter.isUppercase
		if let predicate = UnconditionalPredicate(rawValue: lowercaseLetter) {
			guard !isNegated, coercion == nil else {
				throw .invalidModifier(letter)
			}
			return .unconditional(
				predicate,
				block: isNonNullary
					? try parseBlock(kind: predicate == .input ? .unconditional : .string, enclosingPredicate: nil)
					: nil,
			)
		}
		let matcher = try parseMatcher(letter: letter, coercion: coercion)
		return .conditional(
			matcher,
			isNegated: isNegated,
			block: isNonNullary
				? isNegated
					? try parseBlock(kind: .unconditional, enclosingPredicate: nil)
					: try parseSuccessBlock(for: matcher)
				: nil,
		)
	}

	/// Parses a text token, consuming or ignoring its outer bare whitespace
	/// per `leading` & `trailing`, up to (but not including) an unescaped
	/// character in `terminatorSet`, or the end of the input.
	private mutating func parseText(
		terminatorSet: Set<Character>,
		leading: WhitespaceTreatment,
		trailing: TrailingWhitespaceTreatment,
	) throws(ParsingError) -> String {
		if leading == .ignored {
			skipWhitespace()
		}
		var text = ""
		var trailingBareWhitespaceCount = 0
		while let char = input.first, !terminatorSet.contains(char) {
			input.removeFirst()
			guard char == escapePrefix else {
				text.append(char)
				trailingBareWhitespaceCount = char.isWhitespace ? trailingBareWhitespaceCount + 1 : 0
				continue
			}
			guard let escaped = input.first else {
				throw .danglingEscape
			}
			input.removeFirst()
			text.append(escaped)
			trailingBareWhitespaceCount = 0
		}
		let isTrailingWhitespaceConsumed =
			switch trailing {
			case .consumed:
				true
			case let .consumedBefore(terminator):
				input.first == terminator
			case .ignored:
				false
			}
		if !isTrailingWhitespaceConsumed {
			text.removeLast(trailingBareWhitespaceCount)
		}
		return text
	}

	/// Skips ignored bare whitespace; always returns `true`, so it may precede
	/// a loop condition.
	@discardableResult
	private mutating func skipWhitespace() -> Bool {
		input = input.drop(while: \.isWhitespace)
		return true
	}

	/// Reports an error iff bare whitespace succeeds `token`, whose succeeding
	/// whitespace is forbidden.
	private func forbidWhitespace(after token: Character) throws(ParsingError) {
		guard input.first?.isWhitespace != true else {
			throw .forbiddenWhitespace(after: token)
		}
	}
}

/// How outer bare whitespace preceding a text token is treated.
private enum WhitespaceTreatment { // swiftlint:disable:this one_declaration_per_file
	case consumed
	case ignored
}

/// How outer bare whitespace succeeding a text token is treated.
private enum TrailingWhitespaceTreatment { // swiftlint:disable:this one_declaration_per_file
	case consumed
	/// Consumed iff the text token is succeeded by the given character.
	case consumedBefore(Character)
	case ignored
}

// MARK: - Block kinds

/// A block's kind, which selects its valid pipelines &
/// `<block-placeholder>`s.
private enum BlockKind: Equatable { // swiftlint:disable:this one_declaration_per_file
	case any
	case boolean
	case chronologic
	case number
	case string
	case unconditional

	/// Whether this kind's template may contain `<block-placeholder>`s.
	var hasBlockPlaceholders: Bool {
		switch self {
		case .any, .boolean, .chronologic, .number, .string:
			true
		case .unconditional:
			false
		}
	}

	/// The kind of a non-nullary `<block-placeholder>`'s pipeline block.
	var blockPlaceholderPipelineKind: Self {
		switch self {
		case .any, .boolean, .unconditional: // swiftformat:disable:this sortSwitchCases
			.unconditional
		case .chronologic, .number, .string: // swiftformat:disable:this sortSwitchCases
			self
		}
	}

	/// The pipeline's nonterminal name.
	var pipelineName: String {
		switch self {
		case .any, .boolean, .unconditional: // swiftformat:disable:this sortSwitchCases
			"<unconditional-pipeline>"
		case .chronologic:
			"<chronologic-pipeline>"
		case .number:
			"<number-pipeline>"
		case .string:
			"<string-pipeline>"
		}
	}

	/// The shapes of this kind's pipeline's `<*-transform-call>`s.
	var pipelineShapeSet: Set<PipelineShape> {
		switch self {
		case .any, .boolean, .unconditional: // swiftformat:disable:this sortSwitchCases
			[.unconditional]
		case .chronologic:
			[.chronologic, .unconditional]
		case .number:
			[.number, .numberToString, .unconditional]
		case .string:
			[.string]
		}
	}

	/// The `<success-block>` kind for `predicate`.
	init(successBlockFor predicate: Predicate) {
		self =
			switch predicate {
			case .boolean, .false, .true: // swiftformat:disable:this sortSwitchCases
				.boolean
			case .chronologic:
				.chronologic
			case .empty, .null, .version, .whitespace: // swiftformat:disable:this sortSwitchCases
				.any
			case .number:
				.number
			case .string:
				.string
			}
	}
}

/// The shape of a `<*-transform-pipeline>`'s `<*-transform-call>`s.
private enum PipelineShape { // swiftlint:disable:this one_declaration_per_file
	/// A `<chronologic-transform-pipeline>`.
	case chronologic
	/// A `<number-transform-pipeline>`.
	case number
	/// A `<number-to-string-transform-pipeline>`.
	case numberToString
	/// A `<string-transform-pipeline>`.
	case string
	/// An `<unconditional-transform-pipeline>`.
	case unconditional
}

private extension [TransformCall] {
	/// Whether these calls, which must be non-empty, have `shape`.
	func hasShape(_ shape: PipelineShape) -> Bool {
		guard let first, let last else {
			return false
		}
		return switch shape {
		case .chronologic:
			allSatisfy { $0.transform.kind == .chronologic }
		case .number:
			allSatisfy { $0.transform.kind == .number }
		case .numberToString:
			last.transform.kind == .numberToString && dropLast().allSatisfy { $0.transform.kind == .number }
		case .string:
			allSatisfy { $0.transform.kind == .string }
		case .unconditional:
			first.isCoerced && allSatisfy { $0.transform.kind == .string }
		}
	}
}

private extension TemplateElement {
	var isPlaceholder: Bool {
		if case .placeholder = self {
			true
		} else {
			false
		}
	}
}

private extension Predicate {
	/// The `<coercion>`s this predicate supports.
	var supportedCoercionSet: Set<Coercion?> {
		switch self {
		case .boolean, .false, .true: // swiftformat:disable:this sortSwitchCases
			[.strict]
		case .number:
			[.lenient, .strict]
		case .chronologic, .empty, .null, .string, .version, .whitespace:
			.init()
		}
	}
}

// MARK: - Constants

let formatModifierPrefix = Character(":")
let placeholderPrefix = Character("%")
let blockTerminator = Character("+")
let namePrefix = Character(":")
let transformCallPrefix = Character(".")

private let abortOnSuccess = Character("-")
private let abortOnFailure = Character("+")
private let abortModifierSet = Set([abortOnSuccess, abortOnFailure])
private let strictCoercionPrefix = Character(".")
private let lenientCoercionPrefix = Character("_")
private let branchNegation = Character("-")
private let nullaryMatch = Character("m")

private let argumentFence = Character(":")
private let argumentSeparator = Character(",")

private let formatBlockTerminatorSet = Set([sortModifierPrefix, fieldSpecSeparator])
private let formatBlockNameTerminatorSet = formatBlockTerminatorSet.union([transformCallPrefix])
private let blockNameTerminatorSet = Set([transformCallPrefix, blockTerminator])
private let formatTemplateTextTerminatorSet = formatBlockTerminatorSet.union([placeholderPrefix])
private let blockTemplateTextTerminatorSet = Set([placeholderPrefix, blockTerminator])

private let groupName = "group"
private let scaleName = "scale"
private let timeZoneName = "timeZone"

private let valueTransformByName = [
	"absoluteValue": Transform.absoluteValue,
	"dateOnly": .dateOnly,
	"initialUppercase": .initialUppercase,
	"lowercase": .lowercase,
	"round": .round,
	"trimWhitespace": .trimWhitespace,
	"uppercase": .uppercase,
]
private let justificationByName = [
	"centerEndJustify": Justification.centerEnd,
	"centerStartJustify": .centerStart,
	"endJustify": .end,
	"startJustify": .start,
]
private let transformNames =
	Set(valueTransformByName.keys).union(justificationByName.keys).union([groupName, scaleName, timeZoneName])

/// The shapes of a `<value-transform-pipeline>`'s `<*-transform-call>`s.
private let valueTransformPipelineShapeSet = Set([PipelineShape.string, .number, .numberToString, .chronologic])
