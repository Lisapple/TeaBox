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
			moved = (BOOL)[fileManager trashItemAtURL:[NSURL fileURLWithPath:path] resultingItemURL:nil error:nil];
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
	for (Step * step in self.steps) {
		success |= [step moveToTrash];
		success |= [step delete];
	}
	return success;
}

@end
