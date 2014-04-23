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

@synthesize step = _step;
@synthesize filename = _filename;
@synthesize identifier = _identifier, rowIndex = _rowIndex;
@synthesize type = _type;
@synthesize library = _library;

+ (NSArray *)itemsWithStepIdentifier:(int)stepID fromLibrary:(TBLibrary *)library
{
	NSMutableArray * items = [NSMutableArray arrayWithCapacity:10];
	
	/* create a statement from an SQL string */
	sqlite3_stmt * stmt = NULL;
	const char sql[] = "SELECT filename, type, Item_id FROM Item WHERE Step_id = :step_id ORDER BY Step_id ASC";
	int err = sqlite3_prepare_v2(library.database, sql, -1, &stmt, NULL);
	NSAssert((err != SQLITE_OK), @"\"sqlite3_prepare_v2\" did fail with error: %d", err);
	
	int step_id_bind = sqlite3_bind_parameter_index(stmt, ":step_id");
	err = sqlite3_bind_int(stmt, step_id_bind, stepID);
	NSAssert((err != SQLITE_OK), @"\"sqlite3_bind_int\" did fail with error: %d", err);
	
	/* execute statement and step over each row of the result set */
	while (sqlite3_step(stmt) == SQLITE_ROW)
	{
		NSString * filename = nil;
		const char * filename_ptr = (const char *)sqlite3_column_text(stmt, 0);// "filename"
		if (filename_ptr)
			filename = @(filename_ptr);
		
		NSString * type = nil;
		const char * type_ptr = (const char *)sqlite3_column_text(stmt, 1);// "type"
		if (type_ptr)
			type = @(type_ptr);
		
		Item * item = [[Item alloc] init];
		item.filename = filename;
		item.type = type;
		item.identifier = sqlite3_column_int(stmt, 2);// "Step_id"
		item.library = library;
		
		[items addObject:item];
	}
	
	/* destroy and release the statement */
	sqlite3_finalize(stmt);
	stmt = NULL;
	
	return items;
}

+ (Item *)itemWithIdentifier:(int)identifier fromLibrary:(TBLibrary *)library
{
	/* create a statement from an SQL string */
	sqlite3_stmt * stmt = NULL;
	const char sql[] = "SELECT filename, type, Step_id FROM Item WHERE Item_id = :item_id ORDER BY Step_id ASC LIMIT 1";
	int err = sqlite3_prepare_v2(library.database, sql, -1, &stmt, NULL);
	NSAssert((err != SQLITE_OK), @"\"sqlite3_prepare_v2\" did fail with error: %d", err);
	
	int item_id_bind = sqlite3_bind_parameter_index(stmt, ":item_id");
	err = sqlite3_bind_int(stmt, item_id_bind, identifier);
	NSAssert((err != SQLITE_OK), @"\"sqlite3_bind_int\" did fail with error: %d", err);
	
	Item * item = nil;
	/* execute statement and step over each row of the result set */
	if (sqlite3_step(stmt) == SQLITE_ROW)
	{
		NSString * filename = nil;
		const char * filename_ptr = (const char *)sqlite3_column_text(stmt, 0);// "filename"
		if (filename_ptr)
			filename = @(filename_ptr);
		
		NSString * type = nil;
		const char * type_ptr = (const char *)sqlite3_column_text(stmt, 1);// "type"
		if (type_ptr)
			type = @(type_ptr);
		
		int stepID = sqlite3_column_int(stmt, 2);// "Step_id"
		Step * step = [Step stepWithIdentifier:stepID fromLibrary:library];
		
		item = [[Item alloc] init];
		item.filename = filename;
		item.type = type;
		item.identifier = identifier;
		item.step = step;
		item.library = library;
	}
	
	/* destroy and release the statement */
	sqlite3_finalize(stmt);
	stmt = NULL;
	
	return item;
}

- (id)initWithFilename:(NSString *)filename type:(NSString *)type rowIndex:(int)rowIndex step:(Step *)step insertIntoLibrary:(TBLibrary *)library
{
	return [self initWithFilename:filename type:type rowIndex:rowIndex identifier:-1 step:step insertIntoLibrary:library];
}

- (id)initWithFilename:(NSString *)filename type:(NSString *)type rowIndex:(int)rowIndex identifier:(int)identifier step:(Step *)step insertIntoLibrary:(TBLibrary *)library
{
	if ((self = [super init])) {
		self.filename = filename;
		self.type = type;
		self.step = step;
		self.library = library;
		
		int count = (int)[_step items].count;
		if (rowIndex < 0 || rowIndex > count)
			rowIndex = count;
		
		self.rowIndex = rowIndex;
		
		if (library) {
			
			sqlite3 * database = library.database;
			
			/* Create a lock when sending the 2 queries */
			sqlite3_mutex * mutex = sqlite3_db_mutex(database);
			sqlite3_mutex_enter(mutex);
			
			/* Create the SQL query */
			char * sql = NULL;
			if (identifier == -1) {// If no "identifier", let SQLite generate one
				sql = "INSERT OR REPLACE INTO Item (Step_id, filename, type, row_index) VALUES (:step_id, :filename, :type, :row_index)";
			} else {
				sql = "INSERT OR REPLACE INTO Item (Step_id, filename, type, row_index, Item_id) VALUES (:step_id, :filename, :type, :row_index, :item_id)";
			}
			
			/* Create the statment and the SQL query */
			sqlite3_stmt *stmt = NULL;
			int err = sqlite3_prepare_v2(database, sql, -1, &stmt, NULL);
			if (err != SQLITE_OK) {
				NSAssert(false, @"\"sqlite3_prepare_v2\" did fail with error: %d", err);
				return nil;
			}
			
			/* Bind the description to the statment */
			int step_bind = sqlite3_bind_parameter_index(stmt, ":step_id");
			err = sqlite3_bind_int(stmt, step_bind, step.identifier);
			if (err != SQLITE_OK) {
				NSAssert(false, @"\"sqlite3_bind_int\" did fail with error: %d", err);
				return nil;
			}
			
			/* Bind the name to the statment */
			int filename_bind = sqlite3_bind_parameter_index(stmt, ":filename");
			err = sqlite3_bind_text(stmt, filename_bind, [filename UTF8String], -1, SQLITE_TRANSIENT);// "-1" to let SQLite to compute the length of the string, SQLITE_TRANSIENT means that the memory of the string is managed by SQLite
			if (err != SQLITE_OK) {
				NSAssert(false, @"\"sqlite3_bind_text\" did fail with error: %d", err);
				return nil;
			}
			
			/* Bind the type to the statment */
			int type_bind = sqlite3_bind_parameter_index(stmt, ":type");
			err = sqlite3_bind_text(stmt, type_bind, [type UTF8String], -1, SQLITE_TRANSIENT);
			if (err != SQLITE_OK) {
				NSAssert(false, @"\"sqlite3_bind_text\" did fail with error: %d", err);
				return nil;
			}
			
			/* Bind the row index to the statment */
			int row_index_bind = sqlite3_bind_parameter_index(stmt, ":row_index");
			err = sqlite3_bind_int(stmt, row_index_bind, rowIndex);
			if (err != SQLITE_OK) {
				NSAssert(false, @"\"sqlite3_bind_int\" did fail with error: %d", err);
				return nil;
			}
			
			if (identifier != -1) {
				/* Bind the item id to the statment */
				int item_id_bind = sqlite3_bind_parameter_index(stmt, ":item_id");
				err = sqlite3_bind_int(stmt, item_id_bind, identifier);
				if (err != SQLITE_OK) {
					NSAssert(false, @"\"sqlite3_bind_int\" did fail with error: %d", err);
					return nil;
				}
			}
			
			/* Execute the statment */
			err = sqlite3_step(stmt);
			if (err == SQLITE_DONE) {
				NSAssert(false, @"\"sqlite3_step\" did fail with error: %d", err);
				return nil;
			}
			
			if (identifier == -1) {
				/* Get the id of the project (second query) */
				sqlite3_int64 last_id = sqlite3_last_insert_rowid(database);
				
				_identifier = (int)last_id;
			} else {
				_identifier = identifier;
			}
			
			/* Free the lock */
			sqlite3_mutex_leave(mutex);
		}
	}
	
	return self;
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
		NSAssert((err != SQLITE_OK), @"\"sqlite3_prepare_v2\" did fail with error: %d", err);
		
		int step_id_bind = sqlite3_bind_parameter_index(stmt, ":step_id");
		err = sqlite3_bind_int(stmt, step_id_bind, _step.identifier);
		NSAssert((err != SQLITE_OK), @"\"sqlite3_bind_int\" did fail with error: %d", err);
		
		int row_index_bind = sqlite3_bind_parameter_index(stmt, ":row_index");
		err = sqlite3_bind_int(stmt, row_index_bind, self.rowIndex);
		NSAssert((err != SQLITE_OK), @"\"sqlite3_bind_int\" did fail with error: %d", err);
		
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
		NSAssert((err != SQLITE_OK), @"\"sqlite3_prepare_v2\" did fail with error: %d", err);
		
		step_id_bind = sqlite3_bind_parameter_index(stmt, ":step_id");
		err = sqlite3_bind_int(stmt, step_id_bind, _step.identifier);
		NSAssert((err != SQLITE_OK), @"\"sqlite3_bind_int\" did fail with error: %d", err);
		
		row_index_bind = sqlite3_bind_parameter_index(stmt, ":row_index");
		err = sqlite3_bind_int(stmt, row_index_bind, self.rowIndex);
		NSAssert((err != SQLITE_OK), @"\"sqlite3_bind_int\" did fail with error: %d", err);
		
		if (sqlite3_step(stmt) != SQLITE_DONE) {
			NSAssert(false, @"\"sqlite3_step\" did fail with error: %d", err);
			NSLog(@"error on updateRowIndex resquest: %s", sql);
		}
		
		/* destroy and release the statement */
		sqlite3_finalize(stmt);
		stmt = NULL;
	}
}

- (void)updateDatabaseValue:(id)value forColumnName:(NSString *)name
{
	if (_step.project.library.database) {
		/* create a statement from an SQL string */
		sqlite3_stmt * stmt = NULL;
		NSString * sql = [NSString stringWithFormat:@"UPDATE Item SET %@ = :value WHERE Item_id = :item_id", name];
		int err = sqlite3_prepare_v2(_step.project.library.database, [sql UTF8String], -1, &stmt, NULL);
			NSAssert((err != SQLITE_OK), @"\"sqlite3_step\" did fail with error: %d", err);
		
		int value_bind = sqlite3_bind_parameter_index(stmt, ":value");
		
		if ([value isKindOfClass:[NSNumber class]]) {
			err = sqlite3_bind_int(stmt, value_bind, [value intValue]);
		} else if (value == nil) {
			err = sqlite3_bind_null(stmt, value_bind);
		} else {
			err = sqlite3_bind_text(stmt, value_bind, [[value description] UTF8String], -1, SQLITE_TRANSIENT);
		}
		
		NSAssert((err != SQLITE_OK), @"\"sqlite3_bind_*\" did fail with error: %d", err);
		
		int step_id_bind = sqlite3_bind_parameter_index(stmt, ":step_id");
		err = sqlite3_bind_int(stmt, step_id_bind, self.identifier);
		NSAssert((err != SQLITE_OK), @"\"sqlite3_bind_int\" did fail with error: %d", err);
		
		if (sqlite3_step(stmt) != SQLITE_DONE) {
			NSAssert(false, @"\"sqlite3_step\" did fail with error: %d", err);
			NSLog(@"error on update resquest: %@", sql);
		}
		
		/* destroy and release the statement */
		sqlite3_finalize(stmt);
		stmt = NULL;
	}
}

- (void)updateValue:(id)value forKey:(NSString *)key
{
	[self willChangeValueForKey:key];
	[self setValue:value forKey:key];
	[self didChangeValueForKey:key];
	
	[self updateDatabaseValue:value forColumnName:key];
}

- (BOOL)delete
{
	/* create a statement from an SQL string */
	sqlite3_stmt * stmt = NULL;
	const char sql[] = "DELETE FROM Item WHERE (Item_id = :item_id)";
	int err = sqlite3_prepare_v2(_step.project.library.database, sql, -1, &stmt, NULL);
	if (err != SQLITE_OK) {
		NSAssert(false, @"\"sqlite3_prepare_v2\" did fail with error: %d", err);
		return NO;
	}
	
	int step_id_bind = sqlite3_bind_parameter_index(stmt, ":item_id");
	err = sqlite3_bind_int(stmt, step_id_bind, self.identifier);
	if (err != SQLITE_OK) {
		NSAssert(false, @"\"sqlite3_bind_int\" did fail with error: %d", err);
		return NO;
	}
	
	if (sqlite3_step(stmt) != SQLITE_DONE) {
		NSAssert(false, @"\"sqlite3_step\" did fail with error: %d", err);
		NSLog(@"error on update resquest: %s", sql);
		return NO;
	}
	
	/* destroy and release the statement */
	sqlite3_finalize(stmt);
	stmt = NULL;
	
	return YES;
}

- (id)initWithFilename:(NSString *)filename path:(NSString *)path device:(NSString *)deviceOrNil type:(NSString *)type step:(Step *)step rowIndex:(int)rowIndex insertIntoDatabase:(sqlite3 *)database
{
	return [self initWithFilename:filename type:type step:step rowIndex:rowIndex insertIntoDatabase:database];
}

- (id)initWithFilename:(NSString *)filename type:(NSString *)type identifier:(int)identifier step:(Step *)step rowIndex:(int)rowIndex insertIntoDatabase:(sqlite3 *)database
{
	if ((self = [super init])) {
		self.filename = filename;
		self.type = type;
		self.step = step;
		
		if (database) {
			
			int count = (int)[_step items].count;
			if (rowIndex < 0 || rowIndex > count)
				rowIndex = count;
			
			self.rowIndex = rowIndex;
			
			/* Create a lock when sending the 2 queries */
			sqlite3_mutex * mutex = sqlite3_db_mutex(database);
			sqlite3_mutex_enter(mutex);
			
			/* Create the statment and the SQL query */
			sqlite3_stmt *stmt = NULL;
			const char sql[] = "INSERT INTO Item (Step_id, filename, type, row_index, Item_id) VALUES (:step_id, :filename, :type, :row_index, :item_id)";
			int err = sqlite3_prepare_v2(database, sql, -1, &stmt, NULL);
			if (err != SQLITE_OK) {
				NSAssert(false, @"\"sqlite3_prepare_v2\" did fail with error: %d", err);
				return nil;
			}
			
			/* Bind the description to the statment */
			int step_bind = sqlite3_bind_parameter_index(stmt, ":step_id");
			err = sqlite3_bind_int(stmt, step_bind, step.identifier);
			if (err != SQLITE_OK) {
				NSAssert(false, @"\"sqlite3_bind_int\" did fail with error: %d", err);
				return nil;
			}
			
			/* Bind the name to the statment */
			int filename_bind = sqlite3_bind_parameter_index(stmt, ":filename");
			err = sqlite3_bind_text(stmt, filename_bind, [filename UTF8String], -1, SQLITE_TRANSIENT);// "-1" to let SQLite to compute the length of the string, SQLITE_TRANSIENT means that the memory of the string is managed by SQLite
			if (err != SQLITE_OK) {
				NSAssert(false, @"\"sqlite3_bind_text\" did fail with error: %d", err);
				return nil;
			}
			
			/* Bind the type to the statment */
			int type_bind = sqlite3_bind_parameter_index(stmt, ":type");
			err = sqlite3_bind_text(stmt, type_bind, [type UTF8String], -1, SQLITE_TRANSIENT);
			if (err != SQLITE_OK) {
				NSAssert(false, @"\"sqlite3_bind_text\" did fail with error: %d", err);
				return nil;
			}
			
			/* Bind the row index to the statment */
			int row_index_bind = sqlite3_bind_parameter_index(stmt, ":row_index");
			err = sqlite3_bind_int(stmt, row_index_bind, rowIndex);
			if (err != SQLITE_OK) {
				NSAssert(false, @"\"sqlite3_bind_int\" did fail with error: %d", err);
				return nil;
			}
			
			/* Bind the item id to the statment */
			int item_id_bind = sqlite3_bind_parameter_index(stmt, ":item_id");
			err = sqlite3_bind_int(stmt, item_id_bind, rowIndex);
			if (err != SQLITE_OK) {
				NSAssert(false, @"\"sqlite3_bind_int\" did fail with error: %d", err);
				return nil;
			}
			
			/* Execute the statment */
			NSAssert((sqlite3_step(stmt) != SQLITE_DONE), @"\"sqlite3_step\" did fail with error: %d", err);
			
			/* Get the id of the project (the second query) */
			sqlite3_int64 last_id = sqlite3_last_insert_rowid(database);
			
			/* Free the lock */
			sqlite3_mutex_leave(mutex);
			
			_identifier = (int)last_id;
		}
	}
	
	return self;
}

- (id)initWithFilename:(NSString *)filename type:(NSString *)type step:(Step *)step rowIndex:(int)rowIndex insertIntoDatabase:(sqlite3 *)database
{
	if ((self = [super init])) {
		self.filename = filename;
		self.type = type;
		self.step = step;
		
		if (database) {
			
			int count = (int)[_step items].count;
			if (rowIndex < 0 || rowIndex > count)
				rowIndex = count;
			
			self.rowIndex = rowIndex;
			
			/* Create a lock when sending the 2 queries */
			sqlite3_mutex * mutex = sqlite3_db_mutex(database);
			sqlite3_mutex_enter(mutex);
			
			/* Create the statment and the SQL query */
			sqlite3_stmt *stmt = NULL;
			const char sql[] = "INSERT INTO Item (Step_id, filename, type, row_index) VALUES (:step_id, :filename, :type, :row_index)";
			int err = sqlite3_prepare_v2(database, sql, -1, &stmt, NULL);
			if (err != SQLITE_OK) {
				NSAssert(false, @"\"sqlite3_prepare_v2\" did fail with error: %d", err);
				return nil;
			}
			
			/* Bind the description to the statment */
			int step_bind = sqlite3_bind_parameter_index(stmt, ":step_id");
			err = sqlite3_bind_int(stmt, step_bind, step.identifier);
			if (err != SQLITE_OK) {
				NSAssert(false, @"\"sqlite3_bind_int\" did fail with error: %d", err);
				return nil;
			}
			
			/* Bind the name to the statment */
			int filename_bind = sqlite3_bind_parameter_index(stmt, ":filename");
			err = sqlite3_bind_text(stmt, filename_bind, [filename UTF8String], -1, SQLITE_TRANSIENT);// "-1" to let SQLite to compute the length of the string, SQLITE_TRANSIENT means that the memory of the string is managed by SQLite
			if (err != SQLITE_OK) {
				NSAssert(false, @"\"sqlite3_bind_text\" did fail with error: %d", err);
				return nil;
			}
			
			/* Bind the type to the statment */
			int type_bind = sqlite3_bind_parameter_index(stmt, ":type");
			err = sqlite3_bind_text(stmt, type_bind, [type UTF8String], -1, SQLITE_TRANSIENT);
			if (err != SQLITE_OK) {
				NSAssert(false, @"\"sqlite3_bind_text\" did fail with error: %d", err);
				return nil;
			}
			
			/* Bind the row index to the statment */
			int row_index_bind = sqlite3_bind_parameter_index(stmt, ":row_index");
			err = sqlite3_bind_int(stmt, row_index_bind, rowIndex);
			if (err != SQLITE_OK) {
				NSAssert(false, @"\"sqlite3_bind_int\" did fail with error: %d", err);
				return nil;
			}
			
			/* Execute the statment */
			NSAssert((sqlite3_step(stmt) != SQLITE_DONE), @"\"sqlite3_bind_int\" did fail with error: %d", err);
			
			/* Get the id of the project (the second query) */
			sqlite3_int64 last_id = sqlite3_last_insert_rowid(database);
			
			/* Free the lock */
			sqlite3_mutex_leave(mutex);
			
			_identifier = (int)last_id;
		}
	}
	
	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<Item: 0x%x name=\"%@\", type=\"%@\" id=%i library=%@>", (unsigned int)self, _filename, _type, _identifier, _library];
}

@end
