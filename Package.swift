// swift-tools-version:6.4

private import PackageDescription

private let swiftSettings = [
	SwiftSetting
	.enableUpcomingFeature("ExistentialAny"), // swiftformat:disable:this indent
	.enableUpcomingFeature("ImmutableWeakCaptures"),
	.enableUpcomingFeature("InferIsolatedConformances"),
	.enableUpcomingFeature("InternalImportsByDefault"),
	.enableUpcomingFeature("MemberImportVisibility"),
	.enableUpcomingFeature("NonisolatedNonsendingByDefault"),
	.strictMemorySafety(),
	.treatAllWarnings(as: .error),
]

_ = Package(
	name: "mas",
	platforms: [.macOS(.v15)],
	products: [.executable(name: "mas", targets: ["mas"])],
	dependencies: [
		.package(url: "https://github.com/KittyMac/Sextant", from: "0.4.41"),
		// swiftlint:disable:next todo
		// TODO: Temp/todo.md "Swift Argument Parser Empty Values": mas cannot be
		// released until a Swift Argument Parser release includes
		// apple/swift-argument-parser#961 (already in its main branch) & this
		// dependency is a `from:` that release instead of this revision
		.package(
			url: "https://github.com/apple/swift-argument-parser",
			revision: "f29e03f4f96125cd930a045b4c17145c7bd5557a",
		),
		.package(url: "https://github.com/apple/swift-collections", from: "1.7.3"),
		.package(url: "https://github.com/attaswift/BigInt", from: "6.0.1"),
		.package(url: "https://github.com/pointfreeco/swift-parsing", from: "0.15.2"),
		.package(url: "https://github.com/rarestype/swift-json", from: "3.5.0"),
		.package(url: "https://github.com/scinfu/SwiftSoup", from: "2.14.3"),
		.package(url: "https://github.com/swiftlang/swift-subprocess", from: "1.0.2"),
	],
	targets: [
		.plugin(name: "MASBuildToolPlugin", capability: .buildTool()),
		.target(name: "PrivateFrameworks"),
		.executableTarget(
			name: "mas",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				.product(name: "JSON", package: "swift-json"),
				.product(name: "OrderedCollections", package: "swift-collections"),
				.product(name: "Parsing", package: "swift-parsing"),
				.product(name: "Subprocess", package: "swift-subprocess"),
				"BigInt",
				"PrivateFrameworks",
				"Sextant",
				"SwiftSoup",
			],
			swiftSettings: swiftSettings,
			linkerSettings: [.unsafeFlags(["-F", "/System/Library/PrivateFrameworks"])],
			plugins: [.plugin(name: "MASBuildToolPlugin")],
		),
		.testTarget(
			name: "MASTests",
			dependencies: ["BigInt", "mas"],
			resources: [.process("Resources")],
			swiftSettings: swiftSettings,
		),
	],
	swiftLanguageModes: [.v6],
)
