//
//  Item+additions.h
//  Tea Box
//
//  Created by Max on 15/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

@import Quartz; // For QuickLook

#import "Item.h"

@interface Item (additions)

//- (BOOL)moveToPath:(NSString *)path;
- (BOOL)moveToTrash;

@end
