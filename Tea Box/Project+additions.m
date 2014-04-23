//
//  Project+additions.m
//  Tea Box
//
//  Created by Max on 15/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "Project+additions.h"
#import "Step+additions.h"

@implementation Project (additions)

- (BOOL)moveToPath:(NSString *)path moveSteps:(BOOL)moveSteps
{
	return NO;
}

- (BOOL)moveToTrash
{
	NSString * path = [self.library pathForProjectFolder:self];
	const char * folderPath = [path UTF8String];
	char * targetPath = NULL;
	FSPathMoveObjectToTrashSync(folderPath, &targetPath, 0);
	
	return (targetPath != NULL);
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
