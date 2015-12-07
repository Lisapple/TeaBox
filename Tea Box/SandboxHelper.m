//
//  SandboxHelper.m
//  Comparator
//
//  Created by Maxime Leroy on 5/31/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "SandboxHelper.h"
#import "TBLibrary.h"

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

+ (void)executeBlockWithSecurityScopedLibraryAccessing:(void (^)(NSError *))block
{
	if ([self.class sandboxSupported]) {
		NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
		NSData * bookmarkData = [userDefaults objectForKey:kLibraryBookmarkDataKey];
		if (bookmarkData) {
			
			NSURLBookmarkResolutionOptions bookmarkOptions = 0;
#if _SANDBOX_SUPPORTED_
			bookmarkOptions = NSURLBookmarkResolutionWithSecurityScope;
#endif
			NSError * error = nil;
			NSURL * fileURL = [NSURL URLByResolvingBookmarkData:bookmarkData
														options:bookmarkOptions
												  relativeToURL:nil
											bookmarkDataIsStale:NULL
														  error:&error];
			BOOL success = [fileURL startAccessingSecurityScopedResource];
			if (!success && !error) {
				error = [NSError errorWithDomain:@"" code:-1 userInfo:@{}];
			}
			if (block) {
				block(error);
			}
			[fileURL stopAccessingSecurityScopedResource];
		} else if (block) {
			NSError * error = [NSError errorWithDomain:@"" code:-1 userInfo:@{}];
			block(error);
		}
	} else if (block) {
		block(nil);
	}
}

+ (void)executeWithSecurityScopedAccessToURL:(NSURL *)fileURL block:(void (^)(NSError *))block
{
	[self.class executeWithSecurityScopedAccessToPath:fileURL.path block:block];
}

+ (void)executeWithSecurityScopedAccessToPath:(NSString *)path block:(void (^)(NSError *))block
{
	if ([self.class sandboxSupported]) {
		if (path) {
			NSData * bookmarkData = nil;
			
			NSString * libraryPath = [TBLibrary defaultLibrary].path;
			if (path.length >= libraryPath.length &&
				[[path substringToIndex:libraryPath.length] isEqualToString:libraryPath]) { // The file is into the library, use library bookmark data
				NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
				bookmarkData = [userDefaults dataForKey:kLibraryBookmarkDataKey];
			} else { // The file is not into the library, look for saved bookmark data
				NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
				bookmarkData = [userDefaults objectForKey:path];
			}
			
			if (bookmarkData) {
				NSError * error = nil;
				NSURLBookmarkResolutionOptions bookmarkOptions = NSURLBookmarkResolutionWithSecurityScope;
				NSURL * fileURL = [NSURL URLByResolvingBookmarkData:bookmarkData
															options:bookmarkOptions
													  relativeToURL:nil
												bookmarkDataIsStale:NULL
															  error:&error];
				BOOL success = [fileURL startAccessingSecurityScopedResource];
				if (!success && !error) {
					error = [NSError errorWithDomain:@"TBSandboxHelperDomain" code:-1
											userInfo:@{ NSLocalizedDescriptionKey : @"Unable to create a secure access to file" }];
				}
				if (block) {
					block(error);
				}
				[fileURL stopAccessingSecurityScopedResource];
			} else if (block) {
				NSError * error = [NSError errorWithDomain:@"TBSandboxHelperDomain" code:-1
												  userInfo:@{ NSLocalizedDescriptionKey : @"No bookmark data found" }];
				block(error);
			}
		} else if (block) {
			NSError * error = [NSError errorWithDomain:@"TBSandboxHelperDomain" code:-1
											  userInfo:@{ NSLocalizedDescriptionKey : @"Given path is null" }];
			block(error);
		}
	} else if (block) {
		block(nil); // No error returned, Sandbox not activated
	}
}

+ (void)executeWithSecurityScopedAccessToItem:(Item *)item block:(void (^)(NSError *))block
{
	if ([self.class sandboxSupported]) {
		if (item) {
			NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
			NSString * key = [NSString stringWithFormat:@"%i/%i/%i", item.step.project.identifier, item.step.identifier, item.identifier];
			NSData * bookmarkData = [userDefaults objectForKey:key];
			if (!bookmarkData) {
				// The file is into the library, use library bookmark data
				bookmarkData = [userDefaults dataForKey:kLibraryBookmarkDataKey];
			}
			
			if (bookmarkData) {
				NSError * error = nil;
				NSURLBookmarkResolutionOptions bookmarkOptions = NSURLBookmarkResolutionWithSecurityScope;
				NSURL * fileURL = [NSURL URLByResolvingBookmarkData:bookmarkData
															options:bookmarkOptions
													  relativeToURL:nil
												bookmarkDataIsStale:NULL
															  error:&error];
				BOOL success = [fileURL startAccessingSecurityScopedResource];
				if (!success && !error) {
					error = [NSError errorWithDomain:@"TBSandboxHelperDomain" code:-1
											userInfo:@{ NSLocalizedDescriptionKey : @"Unable to create a secure access to file" }];
				}
				if (block) {
					block(error);
				}
				[fileURL stopAccessingSecurityScopedResource];
			} else if (block) {
				NSError * error = [NSError errorWithDomain:@"TBSandboxHelperDomain" code:-1
												  userInfo:@{ NSLocalizedDescriptionKey : @"No bookmark data found" }];
				block(error);
			}
		} else if (block) {
			NSError * error = [NSError errorWithDomain:@"TBSandboxHelperDomain" code:-1
											  userInfo:@{ NSLocalizedDescriptionKey : @"Given path is null" }];
			block(error);
		}
	} else if (block) {
		block(nil); // No error returned, Sandbox not activated
	}
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
	return fileURL.path;
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
