//
// URLRequest.swift
// mas
//
// Copyright © 2026 mas-cli. All rights reserved.
//

internal import Foundation

extension URLRequest {
	init(
		url: URL,
		cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
		timeoutInterval: TimeInterval = 60.0, // swiftlint:disable:this function_default_parameter_at_end
		headers: [String: String],
	) {
		self.init(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
		for (httpHeaderField, value) in headers {
			setValue(value, forHTTPHeaderField: httpHeaderField)
		}
	}
}
