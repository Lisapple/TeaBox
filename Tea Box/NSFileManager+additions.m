//
//  NSFileManager+additions.m
//  FileManagerPlus
//
//  Created by Max on 04/12/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "NSFileManager+additions.h"
#import "BlockTimer.h"

@implementation NSFileManager (additions)

- (void)copyItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath progressionHandler:(void (^)(float progression))progressionHandler completionHandler:(void (^)(void))completionHandler errorHandler:(void (^)(NSError * error))errorHandler
{
	__block NSString * destinationPath = [dstPath copy];
	__block BlockTimer * timer = [[BlockTimer alloc] init];
	
	[self removeItemAtPath:dstPath error:NULL];
	
	NSNumber * filesizeNumber = nil;
	[[NSURL fileURLWithPath:srcPath] getResourceValue:&filesizeNumber forKey:NSURLFileSizeKey error:NULL];
	__block unsigned long long inputFileSize = [filesizeNumber unsignedLongLongValue];
	
	void (^block)(void) = ^(void) {
		NSNumber * filesizeNumber = nil;
		[[NSURL fileURLWithPath:dstPath] getResourceValue:&filesizeNumber forKey:NSURLFileSizeKey error:NULL];
		unsigned long long outputFileSize = [filesizeNumber unsignedLongLongValue];
		
		progressionHandler(outputFileSize / (float)inputFileSize);
	};
	
	[timer performBlock:block afterDelay:1. repeat:YES];
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
	dispatch_async(queue, ^{
		NSError * error = nil;
		if ([self copyItemAtPath:srcPath toPath:destinationPath error:&error]) {
			completionHandler();
		} else {
			errorHandler(error);
		}
		
		[timer stop];
	});
}

- (void)copyItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL progressionHandler:(void (^)(float progression))progressionHandler completionHandler:(void (^)(void))completionHandler errorHandler:(void (^)(NSError * error))errorHandler
{
	[self copyItemAtPath:srcURL.path
				  toPath:dstURL.path
	  progressionHandler:progressionHandler
	 completionHandler:completionHandler
			errorHandler:errorHandler];
}

#pragma mark - Deprecated Methods
- (void)copyItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath progressionBlock:(void (^)(float progression))progressionBlock errorBlock:(void (^)(NSError * error))errorBlock
{
	[self copyItemAtPath:srcPath toPath:dstPath progressionHandler:progressionBlock errorHandler:errorBlock];
}

- (void)copyItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath progressionHandler:(void (^)(float progression))progressionHandler errorHandler:(void (^)(NSError * error))errorHandler
{
	[self copyItemAtPath:srcPath
				  toPath:dstPath
	  progressionHandler:progressionHandler
	   completionHandler:^{
		   progressionHandler(1.);
	   }
			errorHandler:errorHandler];
}

- (void)copyItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL progressionHandler:(void (^)(float progression))progressionHandler errorHandler:(void (^)(NSError * error))errorHandler
{
	[self copyItemAtPath:[srcURL path]
				  toPath:[dstURL path]
	  progressionHandler:progressionHandler
			errorHandler:errorHandler];
}

@end
