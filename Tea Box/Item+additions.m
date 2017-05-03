//
//  Item+additions.m
//  Tea Box
//
//  Created by Max on 15/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "Item+additions.h"
#import "SandboxHelper.h"

@implementation FileItem (additions)

- (BOOL)moveToPath:(NSString *)path
{
	return NO;
}

@end


@implementation Item (QLPreviewItem)

- (NSURL *)previewItemURL
{
	return [(FileItem *)self URL];
}

- (NSString *)previewItemTitle
{
	return [(FileItem *)self URL].lastPathComponent;
}

@end
