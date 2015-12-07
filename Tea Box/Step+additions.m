//
//  Step+additions.m
//  Tea Box
//
//  Created by Max on 15/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "Step+additions.h"
#import "SandboxHelper.h"

@implementation Step (additions)

- (BOOL)moveToPath:(NSString *)path moveItems:(BOOL)moveItems
{
	return NO;
}

- (BOOL)moveToTrash
{
	__block BOOL moved = NO;
	NSString * path = [self.library pathForStepFolder:self];
	[SandboxHelper executeWithSecurityScopedAccessToPath:path block:^(NSError * error) {
		if (!error) {
			NSFileManager * fileManager = [NSFileManager defaultManager];
			if ([fileManager respondsToSelector:@selector(trashItemAtURL:resultingItemURL:error:)]) { // OSX.8+
				moved = (BOOL)[fileManager trashItemAtURL:[NSURL fileURLWithPath:path] resultingItemURL:nil error:nil];
			} else {
				const char * sourcePath = path.UTF8String;
				char * targetPath = NULL;
				OSStatus error = FSPathMoveObjectToTrashSync(sourcePath, &targetPath, kFSFileOperationDefaultOptions);
				moved = (targetPath != NULL);
				
				if (!moved) NSLog(@"move to trash fails for %@ (%d)", path, error);
			}
		}
	}];
	return moved;
}


- (BOOL)moveAllItemsToPath:(NSString *)path
{
	return NO;
}

- (BOOL)moveLinkedItemsToPath:(NSString *)path
{
	return NO;
}


- (BOOL)moveAllItemsToTrash
{
	return NO;
}

- (BOOL)moveLinkedItemsToTrash
{
	return NO;
}

@end
