//
//  SandboxHelper.h
//  Comparator
//
//  Created by Maxime Leroy on 5/31/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Item.h"

@interface SandboxHelper : NSObject

+ (BOOL)sandboxSupported;

+ (void)executeBlockWithSecurityScopedLibraryAccessing:(void (^)(NSError *))block;

+ (void)executeWithSecurityScopedAccessToURL:(NSURL *)fileURL block:(void (^)(NSError *))block;
+ (void)executeWithSecurityScopedAccessToPath:(NSString *)path block:(void (^)(NSError *))block;
+ (void)executeWithSecurityScopedAccessToItem:(Item *)item block:(void (^)(NSError *))block;

+ (void)addStartedScopedResource:(NSURL *)securityScopedResourceURL;
+ (void)stopAllStartedScopedResource;

@end
