//
// OutdatedAccuracy.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import ArgumentParser

enum OutdatedAccuracy: String, EnumerableFlag {
	case accurate
	case accurateIgnoreUnknownApps
	case inaccurate

	static func help(for outdatedAccuracy: Self) -> ArgumentHelp? {
		switch outdatedAccuracy {
		case .accurate:
			"""
			Use accurate, slower logic that starts then cancels a download for each queried app, which can exceed download\
			 limits & which will open dialogs for undownloadable apps
			"""
		case .accurateIgnoreUnknownApps:
			"Use --accurate logic, but ignore apps that are unknown to the App Store"
		case .inaccurate:
			"Use inaccurate, faster logic that avoids dialogs & that ignores apps that are unknown to the App Store"
		}
	}
}
