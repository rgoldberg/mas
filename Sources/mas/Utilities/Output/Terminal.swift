//
// Terminal.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import Darwin

enum Alignment: Equatable { // swiftlint:disable sorted_enum_cases
	case start
	case centerStart
	case centerEnd
	case end // swiftlint:enable sorted_enum_cases
}

extension String { // swiftlint:disable:next function_default_parameter_at_end
	func terminalAlign(_ alignment: Alignment = .start, with pad: Character = " ", to minimumWidth: Int)
	-> Self {
		precondition(pad.terminalWidth == 1)
		let paddingWidths = terminalPaddingWidths(alignment, to: minimumWidth)
		return .init(repeating: pad, count: paddingWidths.leading)
			+ self
			+ .init(repeating: pad, count: paddingWidths.trailing)
	}

	/// The widths of the leading & trailing padding that align this string per
	/// `alignment` to `minimumWidth`, both 0 iff it is already at least that
	/// wide.
	func terminalPaddingWidths(_ alignment: Alignment, to minimumWidth: Int) -> (leading: Int, trailing: Int) {
		let paddingWidth = Swift::max(0, minimumWidth - terminalWidth)
		return switch alignment {
		case .start:
			(0, paddingWidth)
		case .centerStart:
			(paddingWidth / 2, (paddingWidth + 1) / 2)
		case .centerEnd:
			((paddingWidth + 1) / 2, paddingWidth / 2)
		case .end:
			(paddingWidth, 0)
		}
	}
}

extension StringProtocol {
	var terminalWidth: Int {
		reduce(0) { $0 + $1.terminalWidth }
	}
}

private extension Character {
	/// An emoji presentation sequence (incl. a ZWJ, flag, keycap, or modifier
	/// sequence) occupies 2 columns as a whole; any other character occupies the
	/// sum of its scalars' widths (e.g., a base & its 0-width combining marks).
	var terminalWidth: Int {
		unicodeScalars.first.map { firstScalar in
			firstScalar.properties.isEmojiPresentation
				|| firstScalar.properties.isEmoji && unicodeScalars.contains("\u{FE0F}") // VS16: emoji presentation
				? 2
				: unicodeScalars.reduce(0) { $0 + $1.terminalWidth }
		}
			?? 0
	}
}

private extension Unicode.Scalar {
	/// A UTF-8 `LC_CTYPE` locale, since mas always outputs UTF-8, regardless of
	/// the environment's locale (e.g., `C`, in which `wcwidth` fails for every
	/// non-ASCII character).
	private nonisolated(unsafe) static let utf8Locale = unsafe newlocale(LC_CTYPE_MASK, "UTF-8", nil)

	var terminalWidth: Int {
		let previousLocale = unsafe uselocale(unsafe Self.utf8Locale)
		defer { unsafe uselocale(previousLocale) }
		return max(0, .init(wcwidth(.init(value))))
	}
}
