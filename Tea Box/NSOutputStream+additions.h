//
//  NSOutputStream+additions.h
//  TeaBoxBonjour
//
//  Created by Max on 21/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSOutputStream (additions)

- (BOOL)sendUTF8String:(NSString *)string;
- (BOOL)sendData:(NSData *)data;

@end
