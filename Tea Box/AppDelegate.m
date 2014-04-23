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

@synthesize browser = _browser, publisher = _publisher;

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

#pragma mark - Bonjour Browser & Publisher Methods

- (void)startBrowsingSharedProjects
{
	_browser = [[BonjourBrowser alloc] initWithServiceName:kServiceName];
	_browser.delegate = self;
	[_browser start];
}

- (void)startPublishingSharedProjects
{
	_publisher = [[BonjourPublisher alloc] initWithServiceName:kServiceName];
	_publisher.delegate = self;
	[_publisher publish];
}

#warning @TODO: Remove this part
#pragma mark - BonjourBrowser Delegate
#if 0

- (void)browser:(BonjourBrowser *)browser didFoundServices:(NSArray *)services
{
	NSLog(@"%ld Tea Box services found", services.count);
	
	/* Get all shared projects from all found services */
	for (BonjourService * service in services) {
		
#if __DEBUG__
		[service sendUTF8String:@"PROJECTS"];
#else
		NSString * localizedName = [[NSHost currentHost] localizedName];
		if (![service.netService.name isEqualToString:localizedName]) {// Don't catch himself
			NSLog(@"Sending \"PROJECTS\" to %@", service.netService.name);
			[service sendUTF8String:@"PROJECTS"];
		}
#endif
	}
}

- (BOOL)browser:(BonjourBrowser *)browser shouldOpenService:(BonjourService *)service
{
#if __DEBUG__
	return YES;
#else
	NSString * localizedName = [[NSHost currentHost] localizedName];
	return !([service.netService.name isEqualToString:localizedName]);
#endif
}

- (void)browser:(BonjourBrowser *)browser didOpenService:(BonjourService *)service
{
	NSLog(@"Service named \"%@\" is opened", service.hostName);
}

- (void)browser:(BonjourBrowser *)browser didReceiveData:(NSData *)data fromService:(BonjourService *)service
{
	NSArray * cachesPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES /* Expand the tilde */);
	NSString * cachesPath = ([cachesPaths count] > 0) ? cachesPaths[0] : NSTemporaryDirectory();
	TBLibrary * library = [TBLibrary libraryWithName:service.hostName];
	if (!library) {
		NSString * path = [NSString stringWithFormat:@"%@/com.lisacintosh.Tea-Box/%@.teaboxdb", cachesPath, service.hostName];
		
		[[NSFileManager defaultManager] removeItemAtPath:path error:NULL];// Remove the old one to get fresh database
		
		library = [TBLibrary createLibraryWithName:service.hostName atPath:path isSharedLibrary:YES];
	}
	
	NSDictionary * dictionary = nil;
	if (data.length > 0)
		dictionary = (NSDictionary *)[data objectFromJSONData];
	
	if (dictionary) {
		NSString * request = dictionary[@"request"];
		NSArray * arguments = dictionary[@"arguments"];
		NSArray * object = dictionary[@"object"];
		
		NSLog(@"browser:didReceiveData: (request: %@ args: %ld items object for class %@) fromService: %@", request, arguments.count, NSStringFromClass([object class]), service.hostName);
		
		if ([request isEqualToString:@"PROJECTS"]) {
			NSArray * projectAttributes = (NSArray *)object;
			NSMutableArray * projects = [[NSMutableArray alloc] initWithCapacity:projectAttributes.count];
			for (NSDictionary * attributes in projectAttributes) {
				Project * project = [[Project alloc] initWithName:attributes[@"name"]
													  description:attributes[@"description"]
														 priority:[attributes[@"priority"] intValue]
													   identifier:[attributes[@"identifier"] intValue]
												insertIntoLibrary:library];
				[projects addObject:project];
			}
			service.projects = projects;
			
			[[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadTableViewNotification"
																object:nil];
			
		} else if ([request isEqualToString:@"STEPS"] && arguments.count > 0) {// The request should be "STEPS [Project_id]"
			
			Project * project = nil;
			
			NSArray * stepsAttributes = (NSArray *)object;
			NSMutableArray * steps = [[NSMutableArray alloc] initWithCapacity:stepsAttributes.count];
			for (NSDictionary * attributes in stepsAttributes) {
				int projectID = [attributes[@"projectID"] intValue];
				NSArray * projects = [Project allProjectsFromLibrary:library];
				for (Project * aProject in projects) {
					if (aProject.identifier == projectID) { project = aProject; break; }
				}
				
				Step * step = [[Step alloc] initWithName:attributes[@"name"]
											 description:attributes[@"description"]
											  identifier:[attributes[@"identifier"] intValue]
												 project:project
									   insertIntoLibrary:library];
				[steps addObject:step];
				
				//identifier = projectID;
				
				NSLog(@"Step: %@", attributes);
				
				[service sendUTF8String:[NSString stringWithFormat:@"ITEMS %i", [attributes[@"identifier"] intValue]]];
			}
			
			NSLog(@"project: %@", project);
			
			if (project) {
				_projectViewController.project = project;
				[NavigationController pushViewController:_projectViewController animated:YES];
			}
			
		} else if ([request isEqualToString:@"ITEMS"] && arguments.count > 0) {// The request should be "ITEMS [Step_id]"
			
			NSArray * itemsAttributes = (NSArray *)object;
			NSMutableArray * items = [[NSMutableArray alloc] initWithCapacity:itemsAttributes.count];
			for (NSDictionary * attributes in itemsAttributes) {
				
				int stepID = [attributes[@"stepID"] intValue];
				
				Step * step = nil;
				NSArray * projects = [Project allProjectsFromLibrary:library];
				for (Project * project in projects) {
					step = [project stepWithIdentifier:stepID];
					if (step) break;
				}
				
				int identifier = [attributes[@"identifier"] intValue];
				Item * item = [[Item alloc] initWithFilename:attributes[@"filename"]
														type:attributes[@"type"]
													rowIndex:-1
												  identifier:identifier
														step:step
										   insertIntoLibrary:library];
				
				if ([item.type isEqualToString:kItemTypeText] || [item.type isEqualToString:kItemTypeWebURL]) {// For text files, download it automaticly
					[service sendUTF8String:[NSString stringWithFormat:@"FILE_INFO %i", identifier]];
				}
				
				[items addObject:item];
			}
			
		} else if ([request isEqualToString:@"ALL_ITEMS"] && arguments.count > 0) {// The request should be "ALL_ITEMS [Project_id]"
			
		} else if ([request isEqualToString:@"TEXT_CONTENT"] && arguments.count > 0) {// The request should be "TEXT_CONTENT [Item_id]"
			
		} else if ([request isEqualToString:@"FILE_INFO"] && arguments.count > 0) {// The request should be "FILE_INFO [Item_id]"
			
			int itemID = [arguments[0] intValue];
			Item * item = [Item itemWithIdentifier:itemID fromLibrary:[TBLibrary defaultLibrary]];
			NSString * path = [[TBLibrary defaultLibrary] pathForItem:item];
			
			NSDictionary * attributes = (NSDictionary *)object;
			[BonjourFileRequest addFileRequest:path
										   md5:attributes[@"MD5"]
									  fileSize:[attributes[@"fileSize"] unsignedIntegerValue]];
			
			NSLog(@"FILE_INFO: %@", object);
			// @TODO: create an entry to a dictionary with filesize (from "object") as object and the id of the item as key
			
			[service sendUTF8String:[NSString stringWithFormat:@"FILE_DATA %i", itemID]];
			
		} else if ([request isEqualToString:@"FILE_DATA"] && arguments.count > 0) {// The request should be "FILE_DATA [Item_id]"
			
		}
	} else {// No JSON sent, it's just data (file content)
		
		/* Get input buffer bytes and length */
		const void * buffer = [data bytes];
		NSUInteger length = [data length];
		
		/* Alloc output buffer */
		unsigned char * hashBytes = (unsigned char *)malloc(CC_MD5_DIGEST_LENGTH * sizeof(unsigned char));
		
		/* Compute MD5 */
		CC_MD5_CTX ctx;
		CC_MD5_Init(&ctx);
		CC_MD5_Update(&ctx, buffer, (CC_LONG)length);
		CC_MD5_Final(hashBytes, &ctx);
		
		/* // @TODO: Use a SHA-1 hash
		 unsigned char * hashBytes = (unsigned char *)malloc(CC_SHA1_DIGEST_LENGTH * sizeof(unsigned char));
		 CC_SHA1_CTX ctx;
		 CC_SHA1_Init(&ctx);
		 CC_SHA1_Update(&ctx, buffer, (CC_LONG)length);
		 CC_SHA1_Final(hashBytes, &ctx);
		 */
		
		NSString * md5String = [[NSData dataWithBytes:hashBytes length:CC_MD5_DIGEST_LENGTH] description];
		md5String = [[md5String substringToIndex:(md5String.length - 1)] substringFromIndex:1];// Remove the first and last characters from "<bbbb...bbbb>"
		free(hashBytes);
		
		BonjourFileRequest * fileRequest = [BonjourFileRequest fileRequestForMD5:md5String andFileSize:length];
		NSString * path = fileRequest.filename;
		
		NSLog(@"browser:didReceiveData: (%lu bytes) fromService: %@ -> %@", data.length, service.hostName, path);
		
		// @TODO: save the file
	}
}

#pragma mark - BonjourPublisher Delegate

- (NSData *)publisher:(BonjourPublisher *)publisher responseForRequest:(NSString *)request arguments:(NSArray *)arguments
{
	NSLog(@"%@ %@ %@", NSStringFromSelector(_cmd), request, arguments);
	
	NSMutableDictionary * dictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:request, @"request", nil];
	if (arguments && arguments.count > 0)
		dictionary[@"arguments"] = arguments;
	
	if ([request isEqualToString:@"PROJECTS"]) {
		NSMutableArray * allProjectsAttributes = [[NSMutableArray alloc] initWithCapacity:10];
		
		NSArray * allProjects = [Project allProjectsFromLibrary:[TBLibrary defaultLibrary]];
		for (Project * project in allProjects) {
			NSMutableDictionary * projectAttributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:project.name, @"name",
													   @(project.priority), @"priority",
													   @(project.identifier), @"identifier", nil];
			if (project.description)
				projectAttributes[@"description"] = project.description;
			
			[allProjectsAttributes addObject:projectAttributes];
		}
		dictionary[@"object"] = allProjectsAttributes;
		
	} else if ([request isEqualToString:@"STEPS"] && arguments.count > 0) {// The request should be "STEPS [Project_id]"
		NSMutableArray * stepsAttributes = [[NSMutableArray alloc] initWithCapacity:10];
		
		int projectID = [arguments[0] intValue];
		NSArray * steps = [Step stepsWithProjectIdentifier:projectID fromLibrary:[TBLibrary defaultLibrary]];
		for (Step * step in steps) {
			NSMutableDictionary * attributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:step.name, @"name",
												@(step.identifier), @"identifier",
												@(projectID), @"projectID", nil];
			if (step.description)
				attributes[@"description"] = step.description;
			
			[stepsAttributes addObject:attributes];
		}
		
		NSLog(@"stepsAttributes: %@", stepsAttributes);
		
		dictionary[@"object"] = stepsAttributes;
		
	} else if ([request isEqualToString:@"ITEMS"] && arguments.count > 0) {// The request should be "ITEMS [Step_id]"
		int stepID = [arguments[0] intValue];
		Step * step = nil;
		NSArray * allProjects = [Project allProjectsFromLibrary:[TBLibrary defaultLibrary]];
		for (Project * aProject in allProjects) {
			step = [aProject stepWithIdentifier:stepID];
			if (step) break;
		}
		
		NSArray * items = step.items;
		NSMutableArray * itemsAttributes = [[NSMutableArray alloc] initWithCapacity:items.count];
		for (Item * item in items) {
			NSMutableDictionary * attributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:item.filename, @"filename",
												item.type, @"type",
												@(stepID), @"stepID",
												@(item.rowIndex), @"rowIndex",
												@(item.identifier), @"identifier", nil];
			[itemsAttributes addObject:attributes];
		}
		
		NSLog(@"itemsAttributes: %@", itemsAttributes);
		
		dictionary[@"object"] = itemsAttributes;
		
		NSLog(@"dictionary: %@", dictionary);
		
	} else if ([request isEqualToString:@"ALL_ITEMS"] && arguments.count > 0) {// The request should be "ALL_ITEMS [Project_id]"
		
		NSMutableArray * itemsAttributes = [[NSMutableArray alloc] initWithCapacity:10];
		
		int projectID = [arguments[0] intValue];
		NSArray * steps = [Step stepsWithProjectIdentifier:projectID fromLibrary:[TBLibrary defaultLibrary]];
		for (Step * step in steps) {
			NSArray * items = step.items;
			for (Item * item in items) {
				[itemsAttributes addObject:@{@"filename" : item.filename}];
			}
		}
		dictionary[@"object"] = itemsAttributes;
		
	} else if ([request isEqualToString:@"TEXT_CONTENT"] && arguments.count > 0) {// The request should be "TEXT_CONTENT [Item_id]"
		//int itemID = [[arguments objectAtIndex:0] intValue];
		// @TODO: get the path of the file and return the content text
		dictionary[@"object"] = @"";
		
	} else if ([request isEqualToString:@"FILE_INFO"] && arguments.count > 0) {// The request should be "FILE_INFO [Item_id]"
		int itemID = [arguments[0] intValue];
		Item * item = [Item itemWithIdentifier:itemID fromLibrary:[TBLibrary defaultLibrary]];
		NSString * path = [[TBLibrary defaultLibrary] pathForItem:item];
		
		/* Get input buffer bytes and length */
		NSData * data = [[NSData alloc] initWithContentsOfFile:path];
		const void * buffer = [data bytes];
		NSUInteger length = [data length];
		
		/* Alloc output buffer */
		unsigned char * hashBytes = (unsigned char *)malloc(CC_MD5_DIGEST_LENGTH * sizeof(unsigned char));
		
		/* Compute MD5 */
		CC_MD5_CTX ctx;
		CC_MD5_Init(&ctx);
		CC_MD5_Update(&ctx, buffer, (CC_LONG)length);
		CC_MD5_Final(hashBytes, &ctx);
		
		NSString * md5String = [[NSData dataWithBytes:hashBytes length:CC_MD5_DIGEST_LENGTH] description];
		md5String = [[md5String substringToIndex:(md5String.length - 1)] substringFromIndex:1];
		free(hashBytes);
		
		NSNumber * fileSize;
		[[NSURL fileURLWithPath:path] getResourceValue:&fileSize forKey:NSURLFileSizeKey error:NULL];
		NSDictionary * info = @{ @"fileSize" : fileSize, @"MD5" : md5String};
		dictionary[@"object"] = info;
		
	} else if ([request isEqualToString:@"FILE_DATA"] && arguments.count > 0) {// The request should be "FILE_DATA [Item_id]"
		
		int itemID = [arguments[0] intValue];
		Item * item = [Item itemWithIdentifier:itemID fromLibrary:[TBLibrary defaultLibrary]];
		NSData * data = [NSData dataWithContentsOfFile:[[TBLibrary defaultLibrary] pathForItem:item]];
		return data;// @TODO: send data from the file content by batch with -[NSFileHandle readDataOfLength]
	}
	
	return [dictionary JSONData];
}
#endif

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
