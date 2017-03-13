//
//  NSMenu+additions.m
//  Tea Box
//
//  Created by Max on 25/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "NSMenu+additions.h"

@implementation NSMenu (additions)

- (NSMenuItem *)addItemWithTitle:(NSString *)title target:(id)target action:(SEL)action
{
	NSMenuItem * menuItem = [[NSMenuItem alloc] initWithTitle:title action:action keyEquivalent:@""];
	menuItem.target = target;
	[self addItem:menuItem];
	return menuItem;
}

- (NSMenuItem *)addItemWithTitle:(NSString *)title target:(id)target action:(SEL)action tag:(NSInteger)tag
{
	NSMenuItem * menuItem = [[NSMenuItem alloc] initWithTitle:title action:action keyEquivalent:@""];
	menuItem.target = target;
	menuItem.tag = tag;
	[self addItem:menuItem];
	return menuItem;
}

@end
