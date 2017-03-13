//
//  Project.m
//  Tea Box
//
//  Created by Max on 03/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "Project.h"

#import "SandboxHelper.h"
#import "NSDate+additions.h"

ProjectPriority ProjectPriorityWithString(NSString * string) {
	if /**/ ([string isEqualToString:@"Low"])
		return ProjectPriorityLow;
	else if ([string isEqualToString:@"Normal"])
		return ProjectPriorityNormal;
	else if ([string isEqualToString:@"High"])
		return ProjectPriorityHigh;
	return ProjectPriorityNone;
}

NSString * ProjectPriorityDescription(ProjectPriority priority) {
	switch (priority) {
		case ProjectPriorityNone:	return @"None";
		case ProjectPriorityLow:	return @"Low";
		case ProjectPriorityNormal:	return @"Normal";
		case ProjectPriorityHigh:	return @"High";
	}
	return nil;
}

@interface Project ()

@property (strong) NSMutableArray <Step *> * steps;

@end

@implementation Project

- (instancetype)initWithName:(NSString *)name description:(nullable NSString *)description
{
	if ((self = [super init])) {
		self.name = name;
		self.description = description;
		_steps = [NSMutableArray arrayWithCapacity:5];
		
		[[NSNotificationCenter defaultCenter] addObserverForName:StepDidUpdateNotification object:nil queue:nil
													  usingBlock:^(NSNotification * note) {
														  if ([self.steps containsObject:note.object]) [self markAsUpdated];
													  }];
	}
	return self;
}

- (void)addStep:(Step *)step
{
	[_steps addObject:step];
	[self markAsUpdated];
}

- (void)addSteps:(NSArray <Step *> *)steps
{
	[_steps addObjectsFromArray:steps];
	[self markAsUpdated];
}

- (void)removeStep:(Step *)step
{
	[_steps removeObject:step];
	[self markAsUpdated];
}

- (void)markAsUpdated
{
	self.lastModificationDate = [NSDate date];
}

- (nullable Step *)stepForItem:(Item *)item
{
	for (Step * step in self.steps) {
		if ([step.items containsObject:item])
			return step;
	}
	return nil;
}

- (BOOL)removeFromDisk
{
	// @TODO: Implement it
	return NO;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:StepDidUpdateNotification object:nil];
}




@synthesize description = _description;

+ (NSArray <Project *> *)allProjectsFromLibrary:(TBLibrary *)library
{
	if (!library) {
		return nil;
	}
	
	// @TODO: cache this value and remove the cache at every changement into the database
	NSMutableArray <Project *> * projects = [NSMutableArray arrayWithCapacity:10];
	[SandboxHelper executeWithSecurityScopedAccessToPath:library.path block:^(NSError * error) {
		if (!error) {
			
			/* create a statement from an SQL string */
			sqlite3_stmt * stmt = NULL;
			sqlite3 * db = library.database;
			const char sql[] = "SELECT name, description, priority, creation_date, last_modification_date, index_path, Project_id FROM Project ORDER BY priority, Project_id ASC";
			int err = sqlite3_prepare_v2(db, sql, -1, &stmt, NULL);
			if (err != SQLITE_OK) {
				NSAssert(false, @"\"sqlite3_prepare_v2\" did fail with error: %d", err);
				return ;
			}
			
			/* execute statement and step over each row of the result set */
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
		}
	}];
	
	return projects;
}

+ (Project *)projectWithIdentifier:(NSInteger)identifier fromLibrary:(TBLibrary *)library
{
	__block Project * project = nil;
	[SandboxHelper executeBlockWithSecurityScopedLibraryAccessing:^(NSError * error) {
		if (!error) {
			/* create a statement from an SQL string */
			sqlite3_stmt * stmt = NULL;
			const char sql[] = "SELECT name, description, priority, creation_date, last_modification_date, index_path FROM Project WHERE Project_id = :project_id LIMIT 1";
			int err = sqlite3_prepare_v2(library.database, sql, -1, &stmt, NULL);
			if (err != SQLITE_OK) {
				NSAssert(false, @"\"sqlite3_prepare_v2\" did fail with error: %d", err);
				return ;
			}
			
			int project_id_bind = sqlite3_bind_parameter_index(stmt, ":project_id");
			err = sqlite3_bind_int(stmt, project_id_bind, (int)identifier);
			if (err != SQLITE_OK) {
				NSAssert(false, @"\"sqlite3_bind_int\" did fail with error: %d", err);
				return ;
			}
			
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
		}
	}];
	return project;
}

- (instancetype)initWithCreationDate:(NSDate *)creationDate
{
	if ((self = [super init])) {
		_creationDate = creationDate;
		_steps = [NSMutableArray arrayWithCapacity:5];
	}
	
	return self;
}

- (instancetype)initWithName:(NSString *)name description:(NSString *)description priority:(NSInteger)priority identifier:(NSInteger)identifier
{
	if ((self = [self initWithName:name description:description])) {
		self.identifier = identifier;
		self.priority = priority;
	}
	return self;
}

- (void)updateValue:(id)value forKey:(NSString *)key
{
	[self willChangeValueForKey:key];
	[self setValue:value forKey:key];
	[self didChangeValueForKey:key];
	
	_lastModificationDate = [NSDate date];
}

- (Step *)stepWithIdentifier:(NSInteger)identifier
{
	// @TODO: Create a request directly from SQLite
	for (Step * aStep in self.steps) {
		if (aStep.identifier == identifier)
			return aStep;
	}
	return nil;
}

- (BOOL)delete
{
	__block BOOL success = NO;
	[SandboxHelper executeWithSecurityScopedAccessToPath:self.library.path block:^(NSError * error) {
		if (!error) {
			
			/* create a statement from an SQL string */
			sqlite3_stmt * stmt = NULL;
			const char sql[] = "DELETE FROM Project WHERE (Project_id = :project_id)";
			int err = sqlite3_prepare_v2(self.library.database, sql, -1, &stmt, NULL);
			if (err != SQLITE_OK)
				return ;
			
			int step_id_bind = sqlite3_bind_parameter_index(stmt, ":project_id");
			err = sqlite3_bind_int(stmt, step_id_bind, (int)self.identifier);
			if (err != SQLITE_OK)
				return ;
			
			if (sqlite3_step(stmt) != SQLITE_DONE) {
				NSLog(@"error on update resquest: %s", sql);
				return ;
			}
			
			/* destroy and release the statement */
			sqlite3_finalize(stmt);
			success = YES;
		}
	}];
	
	return success;
}

- (void)setCreationDate:(NSDate * _Nonnull)creationDate
{
	_creationDate = creationDate;
}

@end
