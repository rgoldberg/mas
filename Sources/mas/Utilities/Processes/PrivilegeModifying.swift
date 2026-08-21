//
// PrivilegeModifying.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

private import Foundation

protocol PrivilegeModifying {
	func modifyPrivileges() throws
}

protocol EffectiveDropping: PrivilegeModifying {} // swiftlint:disable:this one_declaration_per_file

extension EffectiveDropping { // swiftlint:disable:this file_types_order
	func modifyPrivileges() throws {
		try ProcessInfo.processInfo.dropEffectiveRootWheel()
	}
}

protocol RealDropping: PrivilegeModifying {} // swiftlint:disable:this one_declaration_per_file

extension RealDropping { // swiftlint:disable:this file_types_order
	func modifyPrivileges() throws {
		try ProcessInfo.processInfo.dropRootWheel()
	}
}

protocol PrivilegePreserving: PrivilegeModifying {} // swiftlint:disable:this one_declaration_per_file

extension PrivilegePreserving {
	func modifyPrivileges() {}
}
