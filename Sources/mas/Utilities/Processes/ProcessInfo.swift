//
// ProcessInfo.swift
// mas
//
// Copyright © 2024 mas-cli. All rights reserved.
//

internal import Darwin
private import Foundation

extension ProcessInfo {
	var sudoUID: uid_t {
		get throws(MASError) {
			guard let sudoUID = environment["SUDO_UID"].flatMap(uid_t.init) else {
				throw MASError.error("Failed to get sudo uid")
			}

			return sudoUID
		}
	}

	var sudoGID: gid_t {
		get throws(MASError) {
			guard let sudoGID = environment["SUDO_GID"].flatMap(gid_t.init) else {
				throw MASError.error("Failed to get sudo gid")
			}

			return sudoGID
		}
	}

	func dropRoot() throws {
		if getegid() == 0 {
			try set(effectiveGID: try sudoGID)
		}
		if geteuid() == 0 {
			try set(effectiveUID: try sudoUID)
		}
	}
}
