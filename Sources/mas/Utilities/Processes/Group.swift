//
// Group.swift
// mas
//
// Copyright © 2025 mas-cli. All rights reserved.
//

internal import Darwin

extension gid_t {
	var nameAndGID: String {
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
		throw .error("Failed to switch effective group from \(getegid().nameAndGID) to \(gid.nameAndGID)")
	}
}

func set(gid: gid_t) throws(MASError) {
	guard setgid(gid) == 0 else {
		throw .error("Failed to switch group from \(getgid().nameAndGID) to \(gid.nameAndGID)")
	}
}

func set(groupsOfUID uid: uid_t, gid: gid_t) throws(MASError) {
	guard let name = uid.name else {
		throw .error("Failed to get name of user \(uid.nameAndUID)")
	}
	guard unsafe initgroups(name, .init(bitPattern: gid)) == 0 else {
		throw .error("Failed to switch groups to those of user \(uid.nameAndUID) & group \(gid.nameAndGID)")
	}
}
