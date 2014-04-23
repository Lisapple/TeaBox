//
//  NSInputStream+additions.h
//  TeaBoxBonjour
//
//  Created by Max on 21/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSInputStream (additions)

- (NSString *)getUTF8String;
- (NSData *)getData;

@end
