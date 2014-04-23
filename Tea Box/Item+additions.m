//
//  Item+additions.m
//  Tea Box
//
//  Created by Max on 15/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "Item+additions.h"

@implementation Item (additions)

- (BOOL)moveToPath:(NSString *)path
{
	return NO;
}

- (BOOL)moveToTrash
{
	NSString * path = [self.library pathForItem:self];
	const char * folderPath = [path UTF8String];
	char * targetPath = NULL;
	FSPathMoveObjectToTrashSync(folderPath, &targetPath, 0);
	
	return (targetPath != NULL);
}

@end
