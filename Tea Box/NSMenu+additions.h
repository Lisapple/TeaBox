//
//  NSMenu+additions.h
//  Tea Box
//
//  Created by Max on 25/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface NSMenu (additions)

- (NSMenuItem *)addItemWithTitle:(NSString *)title target:(nullable id)target action:(nullable SEL)action;
- (NSMenuItem *)addItemWithTitle:(NSString *)title target:(nullable id)target action:(nullable SEL)action tag:(NSInteger)tag;

@end

NS_ASSUME_NONNULL_END
