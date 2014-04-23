//
//  NSMenu+additions.h
//  Tea Box
//
//  Created by Max on 25/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface NSMenu (additions)

- (void)addItemWithTitle:(NSString *)title target:(id)target action:(SEL)action;
- (void)addItemWithTitle:(NSString *)title target:(id)target action:(SEL)action tag:(NSInteger)tag;

@end
