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
#import "SandboxHelper.h"

@implementation Item
@end

FileItemType FileItemTypeFromString(NSString * typeString) {
	if ([typeString isEqualToString:kItemTypeImage])
		return FileItemTypeImage;
	else if ([typeString isEqualToString:kItemTypeText])
		return FileItemTypeText;
	else if ([typeString isEqualToString:kItemTypeWebURL])
		return FileItemTypeWebURL;
	else if ([typeString isEqualToString:kItemTypeFile])
		return FileItemTypeFile;
	else if ([typeString isEqualToString:kItemTypeFolder])
		return FileItemTypeFolder;
	
	return FileItemTypeUnknown;
}

extern NSImage * ImageForFileItemType(FileItemType type)
{
	NSString * name = nil;
	switch (type) {
		case FileItemTypeImage: name = @"image";break;
		case FileItemTypeText:	name = @"text";	break;
		case FileItemTypeWebURL:name = @"url";	break;
		case FileItemTypeFile:	name = @"file";	break;
		case FileItemTypeFolder:name = @"folder"; break;
		default: break;
	}
	return (name) ? [NSImage imageNamed:[name stringByAppendingString:@"-type"]] : nil;
}

extern NSImage * SelectedImageForFileItemType(FileItemType type)
{
	NSString * name = nil;
	switch (type) {
		case FileItemTypeImage: name = @"image";break;
		case FileItemTypeText:	name = @"text";	break;
		case FileItemTypeWebURL:name = @"url";	break;
		case FileItemTypeFile:	name = @"file";	break;
		case FileItemTypeFolder:name = @"folder"; break;
		default: break;
	}
	return (name) ? [NSImage imageNamed:[name stringByAppendingString:@"-type-active"]] : nil;
}

@implementation FileItem

- (instancetype)initWithType:(FileItemType)type fileURL:(NSURL *)URL
{
	if ((self = [super init])) {
		_itemType = type;
		_URL = URL;
		_name = URL.lastPathComponent;
	}
	return self;
}

- (BOOL)isLinked
{
	return [self isLinkedInto:[TBLibrary defaultLibrary]];
}

- (BOOL)isLinkedInto:(TBLibrary *)library
{
	return ![[library URLForFileItem:self].baseURL.path isEqualToString:library.path]; // @TODO: Should not use arbitrary `defaultLibrary`
}

- (BOOL)removeFromDisk
{
	__block BOOL success = NO;
	[SandboxHelper executeWithSecurityScopedAccessToURL:self.URL block:^(NSError * _Nullable error) { // @FIXME: Should not be `URL` but `-[TBLibrary URLForFileItem:]`
		if (!error) {
			success = [[NSFileManager defaultManager] removeItemAtURL:self.URL error:nil]; // @FIXME: Should not be `URL` but `-[TBLibrary URLForFileItem:]`
		}
	}];
	return success;
}






NSString * const kItemTypeImage	= @"IMG";
NSString * const kItemTypeText	= @"TXT";
NSString * const kItemTypeWebURL = @"URL";
NSString * const kItemTypeFile	= @"FILE";
NSString * const kItemTypeFolder = @"FOLD";
NSString * const kItemTypeUnkown = @"????";

+ (NSArray <FileItem *> *)itemsWithStepIdentifier:(int)stepID fromLibrary:(TBLibrary *)library
{
	__block NSMutableArray <FileItem *> * items = [NSMutableArray arrayWithCapacity:10];
	[SandboxHelper executeBlockWithSecurityScopedLibraryAccessing:^(NSError * error) {
		if (!error) {
			
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
			while (sqlite3_step(stmt) == SQLITE_ROW) {
				NSString * filename = nil;
				const char * filename_ptr = (const char *)sqlite3_column_text(stmt, 0 /* "filename" */);
				if (filename_ptr)
					filename = @(filename_ptr);
				
				NSString * type = nil;
				const char * type_ptr = (const char *)sqlite3_column_text(stmt, 1 /* "type" */);
				if (type_ptr)
					type = @(type_ptr);
				
				int identifier = sqlite3_column_int(stmt, 2 /* "Step_id" */);
				FileItem * item = [[FileItem alloc] initWithFilename:filename type:type rowIndex:-1 identifier:identifier step:step];
				item.library = library;
				[items addObject:item];
			}
			
			// Destroy and release the statement
			sqlite3_finalize(stmt);
		}
	}];
	return items;
}

- (instancetype)initWithFilename:(NSString *)filename type:(NSString *)type rowIndex:(NSInteger)rowIndex identifier:(NSInteger)identifier step:(Step *)step MIGRATION_ATTRIBUTE
{
	if (self = [super init]) {
		_identifier = identifier;
		_filename = filename;
		_type = type;
		self.step = step;
		
		int count = (int)_step.items.count;
		if (rowIndex < 0 || rowIndex > count)
			rowIndex = count;
		
		self.rowIndex = rowIndex;
	}
	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<Item: 0x%x name=\"%@\", type=\"%@\" id=%li library=%@>", (unsigned int)self, _filename, _type, (long)_identifier, _library];
}

@end


@implementation TextItem

- (instancetype)initWithContent:(NSString *)content
{
	if ((self = [super init])) {
		self.content = content;
	}
	return self;
}

@end


@implementation WebURLItem

- (instancetype)initWithURL:(NSURL *)url
{
	if ((self = [super init])) {
		self.URL = url;
	}
	return self;
}

@end


@implementation TaskItem

- (instancetype)initWithName:(NSString *)name
{
	if ((self = [super init])) {
		_name = name;
	}
	return self;
}

- (TaskState)toggleState
{
	self.state = (self.state + 1) % kTaskStateCount;
	return self.state;
}

@end


@implementation CountdownItem

- (instancetype)initWithName:(NSString *)name
{
	if ((self = [super init])) {
		_name = name;
		_value = 0;
	}
	return self;
}

- (void)setMaximumValue:(NSInteger)maximumValue
{
	_maximumValue = maximumValue;
	[self updateCompleted];
}

- (NSInteger)increment
{
	return [self incrementBy:1];
}

- (NSInteger)incrementBy:(NSInteger)offset
{
	@synchronized (self) {
		_value = MAX(0, MIN(_value + offset, _maximumValue));
		[self updateCompleted];
	}
	return _value;
}

- (NSInteger)decrement
{
	return [self incrementBy:-1];
}

- (void)reset
{
	@synchronized (self) {
		_value = 0;
		[self updateCompleted];
	}
}

- (void)updateCompleted
{
	_completed = (_value >= _maximumValue);
}

@end
