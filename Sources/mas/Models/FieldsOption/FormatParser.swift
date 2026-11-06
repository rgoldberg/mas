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
func parseFormatBlock(_ input: inout Substring) throws(ParsingError) -> Format {
	var parser = FormatParser(input: input)
	defer {
		input = parser.input
	}
	return try parser.parseFormatBlock()
}

/// A recursive-descent parser for fields-format.md's syntax.
private struct FormatParser {
	var input: Substring

	/// Whether the input is at the end of a `<format-block>`.
	private var isAtFormatBlockEnd: Bool {
		input.first.map(formatBlockTerminatorSet.contains) ?? true
	}

	mutating func parseFormatBlock() throws(ParsingError) -> Format {
		skipWhitespace() // `<format-modifier>`'s `<format-block>` ignores preceding whitespace
		let parsed: Format =
			if isAtFormatBlockEnd {
				.empty // A directly absent `<format-block>` defaults to an empty string
			} else if input.first == namePrefix || input.first == transformCallPrefix {
				.pipeline(try parseFormatBlockPipeline())
			} else {
				.template(try parseFormatTemplate())
			}
		skipWhitespace()
		guard isAtFormatBlockEnd else {
			throw .unexpectedCharacter(input.first ?? " ")
		}
		return parsed
	}

	/// Parses a `<format-block>`'s `<pipeline>`.
	private mutating func parseFormatBlockPipeline() throws(ParsingError) -> Pipeline {
		let namedFormat = try parseNamedFormatIfPresent(terminatorSet: formatBlockNameTerminatorSet)
		var calls = [TransformCall]()
		while skipWhitespace(), input.first == transformCallPrefix {
			calls.append(try parseTransformCall())
		}
		guard calls.followsTypes(from: nil) else {
			throw .invalidPipeline("<value-transform-pipeline>")
		}
		return .init(namedFormat: namedFormat, calls: calls)
	}

	/// Parses a block's `<*-pipeline>`, whose kind `kind` selects the valid
	/// transforms.
	private mutating func parseBlockPipeline(kind: BlockKind) throws(ParsingError) -> Pipeline {
		let namedFormat = try parseNamedFormatIfPresent(terminatorSet: blockNameTerminatorSet)
		var calls = [TransformCall]()
		while skipWhitespace(), input.first == transformCallPrefix {
			calls.append(try parseTransformCall())
		}
		// A named format may form a pipeline alone
		guard calls.isEmpty ? namedFormat != nil : kind.isPipeline(calls, isNamed: namedFormat != nil) else {
			throw .invalidPipeline(kind.pipelineName)
		}
		return .init(namedFormat: namedFormat, calls: calls)
	}

	/// Parses a `<named-format-reference>`, if present, into its preset's named
	/// format. No custom presets exist yet, so each existing preset (a built-in
	/// one, or `default`, which is `standard` absent a custom `default`) sets no
	/// format, so its named format is `%i`; any other reference reports an error:
	/// `invalidPresetName` for an invalid preset name, else `unknownPreset`.
	private mutating func parseNamedFormatIfPresent(terminatorSet: Set<Character>) throws(ParsingError) -> Format? {
		guard input.first == namePrefix else {
			return nil
		}
		input.removeFirst()
		try forbidWhitespace(after: namePrefix)
		// swiftlint:disable:next todo
		// TODO: Temp/todo.md "Persistent Custom Presets & Configs": once custom
		//  presets are persisted, use the format of the preset that
		//  `presetAlignment(named:)` resolves, checking that it conforms to the
		//  block that its `<*-format-name>`'s error comment names
		_ = try presetAlignment(
			named: parseText(terminatorSet: terminatorSet, leading: .ignored, trailing: .ignored),
		)
		return .standard
	}

	/// Parses a `<*transform-call>`, including its `<transform-call-prefix>`.
	private mutating func parseTransformCall() throws(ParsingError) -> TransformCall {
		input.removeFirst()
		try forbidWhitespace(after: transformCallPrefix)
		let coercion = try parseCoercion()
		guard let name = parseNameLiteral(&input, from: transformNames) else {
			let unknownName = input.prefixMatch(of: /(?:\\?\p{L})*/)?.output ?? ""
			throw input.dropFirst(unknownName.count) == String(escapePrefix)
				? .danglingEscape
				: .unknownTransform(.init(unknownName.filter { $0 != escapePrefix }))
		}
		let transform: Transform =
			switch name {
			case numberFormatName:
				try parseNumberFormatArgumentsIfPresent()
			case scaleName:
				try parseScaleArguments()
			case timeOnlyTimeZoneName:
				try parseTimeZoneArgumentsIfPresent(
					for: timeOnlyTimeZoneName,
					hasReferenceDate: true,
				) { timeZone, referenceDate in
					.timeOnlyTimeZone(timeZone, referenceDate: referenceDate)
				}
			case timeZoneName:
				try parseTimeZoneArgumentsIfPresent(for: timeZoneName, hasReferenceDate: false) { timeZone, _ in
					.timeZone(timeZone)
				}
			default:
				valueTransformByName[name]! // swiftlint:disable:this force_unwrapping
			}
		switch coercion?.argumentKind {
		case .date:
			guard
				transform.kind == .dateOnly
				|| transform.kind == .date && coercion?.coercion.dateFormats.isDateOnly == false
			else {
				throw .dateCoercionArgumentsNotSupported(name)
			}
		case .number:
			guard transform.kind == .number || transform.kind == .numberToString else {
				throw .numberCoercionArgumentsNotSupported(name)
			}
		case nil:
			break
		}
		return .init(transform: transform, coercion: coercion?.coercion)
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
		// A `<digit-group-size>` of `0` inserts no `<digit-group-separator>`
		guard arguments[1] == nil || arguments[2].flatMap(nonNegativeInteger) != 0 else {
			throw invalidArgumentsError
		}
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
			count: 3,
			terminator: argumentFence,
			isLastArgumentSeparatorTerminated: true,
		)
		try parseArgumentFence(for: scaleName)
		let integers = arguments.dropFirst().map { $0.map { nonNegativeInteger($0) ?? -1 } }
		guard
			let exponent = arguments[0].flatMap(integer),
			integers[0].map((1...100).contains) ?? true,
			integers[1].map((0...100).contains) ?? true
		else {
			throw .invalidTransformArguments(name: scaleName)
		}
		return .scale(exponent: exponent, significantDigits: integers[0], fractionalDigits: integers[1])
	}

	/// Parses `timeZone`'s `<date-time-zone-arguments>` or `timeOnlyTimeZone`'s
	/// `<time-only-time-zone-arguments>` (iff `hasReferenceDate`), each optional,
	/// for the transform named `transformName`, whose `<time-zone-code>` defaults
	/// to `system` & whose absent `<reference-date>` is `nil`, into the transform
	/// that `transform` makes.
	private mutating func parseTimeZoneArgumentsIfPresent(
		for transformName: String,
		hasReferenceDate: Bool,
		_ transform: (TimeZone, CivilDate?) -> Transform,
	) throws(ParsingError) -> Transform {
		let invalidArgumentsError = ParsingError.invalidTransformArguments(name: transformName)
		let afterWhitespace = input.drop(while: \.isWhitespace)
		let argumentCount = hasReferenceDate ? 2 : 1
		var arguments = [String?](repeating: nil, count: argumentCount)
		if afterWhitespace.first == argumentFence {
			input = afterWhitespace.dropFirst()
			arguments = try parseArguments(
				&input,
				count: argumentCount,
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
			try (hasReferenceDate ? arguments[1] : nil).map { argument throws(ParsingError) in
				guard let referenceDate = CivilDate(iso8601Text: argument), referenceDate.startInstant != nil else {
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
				.empty // A directly absent block defaults to an empty string
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
	private mutating func parsePipelineBlock(kind: BlockKind) throws(ParsingError) -> Pipeline {
		skipWhitespace() // A pipeline ignores preceding whitespace
		let pipeline = try parseBlockPipeline(kind: kind)
		skipWhitespace()
		guard input.first == blockTerminator else {
			throw .missingBlockTerminator
		}
		input.removeFirst()
		return pipeline
	}

	/// Parses a `<block-template>` of a block of kind `kind`, up to its
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

	/// Parses a placeholder in a `<block-template>`: an
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
					pipeline: letter.isUppercase
						? try parseUnconditionalPipelineBlock(predicate, enclosingKind: kind)
						: .init(),
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
	/// `<block-terminator>`, per its enclosing block's kind `enclosingKind`, or,
	/// iff `nil`, for a `<format-template>`'s placeholder.
	private mutating func parseUnconditionalPipelineBlock(_ predicate: UnconditionalPredicate, enclosingKind: BlockKind?)
	throws(ParsingError) -> Pipeline {
		try parsePipelineBlock(
			kind: predicate == .input
				? enclosingKind?.inputPipelineKind ?? .input
				: enclosingKind == .unconditional ? .unconditionalString : .string,
		)
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
				pipeline: isNonNullary ? try parseUnconditionalPipelineBlock(predicate, enclosingKind: nil) : .init(),
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
			.conditional(matcher, try parseBinaryBlocks(for: matcher))
		}
	}

	/// Parses a binary placeholder's `<success-block>` & `<failure-block>`, each
	/// with its `<block-terminator>`, at least 1 of which is present, because
	/// both directly absent (e.g., `%S++`) would always insert an empty string.
	private mutating func parseBinaryBlocks(for matcher: Matcher) throws(ParsingError) -> ConditionalForm {
		let success = try parseSuccessBlock(for: matcher)
		let failure = try parseBlock(kind: .unconditional, enclosingPredicate: nil)
		guard success != .empty || failure != .empty else {
			throw .binaryPlaceholderLacksBlock
		}
		return .binary(success: success, failure: failure)
	}

	/// Parses `matcher`'s `<success-block>` & its `<block-terminator>`.
	private mutating func parseSuccessBlock(for matcher: Matcher) throws(ParsingError) -> Format {
		try parseBlock(kind: .init(successBlockFor: matcher), enclosingPredicate: matcher.predicate)
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
			switch coercion.argumentKind {
			case .date:
				guard predicate == .date else {
					throw .dateCoercionArgumentsNotSupported(.init(letter))
				}
			case .number:
				guard predicate == .number else {
					throw .numberCoercionArgumentsNotSupported(.init(letter))
				}
			case nil:
				break
			}
		}
		return .init(predicate: predicate, coercion: coercion?.coercion)
	}

	/// Parses an optional `<*coercion>`.
	private mutating func parseCoercion() throws(ParsingError) -> ParsedCoercion? {
		guard try parseModifier(in: [coercionPrefix]) != nil else {
			return nil
		}
		guard input.first == argumentFence else {
			return .init(coercion: .default, argumentKind: nil)
		}
		input.removeFirst()
		if let dateFormats = try parseDateFormatsIfPresent() {
			guard input.first == argumentFence else {
				throw .invalidDateCoercionArguments
			}
			input.removeFirst()
			skipWhitespace() // As for `<number-coercion-arguments>`' closing `<argument-fence>`
			return .init(coercion: .date(dateFormats), argumentKind: .date)
		}
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
			argumentKind: .number,
		)
	}

	/// Parses a list of `<date-format>`s, if present, which only a
	/// `<date-format>` starts.
	private mutating func parseDateFormatsIfPresent() throws(ParsingError) -> ChronologicFormats? {
		guard let firstName = parseNameLiteral(&input, from: dateFormatNames) else {
			return nil
		}
		var names = [firstName]
		while input.first == argumentSeparator {
			input.removeFirst()
			guard let name = parseNameLiteral(&input, from: dateFormatNames) else {
				throw .invalidDateCoercionArguments
			}
			names.append(name)
		}
		return .init(
			iso8601Forms: .init(names.flatMap { iso8601FormsByDateFormat[$0, default: []] }),
			hasUnixTime: names.contains(unixTimeDateFormat),
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
			branches.append(try parseBranch())
		}
		guard !input.isEmpty else {
			throw .missingBlockTerminator
		}
		input.removeFirst()
		guard branches.count >= 2 else {
			throw .singleBranch
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
		let matcher = try parseMatcher(letter: letter, coercion: coercion)
		return .init(
			matcher: matcher,
			isNegated: isNegated,
			block: letter.isUppercase
				? isNegated
					? try parseBlock(kind: .unconditional, enclosingPredicate: nil)
					: try parseSuccessBlock(for: matcher)
				: nil,
		)
	}

	/// Parses a variable token, consuming or ignoring its outer bare whitespace
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

/// A parsed `<*coercion>`.
private struct ParsedCoercion { // swiftlint:disable:this one_declaration_per_file
	/// Which kind of arguments are present, if any.
	enum ArgumentKind {
		/// `<date-coercion-arguments>`.
		case date
		/// `<number-coercion-arguments>`.
		case number
	}

	let coercion: Coercion
	let argumentKind: ArgumentKind?
}

/// How outer bare whitespace preceding a variable token is treated.
private enum WhitespaceTreatment { // swiftlint:disable:this one_declaration_per_file
	case consumed
	case ignored
}

/// How outer bare whitespace succeeding a variable token is treated.
private enum TrailingWhitespaceTreatment { // swiftlint:disable:this one_declaration_per_file
	case consumed
	/// Consumed iff the variable token is succeeded by the given character.
	case consumedBefore(Character)
	case ignored
}

// MARK: - Block kinds

/// A block's kind, which selects its valid pipelines & `<block-placeholder>`s.
private enum BlockKind: Equatable { // swiftlint:disable:this one_declaration_per_file
	case boolean
	case date
	case dateOnly
	/// A `<fallible-unconditional-placeholder>`'s `%I…+` pipeline's kind, which
	/// no block has.
	case input
	/// A `%I…+` pipeline's kind in `%U`'s or `%E`'s `<success-block>`, which no
	/// block has.
	case namedInput
	/// `%U`'s or `%E`'s, whose value no transform can modify, so its pipeline
	/// must start with a `<named-format-reference>`.
	case nullOrEmpty
	case number
	case string
	case timeOnly
	case unconditional
	/// An `<infallible-unconditional-placeholder>`'s `%L…+` or `%K…+` pipeline's
	/// kind, which no block has.
	case unconditionalString
	case version
	/// `%W`'s, whose value only `trimWhitespace` can modify, so any other
	/// transform must follow a `<named-format-reference>`.
	case whitespace
	/// A `%I…+` pipeline's kind in `%W`'s `<success-block>`, which no block has.
	case whitespaceInput

	/// Whether this kind's template may contain `<block-placeholder>`s.
	var hasBlockPlaceholders: Bool {
		switch self {
		case .boolean, .date, .dateOnly, .nullOrEmpty, .number, .string, .timeOnly, .version, .whitespace:
			true
		case .input, .namedInput, .unconditional, .unconditionalString, .whitespaceInput:
			false
		}
	}

	/// The kind of a non-nullary `<block-placeholder>`'s pipeline block.
	var blockPlaceholderPipelineKind: Self {
		switch self {
		case .boolean, .input, .namedInput, .unconditional, .unconditionalString, .whitespaceInput:
			.unconditional
		case .date, .dateOnly, .nullOrEmpty, .number, .string, .timeOnly, .version, .whitespace:
			self
		}
	}

	/// The kind of a `%I…+` pipeline in this kind's template.
	var inputPipelineKind: Self {
		switch self {
		case .boolean, .date, .dateOnly, .number, .string, .timeOnly, .version:
			.input
		case .input, .namedInput, .unconditionalString, .whitespaceInput:
			.input
		case .nullOrEmpty:
			.namedInput
		case .unconditional:
			.unconditional
		case .whitespace:
			.whitespaceInput
		}
	}

	/// The pipeline's nonterminal name.
	var pipelineName: String {
		switch self {
		case .boolean, .unconditional:
			"<unconditional-pipeline>"
		case .date:
			"<date-pipeline>"
		case .dateOnly:
			"<date-only-pipeline>"
		case .input:
			"<named-format-pipeline>"
		case .namedInput:
			"<named-input-pipeline>"
		case .nullOrEmpty:
			"<named-unconditional-pipeline>"
		case .number:
			"<number-pipeline>"
		case .string:
			"<string-pipeline>"
		case .timeOnly:
			"<time-only-pipeline>"
		case .unconditionalString:
			"<unconditional-string-pipeline>"
		case .version:
			"<version-pipeline>"
		case .whitespace:
			"<whitespace-pipeline>"
		case .whitespaceInput:
			"<whitespace-input-pipeline>"
		}
	}

	/// The `<success-block>` kind for `matcher`.
	init(successBlockFor matcher: Matcher) {
		self =
			switch matcher.predicate {
			case .boolean, .false, .true:
				.boolean
			case .date:
				matcher.coercion?.dateFormats.isDateOnly == true ? .dateOnly : .date
			case .empty, .null:
				.nullOrEmpty
			case .number:
				.number
			case .string:
				.string
			case .timeOnly:
				.timeOnly
			case .version:
				.version
			case .whitespace:
				.whitespace
			}
	}

	/// Whether `calls`, which must be non-empty, form this kind's pipeline after
	/// a `<named-format-reference>` iff `isNamed`, whose value's type only its
	/// preset determines.
	func isPipeline(_ calls: [TransformCall], isNamed: Bool) -> Bool {
		switch self {
		case .boolean, .unconditional:
			(isNamed || calls.first?.coercion != nil) && calls.isStringTransformRun
		case .date:
			calls.followsTypes(from: isNamed ? nil : .date)
		case .dateOnly:
			(isNamed || calls.first?.coercion != nil) && calls.followsTypes(from: isNamed ? nil : .dateOnly)
		case .input:
			calls.followsTypes(from: nil)
		case .namedInput:
			isNamed && calls.followsTypes(from: nil)
		case .nullOrEmpty:
			isNamed && calls.isStringTransformRun
		case .number:
			calls.followsTypes(from: isNamed ? nil : .number)
		case .string:
			calls.followsTypes(from: isNamed ? nil : .string)
		case .timeOnly:
			calls.followsTypes(from: isNamed ? nil : .timeOnly)
		case .unconditionalString:
			(isNamed || calls.first?.coercion == nil) && calls.isStringTransformRun
		case .version:
			calls.followsTypes(from: isNamed ? nil : .version)
		case .whitespace:
			isNamed ? calls.isStringTransformRun : calls.isUncoercedTrimWhitespaceRun
		case .whitespaceInput:
			isNamed ? calls.followsTypes(from: nil) : calls.isUncoercedTrimWhitespaceRun
		}
	}
}

private extension [TransformCall] {
	/// Whether these calls are string transforms, none after the 1st coerced.
	var isStringTransformRun: Bool {
		allSatisfy { $0.transform.kind == .string } && dropFirst().allSatisfy { $0.coercion == nil }
	}

	/// Whether these calls are all `trimWhitespace`, none coerced.
	var isUncoercedTrimWhitespaceRun: Bool {
		allSatisfy { $0.transform == .trimWhitespace && $0.coercion == nil }
	}

	/// Whether each of these calls follows the value type of its input: `type`
	/// (unknown iff `nil`) for the 1st, then its predecessor's output type.
	func followsTypes(from type: TransformValueType?) -> Bool {
		zip([type] + map(\.transform.kind.outputType), self).allSatisfy { type, call in
			type.map { call.follows($0) } ?? true
		}
	}
}

private extension TransformCall {
	/// Whether this call may take an input of `type`: it takes a `<coercion>` iff
	/// its input type differs, but only where a value of `type` can render as a
	/// value of its input type.
	func follows(_ type: TransformValueType) -> Bool {
		let inputType = transform.kind.inputType
		return if let coercion {
			switch type {
			case .date, .dateOnly, .timeOnly:
				inputType == .string
			case .number:
				inputType == .string || inputType == .date && coercion.dateFormats.isNumberUnixTime
			case .string:
				inputType != .string
			case .version:
				switch inputType {
				case .date:
					coercion.dateFormats.hasUnixTime || transform.kind == .dateOnly && coercion.dateFormats
						.iso8601Forms != [.datetime]
				case .timeOnly:
					false
				default:
					true
				}
			}
		} else {
			inputType == type || transform.kind == .dateOnly && type == .dateOnly
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
		case .boolean, .date, .false, .number, .string, .timeOnly, .true, .version:
			true
		case .empty, .null, .whitespace:
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
/// The `<date-format>`s other than `<unix-time>`, by name literal.
private let iso8601FormsByDateFormat = [
	"iso": ChronologicFormats.date.iso8601Forms,
	"iso-date": [.date],
	"iso-datetime": [.datetime],
] as [String: Set<ISO8601Form>]
private let unixTimeDateFormat = "unix-time"
private let dateFormatNames = iso8601FormsByDateFormat.keys + [unixTimeDateFormat]
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
private let transformNames =
	Set(valueTransformByName.keys).union([
		numberFormatName,
		scaleName,
		timeOnlyTimeZoneName,
		timeZoneName,
	])
