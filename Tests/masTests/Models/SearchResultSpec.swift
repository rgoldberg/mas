//
//  SearchResultSpec.swift
//  masTests
//
//  Created by Ben Chatelain on 9/2/20.
//  Copyright © 2020 mas-cli. All rights reserved.
//

import Foundation
import Nimble
import Quick

@testable import mas

public final class SearchResultSpec: AsyncSpec {
    override public static func spec() {
        describe("search result") {
            it("can parse things") {
                await expecta(
                    await consequencesOf(
                        try JSONDecoder()
                            .decode(SearchResult.self, from: Data(from: "search/things-that-go-bump.json"))
                            .trackId
                    )
                )
                    == (1_472_954_003, nil, "", "")
            }
        }
    }
}
