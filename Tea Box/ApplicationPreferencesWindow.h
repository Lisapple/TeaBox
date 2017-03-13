//
//  ApplicationPreferencesWindow.h
//  Tea Box
//
//  Created by Maxime on 08/01/13.
//  Copyright (c) 2013 Lis@cintosh. All rights reserved.
//

#import "MainWindow.h"

@interface ApplicationPreferencesWindow : MainWindow
{
	NSURL * selectedURL;
}

@property (unsafe_unretained) IBOutlet NSPathControl * pathControl;

@property (unsafe_unretained) IBOutlet NSPopUpButton * defaultActionPopUpButton;
@property (unsafe_unretained) IBOutlet NSButton * showPathForLinkedItemsButton;

- (IBAction)pathControlDidSelectPath:(id)sender;
- (IBAction)showHelpAction:(id)sender;

@end
