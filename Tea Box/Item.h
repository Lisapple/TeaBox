//
//  Item.h
//  Tea Box
//
//  Created by Max on 04/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TBLibrary.h"

extern NSString * const kItemTypeImage;
extern NSString * const kItemTypeText;
extern NSString * const kItemTypeWebURL;
extern NSString * const kItemTypeFile;
extern NSString * const kItemTypeFolder;
extern NSString * const kItemTypeUnkown;

@class Step;
@interface Item : NSObject

@property (nonatomic, strong) Step * step;
@property (nonatomic, strong, readonly) NSString * filename;
@property (nonatomic, assign, readonly) int identifier;
@property (nonatomic, assign) int rowIndex;
@property (nonatomic, strong, readonly) NSString * type;
@property (nonatomic, strong) TBLibrary * library;

+ (NSArray *)itemsWithStepIdentifier:(int)stepID fromLibrary:(TBLibrary *)library;
+ (Item *)itemWithIdentifier:(int)identifier fromLibrary:(TBLibrary *)library;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithFilename:(NSString *)filename type:(NSString *)type step:(Step *)step;
- (instancetype)initWithFilename:(NSString *)filename type:(NSString *)type rowIndex:(int)rowIndex identifier:(int)identifier step:(Step *)step NS_DESIGNATED_INITIALIZER;
- (BOOL)insertIntoLibrary:(TBLibrary *)library;

- (void)updateValue:(id)value forKey:(NSString *)key;
- (BOOL)moveToStep:(Step *)destinationStep;

- (BOOL)delete;

@end
