// swift-tools-version:6.3

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
		.package(url: "https://github.com/apple/swift-argument-parser", from: "1.8.2"),
		.package(url: "https://github.com/apple/swift-collections", from: "1.6.0"),
		.package(url: "https://github.com/attaswift/BigInt", from: "6.0.1"),
		.package(url: "https://github.com/rarestype/swift-json", from: "3.5.0"),
		.package(url: "https://github.com/scinfu/SwiftSoup", from: "2.13.9"),
		.package(url: "https://github.com/swiftlang/swift-subprocess", from: "1.0.0"),
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
			dependencies: ["mas"],
			resources: [.process("Resources")],
			swiftSettings: swiftSettings,
		),
	],
	swiftLanguageModes: [.v6],
)
