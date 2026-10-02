//
// MASTests+AppStoreAction.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import Foundation
@testable private import mas
internal import Testing

private extension MASTests {
	@Test
	func `hard linking a new file deletes the superseded hard link's temp folder`() throws {
		let fileManager = FileManager.default
		let folderURL = try fileManager.url(
			for: .itemReplacementDirectory,
			in: .userDomainMask,
			appropriateFor: fileManager.temporaryDirectory,
			create: true,
		)
		defer { try? fileManager.removeItem(at: folderURL) }
		let fileURL1 = folderURL.appending(path: "1.pkg", directoryHint: .notDirectory)
		let fileURL2 = folderURL.appending(path: "2.pkg", directoryHint: .notDirectory)
		try Data("1".utf8).write(to: fileURL1)
		try Data("2".utf8).write(to: fileURL2)
		let hardLinkURL1 = try #require(try hardLinkURL(to: fileURL1, existing: nil, adamID: 1, fileType: "pkg"))
		defer { try? fileManager.removeItem(at: hardLinkURL1.deletingLastPathComponent()) }
		#expect(try hardLinkURL(to: fileURL1, existing: hardLinkURL1, adamID: 1, fileType: "pkg") == hardLinkURL1)
		let hardLinkURL2 = try #require(try hardLinkURL(to: fileURL2, existing: hardLinkURL1, adamID: 1, fileType: "pkg"))
		defer { try? fileManager.removeItem(at: hardLinkURL2.deletingLastPathComponent()) }
		#expect(!fileManager.fileExists(atPath: hardLinkURL1.deletingLastPathComponent().filePath))
		#expect(try Data(contentsOf: hardLinkURL2) == Data("2".utf8))
	}
}
