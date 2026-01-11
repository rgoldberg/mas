//
// AccuracyOptionGroup.swift
// mas
//
// Copyright © 2025 mas-cli. All rights reserved.
//

private import ArgumentParser

struct AccuracyOptionGroup: ParsableArguments {
	@Flag
	var accuracy = OutdatedAccuracy.inaccurate
}
