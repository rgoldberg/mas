//
// SearchSpec.swift
// masTests
//
// Created by Ben Chatelain on 2018-12-28.
// Copyright © 2018 mas-cli. All rights reserved.
//

private import Nimble
import Quick

@testable private import mas

final class SearchSpec: AsyncSpec {
	override static func spec() {
		describe("search command") {
			it("can find slack") {
				let mockResult = SearchResult(
					trackId: 1111,
					trackName: "slack",
					trackViewUrl: "mas preview url",
					version: "0.0"
				)
				await expecta(
					await consequencesOf(
						try await MAS.Search.parse(["slack"]).run(searcher: MockAppStoreSearcher([mockResult.trackId: mockResult]))
					)
				)
					== UnvaluedConsequences(nil, "        1111  slack  (0.0)\n", "")
			}
			it("fails when searching for nonexistent app") {
				await expecta(
					await consequencesOf(
						try await MAS.Search.parse(["nonexistent"]).run(searcher: MockAppStoreSearcher())
					)
				)
					== UnvaluedConsequences(MASError.noSearchResultsFound, "", "")
			}
		}
	}
}
