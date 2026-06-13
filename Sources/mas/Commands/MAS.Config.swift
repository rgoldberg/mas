//
// MAS.Config.swift
// mas
//
// Copyright © 2025 mas-cli. All rights reserved.
//

internal import ArgumentParser
private import Darwin
private import Foundation
private import JSONAST

extension MAS {
	/// Outputs mas config & related system info.
	struct Config: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Output mas config & related system info",
		)

		@OptionGroup
		private var outputFormatOptionGroup: OutputFormatOptionGroup

		func run() {
			outputFormatOptionGroup.info(
				JSON.Object( // swiftformat:disable:this wrap wrapArguments
					dictionaryLiteral: // swiftlint:disable vertical_parameter_alignment_on_call
						("mas", .string(version)), // swiftformat:disable indent
						("slice", .string(runningSliceArchitecture)),
						("slices", .string(supportedSliceArchitectures.joined(separator: " "))),
						("dist", .string(distribution)),
						("origin", .string(gitOrigin)),
						("rev", .string(gitRevision)),
						("swift", .string(swiftVersion)),
						("driver", .string(swiftDriverVersion)),
						("store", .string(appStoreRegion)),
						("region", .string(macRegion)),
						("macos", .string(macOSVersion)),
						("build", .string(configStringValue("kern.osversion"))),
						("mac", .string(configStringValue("hw.product"))),
						("cpu", .string(configStringValue("machdep.cpu.brand_string"))),
						("arch", .string(configStringValue("hw.machine"))), // swiftlint:enable vertical_parameter_alignment_on_call
				), // swiftformat:enable indent
			)
		}
	}
}

private let runningSliceArchitecture = {
	#if arch(arm64)
	"arm64"
	#elseif arch(x86_64)
	"x86_64"
	#else
	"unknown"
	#endif
}()

private var supportedSliceArchitectures: [String] {
	Bundle.main.executableArchitectures.map { archIDs in
		archIDs.map { archID in
			guard let arch = Int(exactly: archID) else {
				return "unknown_\(archID)"
			}

			return switch arch {
			case NSBundleExecutableArchitectureARM64:
				"arm64"
			case NSBundleExecutableArchitectureX86_64:
				"x86_64"
			default:
				"unknown_0x\(String(arch, radix: 16))"
			}
		}
	}
		?? .init()
}

private var macOSVersion: String {
	let version = ProcessInfo.processInfo.operatingSystemVersion
	return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
}

private func configStringValue(_ name: String) -> String {
	var size = 0
	guard unsafe sysctlbyname(name, nil, &size, nil, 0) == 0 else {
		unsafe perror(sysCtlByName)
		return unknown
	}
	guard size > 0 else {
		return unknown
	}

	return unsafe withUnsafeTemporaryAllocation(of: CChar.self, capacity: size) { buffer in
		guard let baseAddress = buffer.baseAddress else {
			return unknown
		}
		guard unsafe sysctlbyname(name, unsafe baseAddress, &size, nil, 0) == 0 else {
			unsafe perror(sysCtlByName)
			return unknown
		}

		return unsafe .init(cString: unsafe baseAddress)
	}
}

private let unknown = "unknown"
private let sysCtlByName = "sysctlbyname"
