//
//  NSDate+additions.h
//  Tea Box
//
//  Created by Max on 01/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

@interface NSDate (additions)

+ (NSDate *)dateFromSQLiteDate:(NSString *)dateString;
- (NSString *)SQLiteDateString;

@end
