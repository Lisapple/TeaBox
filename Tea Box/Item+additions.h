//
//  Item+additions.h
//  Tea Box
//
//  Created by Max on 15/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

@import Quartz; // For QuickLook

#import "Item.h"

@interface FileItem (additions)

- (BOOL)moveToTrash;

@end


@interface Item (QLPreviewItem) <QLPreviewItem>
@end
