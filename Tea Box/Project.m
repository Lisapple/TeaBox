//
//  Project.m
//  Tea Box
//
//  Created by Max on 03/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "Project.h"

#import "Step.h"

#import "NSDate+additions.h"

@implementation Project

@synthesize name= _name;
@synthesize description = _description;
@synthesize indexPath = _indexPath;
@synthesize creationDate = _creationDate, lastModificationDate = _lastModificationDate;
@synthesize library = _library;
@synthesize priority = _priority;

@synthesize identifier = _identifier;

+ (NSArray *)allProjectsFromLibrary:(TBLibrary *)library
{
	// @TODO: cache this value and remove the cache at every changement into the database
	NSMutableArray * projects = [NSMutableArray arrayWithCapacity:10];
	
	/* create a statement from an SQL string */
	sqlite3_stmt * stmt = NULL;
	sqlite3 * db = library.database;
	const char sql[] = "SELECT name, description, priority, creation_date, last_modification_date, index_path, Project_id FROM Project ORDER BY priority, Project_id ASC";
	int err = sqlite3_prepare_v2(db, sql, -1, &stmt, NULL);
	if (err != SQLITE_OK) {
		NSAssert(false, @"\"sqlite3_prepare_v2\" did fail with error: %d", err);
		return nil;
	}
	
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
		
		
		Project * project = [[Project alloc] initWithCreationDate:[NSDate dateFromSQLiteDate:creationDateString]];
		project.name = name;
		project.description = description;
		project.priority = priority;
		project.lastModificationDate = [NSDate dateFromSQLiteDate:lastModificationDateString];
		project.indexPath = indexPath;
		project.library = library;
		project.identifier = (int)sqlite3_column_int(stmt, 6); // "Project_id"
		
		[projects addObject:project];
	}
	
	/* destroy and release the statement */ 
	sqlite3_finalize(stmt);
	
	return projects;
}

+ (Project *)projectWithIdentifier:(int)identifier fromLibrary:(TBLibrary *)library
{
	/* create a statement from an SQL string */
	sqlite3_stmt * stmt = NULL;
	const char sql[] = "SELECT name, description, priority, creation_date, last_modification_date, index_path FROM Project WHERE Project_id = :project_id LIMIT 1";
	int err = sqlite3_prepare_v2(library.database, sql, -1, &stmt, NULL);
	if (err != SQLITE_OK) {
		NSAssert(false, @"\"sqlite3_prepare_v2\" did fail with error: %d", err);
		return nil;
	}
	
	int project_id_bind = sqlite3_bind_parameter_index(stmt, ":project_id");
	err = sqlite3_bind_int(stmt, project_id_bind, identifier);
	if (err != SQLITE_OK) {
		NSAssert(false, @"\"sqlite3_bind_int\" did fail with error: %d", err);
		return nil;
	}
	
	Project * project = nil;
	/* execute statement and step over each row of the result set */ 
	if (sqlite3_step(stmt) == SQLITE_ROW)
	{
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
		
		project = [[Project alloc] initWithCreationDate:[NSDate dateFromSQLiteDate:creationDateString]];
		project.name = name;
		project.description = description;
		project.priority = priority;
		project.lastModificationDate = [NSDate dateFromSQLiteDate:lastModificationDateString];
		project.indexPath = indexPath;
		project.library = library;
		project.identifier = identifier;
	}
	
	/* destroy and release the statement */ 
	sqlite3_finalize(stmt);
	
	return project;
}

- (instancetype)initWithCreationDate:(NSDate *)creationDate
{
	if ((self = [super init])) {
		_creationDate = creationDate;
	}
	
	return self;
}

- (instancetype)initWithName:(NSString *)name description:(NSString *)description priority:(int)priority identifier:(int)identifier
{
	if ((self = [super init])) {
		self.identifier = identifier;
		self.name = name;
		self.description = description;
		self.priority = priority;
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
	const char * sql = NULL;
	if (_identifier == -1) {// If no "projectID", let SQLite generate one
		const char _sql[] = "INSERT OR REPLACE INTO Project (name, description, priority) VALUES (:name, :description, :priority)";
		sql = _sql;
	} else {
		const char _sql[] = "INSERT OR REPLACE INTO Project (name, description, priority, Project_id) VALUES (:name, :description, :priority, :projectID)";
		sql = _sql;
	}
	
	/* Create the statment */
	sqlite3_stmt *stmt = NULL;
	int err = sqlite3_prepare_v2(database, sql, -1, &stmt, NULL);
	if (err != SQLITE_OK)
		return NO;
	
	/* Bind the name to the statment */
	int name_bind = sqlite3_bind_parameter_index(stmt, ":name");
	err = sqlite3_bind_text(stmt, name_bind, _name.UTF8String, -1, SQLITE_TRANSIENT); // "-1" to let SQLite to compute the length of the string
	if (err != SQLITE_OK)
		return NO;
	
	/* Bind the description to the statment */
	int description_bind = sqlite3_bind_parameter_index(stmt, ":description");
	err = sqlite3_bind_text(stmt, description_bind, _description.UTF8String, -1, SQLITE_TRANSIENT);
	if (err != SQLITE_OK)
		return NO;
	
	/* Bind the priority to the statment */
	int priority_bind = sqlite3_bind_parameter_index(stmt, ":priority");
	err = sqlite3_bind_int(stmt, priority_bind, _priority);
	if (err != SQLITE_OK)
		return NO;
	
	if (_identifier != -1) {
		/* Bind the project_id to the statment */
		int project_id_bind = sqlite3_bind_parameter_index(stmt, ":projectID");
		err = sqlite3_bind_int(stmt, project_id_bind, _identifier);
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

- (void)updateDatabaseValue:(id)value forColumnName:(NSString *)name
{
	sqlite3 * database = _library.database;
	if (database) {
		/* create a statement from an SQL string */
		sqlite3_stmt * stmt = NULL;
		NSString * sql = [NSString stringWithFormat:@"UPDATE Project SET %@ = :value, last_modification_date = datetime() WHERE Project_id = :project_id", name];
		int err = sqlite3_prepare_v2(database, [sql UTF8String], -1, &stmt, NULL);
		if (err != SQLITE_OK)
			return ;
		
		int value_bind = sqlite3_bind_parameter_index(stmt, ":value");
		
		if ([value isKindOfClass:[NSNumber class]]) {
			err = sqlite3_bind_int(stmt, value_bind, [value intValue]);
		} else if (value == nil) {
			err = sqlite3_bind_null(stmt, value_bind);
		} else {
			err = sqlite3_bind_text(stmt, value_bind, [[value description] UTF8String], -1, SQLITE_TRANSIENT);
		}
		
		if (err != SQLITE_OK)
			return ;
		
		int project_id_bind = sqlite3_bind_parameter_index(stmt, ":project_id");
		err = sqlite3_bind_int(stmt, project_id_bind, self.identifier);
		if (err != SQLITE_OK)
			return ;
		
		if (sqlite3_step(stmt) != SQLITE_DONE) {
			NSAssert(false, @"\"sqlite3_step\" did fail with error: %d", err);
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
	
	if ([key isEqualToString:@"indexPath"]) {
		[self updateDatabaseValue:value forColumnName:@"index_path"];
	} if ([key isEqualToString:@"creationDate"]) {
		[self updateDatabaseValue:value forColumnName:@"creation_date"];
	} if ([key isEqualToString:@"lastModificationDate"]) {
		[self updateDatabaseValue:value forColumnName:@"last_modification_date"];
	} else {
		[self updateDatabaseValue:value forColumnName:key];
	}
	_lastModificationDate = [NSDate date];
}

- (void)update
{
	// @TODO: had "hasChanged" on every changement to not send the request if no changements
	
	sqlite3 * database = _library.database;
	
	/* create a statement from an SQL string */
	sqlite3_stmt * stmt = NULL;
	const char sql[] = "UPDATE Project SET name = :name, description = :description, index_path = :index_path, priority = :priority, last_modification_date = datetime() WHERE Project.Project_id = :project_id";
	int err = sqlite3_prepare_v2(database, sql, -1, &stmt, NULL);
	if (err != SQLITE_OK)
		return ;
	
	int name_bind = sqlite3_bind_parameter_index(stmt, ":name");
	err = sqlite3_bind_text(stmt, name_bind, [self.name UTF8String], -1, SQLITE_TRANSIENT);
	if (err != SQLITE_OK)
		return ;
	
	int description_bind = sqlite3_bind_parameter_index(stmt, ":description");
	err = sqlite3_bind_text(stmt, description_bind, [self.description UTF8String], -1, SQLITE_TRANSIENT);
	if (err != SQLITE_OK)
		return ;
	
	int index_path_bind = sqlite3_bind_parameter_index(stmt, ":index_path");
	err = sqlite3_bind_text(stmt, index_path_bind, [self.indexPath UTF8String], -1, SQLITE_TRANSIENT);
	if (err != SQLITE_OK)
		return ;
	
	int priority_bind = sqlite3_bind_parameter_index(stmt, ":priority");
	err = sqlite3_bind_int(stmt, priority_bind, self.priority);
	if (err != SQLITE_OK)
		return ;
	
	int project_id_bind = sqlite3_bind_parameter_index(stmt, ":project_id");
	err = sqlite3_bind_int(stmt, project_id_bind, self.identifier);
	if (err != SQLITE_OK)
		return ;
	
	if (sqlite3_step(stmt) != SQLITE_DONE) {
		NSLog(@"error on update resquest: %s", sql);
		return ;
	}
	
	/* destroy and release the statement */ 
	sqlite3_finalize(stmt);
}

- (NSArray *)steps
{
	NSMutableArray * steps = [NSMutableArray arrayWithCapacity:10];
	
	sqlite3 * database = _library.database;
	
	/* create a statement from an SQL string */
	sqlite3_stmt * stmt = NULL;
	const char sql[] = "SELECT name, description, closed, Step_id FROM Step WHERE Project_id = :project_id ORDER BY Step_id ASC";
	int err = sqlite3_prepare_v2(database, sql, -1, &stmt, NULL);
	if (err != SQLITE_OK)
		return nil;
	
	int project_id_bind = sqlite3_bind_parameter_index(stmt, ":project_id");
	err = sqlite3_bind_int(stmt, project_id_bind, self.identifier);
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
		int identifier = (int)sqlite3_column_int(stmt, 3 /* "Step_id" */);
		Step * step = [[Step alloc] initWithName:name description:description closed:closed identifier:identifier project:self];
		step.library = self.library;
		
		[steps addObject:step];
	}
	
	/* destroy and release the statement */ 
	sqlite3_finalize(stmt);
	
	return steps;
}

- (Step *)stepWithIdentifier:(int)identifier
{
	// @TODO: Create a request directly from SQLite
	NSArray * steps = self.steps;
	for (Step * aStep in steps) {
		if (aStep.identifier == identifier) {
			return aStep;
		}
	}
	return nil;
}

- (BOOL)delete
{
	/* create a statement from an SQL string */
	sqlite3_stmt * stmt = NULL;
	const char sql[] = "DELETE FROM Project WHERE (Project_id = :project_id)";
	int err = sqlite3_prepare_v2(self.library.database, sql, -1, &stmt, NULL);
	if (err != SQLITE_OK)
		return NO;
	
	int step_id_bind = sqlite3_bind_parameter_index(stmt, ":project_id");
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

@end
