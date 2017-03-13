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
#import "SandboxHelper.h"

NSString * const StepDidUpdateNotification = @"StepDidUpdateNotificationName";

@interface Step ()
{
	BOOL hasChanged;
}

@property (strong) NSMutableArray <Item *> * items;

- (void)setIdentifier:(NSInteger)identifier MIGRATION_ATTRIBUTE;

@end

@implementation Step

- (instancetype)initWithName:(NSString *)name
{
	if ((self = [super init])) {
		self.name = name;
		_items = [NSMutableArray arrayWithCapacity:5];
	}
	return self;
}

- (void)addItem:(Item *)item
{
	[_items addObject:item];
	// @TODO: Send StepDidUpdateNotification (with step as object)
}

- (void)addItems:(NSArray <Item *> *)items
{
	[_items addObjectsFromArray:items];
	// @TODO: Send StepDidUpdateNotification (with step as object)
}

- (void)removeItem:(Item *)item
{
	[_items removeObject:item];
	// @TODO: Send StepDidUpdateNotification (with step as object)
}

- (BOOL)removeFromDisk
{
	// @TODO: Implement it
	// @TODO: Send StepDidUpdateNotification (with step as object)
	return NO;
}



@synthesize description = _description;

+ (NSArray <Step *> *)stepsWithProjectIdentifier:(NSInteger)identifier fromLibrary:(TBLibrary *)library
{
	NSMutableArray <Step *> * steps = [NSMutableArray arrayWithCapacity:10];
	
	[SandboxHelper executeBlockWithSecurityScopedLibraryAccessing:^(NSError * error) {
		if (!error) {
			Project * project = [Project projectWithIdentifier:identifier fromLibrary:library];
			
			// Create a statement from an SQL string
			sqlite3_stmt * stmt = NULL;
			const char sql[] = "SELECT name, description, closed, Step_id FROM Step WHERE Project_id = :project_id ORDER BY Project_id ASC";
			int err = sqlite3_prepare_v2(library.database, sql, -1, &stmt, NULL);
			if (err != SQLITE_OK)
				return ;
			
			int project_id_bind = sqlite3_bind_parameter_index(stmt, ":project_id");
			err = sqlite3_bind_int(stmt, project_id_bind, (int)identifier);
			if (err != SQLITE_OK)
				return ;
			
			// Execute statement and step over each row of the result set
			while (sqlite3_step(stmt) == SQLITE_ROW) {
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
				Step * step = [[Step alloc] initWithName:name];
				step.path = name;
				step.description = description;
				step.closed = closed;
				step.identifier = identifier;
				[steps addObject:step];
			}
			
			// Destroy and release the statement
			sqlite3_finalize(stmt);
		}
	}];
	
	return steps;
}

+ (Step *)stepWithIdentifier:(int)identifier fromLibrary:(TBLibrary *)library
{
	__block Step * step = nil;
	[SandboxHelper executeBlockWithSecurityScopedLibraryAccessing:^(NSError * error) {
		if (!error) {
			// Create a statement from an SQL string
			sqlite3_stmt * stmt = NULL;
			const char sql[] = "SELECT name, description, closed, Project_id FROM Step WHERE Step_id = :step_id ORDER BY Step_id ASC LIMIT 1";
			int err = sqlite3_prepare_v2(library.database, sql, -1, &stmt, NULL);
			if (err != SQLITE_OK)
				return ;
			
			int step_id_bind = sqlite3_bind_parameter_index(stmt, ":step_id");
			err = sqlite3_bind_int(stmt, step_id_bind, identifier);
			if (err != SQLITE_OK)
				return ;
			
			// Execute statement and step over each row of the result set
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
				step = [[Step alloc] initWithName:name];
				step.description = description;
				step.closed = closed;
				step.identifier = identifier;
			}
			
			// Destroy and release the statement
			sqlite3_finalize(stmt);
		}
	}];
	return step;
}

- (instancetype)initWithName:(NSString *)name description:(NSString *)description project:(Project *)project
{
	return [self initWithName:name description:description closed:NO identifier:-1 project:project];
}

- (instancetype)initWithName:(NSString *)name description:(NSString *)description closed:(BOOL)closed identifier:(NSInteger)identifier project:(Project *)project
{
	if ((self = [self initWithName:name])) {
		_identifier = identifier;
		self.description = description;
		self.closed = closed;
		self.project = project;
	}
	
	return self;
}

- (void)updateValue:(id)value forKey:(NSString *)key
{
	[self willChangeValueForKey:key];
	[self setValue:value forKey:key];
	[self didChangeValueForKey:key];
}

- (BOOL)delete
{
	__block BOOL success = NO;
	[SandboxHelper executeBlockWithSecurityScopedLibraryAccessing:^(NSError * error) {
		if (!error) {
			// Create a statement from an SQL string
			sqlite3_stmt * stmt = NULL;
			const char sql[] = "DELETE FROM Step WHERE (Step_id = :step_id)";
			int err = sqlite3_prepare_v2(_project.library.database, sql, -1, &stmt, NULL);
			if (err != SQLITE_OK)
				return ;
			
			int step_id_bind = sqlite3_bind_parameter_index(stmt, ":step_id");
			err = sqlite3_bind_int(stmt, step_id_bind, (int)self.identifier);
			if (err != SQLITE_OK)
				return ;
			
			if (sqlite3_step(stmt) != SQLITE_DONE) {
				NSLog(@"error on update resquest: %s", sql);
			}
			
			// Destroy and release the statement
			sqlite3_finalize(stmt);
			success = YES;
		}
	}];
	return success;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<Step: 0x%x name=\"%@\", description=\"%@\" id=%li library=%@>", (unsigned int)self, self.name, _description, (long)_identifier, _library];
}

- (void)setIdentifier:(NSInteger)identifier
{
	_identifier = identifier;
}

@end
