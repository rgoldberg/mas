//
// CatalogAppResults.swift
// mas
//
// Copyright © 2018 mas-cli. All rights reserved.
//

internal import JSONAST
private import JSONDecoding

struct CatalogAppResults: JSONDecodable {
	let resultCount: Int // periphery:ignore
	let resultObjects: [JSON.Object]

	private let lazyResults: Lazy<Result<[CatalogApp], any Error>>

	var results: [CatalogApp] { // periphery:ignore
		get throws { // swiftlint:disable:previous unused_declaration
			try lazyResults.value.get()
		}
	}

	init(json: JSON.Node) throws {
		guard case let .object(object) = json else {
			throw MASError.invalidJSON(.init(json))
		}

		resultCount = try object["resultCount"]?.decode() ?? 0
		resultObjects = if case let .array(array) = object[nodeKey: "results"] {
			try array.elements.map { element in
				guard case let .object(object) = element else {
					throw MASError.invalidJSON(.init(json))
				}

				return object
			}
		} else {
			.init()
		}

		let resultObjects = resultObjects
		lazyResults = .init { .init { try resultObjects.map { try .init(json: .object($0)) } } }
	}
}
