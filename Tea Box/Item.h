//
//  Item.h
//  Tea Box
//
//  Created by Max on 04/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "TBCoder.h"

NS_ASSUME_NONNULL_BEGIN

@protocol TBCoding;
@protocol TBDecoding;
@interface Item : NSObject <TBCoding, TBDecoding>

@end


typedef NS_ENUM(NSUInteger, FileItemType) {
	FileItemTypeUnknown,
	FileItemTypeImage,
	FileItemTypeText DEPRECATED_ATTRIBUTE,
	FileItemTypeWebURL,
	FileItemTypeFile,
	FileItemTypeFolder
};

extern NSImage * _Nullable ImageForFileItemType(FileItemType type);
extern NSImage * _Nullable SelectedImageForFileItemType(FileItemType type);

extern FileItemType FileItemTypeFromString(NSString * _Nonnull typeString) MIGRATION_ATTRIBUTE;

@interface FileItem : Item

@property (readonly) FileItemType itemType; // @FIXME: Should be `type` (once current `type` removed)

/// For files into library, `URL.path` is only the filename and `URL.baseURL` the URL of the library  (use `-[TBLibrary URLForFileItem:]` to get complete URL)
/// For linked files, it's a complete URL that could not point to existing file, use `-[NSUserDefault dataForKey:self.URL.absoluteString]` to retreive bookmark data. 
@property (copy) NSURL * URL; // @TODO: Set a read-only but add `rename:` method to only change the last path component of the URL
@property (copy) NSString * name;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithType:(FileItemType)type fileURL:(NSURL *)URL NS_DESIGNATED_INITIALIZER;

- (BOOL)isLinked;
- (BOOL)removeFromDisk;

@end


@interface TextItem : Item

@property (copy) NSString * content;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithContent:(NSString *)content;

@end


@interface WebURLItem : Item

@property (copy) NSURL * URL;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithURL:(NSURL *)url;

@end


typedef NS_ENUM(NSUInteger, TaskState) {
	TaskStateNone,
	TaskStateActive,
	TaskStateCompleted,
	
	kTaskStateCount
};

@interface TaskItem : Item

@property (strong, readonly) NSString * name;
@property (assign) TaskState state;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithName:(NSString *)name;

/// Change state to next following this order: None, Active, Completed, None, etc.
/// Returns the next state
- (TaskState)toggleState;

@end


@interface CountdownItem : Item

@property (strong, readonly) NSString * name;
@property (assign, readonly) NSInteger value;
@property (nonatomic, assign) NSInteger maximumValue;
@property (assign, readonly, getter=isCompleted) BOOL completed;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithName:(NSString *)name;

/// Set `maximumValue` *before* in/decrementing (since `value` is clipped to [0, maximumValue])
- (NSInteger)increment;
- (NSInteger)incrementBy:(NSInteger)offset;
- (NSInteger)decrement;
- (void)reset;

@end


NS_ASSUME_NONNULL_END


#pragma mark - Deprecated

#import "TBLibrary.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kItemTypeImage DEPRECATED_ATTRIBUTE;
extern NSString * const kItemTypeText DEPRECATED_ATTRIBUTE;
extern NSString * const kItemTypeWebURL DEPRECATED_ATTRIBUTE;
extern NSString * const kItemTypeFile DEPRECATED_ATTRIBUTE;
extern NSString * const kItemTypeFolder DEPRECATED_ATTRIBUTE;
extern NSString * const kItemTypeUnkown DEPRECATED_ATTRIBUTE;

@class Step;
@class TBLibrary;

@interface FileItem ()

@property (nonatomic, strong, readonly, nullable) NSString * filename DEPRECATED_ATTRIBUTE;
@property (nonatomic, strong, readonly) NSString * type MIGRATION_ATTRIBUTE;
@property (nonatomic, strong) Step * step DEPRECATED_ATTRIBUTE;
@property (nonatomic, assign, readonly) NSInteger identifier DEPRECATED_ATTRIBUTE;
@property (nonatomic, assign) NSInteger rowIndex DEPRECATED_ATTRIBUTE;
@property (nonatomic, strong) TBLibrary * library DEPRECATED_ATTRIBUTE;

+ (NSArray <FileItem *> *)itemsWithStepIdentifier:(int)stepID fromLibrary:(TBLibrary *)library MIGRATION_ATTRIBUTE;
+ (Item *)itemWithIdentifier:(int)identifier fromLibrary:(TBLibrary *)library UNAVAILABLE_ATTRIBUTE;

- (instancetype)initWithFilename:(NSString *)filename type:(NSString *)type step:(Step *)step UNAVAILABLE_ATTRIBUTE;
//- (instancetype)initWithFilename:(NSString *)filename type:(NSString *)type rowIndex:(NSInteger)rowIndex identifier:(NSInteger)identifier step:(Step *)step MIGRATION_ATTRIBUTE;
- (BOOL)insertIntoLibrary:(TBLibrary *)library UNAVAILABLE_ATTRIBUTE;

- (void)updateValue:(id)value forKey:(NSString *)key UNAVAILABLE_ATTRIBUTE;
- (BOOL)moveToStep:(Step *)destinationStep UNAVAILABLE_ATTRIBUTE;
- (BOOL)delete UNAVAILABLE_ATTRIBUTE;

@end

NS_ASSUME_NONNULL_END
