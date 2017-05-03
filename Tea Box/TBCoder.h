//
//  TBCoder.h
//  Tea Box
//
//  Created by Max on 06/03/2017.
//
//

#import "Project.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const LibraryRootFilename;
extern NSString * const ProjectIndexFilename;

@protocol TBCoding <NSObject>

- (NSString *)representation;

@end

@protocol TBDecoding <NSObject>

- (nullable instancetype)initWithRepresentation:(NSString *)representation;

@end


@interface TBCoder : NSObject

+ (instancetype)coderForPath:(NSString *)path;

- (BOOL)encodeObject:(id <TBCoding>)object;

@end

@class TBLibrary;
@interface TBCoder ()

- (BOOL)encodeLibrary:(TBLibrary *)library;

@end


@interface TBDecoder : NSObject

+ (instancetype)decoderWithPath:(NSString *)path;

@end

@class Project;
@interface TBDecoder ()

- (nullable TBLibrary *)decodeLibrary;
- (nullable Project *)decodeProjectNamed:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
