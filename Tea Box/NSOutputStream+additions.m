//
//  NSOutputStream+additions.m
//  TeaBoxBonjour
//
//  Created by Max on 21/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "NSOutputStream+additions.h"

@implementation NSOutputStream (additions)

- (BOOL)sendUTF8String:(NSString *)string
{
	NSData * data = [string dataUsingEncoding:NSUTF8StringEncoding];
	return [self sendData:data];
}

- (BOOL)sendData:(NSData *)data
{
	NSUInteger remainingToWrite = data.length;
	void * marker = (void *)data.bytes;
	while (0 < remainingToWrite) {
		NSInteger actuallyWritten = (NSInteger)[self write:marker maxLength:remainingToWrite];
		if (actuallyWritten < 0)
			return NO;
		remainingToWrite -= actuallyWritten;
		marker += actuallyWritten;
	}
	return YES;
}

@end
