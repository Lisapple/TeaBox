//
//  SandboxHelper.h
//  Comparator
//
//  Created by Maxime Leroy on 5/31/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "Item.h"

NS_ASSUME_NONNULL_BEGIN

@interface SandboxHelper : NSObject

+ (BOOL)sandboxSupported;

+ (void)executeBlockWithSecurityScopedLibraryAccessing:(void (^)(NSError * _Nullable))block;

+ (void)executeWithSecurityScopedAccessToURL:(NSURL *)fileURL block:(void (^)(NSError * _Nullable))block;
+ (void)executeWithSecurityScopedAccessToPath:(NSString *)path block:(void (^)(NSError * _Nullable))block;

+ (void)executeWithSecurityScopedAccessToProject:(Project *)project block:(void (^)(NSError * _Nullable))block;
+ (void)executeWithSecurityScopedAccessToItem:(Item *)item block:(void (^)(NSError * _Nullable))block DEPRECATED_ATTRIBUTE;

+ (void)executeWithSecurityScopedAccessFromBookmarkData:(nonnull NSData *)bookmarkData block:(void (^)(NSURL * _Nullable fileURL, NSError * _Nullable error))block;

+ (void)addStartedScopedResource:(NSURL *)securityScopedResourceURL;
+ (void)stopAllStartedScopedResource;

@end

NS_ASSUME_NONNULL_END
