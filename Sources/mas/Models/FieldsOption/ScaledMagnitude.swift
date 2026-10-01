//
// ScaledMagnitude.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import BigInt
private import Foundation

/// The magnitude that `scale` renders, `|number| / radix^exponent`, i.e.,
/// `significand × 10^decimalExponent × radix^radixExponent`, which it rounds
/// exactly without computing any power of 10 or of `radix` larger than its
/// result needs (e.g., 10^(10^12) for `1e1000000000000`): it approximates with
/// increasing precision until the approximation decides the rounding, deciding
/// a value exactly at a rounding boundary via its prime factorization.
struct ScaledMagnitude {
	private let significand: BigUInt
	private let decimalExponent: BigInt
	private let radix: BigUInt
	private let radixExponent: BigInt
	/// The bits of precision with which to 1st approximate.
	private let initialPrecision: Int
	/// The primes of 10 & of `radix`.
	private let primes: [BigUInt]
	/// The exponent of each of `primes` in `radix`'s prime factorization.
	private let radixExponentByPrime: [BigUInt: BigInt]
	/// The exponent of each of `primes` in `significand`'s prime factorization.
	private let significandExponentByPrime: [BigUInt: BigInt]
	/// `significand` without its factors in `primes`.
	private let significandRest: BigUInt

	/// `|number| / radix^exponent`, to be rounded to at most `digitCount` `radix`
	/// digits.
	init(_ number: DecimalNumber, dividedByRadix radix: Int, toThe exponent: Int, digitCount: Int) {
		significand = BigUInt(number.digits) ?? 0
		decimalExponent = number.exponent - BigInt(number.digits.count)
		self.radix = BigUInt(radix)
		radixExponent = -BigInt(exponent)
		initialPrecision = 64 + Int((Double(digitCount) * log2(Double(radix))).rounded(.up))
		radixExponentByPrime = factorization(of: self.radix, over: (2...BigUInt(radix)).filter(\.isPrime)).exponentByPrime
		primes = Array(Set([2, 5] + radixExponentByPrime.keys)).sorted()
		(significandExponentByPrime, significandRest) = factorization(of: significand, over: primes)
	}
}

extension ScaledMagnitude {
	/// `floor(log_radix(magnitude))`, for a positive magnitude whose
	/// `floor(log_radix(magnitude))` is at least `lowerBound`.
	func radixMagnitude(atLeast lowerBound: Int) -> Int {
		radixMagnitude(timesRadixToThe: BigInt(1 - lowerBound), precision: initialPrecision)
	}

	/// This magnitude × `radix^power`, rounded to the nearest integer, halves up.
	func rounded(timesRadixToThe power: BigInt) -> BigUInt {
		rounded(timesRadixToThe: power, precision: initialPrecision)
	}

	/// `floor(log_radix(magnitude))`, given that magnitude × `radix^power` is at
	/// least `radix`.
	private func radixMagnitude(timesRadixToThe power: BigInt, precision: Int) -> Int {
		let bounds = bracket(timesRadixToThe: power, precision: precision)
		let lowDigitCount = String(floored(bounds.low, timesPowerOf2: bounds.exponent), radix: Int(radix)).count
		let highDigitCount = String(floored(bounds.high, timesPowerOf2: bounds.exponent), radix: Int(radix)).count
		return lowDigitCount == highDigitCount
			|| highDigitCount == lowDigitCount + 1
			&& isRadixPower(timesRadixToThe: power, exponent: BigInt(lowDigitCount))
			? highDigitCount - 1 - Int(power)
			: radixMagnitude(timesRadixToThe: power, precision: 2 * precision)
	}

	private func rounded(timesRadixToThe power: BigInt, precision: Int) -> BigUInt {
		let bounds = bracket(timesRadixToThe: power, precision: precision)
		let low = roundedHalfUp(bounds.low, timesPowerOf2: bounds.exponent)
		let high = roundedHalfUp(bounds.high, timesPowerOf2: bounds.exponent)
		return low == high || high == low + 1 && isOddHalfInteger(timesRadixToThe: power)
			? high
			: rounded(timesRadixToThe: power, precision: 2 * precision)
	}

	/// `(low, high, exponent)`, such that this magnitude × `radix^power` is
	/// strictly between `low × 2^exponent` & `high × 2^exponent`, computed with
	/// `precision`-bit mantissas.
	private func bracket(timesRadixToThe power: BigInt, precision: Int)
	-> (low: BigUInt, high: BigUInt, exponent: BigInt) {
		// Each truncation to `precision` bits has a relative error less than
		// `2^(1 - precision)`, so the result, a mantissa less than `2^precision`,
		// is within `8 × truncationCount` of exact
		var truncationCount = 0
		func truncated(_ mantissa: BigUInt, _ exponent: BigInt) -> (BigUInt, BigInt) {
			truncationCount += 1
			let excess = max(mantissa.bitWidth - precision, 0)
			return (mantissa >> excess, exponent + BigInt(excess))
		}
		func product(_ lhs: (BigUInt, BigInt), _ rhs: (BigUInt, BigInt)) -> (BigUInt, BigInt) {
			truncated(lhs.0 * rhs.0, lhs.1 + rhs.1)
		}
		func powered(_ base: BigUInt, _ exponent: BigUInt) -> (BigUInt, BigInt) {
			var result = (BigUInt(1), BigInt(0))
			var square = (base, BigInt(0))
			var exponent = exponent
			while !exponent.isZero {
				if exponent[bitAt: 0] {
					result = product(result, square)
				}
				exponent >>= 1
				if !exponent.isZero {
					square = product(square, square)
				}
			}
			return result
		}
		let radixPower = power + radixExponent
		let decimalFactor = powered(10, decimalExponent.magnitude)
		let radixFactor = powered(radix, radixPower.magnitude)
		var numerator = (significand, BigInt(0))
		var denominator = (BigUInt(1), BigInt(0))
		if decimalExponent >= 0 {
			numerator = product(numerator, decimalFactor)
		} else {
			denominator = product(denominator, decimalFactor)
		}
		if radixPower >= 0 {
			numerator = product(numerator, radixFactor)
		} else {
			denominator = product(denominator, radixFactor)
		}
		// Shifted for a quotient of at least `precision` bits
		let shift = max(precision + denominator.0.bitWidth - numerator.0.bitWidth, 0)
		let (mantissa, exponent) =
			truncated((numerator.0 << shift) / denominator.0, numerator.1 - denominator.1 - BigInt(shift))
		let slack = BigUInt(8 * truncationCount + 1)
		return (mantissa > slack ? mantissa - slack : 0, mantissa + slack, exponent)
	}

	/// Whether 2 × this magnitude × `radix^power` is an odd integer.
	private func isOddHalfInteger(timesRadixToThe power: BigInt) -> Bool {
		let exponentByPrime = exponentByPrime(timesRadixToThe: power)
		return exponentByPrime.allSatisfy { prime, exponent in exponent >= (prime == 2 ? -1 : 0) }
			&& exponentByPrime[2] == -1
	}

	/// Whether this magnitude × `radix^power` is `radix^exponent`.
	private func isRadixPower(timesRadixToThe power: BigInt, exponent: BigInt) -> Bool {
		significandRest == 1
			&& exponentByPrime(timesRadixToThe: power).allSatisfy { prime, primeExponent in
				primeExponent == exponent * (radixExponentByPrime[prime] ?? 0)
			}
	}

	/// The exponent of each of `primes` in this magnitude × `radix^power`'s prime
	/// factorization, which has no other prime with a negative exponent.
	private func exponentByPrime(timesRadixToThe power: BigInt) -> [BigUInt: BigInt] {
		.init(
			uniqueKeysWithValues: primes.map { prime in
				(
					prime,
					(significandExponentByPrime[prime] ?? 0)
						+ decimalExponent * (prime == 2 || prime == 5 ? 1 : 0)
						+ (power + radixExponent) * (radixExponentByPrime[prime] ?? 0),
				)
			},
		)
	}
}

/// `floor(mantissa × 2^exponent)`.
private func floored(_ mantissa: BigUInt, timesPowerOf2 exponent: BigInt) -> BigUInt {
	mantissa << exponent
}

/// `mantissa × 2^exponent`, rounded to the nearest integer, halves up.
private func roundedHalfUp(_ mantissa: BigUInt, timesPowerOf2 exponent: BigInt) -> BigUInt {
	floored(mantissa + (BigUInt(1) << (-exponent - 1)), timesPowerOf2: exponent)
}

/// The exponent of each of `primes` in `integer`'s prime factorization &
/// `integer` without its factors in `primes`, for a positive `integer` (for
/// `0`: no exponents & `0`).
private func factorization(of integer: BigUInt, over primes: [BigUInt])
-> (exponentByPrime: [BigUInt: BigInt], rest: BigUInt) {
	primes.reduce(into: ([BigUInt: BigInt](), integer)) { result, prime in
		guard !result.1.isZero else {
			return
		}
		var exponent = BigInt(0)
		while result.1.isMultiple(of: prime) {
			result.1 /= prime
			exponent += 1
		}
		if exponent > 0 {
			result.0[prime] = exponent
		}
	}
}

private extension BigUInt {
	/// Whether this is prime, for a small value.
	var isPrime: Bool {
		self > 1 && !(2..<self).contains(where: isMultiple)
	}
}
