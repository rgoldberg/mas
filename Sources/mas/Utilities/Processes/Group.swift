//
// Group.swift
// mas
//
// Copyright © 2025 mas-cli. All rights reserved.
//

internal import Darwin

private extension gid_t {
	var nameAndID: String {
		let bufferLength = sysconf(_SC_GETGR_R_SIZE_MAX)
		guard bufferLength > 0 else {
			return "(\(self))"
		}

		var grp = unsafe group()
		var buffer = Array(repeating: CChar(0), count: bufferLength)
		var result = unsafe UnsafeMutablePointer<group>?.none
		return if
			unsafe getgrgid_r(self, &grp, &buffer, bufferLength, &result) == 0,
			unsafe result != nil,
			let namePtr = unsafe grp.gr_name
		{
			"\(unsafe String(cString: unsafe namePtr).quoted) (\(self))"
		} else {
			"(\(self))"
		}
	}
}

func set(effectiveGID gid: gid_t) throws(MASError) {
	guard setegid(gid) == 0 else {
		throw .error("Failed to switch effective group from \(getegid().nameAndID) to \(gid.nameAndID)")
	}
}

func reset(effectiveGID gid: gid_t) {
	do {
		try set(effectiveGID: gid)
	} catch {
		MAS.printer.warning(error: error)
	}
}
