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
	[self.sheetParent endSheet:self returnCode:NSModalResponseCancel];
	[self orderOut:nil];
}

- (IBAction)okAction:(id)sender
{
	[self.sheetParent endSheet:self returnCode:NSModalResponseOK];
	[self orderOut:nil];
}

@end
