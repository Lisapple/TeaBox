//
//  AboutWindow.m
//  Tea Box
//
//  Created by Max on 01/10/15.
//
//

#import "AboutWindow.h"

@implementation AboutWindow

- (void)reloadData
{
	_imageView.image = [NSImage imageNamed:@"AppIcon"];
	
	NSString * version = [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
	NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
	formatter.dateFormat = @"yyyy";
	_aboutLabel.stringValue = [NSString stringWithFormat:@"Version %@\nLis@cintosh, %@", version, [formatter stringFromDate:[NSDate date]]];
}

@end
