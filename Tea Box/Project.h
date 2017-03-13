//
//  Project.h
//  Tea Box
//
//  Created by Max on 03/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "Step.h"
#import "Item.h"
#import "TBCoder.h"

typedef NS_ENUM(NSUInteger, ProjectPriority) {
	ProjectPriorityNone,
	ProjectPriorityLow,
	ProjectPriorityNormal,
	ProjectPriorityHigh
};

extern ProjectPriority ProjectPriorityWithString(NSString * _Nonnull string);
extern NSString * _Nullable ProjectPriorityDescription(ProjectPriority priority);

NS_ASSUME_NONNULL_BEGIN

@class Step;
@protocol TBCoding;
@protocol TBDecoding;
@interface Project : NSObject <TBCoding, TBDecoding>

@property (strong) NSString * path;
@property (strong) NSString * name;
@property (copy, nullable) NSString * description;
@property (readonly) NSDate * creationDate;
@property (strong, nullable) NSDate * lastModificationDate;
@property (assign) ProjectPriority projectPriority; // @FIXME: Should be `priority` (once actual `priority` property removed)

@property (readonly) NSArray <Step *> * steps;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithName:(NSString *)name description:(nullable NSString *)description NS_DESIGNATED_INITIALIZER;

- (void)addStep:(Step *)step;
- (void)addSteps:(NSArray <Step *> *)steps;
- (void)removeStep:(Step *)step;

- (void)markAsUpdated;

- (nullable Step *)stepForItem:(Item *)item; // ???: Useful?

- (BOOL)removeFromDisk;

@end

NS_ASSUME_NONNULL_END

#pragma mark - Deprecated
#include <sqlite3.h>
#import "TBLibrary.h"

NS_ASSUME_NONNULL_BEGIN

@class TBLibrary;
@interface Project ()

@property (nonatomic, strong) NSString * indexPath DEPRECATED_ATTRIBUTE; // The path of the index text file
@property (nonatomic, strong) TBLibrary * library DEPRECATED_ATTRIBUTE;
@property (nonatomic, assign) NSInteger priority DEPRECATED_ATTRIBUTE;
@property (nonatomic, assign) NSInteger identifier MIGRATION_ATTRIBUTE;

+ (NSArray <Project *> *)allProjectsFromLibrary:(TBLibrary *)library DEPRECATED_ATTRIBUTE;
+ (Project *)projectWithIdentifier:(NSInteger)identifier fromLibrary:(TBLibrary *)library MIGRATION_ATTRIBUTE;

- (instancetype)initWithCreationDate:(NSDate *)creationDate DEPRECATED_ATTRIBUTE;
- (instancetype)initWithName:(NSString *)name description:(NSString *)description priority:(NSInteger)priority identifier:(NSInteger)identifier DEPRECATED_ATTRIBUTE;
- (BOOL)insertIntoLibrary:(TBLibrary *)library UNAVAILABLE_ATTRIBUTE;
- (void)update UNAVAILABLE_ATTRIBUTE;
- (void)updateValue:(id)value forKey:(NSString *)key DEPRECATED_ATTRIBUTE;
- (Step *)stepWithIdentifier:(NSInteger)identifier DEPRECATED_ATTRIBUTE;
- (BOOL)delete DEPRECATED_ATTRIBUTE;
@end

NS_ASSUME_NONNULL_END
