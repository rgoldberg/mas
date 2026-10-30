//
// Preset.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

/// Parses an optional `<preset-modifier>`: the names of the presets that it
/// leaves attached, in attachment order, given `attached`, those of the presets
/// already attached, which it retains iff absent. An `<absolute-presets>`
/// replaces them (attaching a repeated preset only at its last occurrence),
/// while a `<relative-presets>` applies its `<preset-delta>`s to them.
func parsePresetModifier(_ input: inout Substring, attached: [String]) throws(ParsingError) -> [String] {
	input = input.drop(while: \.isWhitespace)
	guard input.first == presetPrefix else {
		return attached
	}
	let isRelative = input.dropFirst().first.map(presetDeltaOperatorSet.contains) == true
	var presetNames = isRelative ? attached : []
	var isFirst = true
	while input.first == presetPrefix {
		input.removeFirst()
		let deltaOperator = input.first.map(presetDeltaOperatorSet.contains) == true ? input.removeFirst() : nil
		guard (deltaOperator != nil) == isRelative else {
			throw .mixedAbsoluteAndRelativePresets
		}
		let name = try parseEscapedText(&input, terminatorSet: presetNameTerminatorSet)
		input = input.drop(while: \.isWhitespace)
		if name.isEmpty, !isRelative, isFirst, input.first != presetPrefix {
			break // A `<preset-clearing>`
		}
		_ = try presetAlignment(named: name) // Validates that the preset exists
		presetNames.removeAll { $0 == name }
		if deltaOperator != presetRemoval {
			presetNames.append(name)
		}
		isFirst = false
	}
	return presetNames
}

/// The alignment that the preset named `name` sets, else `nil`. No custom
/// presets exist yet, so only the built-in ones & `default` (which is
/// `standard` absent a custom `default`) exist; any other name reports an
/// error: `invalidPresetName` for an invalid preset name, else `unknownPreset`.
func presetAlignment(named name: String) throws(ParsingError) -> Alignment? {
	guard name.isConfigName else {
		throw .invalidPresetName(name)
	}
	// swiftlint:disable:next todo
	// TODO: Temp/todo.md "Persisted Custom Presets & Configs": once custom
	//  presets are persisted, look the name up through the context stack from the
	//  reference's starting context, as configs.md specifies for every config
	//  kind, set its label, format & sort, too, when attached, recording when
	//  each setting of a field spec is set, so that detaching a preset re-exposes
	//  each value that it overrode, attach its own presets within it & report a
	//  preset attached within itself
	guard presetNameSet.contains(name) else {
		throw .unknownPreset(name)
	}
	return alignmentByPresetName[name]
}

let presetPrefix = Character("%")
let presetAddition = Character("+")
let presetRemoval = Character("-")

/// The `<preset-delta>` operators.
private let presetDeltaOperatorSet = Set([presetAddition, presetRemoval])

/// The characters that terminate a `<preset-name>` in a `<preset-modifier>`.
private let presetNameTerminatorSet =
	Set([presetPrefix, labelModifierPrefix, formatModifierPrefix, sortModifierPrefix, fieldSpecSeparator])

/// The alignment of each existing preset that sets one, by preset name.
let alignmentByPresetName = [
	"centerEnd": Alignment.centerEnd,
	"centerStart": .centerStart,
	"end": .end,
	"start": .start,
]

/// Each existing preset's name.
private let presetNameSet = Set(alignmentByPresetName.keys).union([defaultConfigName, standardConfigName])
