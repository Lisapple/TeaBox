//
//  SheetWindow.m
//  Tea Box
//
//  Created by Max on 26/08/15.
//
//

#import "SheetWindow.h"

@implementation SheetWindow

- (IBAction)cancelAction:(id)sender
{
	[NSApp endSheet:self returnCode:NSCancelButton];
	[self orderOut:nil];
}

- (IBAction)okAction:(id)sender
{
	[NSApp endSheet:self returnCode:NSOKButton];
	[self orderOut:nil];
}

@end
