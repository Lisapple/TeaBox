//
//  Step+additions.m
//  Tea Box
//
//  Created by Max on 15/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "Step+additions.h"

@implementation Step (additions)

- (BOOL)moveToPath:(NSString *)path moveItems:(BOOL)moveItems
{
	return NO;
}

- (BOOL)moveToTrash
{
	NSString * path = [self.library pathForStepFolder:self];
	const char * folderPath = [path UTF8String];
	char * targetPath = NULL;
	FSPathMoveObjectToTrashSync(folderPath, &targetPath, 0);
	
	return (targetPath != NULL);
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
