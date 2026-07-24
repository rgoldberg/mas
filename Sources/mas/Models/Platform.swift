//
// Platform.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import JSONAST
internal import JSONDecoding

enum Platform: String {
	case any
	case iOS
	case iPadOS
	case macCatalyst
	case macOS

	var iTunesSearchEntity: String {
		switch self {
		case .any:
			"macSoftware"
		case .iOS:
			"software"
		case .iPadOS:
			"iPadSoftware"
		case .macCatalyst, .macOS:
			"desktopSoftware"
		}
	}
}

extension Platform: CustomStringConvertible {
	var description: String {
		switch self {
		case .macCatalyst:
			"Catalyst"
		default:
			rawValue
		}
	}
}

extension Platform: JSONDecodable {
	init(json: JSON.Node) throws {
		guard case let .object(object) = json else {
			throw MASError.invalidJSON(.init(json))
		}

		try self.init(object: object)
	}

	init(object: JSON.Object) throws {
		do {
			if // swiftformat:disable:this wrap wrapArguments
				let platform = // swiftformat:disable:next indent
					try Self(kind: try object["kind"].decode(), supportedDevicesJSON: object[nodeKey: "supportedDevices"])
			{
				self = platform
				return
			}
		} catch {
			// Empty
		}
		throw MASError.invalidJSON(.init(object))
	}

	init?(kind: String?, supportedDevicesJSON: JSON.Node?) throws {
		switch kind {
		case "mac-software":
			self = .macOS
		case "software":
			guard let supportedDevicesJSON else {
				fallthrough
			}

			var supportsIOS = false
			var supportsIPadOS = false
			for supportedDevice in try [String](json: supportedDevicesJSON) {
				if supportedDevice == "MacDesktop-MacDesktop" {
					self = .macCatalyst
					return
				}
				if supportedDevice.hasPrefix("iPad") {
					supportsIPadOS = true
				} else if supportedDevice.hasPrefix("iPhone") || supportedDevice.hasPrefix("iPodTouch") {
					supportsIOS = true
				}
			}
			if supportsIPadOS {
				self = .iPadOS
			} else if supportsIOS {
				self = .iOS
			} else {
				fallthrough
			}
		default:
			return nil
		}
	}
}
