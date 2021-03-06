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
	
	const CGFloat factor = 0.333f * intensity;
	CGFloat newComps[count];
	memcpy(newComps, comps, count);
	for (int i = 0; i < (count - 1 /* Skip alpha channel */); i++)
		newComps[i] -= newComps[i] * factor;
	
	CGColorSpaceRef colorSpace = CGColorGetColorSpace(colorRef);
	return CGColorCreate(colorSpace, newComps);
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
		_textField.alignment = NSTextAlignmentCenter;
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

- (BOOL)isFlipped
{
	return YES;
}

- (void)setTitle:(NSString *)title
{
	_title = title;
	
	const CGSize size = CGSizeMake(self.frame.size.width / 2., self.frame.size.height / 2. + 4.);
	
	if (!_titleLabel) {
		NSRect frame = NSMakeRect(size.width / 2., size.height / 2. - 4., size.width, size.height);
		_titleLabel = [[NSTextField alloc] initWithFrame:frame];
		_titleLabel.autoresizingMask = (NSViewWidthSizable);
		_titleLabel.editable = NO;
		_titleLabel.bezeled = NO;
		_titleLabel.alignment = NSTextAlignmentCenter;
		_titleLabel.font = [NSFont boldSystemFontOfSize:18.];
		_titleLabel.textColor = [NSColor darkGrayColor];
		_titleLabel.drawsBackground = NO;
		if ([_titleLabel respondsToSelector:@selector(setLineBreakMode:)]) { // macOS 10.10+
			_titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
			_titleLabel.usesSingleLineMode = YES;
		}
		if ([_titleLabel respondsToSelector:@selector(setAllowsDefaultTighteningForTruncation:)]) // macOS 10.11+
			_titleLabel.allowsDefaultTighteningForTruncation = YES;
		
		[self addSubview:_titleLabel];
	}
	_titleLabel.stringValue = _title;
	
	if (!_textField) {
		NSRect frame = NSMakeRect(size.width / 2., size.height / 2. - 4., size.width, size.height);
		_textField = [[NSTextField alloc] initWithFrame:frame];
		_textField.autoresizingMask = (NSViewWidthSizable);
		_textField.editable = YES;
		_textField.bezeled = YES;
		_textField.alignment = NSTextAlignmentCenter;
		_textField.font = [NSFont boldSystemFontOfSize:16.];
		_textField.drawsBackground = YES;
		_textField.delegate = self;
		[self addSubview:_textField];
		[_textField setHidden:YES];
	}
	
	_textField.stringValue = _title;
	[self updateLayout];
}

- (void)setEditable:(BOOL)editable
{
	_editable = editable;
	
	_textField.hidden = !(editable); // Show the TextField when editable
	_titleLabel.hidden = !(_textField.hidden);
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
		NSArray <NSPasteboardItem *> * items = [sender draggingPasteboard].pasteboardItems;
		[_delegate navigationBar:self didDragItems:items onBarButton:button];
	}
	
	/* Call the "didEndDrag..." delegate method */
	if ([_delegate respondsToSelector:@selector(navigationBar:didEndDragOnBarButton:)])
		[_delegate navigationBar:self didEndDragOnBarButton:button];
}

- (void)navigationBarButton:(NavigationBarButton *)button didEndDrag:(NSObject <NSDraggingInfo> *)sender;
{
	if ([_delegate respondsToSelector:@selector(navigationBar:didEndDragOnBarButton:)])
		[_delegate navigationBar:self didEndDragOnBarButton:button];
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
		NSArray <NSPasteboardItem *> * items = [sender draggingPasteboard].pasteboardItems;
		NavigationBarButton * button = ([previousDraggedViewDestination isKindOfClass:[NavigationBarButton class]]) ? (NavigationBarButton *)previousDraggedViewDestination : nil;
		[_delegate navigationBar:self didDragItems:items onBarButton:button];
	}
	return YES;
}

- (void)draggingExited:(NSObject <NSDraggingInfo> *)sender
{
	previousDraggedViewDestination = nil;
	
	if ([_delegate respondsToSelector:@selector(navigationBar:didEndDragOnBarButton:)])
		[_delegate navigationBar:self didEndDragOnBarButton:nil];
}

#pragma - NavigationBarButton Set

- (void)setLeftBarButton:(NavigationBarButton *)leftBarButton
{
	if (leftBarButton) self.leftBarButtons = @[ leftBarButton ];
}

- (void)setRightBarButton:(NavigationBarButton *)rightBarButton
{
	if (rightBarButton) self.rightBarButtons = @[ rightBarButton ];
}

#define kButtonMargin 10.

- (void)setLeftBarButtons:(NSArray <NavigationBarButton *> *)leftBarButtons
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
	[self updateLayout];
}

- (void)setRightBarButtons:(NSArray <NavigationBarButton *> *)rightBarButtons
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
		
		x -= rect.size.width + kButtonMargin;
	}
	[self updateLayout];
}

#undef kButtonMargin

#pragma - Layout

- (void)updateLayout
{
	const CGRect rightMostLeftButtonFrame = _leftBarButtons.lastObject.frame;
	const CGFloat leftTitleMargin = rightMostLeftButtonFrame.origin.x + rightMostLeftButtonFrame.size.width + 8.;
	
	const CGRect leftMostRightButtonFrame = _rightBarButtons.lastObject.frame;
	const CGFloat rightTitleMargin = self.frame.size.width - leftMostRightButtonFrame.origin.x + 8.;
	
	const CGFloat y = _titleLabel.frame.origin.y;
	[_titleLabel sizeToFit];
	const CGFloat width = self.frame.size.width - MAX(leftTitleMargin, rightTitleMargin) * 2;
	_titleLabel.frame = CGRectMake(CGRectGetMidX(self.frame) - width / 2, y, width, _titleLabel.frame.size.height);
}

- (void)drawRect:(NSRect)dirtyRect
{
	// Draw the background image
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
}

@end
