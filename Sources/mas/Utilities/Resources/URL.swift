//
// URL.swift
// mas
//
// Copyright © 2024 mas-cli. All rights reserved.
//

internal import AppKit
private import Foundation
private import ObjectiveC

extension URL {
	var filePath: String {
		if // swiftformat:disable:this wrap wrapArguments
			let path = // swiftformat:disable:next indent
				unsafe withUnsafeFileSystemRepresentation({ unsafe $0.flatMap(unsafe String.init(validatingCString:)) })
		{
			return path
		}
		let path = path(percentEncoded: false).dropLast { $0 == "/" }
		return path.isEmpty ? "/" : .init(path)
	}

	init(folderPath path: String, relativeTo base: Self? = nil) {
		self.init(filePath: path, directoryHint: .isDirectory, relativeTo: base)
	}

	init(nonFolderPath path: String, relativeTo base: Self? = nil) {
		self.init(filePath: path, directoryHint: .notDirectory, relativeTo: base)
	}

	func open(configuration: NSWorkspace.OpenConfiguration = .init()) async throws -> NSRunningApplication {
		try await NSWorkspace.shared.open(self, configuration: configuration)
	}
}
