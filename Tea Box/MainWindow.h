//
//  MainWindow.h
//  Tea Box
//
//  Created by Max on 19/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface MainContentView : NSView
{
	NSView * subcontentView;
}

- (void)addView:(NSView *)aView;

@end

@interface MainWindow : NSWindow

- (void)reloadData;
- (void)addSubview:(NSView *)aView;

@end
