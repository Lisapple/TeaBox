//
//  SandboxHelper.h
//  Comparator
//
//  Created by Maxime Leroy on 5/31/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SandboxHelper : NSObject

+ (BOOL)sandboxSupported;

+ (void)addStartedScopedResource:(NSURL *)securityScopedResourceURL;
+ (void)stopAllStartedScopedResource;

@end
