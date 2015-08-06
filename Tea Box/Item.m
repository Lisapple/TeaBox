//
//  Item.m
//  Tea Box
//
//  Created by Max on 04/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "Item.h"

#import "Step.h"
#import "Project.h"

@implementation Item

NSString * const kItemTypeImage	= @"IMG";
NSString * const kItemTypeText	= @"TXT";
NSString * const kItemTypeWebURL = @"URL";
NSString * const kItemTypeFile	= @"FILE";
NSString * const kItemTypeFolder = @"FOLD";
NSString * const kItemTypeUnkown = @"????";

+ (NSArray *)itemsWithStepIdentifier:(int)stepID fromLibrary:(TBLibrary *)library
{
	NSMutableArray * items = [NSMutableArray arrayWithCapacity:10];
	Step * step = [Step stepWithIdentifier:stepID fromLibrary:library];
	
	// Create a statement from an SQL string
	sqlite3_stmt * stmt = NULL;
	const char sql[] = "SELECT filename, type, Item_id FROM Item WHERE Step_id = :step_id ORDER BY Step_id ASC";
	int err = sqlite3_prepare_v2(library.database, sql, -1, &stmt, NULL);
	NSAssert((err == SQLITE_OK), @"\"sqlite3_prepare_v2\" did fail with error: %d", err);
	
	int step_id_bind = sqlite3_bind_parameter_index(stmt, ":step_id");
	err = sqlite3_bind_int(stmt, step_id_bind, stepID);
	NSAssert((err == SQLITE_OK), @"\"sqlite3_bind_int\" did fail with error: %d", err);
	
	// Execute statement and step over each row of the result set
	while (sqlite3_step(stmt) == SQLITE_ROW)
	{
		NSString * filename = nil;
		const char * filename_ptr = (const char *)sqlite3_column_text(stmt, 0 /* "filename" */);
		if (filename_ptr)
			filename = @(filename_ptr);
		
		NSString * type = nil;
		const char * type_ptr = (const char *)sqlite3_column_text(stmt, 1 /* "type" */);
		if (type_ptr)
			type = @(type_ptr);
		
		int identifier = sqlite3_column_int(stmt, 2 /* "Step_id" */);
		Item * item = [[Item alloc] initWithFilename:filename type:type rowIndex:-1 identifier:identifier step:step];
		item.library = library;
		
		[items addObject:item];
	}
	
	// Destroy and release the statement
	sqlite3_finalize(stmt);
	
	return items;
}

+ (Item *)itemWithIdentifier:(int)identifier fromLibrary:(TBLibrary *)library
{
	// Create a statement from an SQL string
	sqlite3_stmt * stmt = NULL;
	const char sql[] = "SELECT filename, type, Step_id FROM Item WHERE Item_id = :item_id ORDER BY Step_id ASC LIMIT 1";
	int err = sqlite3_prepare_v2(library.database, sql, -1, &stmt, NULL);
	NSAssert((err == SQLITE_OK), @"\"sqlite3_prepare_v2\" did fail with error: %d", err);
	
	int item_id_bind = sqlite3_bind_parameter_index(stmt, ":item_id");
	err = sqlite3_bind_int(stmt, item_id_bind, identifier);
	NSAssert((err == SQLITE_OK), @"\"sqlite3_bind_int\" did fail with error: %d", err);
	
	Item * item = nil;
	// Execute statement and step over each row of the result set
	if (sqlite3_step(stmt) == SQLITE_ROW)
	{
		NSString * filename = nil;
		const char * filename_ptr = (const char *)sqlite3_column_text(stmt, 0 /* "filename" */);
		if (filename_ptr)
			filename = @(filename_ptr);
		
		NSString * type = nil;
		const char * type_ptr = (const char *)sqlite3_column_text(stmt, 1 /* "type" */);
		if (type_ptr)
			type = @(type_ptr);
		
		int stepID = sqlite3_column_int(stmt, 2 /* "Step_id" */);
		Step * step = [Step stepWithIdentifier:stepID fromLibrary:library];
		item = [[Item alloc] initWithFilename:filename type:type rowIndex:-1 identifier:identifier step:step];
		item.library = library;
	}
	
	// Destroy and release the statement
	sqlite3_finalize(stmt);
	
	return item;
}

- (instancetype)initWithFilename:(NSString *)filename type:(NSString *)type step:(Step *)step
{
	return [self initWithFilename:filename type:type rowIndex:-1 identifier:-1 step:step];
}

- (instancetype)initWithFilename:(NSString *)filename type:(NSString *)type rowIndex:(int)rowIndex identifier:(int)identifier step:(Step *)step
{
	if (self = [super init]) {
		_identifier = identifier;
		_filename = filename;
		_type = type;
		self.step = step;
		
		int count = (int)_step.itemsCount;
		if (rowIndex < 0 || rowIndex > count)
			rowIndex = count;
		
		self.rowIndex = rowIndex;
	}
	return self;
}

- (BOOL)insertIntoLibrary:(TBLibrary *)library
{
	NSParameterAssert(library);
	
	self.library = library;
	
	sqlite3 * database = library.database;
	
	/* Create a lock when sending the 2 queries */
	sqlite3_mutex * mutex = sqlite3_db_mutex(database);
	sqlite3_mutex_enter(mutex);
	
	/* Create the SQL query */
	char * sql = NULL;
	if (_identifier == -1) { // If no "identifier", let SQLite generate one
		sql = "INSERT OR REPLACE INTO Item (Step_id, filename, type, row_index) VALUES (:step_id, :filename, :type, :row_index)";
	} else {
		sql = "INSERT OR REPLACE INTO Item (Step_id, filename, type, row_index, Item_id) VALUES (:step_id, :filename, :type, :row_index, :item_id)";
	}
	
	/* Create the statment and the SQL query */
	sqlite3_stmt *stmt = NULL;
	int err = sqlite3_prepare_v2(database, sql, -1, &stmt, NULL);
	if (err != SQLITE_OK)
		return NO;
	
	/* Bind the description to the statment */
	int step_bind = sqlite3_bind_parameter_index(stmt, ":step_id");
	err = sqlite3_bind_int(stmt, step_bind, _step.identifier);
	if (err != SQLITE_OK)
		return NO;
	
	/* Bind the name to the statment */
	int filename_bind = sqlite3_bind_parameter_index(stmt, ":filename");
	err = sqlite3_bind_text(stmt, filename_bind, _filename.UTF8String, -1, SQLITE_TRANSIENT); // "-1" to let SQLite to compute the length of the string, SQLITE_TRANSIENT means that the memory of the string is managed by SQLite
	if (err != SQLITE_OK)
		return NO;
	
	/* Bind the type to the statment */
	int type_bind = sqlite3_bind_parameter_index(stmt, ":type");
	err = sqlite3_bind_text(stmt, type_bind, _type.UTF8String, -1, SQLITE_TRANSIENT);
	if (err != SQLITE_OK)
		return NO;
	
	/* Bind the row index to the statment */
	int row_index_bind = sqlite3_bind_parameter_index(stmt, ":row_index");
	err = sqlite3_bind_int(stmt, row_index_bind, _rowIndex);
	if (err != SQLITE_OK)
		return NO;
	
	if (_identifier != -1) {
		/* Bind the item id to the statment */
		int item_id_bind = sqlite3_bind_parameter_index(stmt, ":item_id");
		err = sqlite3_bind_int(stmt, item_id_bind, _identifier);
		if (err != SQLITE_OK)
			return NO;
	}
	
	/* Execute the statment */
	err = sqlite3_step(stmt);
	if (err != SQLITE_DONE)
		return NO;
	
	if (_identifier == -1) {
		/* Get the id of the project (second query) */
		_identifier = (int)sqlite3_last_insert_rowid(database);
	}
	
	/* Free the lock */
	sqlite3_mutex_leave(mutex);
	
	return YES;
}

- (void)updateRowIndex:(int)rowIndex
{
	// @TODO: test this method
	/*
	 * On INSERT and DELETE, triggers will fix index to next rows but theses triggers use UPDATE on "Item" so it's not possible to use trigger for UPDATE on "Item",
	 *	after removing the item, we need to fix index to next rows (with "row_index" superior to "self.rowIndex") and then increment indexes to all next rows (with "row_index" >= "rowIndex").
	 */
	
	if (_step.project.library.database) {
		/* Prepare and execute the first request that fix indexes to all next rows (decrement rows index) */
		sqlite3_stmt * stmt = NULL;
		const char sql[] = "UPDATE item SET row_index = (row_index - 1) WHERE (Step_id == :step_id AND row_index > :row_index)";
		int err = sqlite3_prepare_v2(_step.project.library.database, sql, -1, &stmt, NULL);
		NSAssert((err == SQLITE_OK), @"\"sqlite3_prepare_v2\" did fail with error: %d", err);
		
		int step_id_bind = sqlite3_bind_parameter_index(stmt, ":step_id");
		err = sqlite3_bind_int(stmt, step_id_bind, _step.identifier);
		NSAssert((err == SQLITE_OK), @"\"sqlite3_bind_int\" did fail with error: %d", err);
		
		int row_index_bind = sqlite3_bind_parameter_index(stmt, ":row_index");
		err = sqlite3_bind_int(stmt, row_index_bind, self.rowIndex);
		NSAssert((err == SQLITE_OK), @"\"sqlite3_bind_int\" did fail with error: %d", err);
		
		if (sqlite3_step(stmt) != SQLITE_DONE) {
			NSAssert(false, @"\"sqlite3_step\" did fail with error: %d", err);
			NSLog(@"error on updateRowIndex resquest: %s", sql);
		}
		
		/* destroy and release the statement */
		sqlite3_finalize(stmt);
		stmt = NULL;
		
		self.rowIndex = rowIndex;
		
		/* Prepare and execute the second request that fix indexes to all next rows (increment rows index) */
		const char sql2[] = "UPDATE item SET row_index = (row_index + 1) WHERE (Step_id == :step_id AND row_index >= :row_index)";
		err = sqlite3_prepare_v2(_step.project.library.database, sql2, -1, &stmt, NULL);
		NSAssert((err == SQLITE_OK), @"\"sqlite3_prepare_v2\" did fail with error: %d", err);
		
		step_id_bind = sqlite3_bind_parameter_index(stmt, ":step_id");
		err = sqlite3_bind_int(stmt, step_id_bind, _step.identifier);
		NSAssert((err == SQLITE_OK), @"\"sqlite3_bind_int\" did fail with error: %d", err);
		
		row_index_bind = sqlite3_bind_parameter_index(stmt, ":row_index");
		err = sqlite3_bind_int(stmt, row_index_bind, self.rowIndex);
		NSAssert((err == SQLITE_OK), @"\"sqlite3_bind_int\" did fail with error: %d", err);
		
		if (sqlite3_step(stmt) != SQLITE_DONE) {
			NSAssert(false, @"\"sqlite3_step\" did fail with error: %d", err);
			NSLog(@"error on updateRowIndex resquest: %s", sql);
		}
		
		/* destroy and release the statement */
		sqlite3_finalize(stmt);
	}
}

- (void)updateDatabaseValue:(id)value forColumnName:(NSString *)name
{
	if (_step.project.library.database) {
		/* create a statement from an SQL string */
		sqlite3_stmt * stmt = NULL;
		NSString * sql = [NSString stringWithFormat:@"UPDATE Item SET %@ = :value WHERE Item_id = :item_id", name];
		int err = sqlite3_prepare_v2(_step.project.library.database, [sql UTF8String], -1, &stmt, NULL);
		NSAssert((err == SQLITE_OK), @"\"sqlite3_prepare_v2\" did fail with error: %d", err);
		
		int value_bind = sqlite3_bind_parameter_index(stmt, ":value");
		
		if ([value isKindOfClass:[NSNumber class]]) {
			err = sqlite3_bind_int(stmt, value_bind, [value intValue]);
		} else if (value == nil) {
			err = sqlite3_bind_null(stmt, value_bind);
		} else {
			err = sqlite3_bind_text(stmt, value_bind, [[value description] UTF8String], -1, SQLITE_TRANSIENT);
		}
		
		NSAssert((err == SQLITE_OK), @"\"sqlite3_bind_*\" did fail with error: %d", err);
		
		int item_id_bind = sqlite3_bind_parameter_index(stmt, ":item_id");
		err = sqlite3_bind_int(stmt, item_id_bind, self.identifier);
		NSAssert((err == SQLITE_OK), @"\"sqlite3_bind_int\" did fail with error %d when inserting %d", err, self.identifier);
		
		if (sqlite3_step(stmt) != SQLITE_DONE) {
			NSAssert(false, @"\"sqlite3_step\" did fail with error: %d", err);
			NSLog(@"error on update resquest: %@", sql);
		}
		
		/* destroy and release the statement */
		sqlite3_finalize(stmt);
	}
}

- (void)updateValue:(id)value forKey:(NSString *)key
{
	[self willChangeValueForKey:key];
	[self setValue:value forKey:key];
	[self didChangeValueForKey:key];
	
	[self updateDatabaseValue:value forColumnName:key];
}

- (BOOL)moveToStep:(Step *)destinationStep
{
	[self updateDatabaseValue:@(destinationStep.identifier) forColumnName:@"Step_id"];

	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	NSString * key = [NSString stringWithFormat:@"%i/%i/%i", _step.project.identifier, _step.identifier, _identifier];
	NSData * bookmarkData = [userDefaults dataForKey:key];
	
	if (self.filename) { // Copied or moved item, move it to new step folder
		
		NSString * path = [NSString stringWithFormat:@"%@/%@", [self.library pathForStepFolder:_step], self.filename];
		NSString * newPath = [NSString stringWithFormat:@"%@/%@", [self.library pathForStepFolder:destinationStep], self.filename];
		BOOL success = [[NSFileManager defaultManager] moveItemAtPath:path toPath:newPath error:NULL];
		if (!success)
			return NO;
		
		// Update bookmark data
		NSUInteger bookmarkOptions = 0;
#if _SANDBOX_SUPPORTED_
		bookmarkOptions = NSURLBookmarkCreationWithSecurityScope;
#endif
		bookmarkData = [[NSURL fileURLWithPath:newPath] bookmarkDataWithOptions:bookmarkOptions
												 includingResourceValuesForKeys:nil
																  relativeToURL:nil
																		  error:NULL];
	}
	
	_step = destinationStep;
	
	if (bookmarkData) { // Save new bookmark data
		NSString * newkey = [NSString stringWithFormat:@"%i/%i/%i", _step.project.identifier, _step.identifier, _identifier];
		[userDefaults setObject:bookmarkData forKey:newkey];
		[userDefaults removeObjectForKey:key];
	}
	
	return YES;
}

- (BOOL)delete
{
	// Create a statement from an SQL string
	sqlite3_stmt * stmt = NULL;
	const char sql[] = "DELETE FROM Item WHERE (Item_id = :item_id)";
	int err = sqlite3_prepare_v2(_step.project.library.database, sql, -1, &stmt, NULL);
	if (err != SQLITE_OK) {
		NSAssert(false, @"\"sqlite3_prepare_v2\" did fail with error: %d", err);
		return NO;
	}
	
	int item_id_bind = sqlite3_bind_parameter_index(stmt, ":item_id");
	err = sqlite3_bind_int(stmt, item_id_bind, self.identifier);
	if (err != SQLITE_OK) {
		NSAssert(false, @"\"sqlite3_bind_int\" did fail with error: %d", err);
		return NO;
	}
	
	if (sqlite3_step(stmt) != SQLITE_DONE) {
		NSAssert(false, @"\"sqlite3_step\" did fail with error: %d", err);
		NSLog(@"error on update request: %s", sql);
		return NO;
	}
	
	// Destroy and release the statement
	sqlite3_finalize(stmt);
	
	return YES;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<Item: 0x%x name=\"%@\", type=\"%@\" id=%i library=%@>", (unsigned int)self, _filename, _type, _identifier, _library];
}

@end
