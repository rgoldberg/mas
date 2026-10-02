//
// MASTests+MAS.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

@testable private import mas
internal import Testing

private extension MASTests {
	@Test(
		arguments: [
			("Data", ["/Applications", "/Volumes/Data/Applications"]),
			(5, ["/Applications"]),
			(nil, ["/Applications"]),
		] as [((any Sendable)?, [String])],
	)
	func `the applications folders include the preferred volume's iff its name is a string`(
		preferredVolumeName: (any Sendable)?,
		applicationsFolderPaths: [String],
	) {
		#expect(
			applicationsFolderURLs(forPreferredVolumeName: preferredVolumeName).map(\.filePath) == applicationsFolderPaths,
		)
	}
}
