//
// User.swift
// mas
//
// Copyright © 2025 mas-cli. All rights reserved.
//

internal import Darwin

private extension uid_t {
	var nameAndID: String {
		let bufferLength = sysconf(_SC_GETPW_R_SIZE_MAX)
		guard bufferLength > 0 else {
			return "(\(self))"
		}

		var pwd = unsafe passwd()
		var buffer = Array(repeating: CChar(0), count: bufferLength)
		var result = unsafe UnsafeMutablePointer<passwd>?.none
		return if
			unsafe getpwuid_r(self, &pwd, &buffer, bufferLength, &result) == 0,
			unsafe result != nil,
			let namePtr = unsafe pwd.pw_name
		{
			"\(unsafe String(cString: unsafe namePtr).quoted) (\(self))"
		} else {
			"(\(self))"
		}
	}
}

func set(effectiveUID uid: uid_t) throws(MASError) {
	guard seteuid(uid) == 0 else {
		throw .error("Failed to switch effective user from \(geteuid().nameAndID) to \(uid.nameAndID)")
	}
}

func reset(effectiveUID uid: uid_t) {
	do {
		try set(effectiveUID: uid)
	} catch {
		MAS.printer.warning(error: error)
	}
}
