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
	[self.parentWindow endSheet:self returnCode:NSModalResponseCancel];
	[self orderOut:nil];
}

- (IBAction)okAction:(id)sender
{
	[self.parentWindow endSheet:self returnCode:NSModalResponseOK];
	[self orderOut:nil];
}

@end
