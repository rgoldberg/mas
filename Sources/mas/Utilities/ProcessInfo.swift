//
// ProcessInfo.swift
// mas
//
// Copyright © 2024 mas-cli. All rights reserved.
//

internal import Darwin
private import Foundation

extension ProcessInfo {
	var sudoUID: uid_t? {
		environment["SUDO_UID"].flatMap { uid_t($0) }
	}

	var sudoGID: gid_t? {
		environment["SUDO_GID"].flatMap { gid_t($0) }
	}

	var requiredSudoUID: uid_t {
		get throws {
			guard let sudoUID else {
				throw MASError.runtimeError("Failed to get sudo uid")
			}

			return sudoUID
		}
	}

	var requiredSudoGID: gid_t {
		get throws {
			guard let sudoGID else {
				throw MASError.runtimeError("Failed to get sudo gid")
			}

			return sudoGID
		}
	}

	func runAsSudoEffectiveUserAndSudoEffectiveGroup(_ body: () async throws -> Void) async throws {
		try await run(asEffectiveUID: requiredSudoUID, andEffectiveGID: requiredSudoGID, body)
	}
}
