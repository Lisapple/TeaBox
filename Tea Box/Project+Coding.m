//
//  Project+Coding.m
//  Tea Box
//
//  Created by Max on 06/03/2017.
//
//

#import "Project+Coding.h"
#import "NSDate+additions.h"

@interface Project ()

- (void)setCreationDate:(NSDate *)date;

@end

@implementation Project (Coding)

- (instancetype)initWithRepresentation:(NSString *)representation
{
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
	
	NSString * name = metadata[@"name"];
	NSString * description = metadata[@"description"];
	if ((self = [self initWithName:name description:description])) {
		self.projectPriority = ProjectPriorityWithString(metadata[@"priority"]);
		
		self.creationDate = [NSDate dateWithISO8601Format:metadata[@"created"]];
		self.lastModificationDate = [NSDate dateWithISO8601Format:metadata[@"updated"]];
		
		NSString * stepPattern = @"^[^!](.(?!\\n{2}))+."; // "[step name](step path)\n- item...\n"
		NSRegularExpressionOptions options = (NSRegularExpressionDotMatchesLineSeparators | NSRegularExpressionAnchorsMatchLines);
		NSRegularExpression * stepRegex = [NSRegularExpression regularExpressionWithPattern:stepPattern options:options error:nil];
		[stepRegex enumerateMatchesInString:representation options:0 range:range
								 usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * stop) {
									 NSCharacterSet * trimSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
									 NSString * string = [representation substringWithRange:result.range];
									 string = [string stringByTrimmingCharactersInSet:trimSet];
									 Step * step = [[Step alloc] initWithRepresentation:string];
									 [self addStep:step];
								 }];
	}
	return self;
}

- (NSString *)representation
{
	// ! Name: Project #1
	// ! Created: 2017-02-12T13:00:00+00:00
	// ! Updated: 2017-02-12T13:34:56+00:00
	// ! Priority: normal
	// ! Description: This project should be finished soon
	// {{ steps }}
	
	NSMutableString * string = [[NSMutableString alloc] initWithCapacity:500];
	
	[string appendFormat:@"! Name: %@" @"\n", self.name];
	[string appendFormat:@"! Created: %@" @"\n", self.creationDate.iso8601DateString];
	[string appendFormat:@"! Updated: %@" @"\n", self.lastModificationDate.iso8601DateString];
	[string appendFormat:@"! Priority: %@" @"\n", ProjectPriorityDescription(self.projectPriority)];
	if (self.description.length > 0)
		[string appendFormat:@"! Description: %@" @"\n", self.description];
	
	[string appendString:@"\n"];
	
	for (Step * step in self.steps) {
		[string appendString:step.representation];
		[string appendString:@"\n"];
	}
	return string;
}

@end
