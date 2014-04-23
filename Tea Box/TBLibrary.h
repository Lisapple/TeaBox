//
//  TBDatabase.h
//  Tea Box
//
//  Created by Max on 07/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kDefaultLibraryKey @"defaultLibrary"
#define kLibraryBookmarkDataKey @"LibraryBookmarkData"

#import "Project.h"
#import "Step.h"
#import "Item.h"

@interface TBLibrary : NSObject
{
	sqlite3 * database;
}

@property (nonatomic, strong) NSString * path, * databasePath;
@property (nonatomic, readonly, getter = isShared) BOOL shared;

+ (TBLibrary *)defaultLibrary;

+ (TBLibrary *)createLibraryWithName:(NSString *)name atPath:(NSString *)path isSharedLibrary:(BOOL)shared;
+ (TBLibrary *)libraryWithName:(NSString *)name;

- (id)initWithPath:(NSString *)path isSharedLibrary:(BOOL)shared;
- (sqlite3 *)database;
- (void)close;

- (int)createSavepoint;
- (BOOL)releaseSavepoint:(int)identifier;
- (BOOL)goBackToSavepoint:(int)identifier;

- (BOOL)createBackup;
- (BOOL)revertToBackup;
- (BOOL)deleteBackup;

- (BOOL)moveLibraryToPath:(NSString *)newPath error:(NSError **)error;
- (BOOL)copyLibraryToPath:(NSString *)newPath error:(NSError **)error;

- (NSString *)pathForProjectFolder:(Project *)project;
- (NSString *)pathForStepFolder:(Step *)step;
- (NSString *)pathForItem:(Item *)item;

- (NSURL *)URLForItem:(Item *)item;

@end
