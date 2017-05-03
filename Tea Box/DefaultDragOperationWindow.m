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
			dragOperation = @"Copy"; break;
		case 2:
			dragOperation = @"Link"; break;
		case 0:
		default:
			dragOperation = @"Move"; break;
	}
	
	[userDefaults setObject:dragOperation forKey:@"Default-Drag-Operation"];
	[userDefaults synchronize];
	
	[self.sheetParent endSheet:self returnCode:NSModalResponseOK];
	[self orderOut:nil];
}

- (IBAction)cancelAction:(id)sender
{
	[self.sheetParent endSheet:self returnCode:NSModalResponseCancel];
	[self orderOut:nil];
}

@end
