//
//  Step.m
//  Tea Box
//
//  Created by Max on 03/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "Step.h"

#import "Project.h"
#import "Item.h"

@interface Step ()
{
	BOOL hasChanged;
}
@end

@implementation Step

@synthesize name = _name;
@synthesize description = _description;
@synthesize closed = _closed;
@synthesize project = _project;
@synthesize library = _library;
@synthesize identifier = _identifier;

+ (NSArray *)stepsWithProjectIdentifier:(int)projectID fromLibrary:(TBLibrary *)library
{
	NSMutableArray * steps = [NSMutableArray arrayWithCapacity:10];
	Project * project = [Project projectWithIdentifier:projectID fromLibrary:library];
	
	/* create a statement from an SQL string */
	sqlite3_stmt * stmt = NULL;
	const char sql[] = "SELECT name, description, closed, Step_id FROM Step WHERE Project_id = :project_id ORDER BY Project_id ASC";
	int err = sqlite3_prepare_v2(library.database, sql, -1, &stmt, NULL);
	if (err != SQLITE_OK)
		return nil;
	
	int project_id_bind = sqlite3_bind_parameter_index(stmt, ":project_id");
	err = sqlite3_bind_int(stmt, project_id_bind, projectID);
	if (err != SQLITE_OK)
		return nil;
	
	/* execute statement and step over each row of the result set */ 
	while (sqlite3_step(stmt) == SQLITE_ROW)
	{
		NSString * name = nil;
		const char * name_ptr = (const char *)sqlite3_column_text(stmt, 0); // "name"
		if (name_ptr)
			name = @(name_ptr);
		
		NSString * description = nil;
		const char * description_ptr = (const char *)sqlite3_column_text(stmt, 1); // "description"
		if (description_ptr)
			description = @(description_ptr);
		
		BOOL closed = (sqlite3_column_int(stmt, 2 /* "closed" */) != 0);
		int identifier = sqlite3_column_int(stmt, 3 /* "Step_id" */);
		Step * step = [[Step alloc] initWithName:name description:description closed:closed identifier:identifier project:project];
		step.library = library;
		
		[steps addObject:step];
	}
	
	/* destroy and release the statement */ 
	sqlite3_finalize(stmt);
	
	return steps;
}

+ (Step *)stepWithIdentifier:(int)identifier fromLibrary:(TBLibrary *)library
{
	/* create a statement from an SQL string */
	sqlite3_stmt * stmt = NULL;
	const char sql[] = "SELECT name, description, closed, Project_id FROM Step WHERE Step_id = :step_id ORDER BY Step_id ASC LIMIT 1";
	int err = sqlite3_prepare_v2(library.database, sql, -1, &stmt, NULL);
	if (err != SQLITE_OK)
		return nil;
	
	int step_id_bind = sqlite3_bind_parameter_index(stmt, ":step_id");
	err = sqlite3_bind_int(stmt, step_id_bind, identifier);
	if (err != SQLITE_OK)
		return nil;
	
	Step * step = nil;
	/* execute statement and step over each row of the result set */ 
	if (sqlite3_step(stmt) == SQLITE_ROW) {
		NSString * name = nil;
		const char * name_ptr = (const char *)sqlite3_column_text(stmt, 0); // "name"
		if (name_ptr)
			name = @(name_ptr);
		
		NSString * description = nil;
		const char * description_ptr = (const char *)sqlite3_column_text(stmt, 1); // "description"
		if (description_ptr)
			description = @(description_ptr);
		
		int projectID = sqlite3_column_int(stmt, 3 /* "Project_id" */);
		Project * project = [Project projectWithIdentifier:projectID fromLibrary:library];
		
		BOOL closed = (sqlite3_column_int(stmt, 2 /* "closed" */) != 0);
		step = [[Step alloc] initWithName:name description:description closed:closed identifier:identifier project:project];
		step.library = library;
	}
	
	/* destroy and release the statement */ 
	sqlite3_finalize(stmt);
	
	return step;
}

- (instancetype)initWithName:(NSString *)name description:(NSString *)description project:(Project *)project
{
	return [self initWithName:name description:description closed:NO identifier:-1 project:project];
}

- (instancetype)initWithName:(NSString *)name description:(NSString *)description closed:(BOOL)closed identifier:(int)identifier project:(Project *)project
{
	if ((self = [super init])) {
		_identifier = identifier;
		self.name = name;
		self.description = description;
		self.closed = closed;
		self.project = project;
	}
	
	return self;
}

- (BOOL)insertIntoLibrary:(TBLibrary *)library
{
	return [self insertIntoLibrary:library error:nil];
}

- (BOOL)insertIntoLibrary:(TBLibrary *)library error:(NSError **)errorPtr
{
	NSParameterAssert(library);
	
	self.library = library;
	
	sqlite3 * database = library.database;
	
	/* Create a lock when sending the 2 queries */
	sqlite3_mutex * mutex = sqlite3_db_mutex(database);
	sqlite3_mutex_enter(mutex);
	
	/* Create the SQL query */
	char * sql = NULL;
	if (_identifier == -1) {// If no "identifier", let SQLite generate one
		sql = "INSERT OR REPLACE INTO Step (Project_id, name, closed, description) VALUES (:project_id, :name, :closed, :description)";
	} else {
		sql = "INSERT OR REPLACE INTO Step (Project_id, name, closed, description, Step_id) VALUES (:project_id, :name, :closed, :description, :step_id)";
	}
	
	/* Create the statment */
	sqlite3_stmt *stmt = NULL;
	int err = sqlite3_prepare_v2(database, sql, -1, &stmt, NULL);
	if (err != SQLITE_OK) {
		AssertOrSetError(false, @"\"sqlite3_prepare_v2\" did fail with error: %d", errorPtr, @"Error with code: %d", err);
		return NO;
	}
	
	/* Bind the project id to the statment */
	int priority_bind = sqlite3_bind_parameter_index(stmt, ":project_id");
	err = sqlite3_bind_int(stmt, priority_bind, _project.identifier);
	if (err != SQLITE_OK) {
		AssertOrSetError(false, @"\"sqlite3_bind_int\" did fail with error: %d", errorPtr, @"Error with code: %d", err);
		return NO;
	}
	
	/* Bind the name to the statment */
	int name_bind = sqlite3_bind_parameter_index(stmt, ":name");
	err = sqlite3_bind_text(stmt, name_bind, _name.UTF8String, -1, SQLITE_TRANSIENT); // "-1" to let SQLite to compute the length of the string, SQLITE_TRANSIENT means that the memory of the string is managed by SQLite
	if (err != SQLITE_OK) {
		AssertOrSetError(false, @"\"sqlite3_bind_text\" did fail with error: %d", errorPtr, @"Error with code: %d", err);
		return NO;
	}
	
	/* Bind the description to the statment */
	int description_bind = sqlite3_bind_parameter_index(stmt, ":description");
	err = sqlite3_bind_text(stmt, description_bind, _description.UTF8String, -1, SQLITE_TRANSIENT);
	if (err != SQLITE_OK) {
		AssertOrSetError(false, @"\"sqlite3_bind_text\" did fail with error: %d", errorPtr, @"Error with code: %d", err);
		return NO;
	}
	
	/* Bind the closed state to the statment */
	int closed_id_bind = sqlite3_bind_parameter_index(stmt, ":closed");
	err = sqlite3_bind_int(stmt, closed_id_bind, (int)_closed);
	if (err != SQLITE_OK) {
		AssertOrSetError(false, @"\"sqlite3_bind_int\" did fail with error: %d", errorPtr, @"Error with code: %d", err);
		return NO;
	}
	
	if (_identifier != -1) {
		/* Bind the Step_id to the statment */
		int step_id_bind = sqlite3_bind_parameter_index(stmt, ":step_id");
		err = sqlite3_bind_int(stmt, step_id_bind, _identifier);
		if (err != SQLITE_OK) {
			AssertOrSetError(false, @"\"sqlite3_bind_int\" did fail with error: %d", errorPtr, @"Error with code: %d", err);
			return NO;
		}
	}
	
	/* Execute the statment */
	err = sqlite3_step(stmt);
	if (err != SQLITE_DONE) {
		AssertOrSetError(false, @"\"sqlite3_step\" did fail with error: %d", errorPtr, @"Error with code: %d", err);
		return NO;
	}
	
	if (_identifier == -1) {
		/* Get the id of the project (second query) */
		_identifier = (int)sqlite3_last_insert_rowid(database);
	}
	
	/* Free the lock */
	sqlite3_mutex_leave(mutex);
	
	return YES;
}

- (void)updateDatabaseValue:(id)value forColumnName:(NSString *)name
{
	if (_project.library.database) {
		hasChanged = YES;
		
		/* create a statement from an SQL string */
		sqlite3_stmt * stmt = NULL;
		NSString * sql = [NSString stringWithFormat:@"UPDATE Step SET %@ = :value WHERE Step_id = :step_id", name];
		int err = sqlite3_prepare_v2(_project.library.database, sql.UTF8String, -1, &stmt, NULL);
		if (err != SQLITE_OK)
			return ;
		
		int value_bind = sqlite3_bind_parameter_index(stmt, ":value");
		
		if ([value isKindOfClass:[NSNumber class]]) {
			err = sqlite3_bind_int(stmt, value_bind, [value intValue]);
		} else if (value == nil) {
			err = sqlite3_bind_null(stmt, value_bind);
		} else {
			err = sqlite3_bind_text(stmt, value_bind, [value description].UTF8String, -1, SQLITE_TRANSIENT);
		}
		
		if (err != SQLITE_OK)
			return ;
		
		int step_id_bind = sqlite3_bind_parameter_index(stmt, ":step_id");
		err = sqlite3_bind_int(stmt, step_id_bind, self.identifier);
		if (err != SQLITE_OK)
			return ;
		
		if (sqlite3_step(stmt) != SQLITE_DONE) {
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

- (void)update
{
	if (!hasChanged) {
		NSLog(@"No changes into %@", self);
		return ;
	}
	
	/* create a statement from an SQL string */
	sqlite3_stmt * stmt = NULL;
	const char sql[] = "UPDATE Step SET name = :name, description = :description, closed = :closed WHERE Step_id = :step_id";
	int err = sqlite3_prepare_v2(_project.library.database, sql, -1, &stmt, NULL);
	if (err != SQLITE_OK) {
		NSAssert(false, @"\"sqlite3_prepare_v2\" did fail with error: %d", err);
		return ;
	}
	
	int name_bind = sqlite3_bind_parameter_index(stmt, ":name");
	err = sqlite3_bind_text(stmt, name_bind, self.name.UTF8String, -1, SQLITE_TRANSIENT);
	if (err != SQLITE_OK) {
		NSAssert(false, @"\"sqlite3_bind_text\" did fail with error: %d", err);
		return ;
	}
	
	int description_bind = sqlite3_bind_parameter_index(stmt, ":description");
	err = sqlite3_bind_text(stmt, description_bind, self.description.UTF8String, -1, SQLITE_TRANSIENT);
	if (err != SQLITE_OK) {
		NSAssert(false, @"\"sqlite3_bind_text\" did fail with error: %d", err);
		return ;
	}
	
	int closed_bind = sqlite3_bind_parameter_index(stmt, ":closed");
	err = sqlite3_bind_int(stmt, closed_bind, (int)self.closed);
	if (err != SQLITE_OK) {
		NSAssert(false, @"\"sqlite3_bind_int\" did fail with error: %d", err);
		return ;
	}
	
	int step_id_bind = sqlite3_bind_parameter_index(stmt, ":step_id");
	err = sqlite3_bind_int(stmt, step_id_bind, self.identifier);
	if (err != SQLITE_OK) {
		NSAssert(false, @"\"sqlite3_bind_int\" did fail with error: %d", err);
		return ;
	}
	
	if (sqlite3_step(stmt) != SQLITE_DONE) {
		NSLog(@"error on update resquest: %s", sql);
	}
	
	/* destroy and release the statement */ 
	sqlite3_finalize(stmt);
}

- (NSUInteger)itemsCount
{
	/* create a statement from an SQL string */
	sqlite3_stmt * stmt = NULL;
	const char sql[] = "SELECT Item_id FROM Item WHERE Step_id = :step_id";
	int err = sqlite3_prepare_v2([TBLibrary defaultLibrary].database, sql, -1, &stmt, NULL);
	if (err != SQLITE_OK)
		return 0;
	
	int step_id_bind = sqlite3_bind_parameter_index(stmt, ":step_id");
	err = sqlite3_bind_int(stmt, step_id_bind, self.identifier);
	if (err != SQLITE_OK)
		return 0;
	
	// Execute statement and step over each row of the result set
	NSUInteger count = 0;
	while (sqlite3_step(stmt) == SQLITE_ROW) { ++count; }
	
	/* destroy and release the statement */
	sqlite3_finalize(stmt);
	
	return count;
}

- (NSArray *)items
{
	NSMutableArray * items = [NSMutableArray arrayWithCapacity:5];
	
	/* create a statement from an SQL string */
	sqlite3_stmt * stmt = NULL;
	const char sql[] = "SELECT filename, type, Item_id, row_index FROM Item WHERE Step_id = :step_id ORDER BY row_index ASC";
	int err = sqlite3_prepare_v2([TBLibrary defaultLibrary].database, sql, -1, &stmt, NULL);
	if (err != SQLITE_OK)
		return nil;
	
	int step_id_bind = sqlite3_bind_parameter_index(stmt, ":step_id");
	err = sqlite3_bind_int(stmt, step_id_bind, self.identifier);
	if (err != SQLITE_OK)
		return nil;
	
	// Execute statement and step over each row of the result set
	while (sqlite3_step(stmt) == SQLITE_ROW) {
		
		NSString * filename = nil;
		const char * filename_ptr = (const char *)sqlite3_column_text(stmt, 0 /* "filename" */);
		if (filename_ptr)
			filename = @(filename_ptr);
		
		const char * type_ptr = (const char *)sqlite3_column_text(stmt, 1 /* "type" */);
		NSString * type = @(type_ptr);
		
		int rowIndex = (int)sqlite3_column_int(stmt, 3 /* "row_index" */);
		
		int identifier = sqlite3_column_int(stmt, 2 /* "Item_id" */);
		Item * item = [[Item alloc] initWithFilename:filename type:type rowIndex:rowIndex identifier:identifier step:self];
		item.library = self.library;
		[items addObject:item];
	}
	
	/* destroy and release the statement */ 
	sqlite3_finalize(stmt);
	
	return items;
}

- (BOOL)delete
{
	/* create a statement from an SQL string */
	sqlite3_stmt * stmt = NULL;
	const char sql[] = "DELETE FROM Step WHERE (Step_id = :step_id)";
	int err = sqlite3_prepare_v2(_project.library.database, sql, -1, &stmt, NULL);
	if (err != SQLITE_OK)
		return NO;
	
	int step_id_bind = sqlite3_bind_parameter_index(stmt, ":step_id");
	err = sqlite3_bind_int(stmt, step_id_bind, self.identifier);
	if (err != SQLITE_OK)
		return NO;
	
	if (sqlite3_step(stmt) != SQLITE_DONE) {
		NSLog(@"error on update resquest: %s", sql);
		return NO;
	}
	
	/* destroy and release the statement */
	sqlite3_finalize(stmt);
	
	return YES;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<Step: 0x%x name=\"%@\", description=\"%@\" id=%i library=%@>", (unsigned int)self, _name, _description, _identifier, _library];
}

@end
