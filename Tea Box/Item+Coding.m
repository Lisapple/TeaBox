//
//  Item+Coding.m
//  Tea Box
//
//  Created by Max on 06/03/2017.
//
//

#import "Item+Coding.h"

@implementation FileItem (Coding)

- (instancetype)initWithRepresentation:(NSString *)representation
{
	NSString * const pattern = @"- \\[(.+)\\]\\((.+)\\)"; // "- [{{name}}]({{file}})"
	NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
	NSAssert(regex, @"");
	
	NSTextCheckingResult * match = [regex firstMatchInString:representation options:0 range:NSMakeRange(0, representation.length)];
	NSString * name = [representation substringWithRange:[match rangeAtIndex:1]];
	NSString * path = [representation substringWithRange:[match rangeAtIndex:2]];
	
	FileItemType type = FileItemTypeUnknown; // @TODO: Set correct value
	if ((self = [self initWithType:type fileURL:[NSURL fileURLWithPath:path]])) { }
	return self;
}

- (NSString *)representation
{
	// - [Text 2 this text introduces...](text 2.txt)
	if (self.isLinked)
		return [NSString stringWithFormat:@"- [%@](%@)", self.URL.relativePath.lastPathComponent, self.URL.absoluteString]; // @TODO: Remove extension
	else
		return [NSString stringWithFormat:@"- [%@](%@)", self.URL.relativePath.lastPathComponent, self.URL.relativePath.lastPathComponent]; // @TODO: Remove extension
}

@end


@implementation TextItem (Coding)

- (instancetype)initWithRepresentation:(NSString *)representation
{
	NSString * const pattern = @"- (.+)"; // "- {{content}}"
	NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
	NSAssert(regex, @"");
	
	NSTextCheckingResult * match = [regex firstMatchInString:representation options:0 range:NSMakeRange(0, representation.length)];
	NSString * content = [representation substringWithRange:[match rangeAtIndex:1]];
	content = [content stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
	
	if ((self = [self initWithContent:content])) { }
	return self;
}

- (NSString *)representation
{
	// - Some text...
	return [NSString stringWithFormat:@"- %@", [self.content stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"]];
}

@end


@implementation TaskItem (Coding)

- (instancetype)initWithRepresentation:(NSString *)representation
{
	NSString * const pattern = @"- \\[(x| )\\] (.+)"; // "- [{{state}}] {{name}}"
	NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
	NSAssert(regex, @"");
	
	NSTextCheckingResult * match = [regex firstMatchInString:representation options:0 range:NSMakeRange(0, representation.length)];
	BOOL isCompleted = [[representation substringWithRange:[match rangeAtIndex:1]] isEqualToString:@"x"];
	NSString * name = [representation substringWithRange:[match rangeAtIndex:2]];
	
	if ((self = [self initWithName:name])) {
		(isCompleted) ? [self markAsCompleted] : [self markAsActive];
	}
	return self;
}

- (NSString *)representation
{
	// - [ ] Complete this task
	// - [x] Complete this task
	return [NSString stringWithFormat:@"- [%@] %@", (self.isCompleted) ? @"x" : @" ", self.name];
}

@end


@implementation CountdownItem (Coding)

- (instancetype)initWithRepresentation:(NSString *)representation
{
	NSString * const pattern = @"- \\[(\\d+)/(\\d+)\\] (.+)"; // "- [{{value}}/{{maximum}}] {{name}}"
	NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
	NSAssert(regex, @"");
	
	NSTextCheckingResult * match = [regex firstMatchInString:representation options:0 range:NSMakeRange(0, representation.length)];
	NSInteger value = [[representation substringWithRange:[match rangeAtIndex:1]] integerValue];
	NSInteger maximumValue = [[representation substringWithRange:[match rangeAtIndex:2]] integerValue];
	NSString * name = [representation substringWithRange:[match rangeAtIndex:3]];
	
	if ((self = [self initWithName:name])) {
		self.maximumValue = maximumValue;
		[self incrementBy:value];
	}
	return self;
}

- (NSString *)representation
{
	// - [2/5] Do this again
	return [NSString stringWithFormat:@"- [%ld/%ld] %@", (long)self.value, (long)self.maximumValue, self.name];
}

@end
