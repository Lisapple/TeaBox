//
//  Step+Coding.m
//  Tea Box
//
//  Created by Max on 06/03/2017.
//
//

#import "Step+Coding.h"

@interface NSString (Regex)

- (BOOL)matchesPattern:(nonnull NSString *)pattern;

@end

@implementation NSString (Regex)

- (BOOL)matchesPattern:(nonnull NSString *)pattern
{
	NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
	return ([regex matchesInString:self options:0 range:NSMakeRange(0, self.length)].count == 1);
}

@end


@implementation Step (Coding)

- (instancetype)initWithRepresentation:(NSString *)representation
{
	NSString * const stepPattern = @"^~?\\[(.+)\\]\\((.+)\\)$"; // "~?[step name](step path)"
	NSRegularExpression * projectNameRegex = [NSRegularExpression regularExpressionWithPattern:stepPattern
																					   options:0 error:nil];
	NSString * firstLine = [representation componentsSeparatedByString:@"\n"].firstObject;
	NSTextCheckingResult * match = [projectNameRegex firstMatchInString:firstLine options:0 range:NSMakeRange(0, firstLine.length)];
	NSString * name = [firstLine substringWithRange:[match rangeAtIndex:1]];
	name = [name stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
	NSString * const path = [firstLine substringWithRange:[match rangeAtIndex:2]];
	
	if ((self = [self initWithName:name])) {
		self.path = path;
		self.closed = [representation hasPrefix:@"/"];
		
		const NSRange range = NSMakeRange(0, representation.length);
		
		NSString * const pattern = @"^- .+$";
		NSRegularExpression * itemRegex = [NSRegularExpression regularExpressionWithPattern:pattern
																					options:NSRegularExpressionAnchorsMatchLines error:nil];
		[itemRegex enumerateMatchesInString:representation options:0 range:range
								 usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * stop) {
									 NSString * itemRepresentation = [representation substringWithRange:result.range];
									 Item * item = nil;
									 if ([itemRepresentation matchesPattern:@"^- \\[.+\\]\\(.+\\)$"]) // File item "- [name](path)"
										 item = [[Item alloc] initWithRepresentation:itemRepresentation];
									 else if ([itemRepresentation matchesPattern:@"^- \\[( |x)\\] .+$"]) // Task "- [ |x] name"
										 item = [[TaskItem alloc] initWithRepresentation:itemRepresentation];
									 else if ([itemRepresentation matchesPattern:@"^- \\[\\d+\\/\\d+\\] .+$"]) // Countdown "- [5/10] name"
										 item = [[CountdownItem alloc] initWithRepresentation:itemRepresentation];
									 else // Text "- {{text}}"
										 item = [[TextItem alloc] initWithRepresentation:itemRepresentation];
									 [self addItem:item];
								 }];
	}
	
	return self;
}

- (NSString *)representation
{
	// Step #1 or ~Step #1
	// {{ items }}
	
	NSMutableString * string = [[NSMutableString alloc] initWithCapacity:100];
	[string appendFormat:@"%@" @"[%@](%@)" @"\n", self.isClosed ? @"~" : @"", self.name, self.path];
	for (Item * item in self.items) {
		[string appendString:item.representation];
		[string appendString:@"\n"];
	}
	return string;
}

@end
