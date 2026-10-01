//
// DecimalNumber.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import BigInt

/// An exact decimal number of unlimited precision & magnitude:
/// `0.digits × 10^exponent`, negated iff `isNegative`.
struct DecimalNumber: Hashable {
	static let zero = Self(digits: "", exponent: 0, isNegative: false)

	/// The significant digits, without leading or trailing `0`s; empty iff 0.
	let digits: String
	/// The power of 10 by which `0.digits` is multiplied.
	let exponent: BigInt
	let isNegative: Bool

	/// `string`, a canonical number (an optional sign, ASCII digits, an optional
	/// `.` & fractional part & an optional exponent, with at least 1 digit before
	/// the exponent); else `nil`.
	init?(_ string: some StringProtocol) {
		guard
			let match = String(string).wholeMatch(of: unsafe canonicalNumberRegex),
			!(match.2.isEmpty && (match.3 ?? "").isEmpty),
			let exponent = BigInt(match.4.map { $0.hasPrefix("+") ? $0.dropFirst() : $0 } ?? "0")
		else {
			return nil
		}
		let allDigits = match.2 + (match.3 ?? "")
		let significantDigits = allDigits.drop { $0 == "0" }
		let digits = String(significantDigits.reversed().drop { $0 == "0" }.reversed())
		self.init(
			digits: digits,
			exponent: digits.isEmpty ? 0 : exponent + BigInt(match.2.count - (allDigits.count - significantDigits.count)),
			isNegative: !digits.isEmpty && match.1 == "-",
		)
	}

	private init(digits: String, exponent: BigInt, isNegative: Bool) {
		self.digits = digits
		self.exponent = exponent
		self.isNegative = isNegative
	}
}

extension DecimalNumber: Comparable {
	static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.signum < rhs.signum
			|| lhs.signum == rhs.signum
			&& (lhs.isNegative ? rhs.hasLesserMagnitude(than: lhs) : lhs.hasLesserMagnitude(than: rhs))
	}

	/// `-1`, `0`, or `1`, per this number's sign.
	private var signum: Int {
		digits.isEmpty ? 0 : isNegative ? -1 : 1
	}

	/// Whether this number's magnitude is less than `other`'s, both being nonzero
	/// or both being 0.
	private func hasLesserMagnitude(than other: Self) -> Bool {
		exponent < other.exponent || exponent == other.exponent && digits.lexicographicallyPrecedes(other.digits)
	}
}

extension DecimalNumber {
	/// This number as a fraction of non-negative `BigInt`s
	/// (`numerator / denominator`), ignoring its sign; `nil` iff its exponent is
	/// too large to compute with.
	var magnitudeFraction: (numerator: BigInt, denominator: BigInt)? {
		Int(exactly: exponent - BigInt(digits.count)).map { scale in
			let significand = BigInt(digits.isEmpty ? "0" : digits) ?? 0
			return scale >= 0 ? (significand * BigInt(10).power(scale), 1) : (significand, BigInt(10).power(-scale))
		}
	}

	/// This number × 1000, rounded down to an integer; `nil` iff it is out of
	/// `Int`'s range.
	var flooredThousandths: Int? {
		magnitudeFraction.flatMap { numerator, denominator in
			let (quotient, remainder) = (numerator * 1000).quotientAndRemainder(dividingBy: denominator)
			return Int(exactly: isNegative ? -quotient - (remainder == 0 ? 0 : 1) : quotient)
		}
	}
}

private nonisolated(unsafe) let canonicalNumberRegex = /([+-]?)([0-9]*)(?:\.([0-9]*))?(?:[eE]([+-]?[0-9]+))?/
