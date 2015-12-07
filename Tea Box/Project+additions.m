//
//  Project+additions.m
//  Tea Box
//
//  Created by Max on 15/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "Project+additions.h"
#import "Step+additions.h"
#import "SandboxHelper.h"

@implementation Project (additions)

- (BOOL)moveToPath:(NSString *)path moveSteps:(BOOL)moveSteps
{
	return NO;
}

- (BOOL)moveToTrash
{
	__block BOOL moved = NO;
	NSString * path = [self.library pathForProjectFolder:self];
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


- (BOOL)moveAllStepsToPath:(NSString *)path
{
	return NO;
}

- (BOOL)moveAllItemsToPath:(NSString *)path
{
	return NO;
}


- (BOOL)moveAllStepsToTrash
{
	return NO;
}

- (BOOL)moveAllItemsToTrash
{
	return NO;
}


- (BOOL)moveAllStepsAndItemsToTrash
{
	BOOL success = YES;
	NSArray * steps = self.steps;
	for (Step * step in steps) {
		success |= [step moveToTrash];
		success |= [step delete];
	}
	
	return success;
}

@end
