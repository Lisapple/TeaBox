//
//  DefaultDragOperationWindow.m
//  Tea Box
//
//  Created by Max on 14/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "DefaultDragOperationWindow.h"

@implementation DefaultDragOperationWindow

@synthesize choiceMatrix = _choiceMatrix;

- (IBAction)okAction:(id)sender
{
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	
	NSString * dragOperation = nil;
	switch (_choiceMatrix.selectedRow) {
		case 1:
			dragOperation = @"Copy";
			break;
		case 2:
			dragOperation = @"Link";
			break;
		case 0:
		default:
			dragOperation = @"Move";
			break;
	}
	
	[userDefaults setObject:dragOperation forKey:@"Default-Drag-Operation"];
	
	[NSApp endSheet:self returnCode:NSOKButton];
	[self orderOut:nil];
}

- (IBAction)cancelAction:(id)sender
{
	[NSApp endSheet:self returnCode:NSCancelButton];
	[self orderOut:nil];
}

@end
