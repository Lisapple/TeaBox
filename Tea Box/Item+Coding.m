//
//  Item+Coding.m
//  Tea Box
//
//  Created by Max on 06/03/2017.
//
//

#import "Item+Coding.h"

@implementation FileItem (Coding)

- (nullable instancetype)initWithRepresentation:(NSString *)representation
{
	NSString * const pattern = @"- \\[(.+)\\]\\((.+)\\)"; // "- [{{name}}]({{file}})"
	NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
	NSAssert(regex, @"");
	
	NSTextCheckingResult * match = [regex firstMatchInString:representation options:0 range:NSMakeRange(0, representation.length)];
	if (match.numberOfRanges != 3)
		return nil;
	
	NSString * const name = [representation substringWithRange:[match rangeAtIndex:1]];
	NSString * const path = [representation substringWithRange:[match rangeAtIndex:2]];
	
	FileItemType type = (path.pathExtension.length) ? FileItemTypeFile : FileItemTypeFolder;
	if ((self = [self initWithType:type fileURL:[NSURL fileURLWithPath:path]])) {
		self.name = name; // @TODO: Remove extension
	}
	return self;
}

- (NSString *)representation
{
	// - [Text 2 this text introduces...](text 2.txt)
	if (self.isLinked)
		return [NSString stringWithFormat:@"- [%@](%@)", self.name, self.URL.absoluteString];
	else
		return [NSString stringWithFormat:@"- [%@](%@)", self.name, self.URL.relativePath.lastPathComponent];
}

@end


@implementation TextItem (Coding)

- (nullable instancetype)initWithRepresentation:(NSString *)representation
{
	NSString * const pattern = @"- (.+)"; // "- {{content}}"
	NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
	NSAssert(regex, @"");
	
	NSTextCheckingResult * match = [regex firstMatchInString:representation options:0 range:NSMakeRange(0, representation.length)];
	if (match.numberOfRanges != 2)
		return nil;
	
	NSString * content = [representation substringWithRange:[match rangeAtIndex:1]];
	content = [content stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
	content = [content stringByReplacingOccurrencesOfString:@"\\t" withString:@"\t"];
	
	if ((self = [self initWithContent:content])) { }
	return self;
}

- (NSString *)representation
{
	// - Some text...
	NSString * content = self.content;
	content = [content stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
	content = [content stringByReplacingOccurrencesOfString:@"\t" withString:@"\\t"];
	return [NSString stringWithFormat:@"- %@", content];
}

@end


@implementation WebURLItem (Coding)

- (nullable instancetype)initWithRepresentation:(NSString *)representation
{
	NSString * const pattern = @"- \\[(.+)\\]\\((.+)\\)"; // "- [{{host}}]({{url}})"
	NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
	NSAssert(regex, @"");
	
	NSTextCheckingResult * match = [regex firstMatchInString:representation options:0 range:NSMakeRange(0, representation.length)];
	if (match.numberOfRanges != 3)
		return nil;
	
	NSString * const name = [representation substringWithRange:[match rangeAtIndex:1]];
	NSString * const urlString = [representation substringWithRange:[match rangeAtIndex:2]];
	NSURL * URL = [NSURL URLWithString:urlString];
	if (!URL)
		return nil;
	
	if ((self = [self initWithURL:URL])) { }
	return self;
}

- (NSString *)representation
{
	// - [example.com](https://example.com)
	return [NSString stringWithFormat:@"- [%@](%@)", self.URL.host ?: self.URL.absoluteString, self.URL.absoluteString];
}

@end


@implementation TaskItem (Coding)

- (nullable instancetype)initWithRepresentation:(NSString *)representation
{
	NSString * const pattern = @"- \\[([ x-])\\] (.+)"; // "- [{{state}}] {{name}}"
	NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
	NSAssert(regex, @"");
	
	NSTextCheckingResult * match = [regex firstMatchInString:representation options:0 range:NSMakeRange(0, representation.length)];
	if (match.numberOfRanges != 3)
		return nil;
	
	NSString * const state = [representation substringWithRange:[match rangeAtIndex:1]];
	NSString * const name = [representation substringWithRange:[match rangeAtIndex:2]];
	
	if ((self = [self initWithName:name])) {
		if /**/ ([state isEqualToString:@"-"])
			self.state = TaskStateActive;
		else if ([state isEqualToString:@"x"])
			self.state = TaskStateCompleted;
		else
			self.state = TaskStateNone;
	}
	return self;
}

- (NSString *)representation
{
	// - [ ] Complete this task
	// - [-] Task active
	// - [x] Task completed
	NSString * stateString = @" ";
	switch (self.state) {
		case TaskStateActive:	stateString = @"-"; break;
		case TaskStateCompleted:stateString = @"x"; break;
		default: break;
	}
	return [NSString stringWithFormat:@"- [%@] %@", stateString, self.name];
}

@end


@implementation CountdownItem (Coding)

- (nullable instancetype)initWithRepresentation:(NSString *)representation
{
	NSString * const pattern = @"- \\[(\\d+)/(\\d+)\\] (.+)"; // "- [{{value}}/{{maximum}}] {{name}}"
	NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
	NSAssert(regex, @"");
	
	NSTextCheckingResult * match = [regex firstMatchInString:representation options:0 range:NSMakeRange(0, representation.length)];
	if (match.numberOfRanges != 4)
		return nil;
	
	const NSInteger value = [[representation substringWithRange:[match rangeAtIndex:1]] integerValue];
	const NSInteger maximumValue = [[representation substringWithRange:[match rangeAtIndex:2]] integerValue];
	NSString * const name = [representation substringWithRange:[match rangeAtIndex:3]];
	
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
