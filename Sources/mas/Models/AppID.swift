//
// AppID.swift
// mas
//
// Copyright © 2024 mas-cli. All rights reserved.
//

enum AppID {
	case adamID(ADAMID)
	case bundleID(String)

	var notInstalledMessage: String {
		"No installed apps with \(self)"
	}

	init(from string: String, forceBundleID: Bool) {
		guard !forceBundleID, let adamID = ADAMID(string) else {
			self = .bundleID(string)
			return
		}

		self = .adamID(adamID)
	}
}

extension AppID: CustomStringConvertible { // swiftlint:disable:this file_types_order
	var description: String {
		switch self {
		case let .adamID(adamID):
			"ADAM ID \(adamID)"
		case let .bundleID(bundleID):
			"bundle ID \(bundleID)"
		}
	}
}

extension [AppID] { // swiftlint:disable:this file_types_order
	var catalogApps: [CatalogApp] {
		get async {
			let lookupAppFromAppID = Environment.current.lookupAppFromAppID
			return await concurrentCompactMap(attemptingTo: "lookup app for", lookupAppFromAppID)
		}
	}
}

typealias ADAMID = UInt64
