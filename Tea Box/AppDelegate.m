//
//  AppDelegate.m
//  Tea Box
//
//  Created by Max on 03/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "AppDelegate.h"

#import "JSONKit.h"

#define kServiceName @"_teabox._tcp."

@implementation AppDelegate

+ (AppDelegate *)app
{
	return (AppDelegate *)[NSApplication sharedApplication].delegate;
}

@synthesize window = _window, aboutWindow = _aboutWindow, preferencesWindow = _preferencesWindow;
@synthesize mainViewController = _mainViewController, projectViewController = _projectViewController;

@synthesize mainWindowMenuItem = _mainWindowMenuItem;

- (void)databaseDidUpdate:(NSString *)filename
{
	NSLog(@"database did update at %@", filename);
	//[self reloadTableViewAction:nil];
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	[NavigationController pushViewController:_mainViewController animated:NO];
	
	[NavigationController addDelegate:self];
	showingProjectViewController = NO;
	
	// Check if the default library is valid:
	// - If the library doesn't exist at path, ask the user to locate a new library or create a new one
	// - If the library exist but the database is not valid, try to get a backup of the data, if no backup valid (or found),
	//		show an error and ask the user to re-create the database (by clicking on a button on an alert).
	
	TBLibrary * defaultLibrary = [TBLibrary defaultLibrary];
	if (!defaultLibrary) {
		NSAlert * alert = [NSAlert alertWithMessageText:@"No Library Founds"
										  defaultButton:@"Choose Library..."
										alternateButton:@"Create New"
											otherButton:@"Quit"
							  informativeTextWithFormat:@"The default Tea Box library can't be found. Do You want to use an existing library or create a new empty one?"];
		
		NSInteger returnCode = [alert runModal];
		if (returnCode == NSAlertDefaultReturn) {// "Choose Library..."
			
			NSOpenPanel * openPanel = [NSOpenPanel openPanel];
			openPanel.allowsMultipleSelection = NO;
			[openPanel setAllowedFileTypes:@[@"teaboxdb"]];
			openPanel.prompt = @"Open";
			if ([openPanel runModal] == NSFileHandlingPanelOKButton ) {
				NSString * path = openPanel.URL.path;
				[TBLibrary createLibraryWithName:@"com.lisacintosh.teabox.default-library" atPath:path isSharedLibrary:NO];
				
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
					[userDefaults objectForKey:kLibraryBookmarkDataKey];
				} else {
					// @TODO: present the error on fail
				}
				
			} else {
				[NSApp terminate:nil];
			}
		} else if (returnCode == NSAlertAlternateReturn) {// "Create New"
			/* Create a new library with a database get from the application bundle */
			NSArray * documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES /* Expand the tilde (~/Documents => /Users/Max/Documents) */);
			NSString * documentPath = ([documentPaths count] > 0) ? documentPaths[0] : NSTemporaryDirectory();
			NSString * path = [documentPath stringByAppendingString:@"/Library.teaboxdb"];
			[TBLibrary createLibraryWithName:@"com.lisacintosh.teabox.default-library" atPath:path isSharedLibrary:NO];
			
		} else {// "Quit"
			[NSApp terminate:nil];
		}
		
	} else if (!defaultLibrary.database) {
		/* If the database can't be initialized, try to get a backup, if no backup available, show an alert to create a new database. */
		
		/* Try to revert the backup */
		BOOL success = [[TBLibrary defaultLibrary] revertToBackup];
		
		if (success) {
			/* Use the default library but initialize the database */
			NSArray * documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES /* Expand the tilde (~/Documents => /Users/Max/Documents) */);
			NSString * documentPath = ([documentPaths count] > 0) ? documentPaths[0] : NSTemporaryDirectory();
			NSString * path = [documentPath stringByAppendingString:@"/Library.teaboxdb"];
			[TBLibrary createLibraryWithName:@"com.lisacintosh.teabox.default-library" atPath:path isSharedLibrary:NO];
		} else {
			NSAlert * alert = [NSAlert alertWithMessageText:@"The library can't be initialized. Do you want to create a new library?"
											  defaultButton:@"Create New"
											alternateButton:nil
												otherButton:@"Quit"
								  informativeTextWithFormat:nil];
			if ([alert runModal] == NSAlertDefaultReturn) {
				/* Create a new library with a database get from the application bundle */
				NSArray * documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES /* Expand the tilde (~/Documents => /Users/Max/Documents) */);
				NSString * documentPath = ([documentPaths count] > 0) ? documentPaths[0] : NSTemporaryDirectory();
				NSString * path = [documentPath stringByAppendingString:@"/Library.teaboxdb"];
				[TBLibrary createLibraryWithName:@"com.lisacintosh.teabox.default-library" atPath:path isSharedLibrary:NO];
			} else {// "Quit"
				[NSApp terminate:nil];
			}
		}
	}
	
	self.window.delegate = self;
	[self.window makeKeyAndOrderFront:nil];/* Order the window only after loading the navigationController and the main viewController */
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
	
	[self startBrowsingSharedProjects];
	[self startPublishingSharedProjects];
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
	// @TODO: check that the backup file is older than the database file before creating a backup
	
	[[TBLibrary defaultLibrary] createBackup];
	[[TBLibrary defaultLibrary] close];
	return NSTerminateNow;
}

#pragma mark - Actions

- (IBAction)openPreferencesAction:(id)sender
{
	[_preferencesWindow reloadData];
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
	NSMenu * mainMenu = [NSApp mainMenu];
	NSMenu * fileMenu = [mainMenu itemAtIndex:1].submenu;
	
	/* Enable "File > Export..." */
	BOOL cellSelected = ([((TableView *)notification.object) indexPathOfSelectedRow] != nil);
	[[fileMenu itemWithTag:MainMenuItemExport] setEnabled:cellSelected];
}

#pragma mark - NavigationController Delegate

- (void)navigationControllerDidPushViewController:(NSViewController *)viewController animated:(BOOL)animated
{
	/* When the navigation controller push the project view controller, we are into the "projectViewController" */
	if (viewController == _projectViewController) {
		NSMenu * mainMenu = [NSApp mainMenu];
		NSMenu * fileMenu = [mainMenu itemAtIndex:1].submenu;
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
		NSMenu * mainMenu = [NSApp mainMenu];
		NSMenu * fileMenu = [mainMenu itemAtIndex:1].submenu;
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
	
	NSString * libraryFilename = [[TBLibrary defaultLibrary].path lastPathComponent];
	savePanel.nameFieldStringValue = libraryFilename;
	
	[savePanel beginSheetModalForWindow:self.window
					  completionHandler:^(NSInteger result) {
						  NSString * newPath = [savePanel.URL path];
						  BOOL success = [[TBLibrary defaultLibrary] moveLibraryToPath:newPath
																				 error:nil];
						  if (!success) {
							  NSLog(@"error when moving default library to path: %@", newPath);
							  return;
						  }
					  }];
}

- (IBAction)reloadTableViewAction:(id)sender // @TODO: Remove this method
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadTableViewNotification"
														object:nil];
}


@end
