//
//  Step.h
//  Tea Box
//
//  Created by Max on 03/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "TBCoder.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const StepDidUpdateNotification;

@class TBLibrary;
@class Project;
@class Item;
@protocol TBCoding;
@protocol TBDecoding;
@interface Step : NSObject <TBCoding, TBDecoding>

@property (strong) NSString * path;
@property (strong) NSString * name;
@property (assign, getter = isClosed) BOOL closed; // @TODO: Rename to `hidden`

@property (readonly) NSArray <Item *> * items;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithName:(NSString *)name NS_DESIGNATED_INITIALIZER;

- (void)addItem:(Item *)item;
- (void)addItems:(NSArray <Item *> *)items;
- (void)removeItem:(Item *)item;

- (BOOL)removeFromDisk;

@end


NS_ASSUME_NONNULL_END


#pragma mark - Deprecated

NS_ASSUME_NONNULL_BEGIN

@interface Step ()

@property (nonatomic, strong) NSString * description DEPRECATED_ATTRIBUTE;
@property (nonatomic, strong) Project * project DEPRECATED_ATTRIBUTE;
@property (nonatomic, strong) TBLibrary * library DEPRECATED_ATTRIBUTE;
@property (nonatomic, readonly, assign) NSInteger identifier DEPRECATED_ATTRIBUTE;

+ (NSArray <Step *> *)stepsWithProjectIdentifier:(NSInteger)projectID fromLibrary:(TBLibrary *)library MIGRATION_ATTRIBUTE;
+ (Step *)stepWithIdentifier:(int)identifier fromLibrary:(TBLibrary *)library MIGRATION_ATTRIBUTE;
- (instancetype)initWithName:(NSString *)name description:(NSString *)description project:(Project *)project DEPRECATED_ATTRIBUTE;
- (instancetype)initWithName:(NSString *)name description:(NSString *)description closed:(BOOL)closed identifier:(NSInteger)identifier project:(Project *)project DEPRECATED_ATTRIBUTE;
- (BOOL)insertIntoLibrary:(TBLibrary *)library UNAVAILABLE_ATTRIBUTE;
- (void)update UNAVAILABLE_ATTRIBUTE;
- (NSUInteger)itemsCount UNAVAILABLE_ATTRIBUTE;
- (void)updateValue:(id)value forKey:(NSString *)key DEPRECATED_ATTRIBUTE;
- (BOOL)delete DEPRECATED_MSG_ATTRIBUTE("Use -[Project removeStep:] instead");

@end

NS_ASSUME_NONNULL_END
