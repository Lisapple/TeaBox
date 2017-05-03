//
//  TBDatabase.h
//  Tea Box
//
//  Created by Max on 07/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#define kLibraryBookmarkDataKey @"LibraryBookmarkData"

#import "Project.h"
#import "Step.h"
#import "Item.h"

NS_ASSUME_NONNULL_BEGIN

@class Project;
@protocol TBCoding;
@protocol TBDecoding;
@interface TBLibrary : NSObject <TBCoding, TBDecoding>

@property (readonly, strong) NSString * path;
@property (readonly, readonly) NSURL * baseURL;
@property (readonly, strong) NSString * name;
@property (readonly) NSArray <Project *> * projects;

+ (TBLibrary *)defaultLibrary;
+ (TBLibrary *)libraryWithName:(NSString *)name;
+ (TBLibrary *)createLibraryAtPath:(NSString *)path name:(nullable NSString *)name;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (nullable instancetype)initWithPath:(NSString *)path NS_DESIGNATED_INITIALIZER;

- (nullable Project *)projectWithName:(NSString *)name;
- (void)addProject:(Project *)project;
- (void)addProjects:(NSArray <Project *> *)projects;
- (void)removeProject:(Project *)project;

- (BOOL)moveLibraryToPath:(NSString *)newPath error:(NSError **)error;
- (BOOL)copyLibraryToPath:(NSString *)newPath error:(NSError **)error;

/// The returned URL contains the relative path from Library and the base URL to the library location on disk.
- (NSURL *)URLForProject:(Project *)project;

- (BOOL)moveProjectToTrash:(Project *)project;

- (BOOL)reloadFromDisk;
- (BOOL)save;

@end

NS_ASSUME_NONNULL_END


NS_ASSUME_NONNULL_BEGIN

@class Step;
@class FileItem;
@interface TBLibrary ()

- (nullable NSURL *)URLForStep:(Step *)step;
- (BOOL)moveStepToTrash:(Step *)step;

- (nullable NSURL *)URLForFileItem:(FileItem *)item;
- (BOOL)moveFileItemToTrash:(FileItem *)item;
- (BOOL)moveFileItemToTrash:(FileItem *)item exists:(nullable BOOL *)exists;

@end

NS_ASSUME_NONNULL_END


NS_ASSUME_NONNULL_BEGIN

#pragma mark - DEPRECATED
@interface TBLibrary ()

- (NSString *)pathForProjectFolder:(Project *)project DEPRECATED_MSG_ATTRIBUTE("Use -URLForProject: instead");
- (NSString *)pathForStepFolder:(Step *)step DEPRECATED_MSG_ATTRIBUTE("Use -URLForStep: instead");
- (nullable NSString *)pathForItem:(Item *)item UNAVAILABLE_ATTRIBUTE;

@end

NS_ASSUME_NONNULL_END


NS_ASSUME_NONNULL_BEGIN
@interface TBLibrary ()
{
	sqlite3 * database;
}
@property (nonatomic, strong) NSString * databasePath DEPRECATED_ATTRIBUTE;
@property (nonatomic, readonly, getter = isShared) BOOL shared DEPRECATED_ATTRIBUTE;

+ (TBLibrary *)createLibraryWithName:(NSString *)name atPath:(NSString *)path isSharedLibrary:(BOOL)shared UNAVAILABLE_ATTRIBUTE;

- (instancetype)initWithPath:(NSString *)path isSharedLibrary:(BOOL)shared UNAVAILABLE_ATTRIBUTE;
- (sqlite3 *)database NS_RETURNS_INNER_POINTER DEPRECATED_ATTRIBUTE;
- (void)close DEPRECATED_ATTRIBUTE;

- (int)createSavepoint UNAVAILABLE_ATTRIBUTE;
- (BOOL)releaseSavepoint:(int)identifier UNAVAILABLE_ATTRIBUTE;
- (BOOL)goBackToSavepoint:(int)identifier UNAVAILABLE_ATTRIBUTE;

- (BOOL)createBackup UNAVAILABLE_ATTRIBUTE;
- (BOOL)revertToBackup UNAVAILABLE_ATTRIBUTE;
- (BOOL)deleteBackup UNAVAILABLE_ATTRIBUTE;

- (NSURL *)URLForItem:(Item *)item UNAVAILABLE_ATTRIBUTE;

@end
NS_ASSUME_NONNULL_END
