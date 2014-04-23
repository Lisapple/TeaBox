//
//  SandboxHelper.m
//  Comparator
//
//  Created by Maxime Leroy on 5/31/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "SandboxHelper.h"

@implementation SandboxHelper

static NSMutableArray * _startedScopedResources = nil;

+ (BOOL)sandboxActivated
{
	return [SandboxHelper sandboxSupported];
}

+ (BOOL)sandboxSupported
{
#if _SANDBOX_SUPPORTED_
	return ([NSURL instancesRespondToSelector:@selector(startAccessingSecurityScopedResource)]);
#else
	return NO;
#endif
}

+ (NSString *)bookmarkPathWithPath:(NSString *)originalPath
{
#if _SANDBOX_SUPPORTED_
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	NSData * bookmarkData = [userDefaults objectForKey:originalPath];
	NSURL * fileURL = [NSURL URLByResolvingBookmarkData:bookmarkData
												options:NSURLBookmarkResolutionWithSecurityScope
										  relativeToURL:nil
									bookmarkDataIsStale:NULL
												  error:NULL];
	return [fileURL path];
#endif
	return nil;
}

+ (void)saveBookmarkDataWithPath:(NSString *)originalPath key:(NSString *)key
{
#if _SANDBOX_SUPPORTED_
	NSURL * fileURL = [NSURL fileURLWithPath:originalPath];
	
	NSError * error = nil;
	NSData * bookmarkData = [fileURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
							  includingResourceValuesForKeys:nil
											   relativeToURL:nil// Use nil for app-scoped bookmark
													   error:&error];
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:bookmarkData forKey:key];
#endif
}

+ (void)addStartedScopedResource:(NSURL *)securityScopedResourceURL
{
	if (!_startedScopedResources) {
		_startedScopedResources = [[NSMutableArray alloc] initWithCapacity:3];
	}
	
	if (![_startedScopedResources containsObject:securityScopedResourceURL])
		[_startedScopedResources addObject:securityScopedResourceURL];
}

+ (void)stopAllStartedScopedResource
{
#if _SANDBOX_SUPPORTED_
	for (NSURL * url in _startedScopedResources) {
		if ([url respondsToSelector:@selector(stopAccessingSecurityScopedResource)])
			[url stopAccessingSecurityScopedResource];
	}
#endif
}

@end
