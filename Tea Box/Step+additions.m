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
			moved = (BOOL)[fileManager trashItemAtURL:[NSURL fileURLWithPath:path] resultingItemURL:nil error:nil];
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
