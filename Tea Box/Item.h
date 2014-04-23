//
//  Item.h
//  Tea Box
//
//  Created by Max on 04/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TBLibrary.h"

#ifndef kItemType
#define kItemType
#define kItemTypeImage @"IMG"
#define kItemTypeText @"TXT"
#define kItemTypeWebURL @"URL"
#define kItemTypeFile @"FILE"
#define kItemTypeFolder @"FOLD"
#define kItemTypeUnkown @"????"
#endif

/*
const char * kItemTypeImage = "IMG";
const char * kItemTypeText = "TXT";
const char * kItemTypeWebURL = "URL";
const char * kItemTypeFile = "FILE";
const char * kItemTypeUnkown = "????";
*/

@class Step;
@interface Item : NSObject

@property (nonatomic, strong) Step * step;
@property (nonatomic, strong) NSString * filename;
@property (nonatomic, assign) int identifier, rowIndex;
@property (nonatomic, strong) NSString * type;
@property (nonatomic, strong) TBLibrary * library;

+ (NSArray *)itemsWithStepIdentifier:(int)stepID fromLibrary:(TBLibrary *)library;
+ (Item *)itemWithIdentifier:(int)identifier fromLibrary:(TBLibrary *)library;

- (id)initWithFilename:(NSString *)filename type:(NSString *)type rowIndex:(int)rowIndex step:(Step *)step insertIntoLibrary:(TBLibrary *)library;
- (id)initWithFilename:(NSString *)filename type:(NSString *)type rowIndex:(int)rowIndex identifier:(int)identifier step:(Step *)step insertIntoLibrary:(TBLibrary *)library;

- (void)updateValue:(id)value forKey:(NSString *)key;

- (BOOL)delete;

@end
