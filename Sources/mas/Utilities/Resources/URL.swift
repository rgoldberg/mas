//
// URL.swift
// mas
//
// Copyright © 2024 mas-cli. All rights reserved.
//

internal import AppKit
private import Darwin
private import Foundation
private import ObjectiveC

extension URL {
	var filePath: String {
		if // swiftformat:disable:this wrap wrapArguments
			let path = // swiftformat:disable:next indent
				unsafe withUnsafeFileSystemRepresentation({ unsafe $0.flatMap(unsafe String.init(validatingCString:)) })
		{
			return path
		}
		let path = path(percentEncoded: false).dropLast { $0 == "/" }
		return path.isEmpty ? "/" : .init(path)
	}

	init(folderPath path: String, relativeTo base: Self? = nil) {
		self.init(filePath: path, directoryHint: .isDirectory, relativeTo: base)
	}

	func open(configuration: NSWorkspace.OpenConfiguration = .init()) async throws -> NSRunningApplication {
		try await NSWorkspace.shared.open(self, configuration: configuration)
	}

	func openOrCreateFolder() throws(MASError) -> Int32 {
		guard isFileURL else {
			throw MASError.error("\(self) is not a file URL")
		}
		var nextFD = unsafe Darwin::open("/", O_RDONLY | O_DIRECTORY | O_CLOEXEC)
		guard nextFD >= 0 else {
			throw MASError.error("Failed to open /: \(unsafe String(cString: unsafe strerror(errno)))")
		}
		for component in standardizedFileURL.pathComponents.dropFirst() {
			let currentFD = nextFD
			defer { close(currentFD) }
			nextFD = unsafe openat(currentFD, component, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
			if nextFD < 0 {
				guard errno == ENOENT else {
					throw MASError.error("Failed to open \(component.quoted): \(unsafe String(cString: unsafe strerror(errno)))")
				}
				let wasCreated = unsafe mkdirat(currentFD, component, 0o755) == 0
				guard wasCreated || errno == EEXIST else {
					throw
						MASError.error("Failed to create \(component.quoted): \(unsafe String(cString: unsafe strerror(errno)))")
				}
				nextFD = unsafe openat(currentFD, component, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
				guard nextFD >= 0 else {
					throw MASError.error("Failed to open \(component.quoted): \(unsafe String(cString: unsafe strerror(errno)))")
				}
				if wasCreated {
					guard fchown(nextFD, 0, 0) == 0 else {
						close(nextFD)
						throw MASError.error(
							"Failed to set owner of \(component.quoted): \(unsafe String(cString: unsafe strerror(errno)))",
						)
					}
					guard fchmod(nextFD, 0o755) == 0 else {
						close(nextFD)
						throw MASError.error(
							"Failed to set permissions of \(component.quoted): \(unsafe String(cString: unsafe strerror(errno)))",
						)
					}
				}
			}
		}
		return nextFD
	}

	func secureCloneOrCopy(to destinationURL: Self) throws {
		guard isFileURL, destinationURL.isFileURL else {
			throw MASError.error("\(self) or \(destinationURL) is not a file URL")
		}
		let sourceFD = unsafe Darwin::open(filePath, O_RDONLY | O_NOFOLLOW | O_CLOEXEC)
		guard sourceFD >= 0 else {
			throw MASError.error("Failed to open \(filePath.quoted): \(unsafe String(cString: unsafe strerror(errno)))")
		}
		defer { close(sourceFD) }
		let destinationFolderFD = try destinationURL.deletingLastPathComponent().openOrCreateFolder()
		defer { close(destinationFolderFD) }
		let fileManager = FileManager.default
		let stagingFolderURL = try fileManager.url(
			for: .itemReplacementDirectory,
			in: .userDomainMask,
			appropriateFor: destinationURL,
			create: true,
		)
		defer { try? fileManager.removeItem(at: stagingFolderURL) }
		let stagingFolderFD =
			unsafe Darwin::open(stagingFolderURL.filePath, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
		guard stagingFolderFD >= 0 else {
			throw MASError.error(
				"Failed to open \(stagingFolderURL.filePath.quoted): \(unsafe String(cString: unsafe strerror(errno)))",
			)
		}
		defer { close(stagingFolderFD) }
		let stagingName = "staging_file"
		let stagingFD: Int32
		if unsafe fclonefileat(sourceFD, stagingFolderFD, stagingName, 0) == 0 {
			stagingFD = unsafe openat(stagingFolderFD, stagingName, O_RDWR | O_NOFOLLOW | O_CLOEXEC)
			guard stagingFD >= 0 else {
				throw MASError.error("Failed to open cloned staging file: \(unsafe String(cString: unsafe strerror(errno)))")
			}
		} else { // Since cloning isn't possible (e.g., crossing volumes): fall back to a regular copy
			let createdFD =
				unsafe openat(stagingFolderFD, stagingName, O_RDWR | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
			guard createdFD >= 0 else {
				throw MASError.error("Failed to create staging file: \(unsafe String(cString: unsafe strerror(errno)))")
			}
			guard fcopyfile(sourceFD, createdFD, nil, .init(COPYFILE_DATA)) == 0 else {
				close(createdFD)
				throw MASError.error("Failed to copy \(filePath.quoted): \(unsafe String(cString: unsafe strerror(errno)))")
			}
			stagingFD = createdFD
		}
		var wasRenamed = false
		defer {
			close(stagingFD)
			if !wasRenamed {
				unsafe unlinkat(stagingFolderFD, stagingName, 0)
			}
		}
		guard fchown(stagingFD, 0, 0) == 0 else {
			throw MASError.error("Failed to set owner of staging file: \(unsafe String(cString: unsafe strerror(errno)))")
		}
		guard fchmod(stagingFD, 0o644) == 0 else {
			throw
				MASError.error("Failed to set permissions of staging file: \(unsafe String(cString: unsafe strerror(errno)))")
		}
		guard
			unsafe renameat(stagingFolderFD, stagingName, destinationFolderFD, destinationURL.lastPathComponent) == 0
		else {
			throw MASError.error(
				"""
				Failed to move staging file to \(destinationURL.filePath.quoted): \
				\(unsafe String(cString: unsafe strerror(errno)))
				""",
			)
		}
		wasRenamed = true
	}
}
