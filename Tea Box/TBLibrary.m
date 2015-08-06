//
//  TBDatabase.m
//  Tea Box
//
//  Created by Max on 07/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "TBLibrary.h"

#define kDatabaseName "database"
#define kBackupName "~database"

@implementation TBLibrary

@synthesize path = _path, databasePath = _databasePath;
@synthesize shared = _shared;

static NSMutableDictionary * _libraries = nil;

+ (void)initialize
{
	static BOOL initialized = NO;
	if (!initialized) {
		
		_libraries = [[NSMutableDictionary alloc] initWithCapacity:3];
		
		NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
		
		NSURL * fileURL = nil;
		NSString * path = nil;
		NSData * bookmarkData = [userDefaults objectForKey:kLibraryBookmarkDataKey];
		if (bookmarkData) {
			
			NSURLBookmarkResolutionOptions bookmarkOptions = 0;
#if _SANDBOX_SUPPORTED_
			bookmarkOptions = NSURLBookmarkResolutionWithSecurityScope;
#endif
			fileURL = [NSURL URLByResolvingBookmarkData:bookmarkData
														options:bookmarkOptions
												  relativeToURL:nil
											bookmarkDataIsStale:NULL
														  error:NULL];
			path = [fileURL path];
		} else {
			path = [userDefaults stringForKey:kDefaultLibraryKey];
		}
		
		if (!path) {
			NSArray * documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES /* Expand the tilde (~/Documents => /Users/Max/Documents) */);
			NSString * documentPath = ([documentPaths count] > 0) ? documentPaths[0] : NSTemporaryDirectory();
			path = [documentPath stringByAppendingString:@"/Library.teaboxdb"];
		}
		
#if _SANDBOX_SUPPORTED_
		[fileURL startAccessingSecurityScopedResource];
#endif
		// @TODO: observe userDefaults to catch path of default library changes
		TBLibrary * defaultLibrary = [[TBLibrary alloc] initWithPath:path isSharedLibrary:NO];
		if (defaultLibrary) _libraries[@"com.lisacintosh.teabox.default-library"] = defaultLibrary;
		
#if _SANDBOX_SUPPORTED_
		[fileURL stopAccessingSecurityScopedResource];
#endif
		
		initialized = YES;
	}
}

+ (TBLibrary *)defaultLibrary
{
	return _libraries[@"com.lisacintosh.teabox.default-library"];
}

+ (TBLibrary *)createLibraryWithName:(NSString *)name atPath:(NSString *)path isSharedLibrary:(BOOL)shared
{
	TBLibrary * library = [[TBLibrary alloc] initWithPath:path isSharedLibrary:shared];
	if (library) [_libraries setValue:library forKey:name];
	return library;
}

+ (TBLibrary *)libraryWithName:(NSString *)name
{
	return _libraries[name];
}

sqlite3 * init_db(const char path[]);
sqlite3 * init_db(const char path[])
{
	sqlite3 * _db = NULL;
	
	sqlite3_initialize();
	int err = sqlite3_open_v2(path, &_db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL);
	
	if (err != SQLITE_OK) {
		printf("error on creating/openning the database at path: \"%s\" (err code %d).", path, err);
		sqlite3_close(_db);
		return NULL;
	}
	
	return _db;
}

- (instancetype)initWithPath:(NSString *)path isSharedLibrary:(BOOL)shared
{
	if ((self = [super init])) {
		self.path = path;
		self.databasePath = [NSString stringWithFormat:@"%@/%s", self.path, kDatabaseName];
		_shared = shared;
		
		if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
			NSError * error = nil;
			BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:path
													 withIntermediateDirectories:YES
																	  attributes:nil
																		   error:&error];
			if (!success)
				[NSApp presentError:error];
		}
		
		if (![[NSFileManager defaultManager] fileExistsAtPath:self.databasePath]) {
			NSError * error = nil;
			NSString * originalDatabasePath = [[NSBundle mainBundle] pathForResource:@"default-database" ofType:@"sqlite3"];
			BOOL success = [[NSFileManager defaultManager] copyItemAtPath:originalDatabasePath toPath:self.databasePath error:&error];
			if (!success)
				[NSApp presentError:error];
		}
		database = init_db([self.databasePath UTF8String]); // @TODO: create a method to close and release "database"
	}
	return self;
}

- (void)close
{
	sqlite3_close(self.database);
}

#pragma mark - Savepoint Management

- (int)createSavepoint
{
	static int identifier = 0;
	identifier++; // start at "savepoint_1"
	NSString * sql = [NSString stringWithFormat:@"SAVEPOINT savepoint_%i", identifier];
	
	int err = sqlite3_exec(self.database, [sql UTF8String], NULL, NULL, NULL);
	if (err != SQLITE_OK)
		return -1;
	
	return identifier;
}

- (BOOL)releaseSavepoint:(int)identifier
{
	NSString * sql = [NSString stringWithFormat:@"RELEASE savepoint_%i", identifier];
	
	int err = sqlite3_exec(self.database, [sql UTF8String], NULL, NULL, NULL);
	if (err != SQLITE_OK)
		return NO;
	
	return YES;
}

- (BOOL)goBackToSavepoint:(int)identifier
{
	NSString * sql = [NSString stringWithFormat:@"ROLLBACK TO savepoint_%i", identifier];
	
	int err = sqlite3_exec(self.database, [sql UTF8String], NULL, NULL, NULL);
	if (err != SQLITE_OK)
		return NO;
	
	return [self releaseSavepoint:identifier];
}

#pragma mark - Savepoint Management

- (BOOL)createBackup
{
	[self deleteBackup];
	
	sqlite3_initialize();
	sqlite3 * backup_db = NULL;
	const char * path = [[NSString stringWithFormat:@"%@/%s", self.path, kBackupName] UTF8String];
	int err = sqlite3_open_v2(path, &backup_db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL);
	
	sqlite3_backup * backup = sqlite3_backup_init(backup_db, "main", self.database, "main");
	if (!backup) return NO;
	
	err += sqlite3_backup_step(backup, -1); // Copy all pages
	err += sqlite3_backup_finish(backup);
	
	return (err == 0);
}

- (BOOL)revertToBackup
{
	NSString * currentDatabasePath = [NSString stringWithFormat:@"%@/%s", self.path, kDatabaseName];
	NSString * backupDatabasePath = [NSString stringWithFormat:@"%@/%s", self.path, kDatabaseName];
	BOOL success = [[NSFileManager defaultManager] removeItemAtPath:currentDatabasePath error:NULL];
	success |= [[NSFileManager defaultManager] moveItemAtPath:backupDatabasePath toPath:currentDatabasePath error:NULL];
	return success;
}

- (BOOL)deleteBackup
{
	NSString * path = [NSString stringWithFormat:@"%@/%s", self.path, kBackupName];
	BOOL success = [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
	return success;
}


- (sqlite3 *)database
{
	return database;
}

- (BOOL)moveLibraryToPath:(NSString *)newPath error:(NSError **)error
{
	NSURL * fileURL = nil;
	NSString * path = nil;
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	NSData * bookmarkData = [userDefaults objectForKey:kLibraryBookmarkDataKey];
	if (bookmarkData) {
		
		NSURLBookmarkResolutionOptions bookmarkOptions = 0;
#if _SANDBOX_SUPPORTED_
		bookmarkOptions = NSURLBookmarkResolutionWithSecurityScope;
#endif
		fileURL = [NSURL URLByResolvingBookmarkData:bookmarkData
											options:bookmarkOptions
									  relativeToURL:nil
								bookmarkDataIsStale:NULL
											  error:NULL];
		path = [fileURL path];
	} else {
		path = [userDefaults stringForKey:kDefaultLibraryKey];
	}
	
#if _SANDBOX_SUPPORTED_
	[fileURL startAccessingSecurityScopedResource];
#endif
	
	BOOL success = [[NSFileManager defaultManager] moveItemAtPath:path toPath:newPath error:error];
	
#if _SANDBOX_SUPPORTED_
	[fileURL stopAccessingSecurityScopedResource];
#endif
	
	if (success) {
		_path = newPath;
		
		_databasePath = [newPath stringByAppendingFormat:@"/database"];
		
		NSURLBookmarkCreationOptions bookmarkOptions = 0;
#if _SANDBOX_SUPPORTED_
		bookmarkOptions = NSURLBookmarkCreationWithSecurityScope;
#endif
		NSURL * fileURL = [NSURL fileURLWithPath:_path];
		NSError * error = nil;
		NSData * bookmarkData = [fileURL bookmarkDataWithOptions:bookmarkOptions
								  includingResourceValuesForKeys:nil
												   relativeToURL:nil // Use nil for app-scoped bookmark
														   error:&error];
		
		NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
		if (bookmarkData)
			[userDefaults setObject:bookmarkData forKey:kLibraryBookmarkDataKey];
		else
			[userDefaults removeObjectForKey:kLibraryBookmarkDataKey];
		
		if (database) {
			sqlite3_close_v2(database); // Close (force even when busy) and release the database
			database = NULL;
		}
		database = init_db([_databasePath UTF8String]);
	}
	
	return success;
}

- (BOOL)copyLibraryToPath:(NSString *)newPath error:(NSError **)error
{
	return [[NSFileManager defaultManager] copyItemAtPath:_path toPath:newPath error:error];
}

/* The returned path looks like "{Path to library}/{Library name}.teaboxdb/Projects/{Project id} - {Project name}" */
- (NSString *)pathForProjectFolder:(Project *)project
{
	NSString * parentFolderPath = [NSString stringWithFormat:@"%@/Projects", self.path];
	NSString * folderName = [NSString stringWithFormat:@"%i - %@", project.identifier, project.name];
	NSString * path = [NSString stringWithFormat:@"%@/%@", parentFolderPath, folderName];
	
	NSFileManager * manager = [[NSFileManager alloc] init];
	if (![manager fileExistsAtPath:path]) {
		folderName = nil;
		NSDirectoryEnumerationOptions options = (NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants);
		NSDirectoryEnumerator * enumerator = [manager enumeratorAtURL:[NSURL fileURLWithPath:parentFolderPath]
										   includingPropertiesForKeys:nil options:options errorHandler:NULL];
		BOOL folderExists = NO;
		int length = (int)ceil(log10(project.identifier));
		for (NSURL * fileURL in enumerator) {
			NSString * filename = [[fileURL path] lastPathComponent];
			if (filename.length > (length + 1)) {
				int folderID = 0;
				if ([[NSScanner scannerWithString:[filename substringToIndex:(length + 1)]] scanInt:&folderID] && folderID == project.identifier) {
					/* Rename the folder with the new name */
					[manager moveItemAtPath:[fileURL path]
									 toPath:path
									  error:NULL];
					folderExists = YES;
					break;
				}
			}
		}
		
		if (!folderExists) {
			[manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
		}
	}
	
	return path;
}

/* The returned path looks like "{Path to library}/{Library name}.teaboxdb/Projects/{Project id} - {Project name}/{Step id} - {Step name}" */
- (NSString *)pathForStepFolder:(Step *)step
{
	NSString * parentFolderPath = [self pathForProjectFolder:step.project];
	NSString * folderName = [NSString stringWithFormat:@"%i - %@", step.identifier, step.name];
	NSString * path = [NSString stringWithFormat:@"%@/%@", parentFolderPath, folderName];
	
	NSFileManager * manager = [[NSFileManager alloc] init];
	if (![manager fileExistsAtPath:path]) {
		NSDirectoryEnumerator * enumerator = [manager enumeratorAtURL:[NSURL fileURLWithPath:parentFolderPath]
										   includingPropertiesForKeys:nil
															  options:(NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants)
														 errorHandler:NULL];
		BOOL folderExists = NO;
		int length = (int)ceil(log10(step.identifier));
		for (NSURL * fileURL in enumerator) {
			NSString * filename = [[fileURL path] lastPathComponent];
			if (filename.length > (length + 1)) {
				int folderID = 0;
				if ([[NSScanner scannerWithString:[filename substringToIndex:(length + 1)]] scanInt:&folderID] && folderID == step.identifier) {
					/* Rename the folder with the new name */
					[manager moveItemAtPath:[fileURL path]
									 toPath:path
									  error:NULL];
					folderExists = YES;
					break;
				}
			}
		}
		
		if (!folderExists) {
			[manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
		}
	}
	
	return path;
}

/* The returned URL looks like "{Path to library}/{Library name}.teaboxdb/Projects/{Project id} - {Project name}/{Step id} - {Step name}/{filename}.{extension}" */
- (NSURL *)URLForItem:(Item *)item
{
	if (item.filename) {// If we have a filename from "item", the file is into the library, return the path with this filename
		return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", [self pathForStepFolder:item.step], item.filename]];
	} else {
		NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
		NSString * key = [NSString stringWithFormat:@"%i/%i/%i", item.step.project.identifier, item.step.identifier, item.identifier];
		NSData * bookmarkData = [userDefaults dataForKey:key];
		
		NSURLBookmarkResolutionOptions bookmarkOptions = 0;
#if _SANDBOX_SUPPORTED_
		bookmarkOptions = NSURLBookmarkResolutionWithSecurityScope;
#endif
		NSURL * fileURL = [NSURL URLByResolvingBookmarkData:bookmarkData
										  options:bookmarkOptions
									relativeToURL:nil // Use nil for app-scoped bookmark
							  bookmarkDataIsStale:NULL
											error:NULL];
		
		return fileURL;
	}
}

- (NSString *)pathForItem:(Item *)item
{
	return [self URLForItem:item].path;
}

@end
