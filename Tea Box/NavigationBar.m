//
//  NavigationBar.m
//  Tea Box
//
//  Created by Max on 19/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "NavigationBar.h"

@interface NavigationBarButton ()

@property (nonatomic, assign) NavigationBarButtonType type;
@property (nonatomic, strong) NSTextField * textField;

@end

@implementation NavigationBarButton

@synthesize title = _title;
@synthesize disabled;
@synthesize highlighted = _highlighted;

@synthesize navigationBar = _navigationBar;

CGColorRef CGColorDarker(CGColorRef colorRef, float intensity);
CGColorRef CGColorDarker(CGColorRef colorRef, float intensity)
{
	unsigned long count = CGColorGetNumberOfComponents(colorRef);
	const CGFloat * comps = CGColorGetComponents(colorRef);
	
	CGFloat new_comps[count];
	for (int i = 0; i < (count - 1 /* Skip alpha channel */); i++) {
		new_comps[i] = comps[i] * (1.f + (-0.333f * intensity)); // A = comps; B = 2/3 * comps; new_comps = A + (B - A) * intensity
	}
	new_comps[count - 1] = comps[count - 1]; // Copy alpha channel
	
	CGColorSpaceRef colorSpace = CGColorGetColorSpace(colorRef);
	return CGColorCreate(colorSpace, new_comps);
}

+ (NSString *)titleForType:(NavigationBarButtonType)aType
{
	switch (aType) {
		case NavigationBarButtonTypeDone:
			return @"Done"; break;
		case NavigationBarButtonTypeDelete:
			return @"Delete"; break;
		case NavigationBarButtonTypeBack:
			return @"Back";
		default: break;
	}
	return @"";
}

- (instancetype)initWithType:(NavigationBarButtonType)aType target:(id)target action:(SEL)action
{
	NSString * title = [NavigationBarButton titleForType:aType];
	NSDictionary * attributes = @{ NSFontNameAttribute : [NSFont systemFontOfSize:12.] };
	NSSize size = [title sizeWithAttributes:attributes];
	
	CGFloat width = MIN(MAX(80., size.width + (2 * 8.)), 150.);
	NSRect frame = NSMakeRect(0., 0., width, 28.);
	if ((self = [super initWithFrame:frame])) {
		_type = aType;
		self.title = title;
		self.target = target;
		self.action = action;
	}
	return self;
}

- (instancetype)initWithTitle:(NSString *)title target:(id)target action:(SEL)action
{
	NSDictionary * attributes = @{ NSFontNameAttribute : [NSFont systemFontOfSize:12.] };
	NSSize size = [title sizeWithAttributes:attributes];
	
	CGFloat width = MIN(MAX(80., size.width + (2 * 8.)), 150.);
	NSRect frame = NSMakeRect(0., 0., width, 28.);
	if ((self = [super initWithFrame:frame])) {
		_type = NavigationBarButtonTypeDefault;
		self.title = title;
		self.target = target;
		self.action = action;
	}
	return self;
}

- (void)setTitle:(NSString *)title
{
	_title = title;
	
	if (!_textField) {
		CGFloat x = 4., width = self.frame.size.width - (2 * 4.);
		if (_type == NavigationBarButtonTypeBack) {
			x = 12., width = self.frame.size.width - (2 * 4.) - 8.;
		}
		
		NSRect frame = NSMakeRect(x, (self.frame.size.height - 16.) / 2., width, 16.);
		_textField = [[NSTextField alloc] initWithFrame:frame];
		[_textField setEditable:NO];
		[_textField setBordered:NO];
		_textField.alignment = NSCenterTextAlignment;
		_textField.stringValue = _title;
		_textField.drawsBackground = NO;
		_textField.font = [NSFont boldSystemFontOfSize:12.];
		_textField.usesSingleLineMode = YES;
		[_textField sizeToFit];
		
		frame = self.frame;
		if (_type == NavigationBarButtonTypeBack) {
			frame.size.width = MAX(80., _textField.frame.size.width + (2 * 4.) + 8.);
		} else {
			frame.size.width = MAX(80., _textField.frame.size.width + (2 * 4.));
		}
		self.frame = frame;
		
		frame = _textField.frame;
		frame.origin.x = (self.frame.size.width - frame.size.width) / 2.;
		_textField.frame = frame;
		[self addSubview:_textField];
	}
}

- (void)drawRect:(NSRect)dirtyRect
{
	CGFloat x = 0., y = 0.;
	CGFloat height = self.frame.size.height, width = self.frame.size.width;
	CGFloat radius = 3.;
	
	CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;
	CGContextBeginPath(context);
	
	if (_type == NavigationBarButtonTypeBack) {
		
		/*	   / pt1 ---------- pt2  */
		/* pt5			BACK	 |	 */
		/*	   \ pt3 ---------- pt4  */
		
		CGFloat arrowLength = 8.;
		CGPoint pt1 = CGPointMake(x + radius + arrowLength, y + height);
		CGPoint pt2 = CGPointMake(x + width - radius, y + height);
		CGPoint pt3 = CGPointMake(x + radius + arrowLength, y);
		CGPoint pt4 = CGPointMake(x + width - radius, y);
		CGPoint pt5 = CGPointMake(x, y + height / 2.);
		
		CGContextMoveToPoint(context, pt1.x, pt1.y);
		CGContextAddLineToPoint(context, pt2.x, pt2.y);
		
		CGContextAddArcToPoint(context, pt2.x + radius, pt2.y, pt4.x + radius, pt4.y, radius);
		CGContextAddArcToPoint(context, pt4.x + radius, pt4.y, pt4.x, pt4.y, radius);
		
		CGContextAddLineToPoint(context, pt3.x, pt3.y);
		
		CGContextAddLineToPoint(context, pt5.x, pt5.y);
		CGContextAddLineToPoint(context, pt1.x, pt1.y);
		
	} else {
		/*  pt1 ---------- pt2  */
		/*	 |     TITLE    |   */
		/*  pt3 ---------- pt4  */
		
		CGPoint pt1 = CGPointMake(x + radius, y + height);
		CGPoint pt2 = CGPointMake(x + width - radius, y + height);
		CGPoint pt3 = CGPointMake(x + radius, y);
		CGPoint pt4 = CGPointMake(x + width - radius, y);
		
		CGContextMoveToPoint(context, pt1.x, pt1.y);
		CGContextAddLineToPoint(context, pt2.x, pt2.y);
		
		CGContextAddArcToPoint(context, pt2.x + radius, pt2.y, pt4.x + radius, pt4.y, radius);
		CGContextAddArcToPoint(context, pt4.x + radius, pt4.y, pt4.x, pt4.y, radius);
		
		CGContextAddLineToPoint(context, pt3.x, pt3.y);
		
		CGContextAddArcToPoint(context, pt3.x - radius, pt3.y, pt1.x - radius, pt1.y, radius);
		CGContextAddArcToPoint(context, pt1.x - radius, pt1.y, pt1.x, pt1.y, radius);
	}
	
	CGContextClosePath(context);
	CGPathRef pathRef = CGContextCopyPath(context);
	CGContextClip(context);
	
	CGColorSpaceRef colorSpace = NULL;
	CGColorRef startColorRef, endColorRef;
	switch (_type) {
		case NavigationBarButtonTypeDone: {
			colorSpace = CGColorSpaceCreateDeviceRGB();
			startColorRef = CGColorCreateGenericRGB(0.776, 1., 0.53, 1.);
			endColorRef = CGColorCreateGenericRGB(0.286, 0.678, 0.125, 1.);
		}
			break;
		case NavigationBarButtonTypeDelete: {
			colorSpace = CGColorSpaceCreateDeviceRGB();
			startColorRef = CGColorCreateGenericRGB(1., 0.4, 0.4, 1.);
			endColorRef = CGColorCreateGenericRGB(0.9, 0.2, 0.2, 1.);
		}
			break;
		default: {
			colorSpace = CGColorSpaceCreateDeviceGray();
			startColorRef = CGColorCreateGenericGray(0.984, 1.);
			endColorRef = CGColorCreateGenericGray(0.953, 1.);
		}
			break;
	}
	
	CGFloat locations[2] = { 0., 1. };
	if (((NSCell *)self.cell).isHighlighted) { // Use a draker color when highlighted
		CGColorRef oldStartColorRef = startColorRef, oldEndColorRef = endColorRef;
		startColorRef = CGColorDarker(oldStartColorRef, 0.25), endColorRef = CGColorDarker(oldEndColorRef, 0.25);
		CGColorRelease(oldStartColorRef), CGColorRelease(oldEndColorRef);
	}
	
	CGColorRef values[2] = { startColorRef, endColorRef };
	CFArrayRef colors = CFArrayCreate(kCFAllocatorDefault, (const void **)values, 2, NULL);
	
	CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, colors, locations);
	CGColorRelease(startColorRef), CGColorRelease(endColorRef);
	CFRelease(colors);
	CGColorSpaceRelease(colorSpace);
	
	CGContextDrawLinearGradient(context, gradient, CGPointZero, CGPointMake(0., self.frame.size.height), 0);
	CGGradientRelease(gradient);
	
	/* Draw the stroke around the button */
	CGContextSetLineWidth(context, 2.);
	CGContextAddPath(context, pathRef);
	
	NSColor * textColor, * strokeColor;
	switch (_type) {
		case NavigationBarButtonTypeDone: {
			textColor = [NSColor colorWithDeviceRed:0.2 green:0.45 blue:0. alpha:1.];
			strokeColor = [NSColor colorWithDeviceRed:0.4 green:0.65 blue:0.165 alpha:1.];
		}
			break;
		case NavigationBarButtonTypeDelete: {
			strokeColor = textColor = [NSColor colorWithDeviceRed:0.5 green:0. blue:0. alpha:1.];
		}
			break;
		default: {
			textColor = (_textField.window.isKeyWindow) ? [NSColor darkGrayColor] : [NSColor grayColor];
			strokeColor = [NSColor colorWithCalibratedWhite:0.69 alpha:1.];
		}
			break;
	}
	_textField.textColor = textColor;
	[strokeColor setStroke];
	CGContextStrokePath(context);
	CGPathRelease(pathRef);
}


- (NSDragOperation)draggingEntered:(NSObject <NSDraggingInfo> *)sender
{
	[_navigationBar navigationBarButton:self didBeginDrag:sender];
	return [sender draggingSourceOperationMask];
}

- (BOOL)performDragOperation:(NSObject <NSDraggingInfo> *)sender
{
	[_navigationBar navigationBarButton:self didReceiveDrag:sender];
	return YES;
}

- (void)draggingExited:(NSObject <NSDraggingInfo> *)sender
{
	[_navigationBar navigationBarButton:self didEndDrag:sender];
}

@end

@implementation NavigationBar

@synthesize title = _title;
@synthesize textField = _textField;
@synthesize editable = _editable;
@synthesize leftBarButton = _leftBarButton, rightBarButton = _rightBarButton;
@synthesize delegate = _delegate;

- (BOOL)isFlipped
{
	return YES;
}

- (void)setTitle:(NSString *)title
{
	_title = title;
	
	if (!_textField) {
		CGFloat width = self.frame.size.width / 2.;
		CGFloat height = self.frame.size.height / 2. + 4.;
		NSRect frame = NSMakeRect(width / 2., height / 2. - 4., width, height);
		_textField = [[NSTextField alloc] initWithFrame:frame];
		_textField.autoresizingMask = (NSViewWidthSizable);
		[_textField setEditable:YES];
		[_textField setBezeled:YES];
		_textField.alignment = NSCenterTextAlignment;
		_textField.font = [NSFont boldSystemFontOfSize:16.];
		_textField.drawsBackground = YES;
		_textField.delegate = self;
		
		[_textField setHidden:YES];
		
		[self addSubview:_textField];
	}
	
	_textField.stringValue = _title;
}

- (void)setEditable:(BOOL)editable
{
	_editable = editable;
	
	_textField.hidden = !(editable); // Show the TextField when editable
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
	_title = _textField.stringValue;
	return YES;
}

#pragma - NavigationBarButton Delegate

- (void)navigationBarButton:(NavigationBarButton *)button didBeginDrag:(NSObject <NSDraggingInfo> *)sender
{
	if ([_delegate respondsToSelector:@selector(navigationBar:didBeginDragOnBarButton:)]) {
		[_delegate navigationBar:self didBeginDragOnBarButton:button];
	}
}

- (void)navigationBarButton:(NavigationBarButton *)button didReceiveDrag:(NSObject <NSDraggingInfo> *)sender
{
	if ([_delegate respondsToSelector:@selector(navigationBar:didDragItems:onBarButton:)]) {
		NSArray * items = [sender draggingPasteboard].pasteboardItems;
		[_delegate navigationBar:self didDragItems:items onBarButton:button];
	}
	
	/* Call the "didEndDrag..." delegate method */
	if ([_delegate respondsToSelector:@selector(navigationBar:didEndDragOnBarButton:)]) {
		[_delegate navigationBar:self didEndDragOnBarButton:button];
	}
}

- (void)navigationBarButton:(NavigationBarButton *)button didEndDrag:(NSObject <NSDraggingInfo> *)sender;
{
	if ([_delegate respondsToSelector:@selector(navigationBar:didEndDragOnBarButton:)]) {
		[_delegate navigationBar:self didEndDragOnBarButton:button];
	}
}

#pragma - NavigationBar Delegate

- (NSDragOperation)draggingEntered:(NSObject <NSDraggingInfo> *)sender
{
	if ([_delegate respondsToSelector:@selector(navigationBar:didBeginDragOnBarButton:)]) {
		[_delegate navigationBar:self didBeginDragOnBarButton:nil];
	}
	return [sender draggingSourceOperationMask];
}

- (NSDragOperation)draggingUpdated:(id < NSDraggingInfo >)sender
{
	NSView * draggedViewDestination = self;
	
	NSPoint location = [self convertPoint:[sender draggingLocation] fromView:self.window.contentView];;
	if (_leftBarButton && NSPointInRect(location, _leftBarButton.frame))
		draggedViewDestination = _leftBarButton;
	else if (_rightBarButton && NSPointInRect(location, _rightBarButton.frame))
		draggedViewDestination = _rightBarButton;
	
	if (draggedViewDestination != previousDraggedViewDestination) {
		if ([draggedViewDestination isKindOfClass:[NavigationBarButton class]])
			[draggedViewDestination draggingEntered:sender];
		else
			[previousDraggedViewDestination draggingExited:sender];
		
		previousDraggedViewDestination = draggedViewDestination;
	}
	
	return [sender draggingSourceOperationMask];
}

- (BOOL)performDragOperation:(NSObject <NSDraggingInfo> *)sender
{
	NSPoint location = [self convertPoint:[sender draggingLocation] fromView:self.window.contentView];;
	if (_leftBarButton && NSPointInRect(location, _leftBarButton.frame))
		return [_leftBarButton performDragOperation:sender];
	else if (_rightBarButton && NSPointInRect(location, _rightBarButton.frame))
		return [_rightBarButton performDragOperation:sender];
	
	if ([_delegate respondsToSelector:@selector(navigationBar:didDragItems:onBarButton:)]) {
		NSArray * items = [sender draggingPasteboard].pasteboardItems;
		NavigationBarButton * button = ([previousDraggedViewDestination isKindOfClass:[NavigationBarButton class]]) ? (NavigationBarButton *)previousDraggedViewDestination : nil;
		[_delegate navigationBar:self didDragItems:items onBarButton:button];
	}
	return YES;
}

- (void)draggingExited:(NSObject <NSDraggingInfo> *)sender
{
	previousDraggedViewDestination = nil;
	
	if ([_delegate respondsToSelector:@selector(navigationBar:didEndDragOnBarButton:)]) {
		[_delegate navigationBar:self didEndDragOnBarButton:nil];
	}
}

#pragma - NavigationBarButton Set

- (void)setLeftBarButton:(NavigationBarButton *)leftBarButton
{
	self.leftBarButtons = @[ leftBarButton ];
}

- (void)setRightBarButton:(NavigationBarButton *)rightBarButton
{
	self.rightBarButtons = @[ rightBarButton ];
}

#define kButtonMargin 10.

- (void)setLeftBarButtons:(NSArray *)leftBarButtons
{
	[_leftBarButtons valueForKey:@"removeFromSuperview"];
	_leftBarButtons = leftBarButtons;
	
	CGFloat x = kButtonMargin;
	for (NavigationBarButton * button in leftBarButtons) {
		button.navigationBar = self;
		
		CGFloat y = (self.frame.size.height - button.frame.size.height) / 2.;
		NSRect rect = button.frame;
		rect.origin = NSMakePoint(x, (int)y);
		button.frame = rect;
		[self addSubview:button];
		
		x += rect.size.width + kButtonMargin;
	}
}

- (void)setRightBarButtons:(NSArray *)rightBarButtons
{
	[_rightBarButtons valueForKey:@"removeFromSuperview"];
	_rightBarButtons = rightBarButtons;
	
	CGFloat x = self.frame.size.width - kButtonMargin;
	for (NavigationBarButton * button in rightBarButtons) {
		button.navigationBar = self;
		
		CGFloat y = (self.frame.size.height - button.frame.size.height) / 2.;
		NSRect rect = button.frame;
		rect.origin = NSMakePoint(x - rect.size.width, (int)y);
		button.frame = rect;
		button.autoresizingMask = (NSViewMinXMargin);
		[self addSubview:button];
		
		x -= (rect.size.width + kButtonMargin);
	}
}

#undef kButtonMargin

#pragma - DrawRect

- (void)drawRect:(NSRect)dirtyRect
{
	/* Draw the background image */
	if (!backgroundImage) {
		NSImage * image = [NSImage imageNamed:@"navigation-bar-background"];
		backgroundImage = [image CGImageForProposedRect:NULL
												context:[NSGraphicsContext currentContext]
												  hints:nil];
		CGImageRetain(backgroundImage);
	}
	CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;
	
	[NSGraphicsContext saveGraphicsState];
	{
		CGContextTranslateCTM(context, self.bounds.size.width, self.bounds.size.height);
		CGContextRotateCTM(context, M_PI);
		CGContextDrawImage(context, self.bounds, backgroundImage);
	}
	[NSGraphicsContext restoreGraphicsState];
	
	/* Draw the title */
	[NSGraphicsContext saveGraphicsState];
	{
		CGContextSetTextMatrix(context, CGAffineTransformMakeScale(1., -1.)); // Flip the text from the actual not flipped view setting (flipping by the y axis)
		
		const CGFloat fontHeight = 18.;
		NSString * systemFontName = [NSFont boldSystemFontOfSize:10.].fontName;
		CGContextSelectFont(context, systemFontName.UTF8String, fontHeight, kCGEncodingMacRoman);
		
		const char * string = _title.UTF8String;
		const unsigned long length = strlen(string);
		
		CGPoint oldPosition = CGContextGetTextPosition(context);
		CGContextSetTextDrawingMode(context, kCGTextInvisible); // Draw the text invisible to get the position
		CGContextShowTextAtPoint(context, oldPosition.x, oldPosition.y, string, length);
		CGPoint newPosition = CGContextGetTextPosition(context); // Get the position
		
		CGSize textSize = CGSizeMake(newPosition.x - oldPosition.x, newPosition.y - oldPosition.y);
		
		CGFloat textX = self.bounds.size.width / 2. - textSize.width / 2.;
		CGFloat textY = self.bounds.size.height / 1.5;
		
		[[NSColor darkGrayColor] setFill];
		CGContextSetTextDrawingMode(context, kCGTextFill);
		
		CGContextShowTextAtPoint(context, textX, textY, string, length);
	}
	[NSGraphicsContext restoreGraphicsState];
}

@end
