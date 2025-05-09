//
// InstalledAppSpec.swift
// masTests
//
// Created by Ben Chatelain on 2021-09-30.
// Copyright © 2021 mas-cli. All rights reserved.
//

private import Nimble
import Quick

@testable private import mas

final class InstalledAppSpec: QuickSpec {
	override static func spec() {
		let app = InstalledApp(
			id: 111,
			name: "App",
			bundleID: "",
			path: "",
			version: "1.0.0"
		)

		describe("installed app") {
			it("is not outdated when there is no new version available") {
				expect(consequencesOf(app.isOutdated(comparedTo: SearchResult(version: "1.0.0"))))
					== ValuedConsequences(false, nil, "", "")
			}
			it("is outdated when there is a new version available") {
				expect(consequencesOf(app.isOutdated(comparedTo: SearchResult(version: "2.0.0"))))
					== ValuedConsequences(true, nil, "", "")
			}
			it("is not outdated when the new version of mac-software requires a higher OS version") {
				expect(
					consequencesOf(
						app.isOutdated(comparedTo: SearchResult(minimumOsVersion: "99.0.0", version: "3.0.0"))
					)
				)
					== ValuedConsequences(false, nil, "", "")
			}
			it("is not outdated when the new version of software requires a higher OS version") {
				expect(
					consequencesOf(
						app.isOutdated(comparedTo: SearchResult(minimumOsVersion: "99.0.0", version: "3.0.0"))
					)
				)
					== ValuedConsequences(false, nil, "", "")
			}
		}
	}
}
