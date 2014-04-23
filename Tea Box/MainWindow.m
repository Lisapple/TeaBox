//
//  MainWindow.m
//  Tea Box
//
//  Created by Max on 19/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "MainWindow.h"

@implementation MainContentView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        // Initialization code here.
		
		NSRect contentRect = self.frame;
		subcontentView = [[NSView alloc] initWithFrame:contentRect];
		subcontentView.autoresizingMask = (NSViewWidthSizable | NSViewHeightSizable);
		[self addSubview:subcontentView];
    }
    
    return self;
}

- (void)addView:(NSView *)aView
{
	NSRect frame = aView.frame;
	frame.size = subcontentView.frame.size;
	aView.frame = frame;
	[subcontentView addSubview:aView];
}

- (void)drawRect:(NSRect)dirtyRect
{
#if 0
	[[NSColor clearColor] setFill];
    NSRectFill(dirtyRect);
	
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
	
	CGContextBeginPath(context);
	
	float width = self.frame.size.width;
	float height = self.frame.size.height;
	float radius = 2.;//4.;
	
	/* Draw the window */
	CGFloat x = 0., y = 0.;
	/*  pt1 ---------- pt2  */
	/*	 |    WINDOW    |   */
	/*  pt3 ---------- pt4  */
	
	CGPoint pt1 = CGPointMake(x + radius, y + height);
	CGPoint pt2 = CGPointMake(x + width - radius, y + height);
	CGPoint pt3 = CGPointMake(x + radius, y);
	CGPoint pt4 = CGPointMake(x + width - radius, y);
	
	CGContextMoveToPoint(context, pt1.x, pt1.y);
	CGContextAddLineToPoint(context, pt2.x, pt2.y);
	
	CGContextAddArcToPoint(context, pt2.x + radius, pt2.y, pt4.x + radius, pt4.y, 0.);
	CGContextAddArcToPoint(context, pt4.x + radius, pt4.y, pt4.x, pt4.y, radius);
	
	CGContextAddLineToPoint(context, pt3.x, pt3.y);
	
	CGContextAddArcToPoint(context, pt3.x - radius, pt3.y, pt1.x - radius, pt1.y, radius);
	CGContextAddArcToPoint(context, pt1.x - radius, pt1.y, pt1.x, pt1.y, 0.);
	CGContextClip(context);
#endif
	
	[[NSColor colorWithCalibratedWhite:(243. / 255.) alpha:1.] setFill];
	NSRectFill(dirtyRect);
}

@end


@implementation MainWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
	if ((self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag])) {
		[self setOpaque:NO];
		self.backgroundColor = [NSColor colorWithDeviceWhite:(243. / 255.) alpha:1.];//[NSColor colorWithPatternImage:[NSImage imageNamed:@"title-bar"]];
		
		//[self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
		
		/*
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:<#(SEL)#>
													 name:NSWindowDidBecomeKeyNotification
												   object:nil];
		*/
	}
	return self;
}

- (void)becomeKeyWindow
{
	[super becomeKeyWindow];
	
	//self.backgroundColor = [NSColor colorWithPatternImage:[NSImage imageNamed:@"title-bar-active"]];//[NSImage imageNamed:@"background-main-view"];
}

- (void)resignKeyWindow
{
	[super resignKeyWindow];
	
	//self.backgroundColor = [NSColor colorWithPatternImage:[NSImage imageNamed:@"title-bar"]];
}

- (void)reloadData
{
    
}

- (void)addSubview:(NSView *)aView
{
	[(MainContentView *)self.contentView addView:aView];
}

- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender
{
	NSLog(@"draggingEntered");
	return [sender draggingSourceOperationMask];
}

- (void)draggingExited:(id < NSDraggingInfo >)sender
{
	NSLog(@"draggingExited");
}

@end
