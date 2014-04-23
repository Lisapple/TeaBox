//
//  NSInputStream+additions.m
//  TeaBoxBonjour
//
//  Created by Max on 21/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "NSInputStream+additions.h"

@implementation NSInputStream (additions)

- (NSString *)getUTF8String
{
	NSData * data = [self getData];
	return [[NSString alloc] initWithData:data
								  encoding:NSUTF8StringEncoding];
}

- (NSData *)getData
{
	NSMutableData * data = [NSMutableData dataWithCapacity:(kMaxTransmissionUnit * 4)];
	NSInteger actuallyRead = 0;
	uint8_t buffer[kMaxTransmissionUnit];
	do {
		actuallyRead = (NSInteger)[self read:(uint8_t *)buffer maxLength:kMaxTransmissionUnit];
		
		if (actuallyRead < 0)
			return nil;
		
		NSData * dataRead = [[NSData alloc] initWithBytes:buffer length:actuallyRead];
		[data appendData:dataRead];
	} while (actuallyRead >= kMaxTransmissionUnit);
	return data;
}

@end
