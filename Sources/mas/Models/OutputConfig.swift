//
// OutputConfig.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import JSONAST

protocol OutputConfig {
	static var defaultFormat: OutputFormat { get }

	static func output(_ objects: [JSON.Object], as outputFormat: OutputFormat)
}

protocol Keyed { // swiftlint:disable:this one_declaration_per_file
	associatedtype Keys: Sequence<JSON.Key>

	static var keys: Keys { get }
}

extension OutputConfig where Self: Keyed { // swiftlint:disable:this file_types_order
	static func output(_ objects: [JSON.Object], as outputFormat: OutputFormat) {
		guard !objects.isEmpty else {
			return
		}

		switch outputFormat {
		case .json:
			MAS.printer.info(objects as [Any], separator: "\n")
		case .keyValue:
			MAS.printer.info(objects.keyValue(keys: keys))
		case .table:
			MAS.printer.info(objects.table(keys: keys))
		}
	}
}

protocol FieldConfigured { // swiftlint:disable:this one_declaration_per_file
	associatedtype FieldConfigs: Sequence<(key: JSON.Key, label: String, transform: @Sendable (String?) -> String)>

	static var fieldConfigs: FieldConfigs { get }
}

extension OutputConfig where Self: FieldConfigured {
	static func output(_ objects: [JSON.Object], as outputFormat: OutputFormat) {
		guard !objects.isEmpty else {
			return
		}

		switch outputFormat {
		case .json:
			MAS.printer.info(objects as [Any], separator: "\n")
		case .keyValue:
			MAS.printer.info(objects.keyValue(fieldConfigs: fieldConfigs))
		case .table:
			MAS.printer.info(objects.table(keys: fieldConfigs.map(\.0)))
		}
	}
}
