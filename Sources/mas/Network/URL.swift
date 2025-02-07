//
//  URL.swift
//  mas
//
//  Created by Ross Goldberg on 2024-10-28.
//  Copyright © 2024 mas-cli. All rights reserved.
//

import AppKit
import PromiseKit

extension URL {
    func open() -> Promise<Void> {
        Promise { seal in
            if #available(macOS 10.15, *) {
                NSWorkspace.shared.open(self, configuration: NSWorkspace.OpenConfiguration()) { _, error in
                    if let error {
                        seal.reject(error)
                    }
                    seal.fulfill(())
                }
            } else {
                guard NSWorkspace.shared.open(self) else {
                    throw MASError.runtimeError("Failed to open \(self)")
                }

                seal.fulfill(())
            }
        }
    }
}
