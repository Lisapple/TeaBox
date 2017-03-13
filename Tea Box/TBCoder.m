//
//  TBCoder.m
//  Tea Box
//
//  Created by Max on 06/03/2017.
//
//

#import "TBCoder.h"

NSString * const LibraryRootFilename = @"root";
NSString * const ProjectIndexFilename = @"index";

@interface TBCoder ()

@property (nonatomic, strong) NSString * path;

@end

@implementation TBCoder

+ (instancetype)coderForPath:(NSString *)path
{
	TBCoder * coder = [[TBCoder alloc] init];
	coder.path = path;
	return coder;
}

- (BOOL)encodeObject:(id <TBCoding>)object;
{
	return [object.representation writeToFile:self.path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (BOOL)encodeLibrary:(TBLibrary *)library;
{
	NSString * path = [self.path stringByAppendingFormat:@"/%@", LibraryRootFilename];
	return [library.representation writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

@end


@interface TBDecoder ()

@property (nonatomic, strong) NSString * path;

@end

@implementation TBDecoder

+ (instancetype)decoderWithPath:(NSString *)path
{
	TBDecoder * decoder = [[TBDecoder alloc] init];
	decoder.path = path;
	return decoder;
}

- (TBLibrary *)decodeLibrary;
{
	NSString * const path = [self.path stringByAppendingFormat:@"/%@", LibraryRootFilename];
	NSString * const content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
	if (content)
		return [[TBLibrary alloc] initWithRepresentation:content];
	
	return nil;
}

- (Project *)decodeProjectNamed:(NSString *)name
{
	
}

@end
