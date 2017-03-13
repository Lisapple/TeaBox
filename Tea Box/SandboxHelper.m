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

static NSMutableArray <NSURL *> * _startedScopedResources = nil;

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
	if (![self.class sandboxSupported]) { if (block) block(nil); return ; } // No error returned, Sandbox not activated
	
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	NSData * bookmarkData = [userDefaults objectForKey:kLibraryBookmarkDataKey];
	if (bookmarkData) {
		[self.class executeWithSecurityScopedAccessFromBookmarkData:bookmarkData block:^(NSURL * fileURL, NSError * error) { block(error); }];
		
	} else if (block) {
		NSError * error = [NSError errorWithDomain:@"" code:-1 userInfo:@{}];
		block(error);
	}
}

+ (void)executeWithSecurityScopedAccessToURL:(NSURL *)fileURL block:(void (^)(NSError *))block
{
	[self.class executeWithSecurityScopedAccessToPath:fileURL.path block:block];
}

+ (void)executeWithSecurityScopedAccessToPath:(NSString *)path block:(void (^)(NSError * _Nullable))block
{
	if (![self.class sandboxSupported]) { if (block) block(nil); return ; } // No error returned, Sandbox not activated
	
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
		[self.class executeWithSecurityScopedAccessFromBookmarkData:bookmarkData block:^(NSURL * fileURL, NSError * error) { block(error); }];
		
	} else if (block) {
		NSError * error = [NSError errorWithDomain:@"TBSandboxHelperDomain" code:-1
										  userInfo:@{ NSLocalizedDescriptionKey : @"No bookmark data found" }];
		block(error);
	}
}

+ (void)executeWithSecurityScopedAccessToProject:(nonnull Project *)project block:(void (^)(NSError * _Nullable))block
{
	if (![self.class sandboxSupported]) { if (block) block(nil); return ; } // No error returned, Sandbox not activated
	
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	NSString * key = [NSString stringWithFormat:@"%li", (long)project.identifier];
	NSData * bookmarkData = [userDefaults objectForKey:key];
	if (!bookmarkData) {
		// The file is into the library, use library bookmark data
		bookmarkData = [userDefaults dataForKey:kLibraryBookmarkDataKey];
	}
	if (bookmarkData) {
		[self.class executeWithSecurityScopedAccessFromBookmarkData:bookmarkData block:^(NSURL * fileURL, NSError * error) { block(error); }];
		
	} else if (block) {
		NSError * error = [NSError errorWithDomain:@"TBSandboxHelperDomain" code:-1
										  userInfo:@{ NSLocalizedDescriptionKey : @"No bookmark data found" }];
		block(error);
	}
}

+ (void)executeWithSecurityScopedAccessToItem:(nonnull FileItem *)item block:(void (^)(NSError * _Nullable))block
{
	if (![self.class sandboxSupported]) { if (block) block(nil); return ; } // No error returned, Sandbox not activated
	
	NSString * const key = item.URL.absoluteString;
	NSUserDefaults * const userDefaults = [NSUserDefaults standardUserDefaults];
	NSData * bookmarkData = [userDefaults objectForKey:key];
	if (!bookmarkData) // The file is into the library, use library bookmark data
		bookmarkData = [userDefaults dataForKey:kLibraryBookmarkDataKey];
	
	if (bookmarkData)
		[self.class executeWithSecurityScopedAccessFromBookmarkData:bookmarkData block:^(NSURL * fileURL, NSError * error) { block(error); }];
	else if (block) {
		NSError * error = [NSError errorWithDomain:@"TBSandboxHelperDomain" code:-1
										  userInfo:@{ NSLocalizedDescriptionKey : @"No bookmark data found" }];
		block(error);
	}
}

+ (void)executeWithSecurityScopedAccessFromBookmarkData:(nonnull NSData *)bookmarkData block:(void (^)(NSURL * _Nullable, NSError * _Nullable))block
{
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
	if (block)
		block(fileURL, error);
	
	[fileURL stopAccessingSecurityScopedResource];
}

+ (NSString *)bookmarkPathWithPath:(nonnull NSString *)path
{
#if _SANDBOX_SUPPORTED_
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	NSData * bookmarkData = [userDefaults objectForKey:path];
	NSURL * fileURL = [NSURL URLByResolvingBookmarkData:bookmarkData
												options:NSURLBookmarkResolutionWithSecurityScope
										  relativeToURL:nil
									bookmarkDataIsStale:NULL
												  error:NULL];
	return fileURL.path;
#endif
	return nil;
}

+ (void)saveBookmarkDataWithPath:(nonnull NSString *)path toKey:(nonnull NSString *)key
{
#if _SANDBOX_SUPPORTED_
	NSURL * fileURL = [NSURL fileURLWithPath:path];
	
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
