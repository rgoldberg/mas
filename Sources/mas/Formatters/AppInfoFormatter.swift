//
//  AppInfoFormatter.swift
//  mas
//
//  Created by Ben Chatelain on 1/7/19.
//  Copyright © 2019 mas-cli. All rights reserved.
//

import Foundation

/// Formats text output for the info command.
enum AppInfoFormatter {
    /// Formats text output with app info.
    ///
    /// - Parameter app: Search result with app data.
    /// - Returns: Multiline text output.
    static func format(app: SearchResult) -> String {
        let headline = [
            "\(app.trackName)",
            "\(app.version)",
            "[\(app.displayPrice)]",
        ]
        .joined(separator: " ")

        return [
            headline,
            "By: \(app.sellerName)",
            "Released: \(humanReadableDate(app.currentVersionReleaseDate))",
            "Minimum OS: \(app.minimumOsVersion)",
            "Size: \(humanReadableSize(app.fileSizeBytes))",
            "From: \(app.trackViewUrl)",
        ]
        .joined(separator: "\n")
    }

    /// Formats a file size.
    ///
    /// - Parameter size: Numeric string.
    /// - Returns: Formatted file size description.
    private static func humanReadableSize(_ size: String) -> String {
        let bytesSize = Int64(size) ?? 0
        return ByteCountFormatter.string(fromByteCount: bytesSize, countStyle: .file)
    }

    /// Formats a date in  format.
    ///
    /// - Parameter serverDate: String containing a date in ISO-8601 format.
    /// - Returns: Simple date format.
    private static func humanReadableDate(_ serverDate: String) -> String {
        let humanDateFormatter = ISO8601DateFormatter()
        humanDateFormatter.formatOptions = [.withFullDate]
        return ISO8601DateFormatter().date(from: serverDate).map(humanDateFormatter.string(from:)) ?? ""
    }
}
