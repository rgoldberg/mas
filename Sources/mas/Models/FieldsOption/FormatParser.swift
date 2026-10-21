//
// FormatParser.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import Foundation

// MARK: - Format parsing (fields-format.md)

/// Parses a `<format-modifier>`'s `<format-block>`, from immediately after its
/// `<format-modifier-prefix>` up to (but not including) a
/// `<sort-modifier-prefix>`, a `<field-spec-separator>`, or the end of the
/// input.
///
/// - Returns: The format & the justification from its
///   `<format-transform-pipeline>`, which is `nil` iff the working fields
///   config's justification is inherited (i.e., `<justify>` is absent).
func parseFormatBlock(_ input: inout Substring) throws(ParsingError)
-> (format: Format, justification: Justification?) {
	var parser = FormatParser(input: input)
	defer {
		input = parser.input
	}
	return try parser.parseFormatBlock()
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

	mutating func parseFormatBlock() throws(ParsingError) -> (format: Format, justification: Justification?) {
		skipWhitespace() // `<format-modifier>`'s `<format-block>` ignores preceding whitespace
		let parsed: (format: Format, justification: Justification?) =
			if isAtFormatBlockEnd {
				(.empty, nil) // An absent `<format-block>` defaults to an empty string
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
				justification = parsed // `<justify>` is `(* last wins *)`
			case let .value(call):
				calls.append(call)
			}
		}
		guard calls.isEmpty || valueTransformPipelineShapeSet.contains(where: calls.hasShape) else {
			throw .invalidPipeline("<value-transform-pipeline>")
		}
		// An absent `<justify>` is inherited
		return (.pipeline(calls), justification)
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
		// TODO: once persisted named formats exist, resolve the name to its format,
		//  checking that its output has the input type of any succeeding
		//  `<transform-pipeline>`
		throw .unknownNamedFormat(try parseText(terminatorSet: terminatorSet, leading: .ignored, trailing: .ignored))
	}

	/// Parses a `<*-transform-call>`, including its `<transform-call-prefix>`.
	private mutating func parseTransformCall() throws(ParsingError) -> ParsedTransformCall {
		input.removeFirst()
		try forbidWhitespace(after: transformCallPrefix)
		let coercion = try parseCoercion()
		let name = transformNames.filter { input.hasPrefix($0) }.max { $0.count < $1.count }
		guard let name else {
			throw .unknownTransform(.init(input.prefix(while: \.isLetter)))
		}
		input.removeFirst(name.count)
		if let justification = justificationByName[name] {
			guard coercion == nil else {
				throw .coercionNotSupported(coercionPrefix)
			}
			return .format(justification)
		}
		let transform: Transform =
			switch name {
			case numberFormatName:
				try parseNumberFormatArgumentsIfPresent()
			case scaleName:
				try parseScaleArguments()
			case timeOnlyTimeZoneName:
				try parseTimeZoneArgumentsIfPresent(for: timeOnlyTimeZoneName, Transform.timeOnlyTimeZone)
			case timeZoneName:
				try parseTimeZoneArgumentsIfPresent(for: timeZoneName, Transform.timeZone)
			default:
				valueTransformByName[name]! // swiftlint:disable:this force_unwrapping
			}
		guard coercion?.hasArguments != true || transform.kind == .number || transform.kind == .numberToString else {
			throw .numberCoercionArgumentsNotSupported(name)
		}
		return .value(.init(transform: transform, coercion: coercion?.coercion))
	}

	/// Parses `numberFormat`'s optional `<number-format-arguments>`, whose base
	/// conventions default to the system locale's.
	private mutating func parseNumberFormatArgumentsIfPresent() throws(ParsingError) -> Transform {
		var afterWhitespace = input.drop(while: \.isWhitespace)
		guard afterWhitespace.first == argumentFence else {
			return .numberFormat(.init(locale: .current))
		}
		afterWhitespace.removeFirst()
		input = afterWhitespace
		let invalidArgumentsError = ParsingError.invalidTransformArguments(name: numberFormatName)
		let arguments = try parseArguments(
			&input,
			count: numberFormatArgumentCount,
			terminator: argumentFence,
			isLastArgumentSeparatorTerminated: false,
		)
		try parseArgumentFence(for: numberFormatName)
		return .numberFormat(
			try numberConventions(
				from: arguments[...],
				defaultBaseConventions: .init(locale: .current),
				invalidArgumentsError: invalidArgumentsError,
			),
		)
	}

	/// Parses `scale`'s `<scale-arguments>`.
	private mutating func parseScaleArguments() throws(ParsingError) -> Transform {
		try parseArgumentFence(for: scaleName)
		let arguments = try parseArguments(
			&input,
			count: 4,
			terminator: argumentFence,
			isLastArgumentSeparatorTerminated: true,
		)
		try parseArgumentFence(for: scaleName)
		let integers = arguments.map { $0.map { nonNegativeInteger($0) ?? -1 } }
		guard
			let radix = integers[0], (2...36).contains(radix),
			let exponent = integers[1], exponent >= 0,
			integers[2].map((1...100).contains) ?? true,
			let fractionalDigits = integers[3], (0...100).contains(fractionalDigits)
		else {
			throw .invalidTransformArguments(name: scaleName)
		}
		return .scale(
			radix: radix,
			exponent: exponent,
			significantDigits: integers[2],
			fractionalDigits: fractionalDigits,
		)
	}

	/// Parses `timeZone`'s or `timeOnlyTimeZone`'s (named `transformName`)
	/// optional `<time-zone-arguments>`, whose `<time-zone-code>` defaults to
	/// `system` & whose absent `<reference-date>` is `nil`, into the transform
	/// that `transform` makes.
	private mutating func parseTimeZoneArgumentsIfPresent(
		for transformName: String,
		_ transform: (TimeZone, CivilDate?) -> Transform,
	) throws(ParsingError) -> Transform {
		let invalidArgumentsError = ParsingError.invalidTransformArguments(name: transformName)
		let afterWhitespace = input.drop(while: \.isWhitespace)
		var arguments = [String?](repeating: nil, count: 2)
		if afterWhitespace.first == argumentFence {
			input = afterWhitespace.dropFirst()
			arguments = try parseArguments(
				&input,
				count: 2,
				terminator: argumentFence,
				isLastArgumentSeparatorTerminated: false,
			)
			try parseArgumentFence(for: transformName)
		}
		guard let timeZone = timeZone(forCode: arguments[0] ?? systemTimeZoneCode) else {
			throw invalidArgumentsError
		}
		return transform(
			timeZone,
			try arguments[1].map { argument throws(ParsingError) in
				guard let referenceDate = CivilDate(iso8601Text: argument) else {
					throw invalidArgumentsError
				}
				return referenceDate
			},
		)
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
	private mutating func parseBlock(kind: BlockKind, enclosingPredicate: Predicate?) throws(ParsingError) -> Format {
		skipWhitespace() // A block ignores preceding whitespace
		let block: Format =
			if input.first == blockTerminator {
				.empty // An absent block defaults to an empty string
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

	/// Parses a pipeline of kind `kind`, without a template, then its
	/// `<block-terminator>`.
	private mutating func parsePipelineBlock(kind: BlockKind) throws(ParsingError) -> [TransformCall] {
		skipWhitespace() // A pipeline ignores preceding whitespace
		let calls = try parseBlockPipeline(kind: kind)
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

	/// Parses a `<non-nullary-unconditional-placeholder>`'s pipeline & its
	/// `<block-terminator>`.
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
		if lowercaseLetter == unaryMatch {
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

	/// Parses `matcher`'s `<success-block>` & its `<block-terminator>`.
	private mutating func parseSuccessBlock(for matcher: Matcher) throws(ParsingError) -> Format {
		try parseBlock(kind: .init(successBlockFor: matcher.predicate), enclosingPredicate: matcher.predicate)
	}

	/// Parses a scalar conditional `<predicate>` `letter`, validating that
	/// `coercion` is supported by it.
	private func parseMatcher(letter: Character, coercion: ParsedCoercion?) throws(ParsingError) -> Matcher {
		guard let predicate = Predicate(rawValue: Character(letter.lowercased())) else {
			throw .invalidLetter(letter)
		}
		if let coercion {
			guard predicate.isCoercible else {
				throw .coercionNotSupported(letter)
			}
			guard !coercion.hasArguments || predicate == .number else {
				throw .numberCoercionArgumentsNotSupported(.init(letter))
			}
		}
		return .init(predicate: predicate, coercion: coercion?.coercion)
	}

	/// Parses an optional `<coercion>` or `<number-coercion>`.
	private mutating func parseCoercion() throws(ParsingError) -> ParsedCoercion? {
		guard try parseModifier(in: [coercionPrefix]) != nil else {
			return nil
		}
		guard input.first == argumentFence else {
			return .init(coercion: .default, hasArguments: false)
		}
		input.removeFirst()
		let arguments = try parseArguments(
			&input,
			count: numberFormatArgumentCount + 2,
			terminator: argumentFence,
			isLastArgumentSeparatorTerminated: false,
		)
		guard input.first == argumentFence else {
			throw .invalidNumberCoercionArguments
		}
		input.removeFirst()
		skipWhitespace() // Unlike `<coercion>`'s, its closing `<argument-fence>`'s succeeding whitespace is ignored
		let triviaPrefixPattern = arguments[numberFormatArgumentCount] ?? ""
		let triviaSuffixPattern = arguments[numberFormatArgumentCount + 1] ?? ""
		guard let triviaPrefixRegex = TriviaRegex(pattern: triviaPrefixPattern) else {
			throw .invalidTriviaRegex(triviaPrefixPattern)
		}
		guard let triviaSuffixRegex = TriviaRegex(pattern: triviaSuffixPattern) else {
			throw .invalidTriviaRegex(triviaSuffixPattern)
		}
		return .init(
			coercion: .init(
				numberConventions: try numberConventions(
					from: arguments[..<numberFormatArgumentCount],
					defaultBaseConventions: .canonical,
					invalidArgumentsError: .invalidNumberCoercionArguments,
				),
				triviaPrefixRegex: triviaPrefixRegex,
				triviaSuffixRegex: triviaSuffixRegex,
			),
			hasArguments: true,
		)
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

	/// Parses a `<match-placeholder>`'s `<branches>` & its `<block-terminator>`.
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

	/// Parses a text token, consuming or ignoring its outer bare whitespace per
	/// `leading` & `trailing`, up to (but not including) an unescaped character
	/// in `terminatorSet`, or the end of the input.
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

	/// Skips ignored bare whitespace; always returns `true`, so it may precede a
	/// loop condition.
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

/// A parsed `<coercion>` or `<number-coercion>`.
private struct ParsedCoercion { // swiftlint:disable:this one_declaration_per_file
	let coercion: Coercion
	/// Whether `<number-coercion-arguments>` are present.
	let hasArguments: Bool
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

/// A block's kind, which selects its valid pipelines & `<block-placeholder>`s.
private enum BlockKind: Equatable { // swiftlint:disable:this one_declaration_per_file
	case any
	case boolean
	case date
	case number
	case string
	case timeOnly
	case unconditional

	/// Whether this kind's template may contain `<block-placeholder>`s.
	var hasBlockPlaceholders: Bool {
		switch self {
		case .any, .boolean, .date, .number, .string, .timeOnly:
			true
		case .unconditional:
			false
		}
	}

	/// The kind of a non-nullary `<block-placeholder>`'s pipeline block.
	var blockPlaceholderPipelineKind: Self {
		switch self {
		case .any, .boolean, .unconditional:
			.unconditional
		case .date, .number, .string, .timeOnly:
			self
		}
	}

	/// The pipeline's nonterminal name.
	var pipelineName: String {
		switch self {
		case .any, .boolean, .unconditional:
			"<unconditional-pipeline>"
		case .date:
			"<date-pipeline>"
		case .number:
			"<number-pipeline>"
		case .string:
			"<string-pipeline>"
		case .timeOnly:
			"<time-only-pipeline>"
		}
	}

	/// The shapes of this kind's pipeline's `<*-transform-call>`s.
	var pipelineShapeSet: Set<PipelineShape> {
		switch self {
		case .any, .boolean, .unconditional:
			[.unconditional]
		case .date:
			[.date, .unconditional]
		case .number:
			[.number, .numberToString, .unconditional]
		case .string:
			[.string]
		case .timeOnly:
			[.timeOnly, .unconditional]
		}
	}

	/// The `<success-block>` kind for `predicate`.
	init(successBlockFor predicate: Predicate) {
		self =
			switch predicate {
			case .boolean, .false, .true:
				.boolean
			case .date:
				.date
			case .empty, .null, .whitespace:
				.any
			case .number:
				.number
			case .string, .version:
				.string
			case .timeOnly:
				.timeOnly
			}
	}
}

/// The shape of a `<*-transform-pipeline>`'s `<*-transform-call>`s.
private enum PipelineShape { // swiftlint:disable:this one_declaration_per_file
	/// A `<date-transform-pipeline>`.
	case date
	/// A `<number-transform-pipeline>`.
	case number
	/// A `<number-to-string-transform-pipeline>`.
	case numberToString
	/// A `<string-transform-pipeline>`.
	case string
	/// A `<time-only-transform-pipeline>`.
	case timeOnly
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
		case .date:
			allSatisfy { $0.transform.kind == .date }
		case .number:
			allSatisfy { $0.transform.kind == .number }
		case .numberToString:
			last.transform.kind == .numberToString && dropLast().allSatisfy { $0.transform.kind == .number }
		case .string:
			allSatisfy { $0.transform.kind == .string }
		case .timeOnly:
			allSatisfy { $0.transform.kind == .timeOnly }
		case .unconditional:
			first.coercion != nil && allSatisfy { $0.transform.kind == .string }
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
	/// Whether this predicate supports a `<coercion>`.
	var isCoercible: Bool {
		switch self {
		case .boolean, .date, .false, .number, .true:
			true
		case .empty, .null, .string, .timeOnly, .version, .whitespace:
			false
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
private let coercionPrefix = Character(".")
private let branchNegation = Character("-")
private let unaryMatch = Character("m")

private let formatBlockTerminatorSet = Set([sortModifierPrefix, fieldSpecSeparator])
private let formatBlockNameTerminatorSet = formatBlockTerminatorSet.union([transformCallPrefix])
private let blockNameTerminatorSet = Set([transformCallPrefix, blockTerminator])
private let formatTemplateTextTerminatorSet = formatBlockTerminatorSet.union([placeholderPrefix])
private let blockTemplateTextTerminatorSet = Set([placeholderPrefix, blockTerminator])

private let numberFormatName = "numberFormat"
private let scaleName = "scale"
private let timeOnlyTimeZoneName = "timeOnlyTimeZone"
private let timeZoneName = "timeZone"

private let systemTimeZoneCode = "system"

private let valueTransformByName = [
	"absoluteValue": Transform.absoluteValue,
	"dateOnly": .dateOnly,
	"initialTitlecase": .initialTitlecase,
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
	Set(valueTransformByName.keys).union(justificationByName.keys).union([
		numberFormatName,
		scaleName,
		timeOnlyTimeZoneName,
		timeZoneName,
	])

/// The shapes of a `<value-transform-pipeline>`'s `<*-transform-call>`s.
private let valueTransformPipelineShapeSet = Set([PipelineShape.string, .number, .numberToString, .date, .timeOnly])
