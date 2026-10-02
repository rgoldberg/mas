//
// MASTests+Subprocess.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

@testable private import mas
internal import Testing

private extension MASTests {
	@Test
	func `writing fully retries a partial write with the remaining bytes, even mid-character`() async throws {
		var writtenBytes = [UInt8]()
		try await writeFully("né€😀", to: "test") { bytes in
			writtenBytes.append(bytes[0])
			return 1
		}
		#expect(writtenBytes == Array("né€😀".utf8))
	}

	@Test
	func `writing fully fails if nothing is written`() async {
		await #expect(throws: MASError.self) { try await writeFully("x", to: "test") { _ in 0 } }
	}
}
