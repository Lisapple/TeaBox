//
//  Project.h
//  Tea Box
//
//  Created by Max on 03/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <sqlite3.h>

#import "TBLibrary.h"

@class TBLibrary;
@class Step;
@interface Project : NSObject

@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSString * description;
@property (nonatomic, strong) NSString * indexPath;// The path of the index text file
@property (unsafe_unretained, nonatomic, readonly) NSDate * creationDate;
@property (nonatomic, strong) NSDate * lastModificationDate;
@property (nonatomic, strong) TBLibrary * library;
@property (nonatomic, assign) int priority;
@property (nonatomic, assign) int identifier;

+ (NSArray *)allProjectsFromLibrary:(TBLibrary *)library;
+ (Project *)projectWithIdentifier:(int)identifier fromLibrary:(TBLibrary *)library;

- (id)initWithName:(NSString *)name description:(NSString *)description priority:(int)priority insertIntoLibrary:(TBLibrary *)library;
- (id)initWithName:(NSString *)name description:(NSString *)description priority:(int)priority identifier:(int)projectID insertIntoLibrary:(TBLibrary *)library;

- (void)update;

- (void)updateValue:(id)value forKey:(NSString *)key;

- (NSArray *)steps;
- (Step *)stepWithIdentifier:(int)identifier;

- (BOOL)delete;

// Private
- (id)initWithCreationDate:(NSDate *)creationDate;

@end
