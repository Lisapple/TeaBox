//
//  NSURL+additions.m
//  Tea Box
//
//  Created by Maxime Leroy on 12/8/12.
//
//

#import "NSURL+additions.h"

@implementation NSURL (additions)

- (BOOL)fileIsBundle:(BOOL *)isBundle isPackage:(BOOL *)isPackage
{
	NSString * type;
	BOOL success = [self getResourceValue:&type forKey:NSURLTypeIdentifierKey error:NULL];
	
	*isBundle = (BOOL)UTTypeConformsTo((__bridge CFStringRef)type, kUTTypeBundle);
	*isPackage = (BOOL)UTTypeConformsTo((__bridge CFStringRef)type, kUTTypePackage);
	
	return (success && (type != nil));
}

@end
