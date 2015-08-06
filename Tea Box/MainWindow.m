//
//  MainWindow.m
//  Tea Box
//
//  Created by Max on 19/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "MainWindow.h"

@implementation MainContentView

- (instancetype)initWithCoder:(NSCoder *)aDecoder
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
	[[NSColor colorWithCalibratedWhite:(243. / 255.) alpha:1.] setFill];
	NSRectFill(dirtyRect);
}

@end


@implementation MainWindow

- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
	if ((self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag])) {
		[self setOpaque:NO];
		self.backgroundColor = [NSColor colorWithDeviceWhite:(243. / 255.) alpha:1.];
	}
	return self;
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
	return [sender draggingSourceOperationMask];
}

- (void)draggingExited:(id < NSDraggingInfo >)sender
{
}

@end
