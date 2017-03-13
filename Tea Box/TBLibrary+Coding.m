//
//  TBLibrary+Coding.m
//  Tea Box
//
//  Created by Max on 06/03/2017.
//
//

#import "TBLibrary+Coding.h"

#import "SandboxHelper.h"

NSString * const CoderVersion = @"1.0";

@interface TBLibrary ()

- (void)setProjectPaths:(NSArray *)names;
- (void)setName:(NSString *)name;

@end

@implementation TBLibrary (Coding)

- (instancetype)initWithRepresentation:(NSString *)representation
{
	if ((self = [super init])) {
		// @TODO: Check `Version` with `CoderVersion`
		
		const NSRange range = NSMakeRange(0, representation.length);
		
		NSString * const metadataPattern = @"^! (.+): (.+)$"; // "! key: value"
		NSRegularExpression * metadataRegex = [NSRegularExpression regularExpressionWithPattern:metadataPattern
																						options:NSRegularExpressionAnchorsMatchLines error:nil];
		__block NSMutableDictionary <NSString *, NSString *> * metadata = [NSMutableDictionary dictionaryWithCapacity:3];
		[metadataRegex enumerateMatchesInString:representation options:0 range:range
									 usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * stop) {
										 NSString * key = [representation substringWithRange:[result rangeAtIndex:1]];
										 NSString * value = [representation substringWithRange:[result rangeAtIndex:2]];
										 metadata[key.lowercaseString] = value;
									 }];
		
		// @TODO: Check and set from metadata
		self.name = metadata[@"name"];
		
		NSString * const projectNamePattern = @"^\\[.+\\]\\((.+)\\)$"; // "[project name](path)"
		NSRegularExpression * projectNameRegex = [NSRegularExpression regularExpressionWithPattern:projectNamePattern
																						options:NSRegularExpressionAnchorsMatchLines error:nil];
		__block NSMutableArray <NSString *> * projectPaths = [NSMutableArray arrayWithCapacity:5];
		[projectNameRegex enumerateMatchesInString:representation options:0 range:range
										usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * stop) {
											NSString * name = [representation substringWithRange:[result rangeAtIndex:1]]; // ???: Add trimming?
											if (name.length) [projectPaths addObject:name];
										}];
		self.projectPaths = projectPaths;
	}
	
	return self;
}

- (NSString *)representation
{
	// ! Version: 1.0
	// ! Application: Tea Box 1.2
	// ! Name: My Library
	// [My Project](Projects/My Project)
	// [Project #2](Projects/Project-2)
	
	NSMutableString * string = [[NSMutableString alloc] initWithCapacity:500];
	
	[string appendFormat:@"! Version: %@" @"\n", CoderVersion];
	[string appendFormat:@"! Application: %@" @"\n", @"Tea Box"]; // @TODO: Add app version number
	if (self.name)
		[string appendFormat:@"! Name: %@" @"\n", self.name];
	
	[string appendString:@"\n"];
	
	for (Project * project in self.projects) {
		[string appendFormat:@"[%@]", project.name];
		[string appendFormat:@"(%@)", project.path];
		[string appendString:@"\n"];
	}
	
	return string;
}

@end
