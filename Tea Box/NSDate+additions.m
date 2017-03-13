//
//  NSDate+additions.m
//  Tea Box
//
//  Created by Max on 01/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "NSDate+additions.h"

static NSDateFormatter * _formatter = nil;

@implementation NSDate (additions)

+ (NSDate *)dateFromSQLiteDate:(NSString *)dateString
{
	if (!_formatter) {
		_formatter = [[NSDateFormatter alloc] init];
		_formatter.locale = [NSLocale currentLocale];
		_formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
		_formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"]; // Set to GMT time zone
	}
	return [_formatter dateFromString:dateString];
}

- (NSString *)SQLiteDateString
{
	if (!_formatter) {
		_formatter = [[NSDateFormatter alloc] init];
		_formatter.locale = [NSLocale currentLocale];
		_formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
		_formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"]; // Set to GMT time zone
	}
	return [_formatter stringFromDate:self];
}

+ (NSDate *)dateWithISO8601Format:(NSString *)dateString
{
	NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
	formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
	formatter.timeZone = [NSTimeZone defaultTimeZone];
	return [formatter dateFromString:dateString];
}

- (NSString *)iso8601DateString
{
	NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
	formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
	formatter.timeZone = [NSTimeZone defaultTimeZone];
	return [formatter stringFromDate:self];
}

@end
