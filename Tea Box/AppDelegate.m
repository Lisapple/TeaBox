//
//  AppDelegate.m
//  Tea Box
//
//  Created by Max on 03/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "AppDelegate.h"

@import Fabric;
@import Crashlytics;

#import "NSAlert+additions.h"

@implementation AppDelegate

+ (AppDelegate *)app
{
	return (AppDelegate *)[NSApplication sharedApplication].delegate;
}

- (void)databaseDidUpdate:(NSString *)filename
{
	NSLog(@"database did update at %@", filename);
	//[self reloadTableViewAction:nil];
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	[Fabric with:@[ Crashlytics.class ]];
	
	[NavigationController addDelegate:self];
	showingProjectViewController = NO;
	
	// Check if the default library is valid:
	// - If the library doesn't exist at path, ask the user to locate a new library or create a new one
	// - If the library exist but the database is not valid, try to get a backup of the data, if no backup valid (or found),
	//		show an error and ask the user to re-create the database (by clicking on a button on an alert).
	
	BOOL firstLaunch = ([[NSUserDefaults standardUserDefaults] stringForKey:@"last-launch-app-version"] == nil);
	TBLibrary * defaultLibrary = [TBLibrary defaultLibrary];
	if (!defaultLibrary) {
		if (firstLaunch) { // Show Tutorial
			
			// On tutorial close or skip: close the tutorial and create a default library
			// On tutorial on choose: Load the choosen library or create a new one
			
			_tutorialWindow.completionHandler = ^(NSURL * choosenURL, BOOL skipped) {
				NSString * path = nil;
				if (choosenURL) {
					path = [choosenURL.path stringByAppendingString:@"/Library.teaboxdb"];
				} else {
					NSString * documentPath = DefaultPathForDirectory(NSDocumentDirectory);
					path = [documentPath stringByAppendingString:@"/Library.teaboxdb"];
				}
				NSAssert1(path != nil, @"No path can be get from %@", choosenURL);
				
				// Copy the default library
				NSURL * const defaultLibraryURL = [[NSBundle mainBundle] URLForResource:@"Default Library/Library" withExtension:@"teaboxdb"];
				BOOL success = [[NSFileManager defaultManager] copyItemAtPath:defaultLibraryURL.path toPath:path error:nil];
				
				if (success) // If copy fails, create an empty one
					[TBLibrary createLibraryAtPath:path name:@"com.lisacintosh.teabox.default-library"];
				
				NSURLBookmarkCreationOptions bookmarkOptions = 0;
#if _SANDBOX_SUPPORTED_
				bookmarkOptions = NSURLBookmarkCreationWithSecurityScope;
#endif
				NSError * error = nil;
				NSData * bookmarkData = [[NSURL fileURLWithPath:path] bookmarkDataWithOptions:bookmarkOptions
															   includingResourceValuesForKeys:nil
																				relativeToURL:nil error:&error];
				if (bookmarkData) {
					NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
					[userDefaults setObject:bookmarkData forKey:kLibraryBookmarkDataKey];
				} else {
					// @TODO: present the error on fail
				}
				
				NSString * version = [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
				[[NSUserDefaults standardUserDefaults] setObject:version forKey:@"last-launch-app-version"];
				
				[NavigationController pushViewController:_mainViewController animated:NO];
				self.window.delegate = self;
				[self.window makeKeyAndOrderFront:nil]; // Order front the window only after loading the navigationController and the main viewController
			};
			[_tutorialWindow makeKeyAndOrderFront:nil];
			return ;
			
		} else { // Ask for user what to do (create a new library or choose an existing, or quit)
			
			NSAlert * alert = [NSAlert alertWithStyle:NSAlertStyleWarning
										  messageText:@"No Library Founds"
									  informativeText:@"The default Tea Box library can't be found. Do you want to use an existing library or create a new empty one?"
										 buttonTitles:@[ @"Create New", @"Quit", @"Choose Library..." ]];
			
			NSInteger returnCode = [alert runModal];
			if (returnCode == NSAlertThirdButtonReturn/*Choose Library*/) {
				
				NSOpenPanel * openPanel = [NSOpenPanel openPanel];
				openPanel.allowsMultipleSelection = NO;
				openPanel.allowedFileTypes = @[ @"teaboxdb" ];
				openPanel.prompt = @"Open";
				if ([openPanel runModal] == NSFileHandlingPanelOKButton) {
					NSString * path = openPanel.URL.path;
					[TBLibrary createLibraryAtPath:path name:@"com.lisacintosh.teabox.default-library"];
					
					NSURLBookmarkCreationOptions bookmarkOptions = 0;
#if _SANDBOX_SUPPORTED_
					bookmarkOptions = NSURLBookmarkCreationWithSecurityScope;
#endif
					NSData * bookmarkData = [openPanel.URL bookmarkDataWithOptions:bookmarkOptions
													includingResourceValuesForKeys:nil
																	 relativeToURL:nil
																			 error:NULL];
					if (bookmarkData) {
						NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
						[userDefaults setObject:bookmarkData forKey:kLibraryBookmarkDataKey];
					} else {
						// @TODO: present the error on fail
					}
					
				} else {
					[NSApp terminate:nil];
				}
			} else if (returnCode == NSAlertFirstButtonReturn/*Create New*/) {
				/* Create a new library with a database get from the application bundle */
				NSString * documentPath = DefaultPathForDirectory(NSDocumentDirectory);
				NSString * path = [documentPath stringByAppendingString:@"/Library.teaboxdb"];
				
				// Copy the default library
				NSURL * const defaultLibraryURL = [[NSBundle mainBundle] URLForResource:@"Default Library/Library" withExtension:@"teaboxdb"];
				[[NSFileManager defaultManager] copyItemAtPath:defaultLibraryURL.path toPath:path error:nil];
				
				[TBLibrary createLibraryAtPath:path name:@"com.lisacintosh.teabox.default-library"];
				
			} else { // "Quit"
				[NSApp terminate:nil];
			}
		}
	}
	
	NSString * version = [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
	[[NSUserDefaults standardUserDefaults] setObject:version forKey:@"last-launch-app-version"];
	
	self.window.delegate = self;
	[self.window makeKeyAndOrderFront:nil]; // Order front the window only after loading the navigationController and the main viewController
	[NavigationController pushViewController:_mainViewController animated:NO];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	/*
	 NSDictionary * infoDictionary = [[NSBundle mainBundle] infoDictionary];
	 NSLog(@"Library Database Version = %@", [infoDictionary objectForKey:@"TBLibraryDatabaseVersion"]);
	 */
	
	BOOL registered = [[NSHelpManager sharedHelpManager] registerBooksInBundle:[NSBundle mainBundle]];
	if (!registered)
		NSLog(@"help not registered!");
	
	//[self startBrowsingSharedProjects];
	//[self startPublishingSharedProjects];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
	if (!flag) {
		[_window orderFront:nil];
		[_window makeKeyWindow];
	}
	
	return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	if (![[TBLibrary defaultLibrary] save])
		NSLog(@"Error saving library at %@", [TBLibrary defaultLibrary].path);
	
	return NSTerminateNow;
}

#pragma mark - Actions

- (IBAction)openPreferencesAction:(id)sender
{
	[_preferencesWindow makeKeyAndOrderFront:sender];
}

- (IBAction)openWebsiteAction:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://lisacintosh.com/tea-box/"]];
}

- (IBAction)openSupportAction:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://support.lisacintosh.com/tea-box/"]];
}

- (void)toogleExportMenuItemState:(NSNotification *)notification
{
	NSMenu * fileMenu = [NSApp.mainMenu itemAtIndex:1].submenu;
	
	/* Enable "File > Export..." */
	BOOL cellSelected = ([((TableView *)notification.object) indexPathOfSelectedRow] != nil);
	[fileMenu itemWithTag:MainMenuItemExport].enabled = cellSelected;
}

#pragma mark - NavigationController Delegate

- (void)navigationControllerDidPushViewController:(NSViewController *)viewController animated:(BOOL)animated
{
	/* When the navigation controller push the project view controller, we are into the "projectViewController" */
	if (viewController == _projectViewController) {
		NSMenu * fileMenu = [NSApp.mainMenu itemAtIndex:1].submenu;
		NSMenu * importMenu = [fileMenu itemWithTag:MainMenuItemImport].submenu;
		
		/* Change the main menu "File > New Step..." */
		NSMenuItem * newMenuItem = [fileMenu itemWithTag:MainMenuItemNew];
		newMenuItem.title = @"New Step...";
		newMenuItem.target = _projectViewController;
		newMenuItem.action = @selector(newStepAction:);
		
		/* Enable the menu "File > Import" */
		[[importMenu itemWithTag:MainMenuItemImportImage] setEnabled:YES];
		[[importMenu itemWithTag:MainMenuItemImportWebLink] setEnabled:YES];
		[[importMenu itemWithTag:MainMenuItemImportText] setEnabled:YES];
		[[importMenu itemWithTag:MainMenuItemImportFilesAndFolders] setEnabled:YES];
		
		/* Enable "File > Export..." */
		[[fileMenu itemWithTag:MainMenuItemExport] setEnabled:NO];
		
		NSNotificationCenter * dc = [NSNotificationCenter defaultCenter];
		[dc removeObserver:self name:@"TableViewDidSelectCell" object:nil];
		[dc addObserver:self
			   selector:@selector(toogleExportMenuItemState:)
				   name:@"TableViewDidSelectCell"
				 object:nil];
		
		showingProjectViewController = YES;
	}
}

- (void)navigationControllerDidPopViewController:(NSViewController *)viewController animated:(BOOL)animated
{
	/* When the navigation controller pop to the main view controller, we are into the "mainViewController" */
	if (viewController == _projectViewController) {
		NSMenu * fileMenu = [NSApp.mainMenu itemAtIndex:1].submenu;
		NSMenu * importMenu = [fileMenu itemWithTag:MainMenuItemImport].submenu;
		
		/* Change the main menu "File > New Project..." */
		NSMenuItem * newMenuItem = [fileMenu itemWithTag:MainMenuItemNew];
		newMenuItem.title = @"New Project...";
		newMenuItem.target = _mainViewController;
		newMenuItem.action = @selector(newProjectAction:);
		
		/* Disable the menu "File > Import" */
		[[importMenu itemWithTag:MainMenuItemImportImage] setEnabled:NO];
		[[importMenu itemWithTag:MainMenuItemImportWebLink] setEnabled:NO];
		[[importMenu itemWithTag:MainMenuItemImportText] setEnabled:NO];
		[[importMenu itemWithTag:MainMenuItemImportFilesAndFolders] setEnabled:NO];
		
		/* Disable the menu "File > Export..." */
		[[fileMenu itemWithTag:MainMenuItemExport] setEnabled:YES];
		
		showingProjectViewController = NO;
		
		/* Deselect the selected row of the tableView */
		[_mainViewController.tableView deselectSelectedRowAnimated:YES];
	}
}

- (IBAction)makeMainWindowKey:(id)sender
{
	[_window makeKeyAndOrderFront:sender];
}

- (IBAction)showAboutWindowAction:(id)sender
{
	[_aboutWindow makeKeyAndOrderFront:sender];
}

#pragma mark - NSWindow Delegate

- (void)windowDidBecomeKey:(NSNotification *)notification
{
	self.mainWindowMenuItem.state = NSOnState;
}

- (void)windowDidResignKey:(NSNotification *)notification
{
	self.mainWindowMenuItem.state = NSOffState;
}

#pragma mark - QLPreviewPanelController

- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel;
{
	return showingProjectViewController;
}

- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel
{
	panel.delegate = _projectViewController;
	panel.dataSource = _projectViewController;
	[panel reloadData];
}

- (void)endPreviewPanelControl:(QLPreviewPanel *)panel
{
}

#pragma mark - Actions

- (IBAction)moveDefaultLibrary:(id)sender
{
	NSSavePanel * savePanel = [NSSavePanel savePanel];
	savePanel.title = @"Choose the new location to move the default library:";
	savePanel.prompt = @"Move";
	savePanel.allowedFileTypes = @[@"teaboxdb"];
	
	NSString * libraryFilename = [TBLibrary defaultLibrary].path.lastPathComponent;
	savePanel.nameFieldStringValue = libraryFilename;
	
	[savePanel beginSheetModalForWindow:self.window
					  completionHandler:^(NSInteger result) {
						  NSString * newPath = savePanel.URL.path;
						  BOOL success = [[TBLibrary defaultLibrary] moveLibraryToPath:newPath
																				 error:nil];
						  if (!success) {
							  NSLog(@"error when moving default library to path: %@", newPath);
							  return;
						  }
					  }];
}

@end
