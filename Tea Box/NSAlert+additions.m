//
//  NSAlert+additions.m
//  Tea Box
//
//  Created by Max on 06/03/2017.
//
//

#import "NSAlert+additions.h"

@implementation NSAlert (additions)

+ (instancetype)alertWithStyle:(NSAlertStyle)style
				   messageText:(nullable NSString *)messageText
			   informativeText:(nullable NSString *)informativeText
				  buttonTitles:(NSArray <NSString *> *)titles
{
	NSAlert * alert = [[NSAlert alloc] init];
	alert.alertStyle = style;
	alert.messageText = messageText ?: @"";
	alert.informativeText = informativeText ?: @"";
	for (NSString * title in titles)
		[alert addButtonWithTitle:title];
	
	return alert;
}

@end
