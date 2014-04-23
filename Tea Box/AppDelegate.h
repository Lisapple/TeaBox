//
//  AppDelegate.h
//  Tea Box
//
//  Created by Max on 03/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CommonCrypto/CommonDigest.h>

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#import "NavigationController.h"
#import "MainViewController.h"
#import "ProjectViewController.h"

#import "MainWindow.h"

#import "TBLibrary.h"

enum _MainMenuItemTag {
	MainMenuItemNew = 100,
	MainMenuItemImport = 200,
	MainMenuItemImportImage,
	MainMenuItemImportWebLink,
	MainMenuItemImportText,
	MainMenuItemImportFilesAndFolders,
	MainMenuItemExport = 300
};

@class MainViewController;

@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, NavigationControllerDelegate>
{
	BOOL showingProjectViewController;
}

@property (unsafe_unretained) IBOutlet MainWindow * window, * aboutWindow, * preferencesWindow;
@property (unsafe_unretained) IBOutlet MainViewController * mainViewController;
@property (unsafe_unretained) IBOutlet ProjectViewController * projectViewController;

@property (unsafe_unretained) IBOutlet NSMenuItem * mainWindowMenuItem;

+ (AppDelegate *)app;

- (IBAction)openPreferencesAction:(id)sender;

- (void)startBrowsingSharedProjects;
- (void)startPublishingSharedProjects;

- (IBAction)makeMainWindowKey:(id)sender;
- (IBAction)showAboutWindowAction:(id)sender;

- (IBAction)moveDefaultLibrary:(id)sender;
- (IBAction)reloadTableViewAction:(id)sender;

@end
