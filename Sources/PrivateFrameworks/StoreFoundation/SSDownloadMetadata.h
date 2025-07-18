//
// Generated by https://github.com/blacktop/ipsw (Version: 3.1.603, BuildCommit: Homebrew)
//
// - LC_BUILD_VERSION:  Platform: macOS, MinOS: 15.5, SDK: 15.5, Tool: ld (1167.3)
// - LC_SOURCE_VERSION: 715.5.1.0.0
//

@interface SSDownloadMetadata : NSObject <NSSecureCoding, NSCopying> {
	NSLock *_lock;
}

+ (BOOL)supportsSecureCoding;

@property(readonly, nonnull) NSNumber *ageRestriction;
@property BOOL animationExpected;
@property(retain, nullable) NSString *appleID;
@property(readonly, nonnull) NSString *applicationIdentifier;
@property BOOL artworkIsPrerendered;
@property(readonly, nonnull) NSArray<SSDownloadAsset *> *assets; // Unverified generic type
@property(readonly, nullable) NSString *bundleDisplayName;
@property(retain, nullable) NSString *bundleIdentifier;
@property(readonly, nullable) NSString *bundleShortVersionString;
@property(retain, nullable) NSString *bundleVersion;
@property(retain, nullable) NSString *buyParameters;
@property(readonly, nullable) NSNumber *collectionID NS_AVAILABLE_MAC(13);
@property(retain, nullable) NSString *collectionName;
@property(retain, nullable) NSDictionary *dictionary;
@property(retain, nullable) NSString *downloadKey;
@property(retain, nullable) NSNumber *durationInMilliseconds;
@property(retain, nullable) NSData *epubRightsData;
@property(readonly) BOOL extractionCanBeStreamed;
@property(retain, nullable) NSString *fileExtension;
@property(retain, nullable) NSString *genre;
@property(readonly, nullable) NSNumber *iapContentSize;
@property(readonly, nullable) NSString *iapContentVersion;
@property(retain, nullable) NSString *iapInstallPath;
@property(retain, nullable) NSData *ipaInstallBookmarkData NS_AVAILABLE_MAC(14);
@property(retain, nullable) NSString *ipaInstallPath;
@property(readonly) BOOL isExplicitContents;
@property BOOL isMDMProvided;
@property unsigned long long itemIdentifier;
@property(retain, nullable) NSString *kind;
@property(retain, nullable) NSString *managedAppUUIDString NS_AVAILABLE_MAC(13);
@property(readonly) BOOL needsSoftwareInstallOperation;
@property(retain, nullable) NSURL *preflightPackageURL;
@property(retain, nullable) NSString *productType;
@property(readonly, nullable) NSString *purchaseDate;
@property(getter=isRental) BOOL rental;
@property(readonly, getter=isSample) BOOL sample;
@property(retain, nullable) NSArray<NSMutableDictionary<NSString *, id> *> *sinfs;
@property(readonly, nullable) NSString *sortArtist NS_AVAILABLE_MAC(13);
@property(readonly, nullable) NSString *sortName NS_AVAILABLE_MAC(13);
@property(retain, nullable) NSString *subtitle;
@property(retain, nullable) NSURL *thumbnailImageURL;
@property(retain, nullable) NSString *title;
@property(retain, nullable) NSString *transactionIdentifier;
@property(readonly, nullable) NSNumber *uncompressedSize;
@property(retain, nullable) NSNumber *version NS_AVAILABLE_MAC(13);

- (nullable id)_valueForFirstAvailableKey:(nullable id)key;
- (nonnull instancetype)copyWithZone:(nullable struct _NSZone *)zone;
- (nullable NSDictionary *)deltaPackages; // Unverified return type
- (void)encodeWithCoder:(nullable NSCoder *)coder;
- (nonnull instancetype)init;
- (nonnull instancetype)initWithCoder:(nullable NSCoder *)coder;
- (nonnull instancetype)initWithDictionary:(nullable NSDictionary *)dictionary;
- (nonnull instancetype)initWithKind:(nullable NSString *)kind;
- (nullable id)localServerInfo;
- (void)setExtractionCanBeStreamed:(BOOL)extractionCanBeStreamed NS_DEPRECATED_MAC(10_9, 12);
- (void)setUncompressedSize:(nullable NSNumber *)uncompressedSize NS_DEPRECATED_MAC(10_9, 12);
- (void)setValue:(nullable id)value forMetadataKey:(nonnull NSString *)key; // Unverified key type

@end
