//
//  Step.h
//  Tea Box
//
//  Created by Max on 03/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TBLibrary.h"

@class TBLibrary;
@class Project;
@class Item;
@interface Step : NSObject

@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSString * description;
@property (nonatomic, strong) Project * project;
@property (nonatomic, strong) TBLibrary * library;
@property (nonatomic, readonly, assign) int identifier;
@property (nonatomic, assign, getter = isClosed) BOOL closed;

+ (NSArray *)stepsWithProjectIdentifier:(int)projectID fromLibrary:(TBLibrary *)library;
+ (Step *)stepWithIdentifier:(int)identifier fromLibrary:(TBLibrary *)library;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithName:(NSString *)name description:(NSString *)description project:(Project *)project;
- (instancetype)initWithName:(NSString *)name description:(NSString *)description closed:(BOOL)closed identifier:(int)identifier project:(Project *)project NS_DESIGNATED_INITIALIZER;
- (BOOL)insertIntoLibrary:(TBLibrary *)library;

- (void)update;

- (NSUInteger)itemsCount;
- (NSArray *)items; // Don't call this method on -[Item initWithFilename:type:rowIndex:identifier:step:]

- (void)updateValue:(id)value forKey:(NSString *)key;

- (BOOL)delete;

@end
