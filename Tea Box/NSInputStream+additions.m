//
//  NSInputStream+additions.m
//  TeaBoxBonjour
//
//  Created by Max on 21/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "NSInputStream+additions.h"

const int MaxTransmissionUnit = 7981; // 7981 for WLAN, 1500 for Eternet

@implementation NSInputStream (additions)

- (NSString *)getUTF8String
{
	NSData * data = [self getData];
	return [[NSString alloc] initWithData:data
								  encoding:NSUTF8StringEncoding];
}

- (NSData *)getData
{
	NSMutableData * data = [NSMutableData dataWithCapacity:(MaxTransmissionUnit * 4)];
	NSInteger actuallyRead = 0;
	uint8_t buffer[MaxTransmissionUnit];
	do {
		actuallyRead = (NSInteger)[self read:(uint8_t *)buffer maxLength:MaxTransmissionUnit];
		
		if (actuallyRead < 0)
			return nil;
		
		NSData * dataRead = [[NSData alloc] initWithBytes:buffer length:actuallyRead];
		[data appendData:dataRead];
	} while (actuallyRead >= MaxTransmissionUnit);
	return data;
}

@end
