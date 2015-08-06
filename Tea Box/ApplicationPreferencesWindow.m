//
//  ApplicationPreferencesWindow.m
//  Tea Box
//
//  Created by Maxime on 08/01/13.
//  Copyright (c) 2013 Lis@cintosh. All rights reserved.
//

#import "ApplicationPreferencesWindow.h"

#import "TBLibrary.h"

@implementation ApplicationPreferencesWindow

@synthesize pathControl = _pathControl;
@synthesize defaultActionPopUpButton = _defaultActionPopUpButton;
@synthesize showPathForLinkedItemsButton = _showPathForLinkedItemsButton;

- (void)reloadData
{
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	
	/* Update the default choice pop up button */
	NSString * defaultChoice = [userDefaults objectForKey:@"Default-Drag-Operation"];
	if (defaultChoice) {// For "Copy", "Move" and "Link"
		[_defaultActionPopUpButton selectItemWithTitle:defaultChoice];
	} else {// For "Ask Next Time"
		[_defaultActionPopUpButton selectItemAtIndex:0];
	}
	
	/* Update the option to show path for linked items */
	_showPathForLinkedItemsButton.state = ([userDefaults boolForKey:@"Show Path For Linked Items"])? NSOnState : NSOffState;
	
	/* Update the button for the location of the library */
	NSString * rootPath = [[TBLibrary defaultLibrary].path stringByDeletingLastPathComponent];
	_pathControl.URL = [NSURL fileURLWithPath:rootPath];
	
	_pathControl.target = self;
	_pathControl.action = @selector(pathControlDidSelectPath:);
}

- (IBAction)pathControlDidSelectPath:(id)sender
{
	selectedURL = _pathControl.URL.copy;
	if (selectedURL) {
		_pathControl.enabled = NO;
		NSString * libraryName = [TBLibrary defaultLibrary].path.lastPathComponent;
		[[TBLibrary defaultLibrary] moveLibraryToPath:[selectedURL.path stringByAppendingFormat:@"/%@", libraryName]
												error:NULL];
		_pathControl.enabled = YES;
	}
}

- (IBAction)defaultDragMenuDidSelect:(id)sender
{
	NSMenuItem * menuItem = (NSMenuItem *)sender;
	NSString * defaultChoice = menuItem.title;
	
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	if ([defaultChoice isEqualToString:@"Copy"]) {
		[userDefaults setObject:@"Copy" forKey:@"Default-Drag-Operation"];
	} else if ([defaultChoice isEqualToString:@"Move"]) {
		[userDefaults setObject:@"Move" forKey:@"Default-Drag-Operation"];
	} else if ([defaultChoice isEqualToString:@"Link"]) {
		[userDefaults setObject:@"Link" forKey:@"Default-Drag-Operation"];
	} else {// "Ask Next Time"
		[userDefaults removeObjectForKey:@"Default-Drag-Operation"];
	}
	[userDefaults synchronize];
}

- (IBAction)setShowsPathForLinkedItemsAction:(id)sender
{
	NSButton * button = (NSButton *)sender;
	
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setBool:(button.state == NSOnState) forKey:@"Show Path For Linked Items"];
	[userDefaults synchronize];
}

- (IBAction)resetAlertsAction:(id)sender
{
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults removeObjectForKey:@"Alerts to Hide"];
	[userDefaults synchronize];
}

- (IBAction)showHelpAction:(id)sender
{
	NSString * helpBookName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleHelpBookName"];
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"settings" inBook:helpBookName];
}

@end
