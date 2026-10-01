//
// Terminal.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import Darwin

enum Justification: Equatable { // swiftlint:disable sorted_enum_cases
	case start
	case centerStart
	case centerEnd
	case end // swiftlint:enable sorted_enum_cases
}

extension String { // swiftlint:disable:next function_default_parameter_at_end
	func terminalJustify(_ justification: Justification = .start, with pad: Character = " ", to minimumWidth: Int)
	-> Self {
		precondition(pad.terminalWidth == 1)
		let existingWidth = terminalWidth
		guard existingWidth < minimumWidth else {
			return self
		}
		let paddingWidth = minimumWidth - existingWidth
		return switch justification {
		case .start:
			self + .init(repeating: pad, count: paddingWidth)
		case .centerStart:
			.init(repeating: pad, count: paddingWidth / 2) + self + .init(repeating: pad, count: 1 + (paddingWidth - 1) / 2)
		case .centerEnd:
			.init(repeating: pad, count: 1 + (paddingWidth - 1) / 2) + self + .init(repeating: pad, count: paddingWidth / 2)
		case .end:
			.init(repeating: pad, count: paddingWidth) + self
		}
	}
}

extension StringProtocol {
	var terminalWidth: Int {
		reduce(0) { $0 + $1.terminalWidth }
	}
}

private extension Character {
	var terminalWidth: Int {
		unicodeScalars.reduce(0) { $0 + $1.terminalWidth }
	}
}

private extension Unicode.Scalar {
	private static let localeInitialization: Void = {
		_ = unsafe setlocale(LC_ALL, "")
	}()

	var terminalWidth: Int {
		_ = Self.localeInitialization
		return max(0, .init(wcwidth(.init(value))))
	}
}
