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
		get throws {
			try environment["SUDO_UID"].flatMap(uid_t.init) ?? { throw MASError.error("Failed to get sudo uid") }()
		}
	}

	var sudoGID: gid_t {
		get throws {
			try environment["SUDO_GID"].flatMap(gid_t.init) ?? { throw MASError.error("Failed to get sudo gid") }()
		}
	}

	func dropEffectiveRootWheel() throws {
		if getegid() == 0 {
			try set(effectiveGID: try sudoGID)
		}
		if geteuid() == 0 {
			try set(effectiveUID: try sudoUID)
		}
	}

	func dropRootWheel() throws {
		if getegid() == 0 || getgid() == 0 {
			try set(gid: try sudoGID)
		}
		if geteuid() == 0 || getuid() == 0 {
			try set(uid: try sudoUID)
		}
	}
}

var runningAsRoot: Bool {
	getuid() == 0
}
