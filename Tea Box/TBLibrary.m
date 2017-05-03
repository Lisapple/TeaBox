//
//  TBDatabase.m
//  Tea Box
//
//  Created by Max on 07/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "TBLibrary.h"

#import "SandboxHelper.h"

#import "NSDate+additions.h" // Migration only

NSString * descriptionForError(int err);
NSString * descriptionForError(int err) {
	switch (err) {
		case SQLITE_IOERR: return @"Some kind of disk I/O error occurred";
	}
	return nil;
}

void DebugErrorLog(int err);
void DebugErrorLog(int err) {
	NSString * description = descriptionForError(err);
	if (description)
		NSLog(@"Error %d: %@", err, description);
}

NSString * const kDefaultLibraryKey = @"com.lisacintosh.teabox.default-library";

@interface Project ()

- (void)setCreationDate:(NSDate *)date MIGRATION_ATTRIBUTE;

@end

@interface TBLibrary ()

@property (strong) NSMutableArray * projects;
/// Names of all projects for lazy loading
@property (strong) NSArray * projectPaths;

- (void)setName:(NSString *)name;

- (BOOL)migrateFromSQLite MIGRATION_ATTRIBUTE;

@end

@implementation TBLibrary

static NSMutableDictionary * _libraries = nil; // Note: Actually, only one library is supported

+ (void)initialize
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_libraries = [[NSMutableDictionary alloc] initWithCapacity:1];
		
		NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
		NSData * bookmarkData = [userDefaults objectForKey:kLibraryBookmarkDataKey];
		[SandboxHelper executeWithSecurityScopedAccessFromBookmarkData:bookmarkData block:^(NSURL * _Nullable fileURL, NSError * _Nullable error) {
			NSString * path = fileURL.path;
			if (path && [[NSFileManager defaultManager] fileExistsAtPath:path]) { // Don't create library, just load it if existing
				TBLibrary * defaultLibrary = [[TBLibrary alloc] initWithPath:path];
				if (defaultLibrary) _libraries[kDefaultLibraryKey] = defaultLibrary;
			}
		}];
	});
}

+ (TBLibrary *)defaultLibrary
{
	return _libraries[kDefaultLibraryKey];
}

+ (TBLibrary *)libraryWithName:(NSString *)name
{
	return _libraries[name];
}

+ (TBLibrary *)createLibraryAtPath:(NSString *)path name:(nullable NSString *)name
{
	TBLibrary * library = [[TBLibrary alloc] initWithPath:path];
	if (name) library.name = name;
	if (library) _libraries[name] = library;
	return library;
}

- (instancetype)initWithPath:(NSString *)path
{
	NSString * content = [[NSString alloc] initWithContentsOfFile:[path stringByAppendingFormat:@"/%@", LibraryRootFilename]
														 encoding:NSUTF8StringEncoding error:nil];
	if (content && (self = [self initWithRepresentation:content])) {
		_path = path;
		_projects = [[NSMutableArray alloc] initWithCapacity:10];
		
		// Load projects
		for (NSString * projectPath in self.projectPaths) {
			NSString * const indexPath = [path stringByAppendingFormat:@"/%@/%@", projectPath, ProjectIndexFilename];
			NSString * const content = [[NSString alloc] initWithContentsOfFile:indexPath encoding:NSUTF8StringEncoding error:nil];
			NSAssert(content, @"");
			Project * project = [[Project alloc] initWithRepresentation:content];
			project.path = projectPath;
			if (project) [self addProject:project];
		}
	}
	else if ((self = [super init])) {
		_path = path;
		_projects = [[NSMutableArray alloc] initWithCapacity:10];
		
		BOOL success = YES;
		if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
			NSError * error = nil;
			// Create subdirectories (if needed)
			success &= [[NSFileManager defaultManager] createDirectoryAtPath:path
												 withIntermediateDirectories:YES attributes:nil error:&error];
			if (!success) {
				NSLog(@"Error creating empty library at %@", path);
				return nil;
			}
			
			// Copy default library (from app bundle)
			NSString * path = DefaultPathForDirectory(NSDocumentDirectory);
			if (![path hasSuffix:@".teaboxdb"])
				path = [path stringByAppendingString:@"/Library.teaboxdb"];
			
			NSString * originalDatabasePath = [[NSBundle mainBundle] pathForResource:@"Default Library/Library" ofType:@"teaboxdb"];
			
			success &= [[NSFileManager defaultManager] copyItemAtPath:originalDatabasePath
															   toPath:path error:&error];
			if (!success) {
				NSLog(@"Error copying default library to %@", path);
				
				return nil;
			}
		} else { // Library exisiting with no root file, migrate from SQLite
			[self migrateFromSQLite];
		}
	}
	return self;
}

- (NSURL *)baseURL
{
	return [NSURL fileURLWithPath:self.path];
}

- (void)setName:(NSString *)name
{
	_name = name;
}

- (nullable Project *)projectWithName:(NSString *)name
{
	for (Project * project in self.projects) {
		if ([project.name isEqualToString:name])
			return project;
	}
	return nil;
}

- (void)addProject:(Project *)project
{
	[_projects addObject:project];
}

- (void)addProjects:(NSArray <Project *> *)projects
{
	[_projects addObjectsFromArray:projects];
}

- (void)removeProject:(Project *)project
{
	[_projects removeObject:project];
}

- (BOOL)moveLibraryToPath:(NSString *)newPath error:(NSError **)pError // @TODO: Need refactoring
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
											  error:pError];
		path = fileURL.path;
	}
	
	if (!path) { // If no bookmark data, look at "~/Document/Library.teaboxdb" (in sandbox container)
		NSString * documentPath = DefaultPathForDirectory(NSDocumentDirectory);
		path = [documentPath stringByAppendingString:@"/Library.teaboxdb"];
	}
	
#if _SANDBOX_SUPPORTED_
	[fileURL startAccessingSecurityScopedResource];
#endif
	
	BOOL success = [[NSFileManager defaultManager] moveItemAtPath:path toPath:newPath error:pError];
	
#if _SANDBOX_SUPPORTED_
	[fileURL stopAccessingSecurityScopedResource];
#endif
	
	if (success) {
		_path = newPath;
		
		_databasePath = [newPath stringByAppendingFormat:@"/database"];
		
		NSURL * fileURL = [NSURL fileURLWithPath:_path];
		NSData * bookmarkData = [fileURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
								  includingResourceValuesForKeys:nil relativeToURL:nil // Use nil for app-scoped bookmark
														   error:pError];
		
		NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
		[userDefaults setObject:bookmarkData forKey:kLibraryBookmarkDataKey];
		
		if (database) {
			sqlite3_close_v2(database); // Close (force even when busy) and release the database
			database = NULL;
		}
		database = init_db(_databasePath.UTF8String);
	}
	
	return success;
}

- (BOOL)copyLibraryToPath:(NSString *)newPath error:(NSError **)error
{
	return [[NSFileManager defaultManager] copyItemAtPath:_path toPath:newPath error:error];
}

- (NSURL *)URLForProject:(Project *)project
{
	NSString * relativePath = [@"Projects/" stringByAppendingFormat:@"%@", project.name];
	if (project.identifier != 0) // Migration support only
		relativePath = [@"Projects/" stringByAppendingFormat:@"%li - %@", (long)project.identifier, project.name];
	
	return [NSURL fileURLWithPath:relativePath
					relativeToURL:[NSURL fileURLWithPath:self.path]];
}

- (BOOL)moveProjectToTrash:(Project *)project
{
	__block BOOL success = NO;
	NSURL * const fileURL = [self URLForProject:project];
	[SandboxHelper executeWithSecurityScopedAccessToURL:fileURL block:^(NSError * error) {
		if (!error)
			success = [[NSFileManager defaultManager] trashItemAtURL:fileURL resultingItemURL:nil error:nil];
	}];
	return success;
}

- (BOOL)reloadFromDisk
{
	__block BOOL success = NO;
	[SandboxHelper executeBlockWithSecurityScopedLibraryAccessing:^(NSError * _Nullable error) {
		TBLibrary * library = [[TBDecoder decoderWithPath:self.path] decodeLibrary];
		if (library) {
			self.name = library.name;
		}
		success = (library != nil);
		
		for (Project * project in self.projects) {
			NSString * path = [[self URLForProject:project].path stringByAppendingFormat:@"/%@", ProjectIndexFilename];
			Project * reloadedProject = [[TBDecoder decoderWithPath:path] decodeProjectNamed:project.name];
			if (reloadedProject) {
				project.name = reloadedProject.name;
				project.description = reloadedProject.description;
				project.creationDate = reloadedProject.creationDate;
				project.lastModificationDate = reloadedProject.lastModificationDate;
				project.projectPriority = reloadedProject.projectPriority;
				// @TODO: Reload steps and items
			}
			success &= (reloadedProject != nil);
		}
	}];
	return success;
}

- (BOOL)save
{
	__block BOOL success = NO;
	[SandboxHelper executeBlockWithSecurityScopedLibraryAccessing:^(NSError * _Nullable error) {
		success = [[TBCoder coderForPath:self.path] encodeLibrary:self];
		
		for (Project * project in self.projects) {
			NSString * path = [[self URLForProject:project].path stringByAppendingFormat:@"/%@", ProjectIndexFilename];
			success &= [[TBCoder coderForPath:path] encodeObject:project];
		}
	}];
	return success;
}

#pragma mark - Utilities

- (nullable Project *)projectForStep:(Step *)step
{
	for (Project * aProject in self.projects) {
		if ([aProject.steps containsObject:step])
			return aProject;
	}
	return nil;
}

- (nullable NSURL *)URLForStep:(Step *)step
{
	Project * project = [self projectForStep:step];
	if (!project)
		return nil;
	
	NSURL * folderURL = [[self URLForProject:project] URLByAppendingPathComponent:step.name];
	[SandboxHelper executeWithSecurityScopedAccessToURL:folderURL block:^(NSError * error) {
		if (!error) {
			NSFileManager * manager = [NSFileManager defaultManager];
			if (![manager fileExistsAtPath:folderURL.path])
				[manager createDirectoryAtPath:folderURL.path withIntermediateDirectories:YES attributes:nil error:nil];
		}
	}];
	return folderURL;
}

- (BOOL)moveStepToTrash:(Step *)step
{
	NSURL * const fileURL = [self URLForStep:step];
	__block BOOL success = NO;
	[SandboxHelper executeWithSecurityScopedAccessToURL:fileURL block:^(NSError * error) {
		if (!error)
			success = [[NSFileManager defaultManager] trashItemAtURL:fileURL resultingItemURL:nil error:nil];
	}];
	return success;
}

- (nullable Step *)stepForItem:(Item *)item
{
	for (Project * project in self.projects) {
		for (Step * step in project.steps) {
			if ([step.items containsObject:item])
				return step;
		}
	}
	return nil;
}

- (nullable NSURL *)URLForFileItem:(FileItem *)item
{
	Step * const step = [self stepForItem:item];
	if (step)
		return [[self URLForStep:step] URLByAppendingPathComponent:item.URL.relativePath];
	
	return nil;
}

- (BOOL)moveFileItemToTrash:(FileItem *)item
{
	return [self moveFileItemToTrash:item exists:nil];
}

- (BOOL)moveFileItemToTrash:(FileItem *)item exists:(nullable BOOL *)exists
{
	NSURL * const fileURL = [self URLForFileItem:item];
	__block BOOL success = NO;
	[SandboxHelper executeWithSecurityScopedAccessToURL:fileURL block:^(NSError * error) {
		if (!error) {
			if (exists) *exists = [[NSFileManager defaultManager] fileExistsAtPath:fileURL.path];
			
			success = [[NSFileManager defaultManager] trashItemAtURL:fileURL resultingItemURL:nil error:nil];
		}
	}];
	return success;
}

#pragma mark - Deprecated

/* The returned path looks like "{Path to library}/{Library name}.teaboxdb/Projects/{Project id} - {Project name}" */
- (NSString *)pathForProjectFolder:(Project *)project // DEPRECATED
{
	NSString * parentFolderPath = [NSString stringWithFormat:@"%@/Projects", self.path];
	__block NSString * folderName = [NSString stringWithFormat:@"%li - %@", (long)project.identifier, project.name];
	NSString * path = [NSString stringWithFormat:@"%@/%@", parentFolderPath, folderName];
	
	[SandboxHelper executeWithSecurityScopedAccessToPath:path block:^(NSError * error) {
		if (!error) {
			NSFileManager * manager = [NSFileManager defaultManager];
			if (![manager fileExistsAtPath:path]) {
				folderName = nil;
				NSDirectoryEnumerationOptions options = (NSDirectoryEnumerationSkipsHiddenFiles |
														 NSDirectoryEnumerationSkipsPackageDescendants |
														 NSDirectoryEnumerationSkipsSubdirectoryDescendants);
				NSDirectoryEnumerator * enumerator = [manager enumeratorAtURL:[NSURL fileURLWithPath:parentFolderPath]
												   includingPropertiesForKeys:nil options:options errorHandler:NULL];
				BOOL folderExists = NO;
				int length = (int)ceil(log10(project.identifier));
				for (NSURL * fileURL in enumerator) {
					NSString * filename = fileURL.path.lastPathComponent;
					if (filename.length > (length + 1)) {
						int folderID = 0;
						if ([[NSScanner scannerWithString:[filename substringToIndex:(length + 1)]] scanInt:&folderID] && folderID == project.identifier) {
							// Rename the folder with the new name
							[manager moveItemAtPath:fileURL.path toPath:path error:NULL];
							folderExists = YES;
							break;
						}
					}
				}
				
				if (!folderExists) {
					[manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL];
				}
			}
		}
	}];
	return path;
}

- (NSString *)pathForStepFolder:(Step *)step // DEPRECATED
{
	return [self URLForStep:step].path;
	
	Project * project = [self projectForStep:step];
	if (!project)
		return nil;
	
	NSString * projectFolderPath = [self URLForProject:project].path;
	NSString * path = [NSString stringWithFormat:@"%@/%@", projectFolderPath, step.name];
	[SandboxHelper executeWithSecurityScopedAccessToPath:path block:^(NSError * error) {
		if (!error) {
			NSFileManager * manager = [NSFileManager defaultManager];
			if (![manager fileExistsAtPath:path])
				[manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
		}
	}];
	return path;
}

#pragma mark - Deprecated (migration only)

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

- (sqlite3 *)database
{
	return database;
}

- (BOOL)migrateFromSQLite
{
	_databasePath = [self.path stringByAppendingFormat:@"/database"];
	database = init_db(_databasePath.UTF8String);
	if (!database)
		return NO;
	
	// create a statement from an SQL string
	sqlite3_stmt * stmt = NULL;
	const char sql[] = "SELECT name, description, priority, creation_date, last_modification_date, index_path, Project_id FROM Project ORDER BY priority, Project_id ASC";
	int err = sqlite3_prepare_v2(database, sql, -1, &stmt, NULL);
	if (err != SQLITE_OK) {
		NSAssert(false, @"\"sqlite3_prepare_v2\" did fail with error: %d", err);
		return NO;
	}
	
	while (sqlite3_step(stmt) == SQLITE_ROW) {
		NSString * name = nil;
		const char * name_ptr = (const char *)sqlite3_column_text(stmt, 0); // "name"
		if (name_ptr)
			name = @(name_ptr);
		
		NSString * description = nil;
		const char * description_ptr = (const char *)sqlite3_column_text(stmt, 1); // "description"
		if (description_ptr)
			description = @(description_ptr);
		
		int priority = (int)sqlite3_column_int(stmt, 2); // "priority"
		
		NSString * creationDateString = nil;
		const char * creation_date_string_ptr = (const char *)sqlite3_column_text(stmt, 3); // "creation_date"
		if (creation_date_string_ptr)
			creationDateString = @(creation_date_string_ptr);
		
		NSString * lastModificationDateString = nil;
		const char * last_modification_date_ptr = (const char *)sqlite3_column_text(stmt, 4); // "last_modification_date"
		if (last_modification_date_ptr)
			lastModificationDateString = @(last_modification_date_ptr);
		
		NSString * indexPath = nil;
		const char * index_path_ptr = (const char *)sqlite3_column_text(stmt, 5); // "index_path"
		if (index_path_ptr)
			indexPath = @(index_path_ptr);
		
		Project * project = [[Project alloc] initWithName:name description:description];
		project.identifier = (NSInteger)sqlite3_column_int(stmt, 6); // "Project_id"
		project.path = [NSString stringWithFormat:@"%li - %@", project.identifier, name];
		project.priority = priority;
		project.creationDate = [NSDate dateFromSQLiteDate:creationDateString];
		project.lastModificationDate = [NSDate dateFromSQLiteDate:lastModificationDateString];
		project.indexPath = indexPath;
		project.library = self;
		
		NSArray <Step *> * steps = [Step stepsWithProjectIdentifier:project.identifier fromLibrary:self];
		for (Step * step in steps) {
			NSArray <FileItem *> * oldItems = [FileItem itemsWithStepIdentifier:(int)step.identifier fromLibrary:self];
			NSMutableArray <Item *> * items = [NSMutableArray arrayWithCapacity:oldItems.count];
			for (FileItem * oldItem in oldItems) {
				__block NSURL * URL = nil;
				if (oldItem.filename) { // Into library
					NSURL * projectURL = [self URLForProject:project];
					NSString * stepName = [NSString stringWithFormat:@"%li - %@", step.identifier, step.name];
					NSURL * stepURL = [[NSURL URLWithString:projectURL.relativeString] URLByAppendingPathComponent:stepName];
					URL = [NSURL fileURLWithPath:[stepURL URLByAppendingPathComponent:oldItem.filename].path
								   relativeToURL:projectURL];
					
				} else { // Linked item (path is saved as sandbox bookmark data)
					NSString * key = [NSString stringWithFormat:@"%li/%li/%li", (long)project.identifier, (long)step.identifier, (long)oldItem.identifier];
					NSData * bookmarkData = [[NSUserDefaults standardUserDefaults] dataForKey:key];
					[SandboxHelper executeWithSecurityScopedAccessFromBookmarkData:bookmarkData block:^(NSURL * _Nullable fileURL, NSError * _Nullable error) {
						if (fileURL && !error) {
							URL = fileURL;
							[[NSUserDefaults standardUserDefaults] setObject:bookmarkData forKey:fileURL.absoluteString];
						}
					}];
				}
				FileItemType type = FileItemTypeFromString(oldItem.type);
				Item * item = nil;
				if (type == FileItemTypeText) {
					NSDictionary * options = @{ NSDocumentTypeDocumentAttribute : NSRTFTextDocumentType };
					NSString * content = [[NSAttributedString alloc] initWithURL:URL options:options
															  documentAttributes:nil error:nil].string;
					item = [[TextItem alloc] initWithContent:content];
				} else
					item = [[FileItem alloc] initWithType:type fileURL:URL];
				
				[items addObject:item];
			}
			NSAssert(items.count == oldItems.count, @"");
			[step addItems:items];
		}
		[project addSteps:steps];
		[_projects addObject:project];
	}
	sqlite3_finalize(stmt);
	
	// Delete backup file
	[[NSFileManager defaultManager] removeItemAtPath:[self.path stringByAppendingFormat:@"/~database"]
											   error:nil];
	
	return (database && [self save]);
}

- (void)close
{
	sqlite3_close(self.database);
}

@end
