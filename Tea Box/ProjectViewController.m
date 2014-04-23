//
//  ProjectViewController.m
//  Tea Box
//
//  Created by Max on 04/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "ProjectViewController.h"

#import "NSIndexPath+additions.h"
#import "NSMenu+additions.h"
#import "NSNotificationCenter+additions.h"
#import "NSURL+additions.h"
#import "NSFileManager+additions.h"

#import "Step+additions.h"
#import "Item+additions.h"


@implementation Item (QLPreviewItem)

- (NSURL *)previewItemURL
{
	NSString * path = [self.library pathForItem:self];
    return [NSURL fileURLWithPath:path];
}

- (NSString *)previewItemTitle
{
    return self.filename;
}

@end

@implementation ProjectViewController

@synthesize navigationBar = _navigationBar;
@synthesize tableView = _tableView;
@synthesize bottomLabel = _bottomLabel, priorityButton = _priorityButton;
@synthesize project = _project;
@synthesize descriptionTextField = _descriptionTextField;
@synthesize defaultDragOperationWindow = _defaultDragOperationWindow;

@synthesize projectNameLabel = _projectNameLabel;
@synthesize priorityPopUpButton = _priorityPopUpButton;

@synthesize imageImportFormWindow = _imageImportFormWindow;
@synthesize urlImportFormWindow = _urlImportFormWindow;
@synthesize textImportFormWindow = _textImportFormWindow;

@synthesize quickLookMenuItem = _quickLookMenuItem;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if (!nibNameOrNil) nibNameOrNil = @"ProjectViewController";
	if (!nibBundleOrNil) nibBundleOrNil = [NSBundle mainBundle];
	
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		NSLog(@"%s", __FILE__);
    }
    
    return self;
}

- (void)loadView
{
	priorityNames = @[@"None", @"Low", @"Normal", @"High"];
	
	typeImages = @[[NSImage imageNamed:@"image-type"], [NSImage imageNamed:@"text-type"], [NSImage imageNamed:@"url-type"], [NSImage imageNamed:@"file-type"], [NSImage imageNamed:@"folder-type"]];
	typeSelectedImages = @[[NSImage imageNamed:@"image-type-active"], [NSImage imageNamed:@"text-type-active"], [NSImage imageNamed:@"url-type-active"], [NSImage imageNamed:@"file-type-active"], [NSImage imageNamed:@"folder-type-active"]];
	types = @[kItemTypeImage, kItemTypeText, kItemTypeWebURL, kItemTypeFile, kItemTypeFolder];
	
	[super loadView];
	
	NSArray * draggedTypes = @[@"public.image" /* Images from an application (not on disk) */,
							  NSPasteboardTypeRTF /* RTF formatted data (before NSPasteboardTypeString because RTF data are string, so NSPasteboardTypeString will be preferred if it's placed before NSPasteboardTypeRTF) */,
							  NSPasteboardTypeString /* Text content */,
							  @"public.file-url"];
	[self.tableView registerForDraggedTypes:draggedTypes];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.rowHeight = 24.;
	
	NavigationBarButton * backButton = [[NavigationBarButton alloc] initWithType:kNavigationBarButtonTypeBack
																		  target:self
																		  action:@selector(backAction:)];
	self.navigationBar.leftBarButton = backButton;
	
	NavigationBarButton * editButton = [[NavigationBarButton alloc] initWithTitle:@"Edit"
																		   target:self
																		   action:@selector(editAction:)];
	[editButton registerForDraggedTypes:draggedTypes];
	self.navigationBar.rightBarButton = editButton;
	
	self.navigationBar.delegate = self;
	[self.navigationBar registerForDraggedTypes:draggedTypes];
	
	
	_descriptionTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(10., 2., 80., 12.)];
	[_descriptionTextField setBordered:NO];
	_descriptionTextField.drawsBackground = NO;
	_descriptionTextField.autoresizingMask = NSViewWidthSizable;
	_descriptionTextField.delegate = self;
	
	indexWebViewHeight = 0.;
	_indexWebView = [[IndexWebView alloc] initWithFrame:NSMakeRect(2., 0., 96., 17.)];
	_indexWebView.drawsBackground = NO;
	_indexWebView.autoresizingMask = (NSViewWidthSizable | NSViewHeightSizable);
	_indexWebView.frameLoadDelegate = self;
	_indexWebView.delegate = self;
	
	NSString * path = _project.indexPath;
	if (path.length > 0) {
		
#if _SANDBOX_SUPPORTED_
		NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
		NSData * bookmarkData = [userDefaults objectForKey:path];
		
		NSURL * fileURL = [NSURL URLByResolvingBookmarkData:bookmarkData
													options:NSURLBookmarkResolutionWithSecurityScope
											  relativeToURL:nil
										bookmarkDataIsStale:nil
													  error:NULL];
		[fileURL startAccessingSecurityScopedResource];
		[_indexWebView loadIndexAtURL:fileURL];
		[fileURL stopAccessingSecurityScopedResource];
#else
		[_indexWebView loadIndexAtPath:path];
#endif
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(reloadData)
												 name:@"ReloadTableViewNotification"
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(windowDidResize:)
												 name:NSWindowDidResizeNotification
											   object:nil];
	
	/* Save the index changes when the window resign key (in general, when the user switch to another application) */
	[[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidBecomeKeyNotification
												  usingBlock:^(NSNotification * notification) {
													  [self loadIndexAction:nil];
												  }];
	
	[self reloadData];
}

- (void)windowDidResize:(NSNotification *)notification
{
	NSSize size = [_bottomLabel.stringValue sizeWithAttributes:@{ NSFontAttributeName : _bottomLabel.font }];
	NSRect frame = _priorityButton.frame;
	frame.origin.x = (self.view.frame.size.width - size.width) / 2. - frame.size.width;
	_priorityButton.frame = frame;
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)canBecomeKeyView
{
	return YES;
}

- (BOOL)becomeFirstResponder
{
	NSLog(@"ProjectViewController become first responder");
	return YES;
}

- (BOOL)resignFirstResponder
{
	NSLog(@"ProjectViewController resign first responder");
	return YES;
}

- (void)setProject:(Project *)project
{
	_project = project;
	
	if (_project) {
		NSString * path = _project.indexPath;
		if (path.length > 0) {
			
#if _SANDBOX_SUPPORTED_
			NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
			NSData * bookmarkData = [userDefaults objectForKey:path];
			
			NSURL * fileURL = [NSURL URLByResolvingBookmarkData:bookmarkData
														options:NSURLBookmarkResolutionWithSecurityScope
												  relativeToURL:nil
											bookmarkDataIsStale:nil
														  error:NULL];
			[fileURL startAccessingSecurityScopedResource];
			[_indexWebView loadIndexAtURL:fileURL];
			[fileURL stopAccessingSecurityScopedResource];
#else
			[_indexWebView loadIndexAtPath:path];
#endif
		}
		
		[self reloadData];
	}
}

- (void)reloadData
{
	showsIndexDescription = (_project.indexPath != nil);
	
	steps = [[NSArray alloc] initWithArray:[_project steps]];
	
	_navigationBar.title = _project.name;
	
	[_descriptionTextField setEditable:_editing];
	_descriptionTextField.stringValue = _project.description;
	NSRect frame = _descriptionTextField.frame;
	frame.size.height = INFINITY;
	NSSize size = [_descriptionTextField.cell cellSizeForBounds:frame];
	frame.size.height = size.height;
	_descriptionTextField.frame = frame;
	
	NSMutableArray * _itemsArray = [[NSMutableArray alloc] initWithCapacity:steps.count];
	
	for (Step * step in steps) {
		/* "itemsArray" has the form: [[Item 1, Item 2, Item 3], [Item 1, Item 2, Item 3], []...] */
		NSArray * items = [step items];
		if (items)
			[_itemsArray addObject:items];
		else
			[_itemsArray addObject:@[]];
	}
	
	itemsArray = _itemsArray;
	
	[self.tableView reloadData];
	
	/* Close section that should be closed */
	NSInteger section = 1 + ((showsIndexDescription || _editing)? 1: 0);
	for (Step * step in steps) {
		[self.tableView setState:(step.closed)? TableViewSectionStateClose : TableViewSectionStateOpen
					  forSection:section++];
	}
	
	/* Update the label at bottom */
	[self reloadBottomLabel];
	
	[self.tableView becomeFirstResponder];
	
	[_quickLookMenuItem setEnabled:(self.tableView.indexPathOfSelectedRow != nil)];
}

- (void)reloadBottomLabel
{
	if (_editing) {
		NSString * bottomString = [NSString stringWithFormat:@"Priority: %@", priorityNames[(NSUInteger)_project.priority]];
		_bottomLabel.stringValue = bottomString;
		
		NSSize size = [bottomString sizeWithAttributes:@{NSFontAttributeName: _bottomLabel.font}];
		NSRect frame = _priorityButton.frame;
		frame.origin.x = (self.view.frame.size.width - size.width) / 2. - frame.size.width;
		_priorityButton.frame = frame;
	} else {
		NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
		formatter.dateStyle = NSDateFormatterShortStyle;
		formatter.timeStyle = NSDateFormatterShortStyle;
		_bottomLabel.stringValue = [NSString stringWithFormat:@"Priority: %@ - Modified: %@", priorityNames[(NSUInteger)_project.priority], [formatter stringFromDate:_project.lastModificationDate]];
	}
	
	[_priorityButton setHidden:!_editing];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	indexWebViewHeight = _indexWebView.contentHeight;
	[self.tableView reloadDataForSection:1];
}

- (void)setEditing:(BOOL)editing
{
	/* Change the NavigationBar, show "Back" and "Edit" when not editing, show "Cancel" and "Done" if editing */
	if (editing) {
		NavigationBarButton * cancelButton = [[NavigationBarButton alloc] initWithTitle:@"Cancel"
																				 target:self
																				 action:@selector(cancelAction:)];
		_navigationBar.leftBarButton = cancelButton;
		
		NavigationBarButton * doneButton = [[NavigationBarButton alloc] initWithType:kNavigationBarButtonTypeDone
																			  target:self
																			  action:@selector(doneAction:)];
		_navigationBar.rightBarButton = doneButton;
	} else {
		NavigationBarButton * backButton = [[NavigationBarButton alloc] initWithType:kNavigationBarButtonTypeBack
																			  target:self
																			  action:@selector(backAction:)];
		_navigationBar.leftBarButton = backButton;
		
		NavigationBarButton * editButton = [[NavigationBarButton alloc] initWithTitle:@"Edit"
																			   target:self
																			   action:@selector(editAction:)];
		_navigationBar.rightBarButton = editButton;
	}
	
	_navigationBar.editable = editing;
	
	[_descriptionTextField setEditable:editing];
	[_descriptionTextField setDrawsBackground:editing];
	
	if (editing) {
		[self.tableView startTrackingSections];
		[[NSApp mainWindow] makeFirstResponder:_navigationBar.textField];
	} else {
		[self.tableView stopTrackingSections];
		[[NSApp mainWindow] makeFirstResponder:nil];
	}
	
	_editing = editing;
	[self reloadData];
}

- (void)askForDefaultDragOperation:(NSArray *)paths step:(Step *)step atIndex:(NSInteger)rowIndex
{
	NSDictionary * contextInfo = @{@"paths" : paths, @"step": step, @"rowIndex" : @(rowIndex)};
	[NSApp beginSheet:_defaultDragOperationWindow
	   modalForWindow:self.view.window
		modalDelegate:self
	   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
		  contextInfo:(__bridge_retained void *)contextInfo];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	NSDictionary * dictionary = (__bridge NSDictionary *)contextInfo;
	if (returnCode == NSOKButton) {
		NSArray * paths = (NSArray *)dictionary[@"paths"];
		Step * step = (Step *)dictionary[@"step"];
		int rowIndex = [dictionary[@"rowIndex"] intValue];
		
		NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
		NSString * defaultDragOp = [userDefaults stringForKey:@"Default-Drag-Operation"];
		if ([defaultDragOp isEqualToString:@"Copy"]) {
			
			BOOL containsDirectory = NO;
			for (NSString * path in paths) {
				NSNumber * isDirectory = nil;
				[[NSURL fileURLWithPath:path] getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
				if ([isDirectory boolValue]) { containsDirectory = YES; break; }
			}
			
			if (containsDirectory) {
				
				if ([[userDefaults arrayForKey:@"Alerts to Hide"] containsObject:@"Recursive Alert"]) {
					
					BOOL recursive = [userDefaults boolForKey:@"Use Recursivity"];
					[self copyItemsFromPaths:paths
								   recursive:recursive
							  insertIntoStep:step
								  atRowIndex:-1];
					
				} else {
					
					NSAlert * alert = [NSAlert alertWithMessageText:@"Recursive?"
													  defaultButton:@"Non Recursive"
													alternateButton:@"Recursive"
														otherButton:nil
										  informativeTextWithFormat:@""];
					alert.showsSuppressionButton = YES;
					
					NSDictionary * contextInfo = @{@"paths" : paths, @"step" : step};
					[alert beginSheetModalForWindow:self.view.window
									  modalDelegate:self
									 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
										contextInfo:(__bridge_retained void *)contextInfo];
				}
				
			} else {
				[self copyItemsFromPaths:paths recursive:NO insertIntoStep:step atRowIndex:rowIndex];
			}
			
		} else if ([defaultDragOp isEqualToString:@"Link"]) {
			[self linkItemsFromPaths:paths recursive:NO insertIntoStep:step atRowIndex:rowIndex];
		} else {// Move, by default
			[self moveItemsFromPaths:paths recursive:NO insertIntoStep:step atRowIndex:rowIndex];
		}
	} else {
		
	}
}

#pragma mark - Description TextField Delegate -

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
	NSRect frame = _descriptionTextField.frame;
	frame.size.height = INFINITY;
	NSSize size = [_descriptionTextField.cell cellSizeForBounds:frame];
	frame.size.height = size.height;
	_descriptionTextField.frame = frame;
	
	[self.tableView invalidateContentLayout];
	return YES;
}

#pragma mark - Actions -

- (NSString *)defaultNewStepName
{
	/* Generate a free name (ex: "Untitled Step (2)", "Untitled Step (3)", etc.) */
	NSString * baseStepName = @"Untitled Step", * stepName = baseStepName;
	
	NSArray * allSteps = _project.steps;
	BOOL exists = NO;
	NSInteger index = 2;
	do {
		exists = NO;
		for (Step * step in allSteps) {
			if ([step.name isEqualToString:stepName]) {
				exists = YES;
				stepName = [NSString stringWithFormat:@"%@ (%ld)", baseStepName, index++];
			}
		}
	} while (exists);
	
	return stepName;
}

- (IBAction)newStepAction:(id)sender
{
	Step * step = [[Step alloc] initWithName:[self defaultNewStepName]
								 description:@""
									 project:_project
						   insertIntoLibrary:_project.library];
	[self reloadData];
	
	NSInteger section = 1 + ((showsIndexDescription || _editing)? 1 : 0) + steps.count;
	[self.tableView scrollToSection:section openSection:NO position:TableViewPositionNone];
}

- (IBAction)backAction:(id)sender
{
	/* Remoevt the QuickLook panel */
	QLPreviewPanel * previewPanel = [QLPreviewPanel sharedPreviewPanel];
    if ([QLPreviewPanel sharedPreviewPanelExists] && [previewPanel isVisible]) {
        [previewPanel orderOut:nil];
	}
	
	/* Save the index file changes */
	[self saveTextIndexAction:nil];
	
	/* Disable "Quick Look selected item" */
	[_quickLookMenuItem setEnabled:NO];
	
	[NavigationController popViewControllerAnimated:YES];
	
	self.project = nil;
}

- (IBAction)bottomButtonDidClickedAction:(id)sender
{
	NSMenu * menu = [[NSMenu alloc] initWithTitle:@"bottom-menu"];
	menu.font = [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];
	
	SEL selector = @selector(priorityPopUpDidChangeAction:);
	[menu addItemWithTitle:@"Priority" target:nil action:NULL];
	[menu addItemWithTitle:@"High" target:self action:selector tag:3];
	[menu addItemWithTitle:@"Normal" target:self action:selector tag:2];
	[menu addItemWithTitle:@"Low" target:self action:selector tag:1];
	[menu addItemWithTitle:@"None" target:self action:selector tag:0];
	
	NSMenuItem * selectItem = [menu itemWithTag:(_project.priority)];
	selectItem.state = NSOnState;
	
	/*
	 [menu addItem:[NSMenuItem separatorItem]];
	 
	 [menu addItemWithTitle:@"Project is not Shared" target:nil action:NULL];
	 [menu addItemWithTitle:@"Share Project" target:self action:selector];
	 */
	
	[menu popUpMenuPositioningItem:selectItem
						atLocation:NSMakePoint(_priorityButton.frame.origin.x, -5.)
							inView:self.view];
}

- (IBAction)priorityPopUpDidChangeAction:(id)sender
{
	NSMenuItem * item = (NSMenuItem *)sender;
	NSInteger index = ([item.menu indexOfItem:item] - 1);// Minus one for "Priority"
	NSInteger count = (item.menu.numberOfItems - 1);// Minus one for "Priority"
	if (0 <= index && index < count) {
		NSLog(@"priorityPopUpDidChangeAction: \"%@\" (%ld)", item.title, item.tag);
		[_project updateValue:@(item.tag)
					   forKey:@"priority"];
		[self reloadBottomLabel];
	}
}

- (IBAction)editAction:(id)sender
{
	editSavepoint = [_project.library createSavepoint];
	
	[self setEditing:YES];
}

- (IBAction)doneAction:(id)sender
{
	[_project updateValue:_navigationBar.textField.stringValue// Get the value of the navigationBar's textField and not the navigationBar's title because at this point, the textField is editing so the new value have not been saved
				   forKey:@"name"];
	[_project updateValue:_descriptionTextField.stringValue
				   forKey:@"description"];
	
	if (![_project.library releaseSavepoint:editSavepoint])
		NSLog(@"Error when release \"Savepoint_%i\"", editSavepoint);
	
	[self setEditing:NO];
}

- (IBAction)cancelAction:(id)sender
{
	_descriptionTextField.stringValue = _project.description;
	
	if (![_project.library goBackToSavepoint:editSavepoint])
		NSLog(@"Error when rollback to \"Savepoint_%i\"", editSavepoint);
	
	[self setEditing:NO];
}

- (IBAction)openWithDefaultApplicationAction:(id)sender
{
	Item * item = [self itemAtIndexPath:self.tableView.indexPathOfSelectedRow];
	NSString * path = [_project.library pathForItem:item];
	[[NSWorkspace sharedWorkspace] openFile:path];
}

- (IBAction)showInFinderAction:(id)sender
{
	Item * item = [self itemAtIndexPath:self.tableView.indexPathOfSelectedRow];
	NSURL * fileURL = [_project.library URLForItem:item];
	
#if _SANDBOX_SUPPORTED_
	[fileURL startAccessingSecurityScopedResource];
#endif
	
	[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[fileURL]];
	
#if _SANDBOX_SUPPORTED_
	[fileURL stopAccessingSecurityScopedResource];
#endif
	
#if 0
	/* A little trick:
	 - On sandboxing application, -[NSWorkspace activateFileViewerSelectingURLs:] doesn't work with URLs, only with path.
	 - On non-sandboxing application, the method requierd URLs.
	 */
	if ([NSURL instancesRespondToSelector:@selector(startAccessingSecurityScopedResource)]) {// Test if we are on a system that able to run sandbox application by testing -[NSURL startAccessingSecurityScopedResource]
		[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:[NSArray arrayWithObject:[NSURL fileURLWithPath:path]]];// [NSArray arrayWithObject:path]
	} else {
		NSURL * fileURL = [NSURL fileURLWithPath:path];
		[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:[NSArray arrayWithObject:fileURL]];
	}
#endif
}

- (IBAction)copyToPasteboardSelectedItemAction:(id)sender
{
	NSIndexPath * indexPath = [self.tableView indexPathOfSelectedRow];
	Item * item = [self itemAtIndexPath:indexPath];
	NSString * path = [item.library pathForItem:item];
	
	NSPasteboard * pasteboard = [NSPasteboard generalPasteboard];
	[pasteboard clearContents];
	BOOL success = NO;
	
	if ([item.type isEqualToString:kItemTypeImage]) {
		
		NSImage * image = [[NSImage alloc] initWithContentsOfFile:path];
		success = [pasteboard writeObjects:@[image]];
		
	} else if ([item.type isEqualToString:kItemTypeText]) {
		
		NSAttributedString * attributedString = [[NSAttributedString alloc] initWithPath:path
																	  documentAttributes:NULL];
		success = [pasteboard writeObjects:@[attributedString]];
		
	} else if ([item.type isEqualToString:kItemTypeWebURL]) {
		
		NSString * content = [[NSString alloc] initWithContentsOfFile:path usedEncoding:nil error:NULL];
		success = [pasteboard writeObjects:@[[NSURL URLWithString:content]]];
	}
	
	if (!success) {
		NSLog(@"Error when adding data to pasteboard");
	}
	
	/*
	 if ([item.type isEqualToString:kItemTypeImage]) {
	 
	 NSImage * image = [[NSImage alloc] initWithContentsOfFile:path];
	 NSArray * representations = image.representations;
	 if (representations.count > 0) {
	 data = [[representations objectAtIndex:0] representationUsingType:NSPNGFileType
	 properties:nil];
	 }
	 [image release];
	 
	 type = NSPasteboardTypePNG;
	 
	 } else if ([item.type isEqualToString:kItemTypeText]) {
	 
	 NSDictionary * attributes = nil;
	 NSAttributedString * attributedString = [[NSAttributedString alloc] initWithPath:path
	 documentAttributes:&attributes];
	 data = [attributedString RTFFromRange:NSMakeRange(0., attributedString.length)
	 documentAttributes:attributes];
	 [attributedString release];
	 
	 type = NSPasteboardTypeRTF;
	 
	 } else if ([item.type isEqualToString:kItemTypeWebURL]) {
	 
	 data = [NSData dataWithContentsOfFile:path];
	 
	 type = NSPasteboardTypeString;
	 }
	 */
	
	/*
	 if (data) {
	 NSPasteboard * pasteboard = [NSPasteboard generalPasteboard];
	 BOOL success = [pasteboard setData:data forType:type];
	 if (!success) {
	 NSLog(@"Error when adding data to pasteboard");
	 }
	 }
	 */
}

- (IBAction)exportSelectedItemAction:(id)sender
{
	NSIndexPath * indexPath = [self.tableView indexPathOfSelectedRow];
	Item * item = [self itemAtIndexPath:indexPath];
	NSString * path = [item.library pathForItem:item];
	
	NSSavePanel * savePanel = [NSSavePanel savePanel];
	savePanel.nameFieldStringValue = item.filename;
	[savePanel beginSheetModalForWindow:self.view.window
					  completionHandler:^(NSInteger result) {
						  if (result == NSFileHandlingPanelOKButton) {
							  NSString * destinationPath = savePanel.URL.path;
							  
							  NSError * error = nil;
							  BOOL success = [[NSFileManager defaultManager] copyItemAtPath:path toPath:destinationPath error:&error];
							  if (!success)
								  [NSApp presentError:error];
						  }
					  }];
}

- (IBAction)locateSelectedItemAction:(id)sender
{
	NSIndexPath * indexPath = [self.tableView indexPathOfSelectedRow];
	__unsafe_unretained Item * item = [self itemAtIndexPath:indexPath];
	NSString * path = [item.library pathForItem:item];
	
	NSOpenPanel * openPanel = [NSOpenPanel openPanel];
	openPanel.directoryURL = [NSURL fileURLWithPath:[path stringByDeletingLastPathComponent]];
	openPanel.allowsMultipleSelection = NO;
	openPanel.canChooseDirectories = YES;
	openPanel.canChooseFiles = YES;
	[openPanel beginSheetModalForWindow:self.view.window
					  completionHandler:^(NSInteger result) {
						  if (result == NSFileHandlingPanelOKButton) {
							  NSString * newPath = openPanel.URL.path;
							  
							  NSString * stepFolder = [item.library pathForStepFolder:item.step];
							  NSString * libraryPath = item.library.path;
							  
							  if ([newPath.lastPathComponent isEqualToString:stepFolder]) {
								  /* Just set "item.filename" with the new selected file */
								  [item updateValue:newPath.lastPathComponent forKey:@"filename"];
								  
							  } else if (newPath.length >= libraryPath.length && [[newPath substringToIndex:libraryPath.length] isEqualToString:libraryPath]) {
								  /* Copy the file to the step folder and set "item.filename" with the selected file */
								  
								  NSError * error = NULL;
								  NSString * destinationPath = [NSString stringWithFormat:@"%@/%@", stepFolder, newPath.lastPathComponent];
								  BOOL success = [[NSFileManager defaultManager] copyItemAtPath:newPath toPath:destinationPath error:&error];
								  if (!success)
									  [NSApp presentError:error];
								  
								  [item updateValue:[newPath lastPathComponent] forKey:@"filename"];
							  } else {
								  /* Create bookmark data to the file (as the file was linked), save it to the userDefaults and set "item.filename" to nil */
								  
								  NSUInteger bookmarkOptions = 0;
#if _SANDBOX_SUPPORTED_
								  bookmarkOptions = NSURLBookmarkCreationWithSecurityScope;
#endif
								  NSData * bookmarkData = [openPanel.URL bookmarkDataWithOptions:bookmarkOptions
																  includingResourceValuesForKeys:nil
																				   relativeToURL:nil
																						   error:NULL];
								  
								  NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
								  NSString * key = [NSString stringWithFormat:@"%i/%i/%i", item.step.project.identifier, item.step.identifier, item.identifier];
								  [userDefaults setObject:bookmarkData forKey:key];
								  
								  [item updateValue:[newPath lastPathComponent] forKey:nil];// Set "item.filename" to nil
							  }
							  
							  [self.tableView reloadData];
						  }
					  }];
}

- (IBAction)deleteSelectedItemAction:(id)sender
{
	NSIndexPath * indexPath = [self.tableView indexPathOfSelectedRow];
	Item * item = [self itemAtIndexPath:indexPath];
	NSString * path = [item.library pathForItem:item];
	
	if (item.filename) {// If the item is located into the library
		if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {// If the file exists, ask the user to delete the item folder
			NSAlert * alert = [NSAlert alertWithMessageText:@"Do you want to keep the file in the library or move it to the trash?"
											  defaultButton:@"Keep File"
											alternateButton:@"Move to Trash"
												otherButton:@"Cancel"
								  informativeTextWithFormat:@"This action can't be undone."];
			alert.alertStyle = NSWarningAlertStyle;
			[alert beginSheetModalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(deleteItemAlertDidEnd:returnCode:contextInfo:) contextInfo:(__bridge_retained void *)item];
		} else {// If the file no longer exists at the specified path, juste ask to delete the entry
			NSAlert * alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"Do you really want to delete the entry for %@", item.filename]
											  defaultButton:@"Delete"
											alternateButton:nil
												otherButton:@"Cancel"
								  informativeTextWithFormat:@"This action can't be undone."];
			alert.alertStyle = NSWarningAlertStyle;
			[alert beginSheetModalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(deleteItemConfirmationAlertDidEnd:returnCode:contextInfo:) contextInfo:(__bridge_retained void *)item];
		}
	} else {// Else, if the item is linked
		NSAlert * alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"Do you really want to delete the entry for %@", path.lastPathComponent]
										  defaultButton:@"Delete"
										alternateButton:nil
											otherButton:@"Cancel"
							  informativeTextWithFormat:@"The file will not be deleted.\nThis action can't be undone."];
		alert.alertStyle = NSWarningAlertStyle;
		[alert beginSheetModalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(deleteLinkedItemAlertDidEnd:returnCode:contextInfo:) contextInfo:(__bridge_retained void *)item];
	}
}

- (void)deleteItemAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertDefaultReturn || returnCode == NSAlertAlternateReturn) {
		BOOL success = YES;
		Item * item = (__bridge Item *)contextInfo;
		if (returnCode == NSAlertDefaultReturn) {// "Keep File"
		} else {// "Move to Trash"
			success = [item moveToTrash];
		}
		if (success)
			[item delete];
		else {
			// @TODO: on fail (the folder can't be moved to trash, by example), show an alert to ask to re-try later (after close all applications, etc.).
		}
		
		[self reloadData];
	}
}

- (void)deleteItemConfirmationAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	BOOL success = YES;
	Item * item = (__bridge Item *)contextInfo;
	if (returnCode == NSAlertDefaultReturn) {// "Delete"
		success = [item delete];
	} else {// "Cancel"
	}
	
	[self reloadData];
}

- (void)deleteLinkedItemAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	BOOL success = YES;
	Item * item = (__bridge Item *)contextInfo;
	if (returnCode == NSAlertDefaultReturn) {// "Delete"
		success = [item delete];
	} else {// "Cancel"
	}
	
	[self reloadData];
}

- (IBAction)deleteSelectedStepAction:(id)sender
{
	NSInteger section = [self.tableView selectedSection];
	if (section != -1) {
		section--;// Remove the "Description" section
		if (showsIndexDescription || _editing) section--;// Remove the "Notes" section
		Step * step = steps[section];
		
		/* Don't show this alert if no files have been added */
		BOOL containsItemFromLibrary = NO;
		NSArray * items = step.items;
		for (Item * item in items) {
			if (item.filename) /* Check that the item is not linked */ { containsItemFromLibrary = YES; break; }
		}
		
		if (containsItemFromLibrary) {
			NSAlert * alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"Do you want to keep all files from \"%@\" in the library or move them to the trash?", step.name]
											  defaultButton:@"Keep Files"
											alternateButton:@"Move to Trash"
												otherButton:@"Cancel"
								  informativeTextWithFormat:@"This action can't be undone."];
			alert.alertStyle = NSWarningAlertStyle;
			[alert beginSheetModalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(deleteStepAlertDidEnd:returnCode:contextInfo:) contextInfo:(__bridge_retained void *)step];
		} else {
			NSAlert * alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"Do you really want to delete \"%@\"?", step.name]
											  defaultButton:@"Delete"
											alternateButton:nil
												otherButton:@"Cancel"
								  informativeTextWithFormat:@"This action can't be undone."];
			alert.alertStyle = NSWarningAlertStyle;
			[alert beginSheetModalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(deleteStepAlertDidEnd:returnCode:contextInfo:) contextInfo:(__bridge_retained void *)step];
		}
	}
}

- (void)deleteStepAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertDefaultReturn || returnCode == NSAlertAlternateReturn) {
		BOOL success = YES;
		Step * step = (__bridge Step *)contextInfo;
		if (returnCode == NSAlertDefaultReturn) {// "Keep File"
		} else {// "Move to Trash"
			success = [step moveToTrash];
		}
		if (success)
			[step delete];
		else {
			// @TODO: on fail (the folder can't be moved to trash, by example), show an alert to ask to re-try later (after close all applications, etc.).
			NSAlert * alert = [NSAlert alertWithMessageText:@"Error when moving folder to trash!"
											  defaultButton:@"OK"
											alternateButton:nil
												otherButton:nil
								  informativeTextWithFormat:@"Try to close others applications and then retry to delete."];
			[alert beginSheetModalForWindow:self.view.window
							  modalDelegate:nil
							 didEndSelector:NULL
								contextInfo:nil];
		}
		
		[self reloadData];
	}
}

- (IBAction)loadIndexAction:(id)sender
{
	NSString * path = _project.indexPath;
	if (path.length > 0) {
		
#if _SANDBOX_SUPPORTED_
		NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
		NSData * bookmarkData = [userDefaults objectForKey:path];
		
		NSURL * fileURL = [NSURL URLByResolvingBookmarkData:bookmarkData
													options:NSURLBookmarkResolutionWithSecurityScope
											  relativeToURL:nil
										bookmarkDataIsStale:nil
													  error:NULL];
		
		[fileURL startAccessingSecurityScopedResource];
		[_indexWebView loadIndexAtURL:fileURL];
		[fileURL stopAccessingSecurityScopedResource];
#else
		[_indexWebView loadIndexAtURL:[NSURL fileURLWithPath:path]];
#endif
	}
	[self.tableView reloadDataForSection:1];
}

- (IBAction)saveTextIndexAction:(id)sender
{
	NSString * path = _project.indexPath;
	if (path.length > 0) {
		
#if _SANDBOX_SUPPORTED_
		NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
		NSData * bookmarkData = [userDefaults objectForKey:path];
		
		NSURL * fileURL = [NSURL URLByResolvingBookmarkData:bookmarkData
													options:NSURLBookmarkResolutionWithSecurityScope
											  relativeToURL:nil
										bookmarkDataIsStale:nil
													  error:NULL];
		BOOL success = [fileURL startAccessingSecurityScopedResource];
		[_indexWebView saveIndexAtURL:fileURL];
		[fileURL stopAccessingSecurityScopedResource];
#else
		[_indexWebView saveIndexAtPath:path];
#endif
	}
}

- (IBAction)showQuickLookAction:(id)sender
{
	QLPreviewPanel * previewPanel = [QLPreviewPanel sharedPreviewPanel];
    
    if ([QLPreviewPanel sharedPreviewPanelExists] && [previewPanel isVisible]) {
        [previewPanel orderOut:nil];
    } else {
        [previewPanel makeKeyAndOrderFront:nil];
    }
}

#pragma mark Import Actions

- (IBAction)importImageAction:(id)sender
{
	_imageImportFormWindow.importDelegate = self;
	[NSApp beginSheet:_imageImportFormWindow
	   modalForWindow:self.view.window
		modalDelegate:nil
	   didEndSelector:NULL
		  contextInfo:NULL];
}

- (IBAction)importURLAction:(id)sender
{
	_urlImportFormWindow.importDelegate = self;
	[NSApp beginSheet:_urlImportFormWindow
	   modalForWindow:self.view.window
		modalDelegate:nil
	   didEndSelector:NULL
		  contextInfo:NULL];
}

- (IBAction)importTextAction:(id)sender
{
	_textImportFormWindow.importDelegate = self;
	[NSApp beginSheet:_textImportFormWindow
	   modalForWindow:self.view.window
		modalDelegate:nil
	   didEndSelector:NULL
		  contextInfo:NULL];
}

- (void)importFormWindow:(ImportFormWindow *)window didEndWithObject:(id)object
{
	/* If an item is selected, add the item after it, else, create a new step */
	NSIndexPath * indexPath = self.tableView.indexPathOfSelectedRow;
	Step * step = [self stepForSection:indexPath.section];
	if (!step) {
		step = [[Step alloc] initWithName:[self defaultNewStepName]
							   description:nil
								   project:_project
						 insertIntoLibrary:_project.library];
	}
	
	NSString * destinationPath = [_project.library pathForStepFolder:step];
	NSString * filename = nil;
	
	NSString * type = nil;
	if (window == _imageImportFormWindow) {
		type = kItemTypeImage;
		filename = [self freeDraggedFilenameForStep:step extension:@"png"];
		NSString * path = [NSString stringWithFormat:@"%@/%@", destinationPath, filename];
		
		NSArray * representations = [(NSImage *)object representations];
		if (representations.count == 0) return ;
		NSData * data = [representations[0] representationUsingType:NSPNGFileType
																		properties:nil];
		[data writeToFile:path atomically:YES];
		
	} else if (window == _urlImportFormWindow) {
		type = kItemTypeWebURL;
		filename = [self freeDraggedFilenameForStep:step extension:@"txt"];
		NSString * path = [NSString stringWithFormat:@"%@/%@", destinationPath, filename];
		NSData * data = [[(NSURL *)object absoluteString] dataUsingEncoding:NSUTF8StringEncoding];
		[data writeToFile:path atomically:YES];
		
	} else if (window == _textImportFormWindow) {
		type = kItemTypeText;
		filename = [self freeDraggedFilenameForStep:step extension:@"rtf"];
		NSString * path = [NSString stringWithFormat:@"%@/%@", destinationPath, filename];
		NSAttributedString * attributedString = (NSAttributedString *)object;
		NSData * data = [attributedString RTFFromRange:NSMakeRange(0, attributedString.length)
									documentAttributes:NULL];
		[data writeToFile:path atomically:YES];
	}
	
	Item * item = [[Item alloc] initWithFilename:filename
											type:type
										rowIndex:-1
											step:step
							   insertIntoLibrary:_project.library];
	
	[self reloadData];
	
	/* Scroll to the new cell */
	NSIndexPath * newIndexPath = [NSIndexPath indexPathWithSection:indexPath.section row:(indexPath.row + 1)];
	[self.tableView scrollToRowAtIndexPath:newIndexPath
								  position:TableViewPositionNone];
	[self.tableView selectRowAtIndexPath:newIndexPath];
}

- (IBAction)importFilesAndFoldersAction:(id)sender
{
	NSOpenPanel * openPanel = [NSOpenPanel openPanel];
	openPanel.allowsMultipleSelection = YES;
	openPanel.canChooseDirectories = YES;
	openPanel.canChooseFiles = YES;
	
	[openPanel beginSheetModalForWindow:self.view.window
					  completionHandler:^(NSInteger result) {
						  if (result == NSOKButton) {
							  
							  Step * step = nil;
							  NSIndexPath * indexPath = self.tableView.indexPathOfSelectedRow;
							  if (indexPath && indexPath.section > -1) {
								  step = [self stepForSection:indexPath.section];
							  } else {
								  step = [[Step alloc] initWithName:[self defaultNewStepName]
														 description:nil
															 project:_project
												   insertIntoLibrary:_project.library];
							  }
							  
							  NSArray * URLs = [openPanel URLs];
							  __unsafe_unretained NSMutableArray * paths = [NSMutableArray arrayWithCapacity:URLs.count];
							  for (NSURL * fileURL in URLs) { [paths addObject:fileURL.path]; }
							  
							  int rowIndex = (indexPath)? (int)indexPath.row: -1;
							  NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
							  NSString * defaultDragOp = [userDefaults stringForKey:@"Default-Drag-Operation"];
							  if (defaultDragOp) {
								  if ([defaultDragOp isEqualToString:@"Copy"]) {
									  
									  BOOL containsDirectory = NO;
									  for (NSString * path in paths) {
										  NSNumber * isDirectory = nil;
										  [[NSURL fileURLWithPath:path] getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
										  if ([isDirectory boolValue]) { containsDirectory = YES; break; }
									  }
									  
									  if (containsDirectory) {
										  if ([[userDefaults arrayForKey:@"Alerts to Hide"] containsObject:@"Recursive Alert"]) {
											  
											  BOOL recursive = [userDefaults boolForKey:@"Use Recursivity"];
											  [self copyItemsFromPaths:paths
															 recursive:recursive
														insertIntoStep:step
															atRowIndex:-1];
											  
										  } else {
											  
											  NSAlert * alert = [NSAlert alertWithMessageText:@"Recursive?"
																				defaultButton:@"Non Recursive"
																			  alternateButton:@"Recursive"
																				  otherButton:nil
																	informativeTextWithFormat:@""];
											  alert.showsSuppressionButton = YES;
											  
											  NSDictionary * contextInfo = @{@"paths" : paths, @"step" : step};
											  [alert beginSheetModalForWindow:self.view.window
																modalDelegate:self
															   didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
																  contextInfo:(__bridge_retained void *)contextInfo];
										  }
									  } else {
										  [self copyItemsFromPaths:paths recursive:NO insertIntoStep:step atRowIndex:rowIndex];
									  }
									  
								  } else if ([defaultDragOp isEqualToString:@"Link"]) {
									  [self linkItemsFromPaths:paths recursive:NO insertIntoStep:step atRowIndex:rowIndex];
								  } else {// Move, by default
									  [self moveItemsFromPaths:paths recursive:NO insertIntoStep:step atRowIndex:rowIndex];
								  }
							  } else {
								  
								  int64_t delayInSeconds = .5;
								  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
								  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
									  [self askForDefaultDragOperation:paths step:step atIndex:indexPath.row];
								  });
							  }
						  }
					  }];
}

#pragma mark - NavigationBar Delegate -

- (void)navigationBar:(NavigationBar *)navigationBar didBeginDragOnBarButton:(NavigationBarButton *)button
{
	if (_editing)
		[self setEditing:NO];
	
	navigationBar.leftBarButton = nil;
	
	if (navigationBar.rightBarButton.tag != 1234) {
		NavigationBarButton * newStepButton = [[NavigationBarButton alloc] initWithTitle:@"New Step"
																				  target:nil
																				  action:NULL];
		newStepButton.tag = 1234;
		navigationBar.rightBarButton = newStepButton;
	}
}

- (void)navigationBar:(NavigationBar *)navigationBar didDragItems:(NSArray *)items onBarButton:(NavigationBarButton *)button
{
	if (button.tag == 1234) {
		Step * step = [[Step alloc] initWithName:[self defaultNewStepName]
									 description:@""
										 project:_project
							   insertIntoLibrary:_project.library];
		
		NSMutableArray * paths = [NSMutableArray arrayWithCapacity:items.count];
		for (NSPasteboardItem * item in items) {
			
			NSString * path = item.filePath;
			if (path)
				[paths addObject:path];
		}
		[self moveItemsFromPaths:paths recursive:NO insertIntoStep:step atRowIndex:-1];
		
		[self reloadData];
	}
}

- (void)navigationBar:(NavigationBar *)navigationBar didEndDragOnBarButton:(NavigationBarButton *)button
{
	NavigationBarButton * backButton = [[NavigationBarButton alloc] initWithType:kNavigationBarButtonTypeBack
																		  target:self
																		  action:@selector(backAction:)];
	_navigationBar.leftBarButton = backButton;
	
	NavigationBarButton * editButton = [[NavigationBarButton alloc] initWithTitle:@"Edit"
																		   target:self
																		   action:@selector(editAction:)];
	_navigationBar.rightBarButton = editButton;
}

#pragma mark - IndexWebView Delegate -

- (void)indexWebView:(IndexWebView *)indexWebView didSelectLinkedStepWithName:(NSString *)stepName
{
	BOOL founds = NO;
	NSInteger index = 1;// Begin at "one" for the description section
	if (showsIndexDescription) index++;// Add a section for the index
	for (Step * step in steps) {
		if ([stepName isEqualToString:step.name]) {
			founds = YES; break;
		}
		index++;
	}
	
	if (founds)
		[self.tableView scrollToSection:index openSection:YES position:TableViewPositionNone];
}

- (void)indexWebView:(IndexWebView *)indexWebView didClickOnLink:(NSURL *)webURL
{
	BOOL success = [[NSWorkspace sharedWorkspace] openURL:webURL];
	if (!success) {
		NSAlert * alert = [NSAlert alertWithMessageText:@"The URL can't be opened"
										  defaultButton:@"OK"
										alternateButton:nil
											otherButton:nil
							  informativeTextWithFormat:[NSString stringWithFormat:@"Check the URL: %@", webURL.absoluteString], nil];
		[alert beginSheetModalForWindow:self.view.window
						  modalDelegate:nil
						 didEndSelector:NULL
							contextInfo:NULL];
	}
}

- (BOOL)indexWebView:(IndexWebView *)indexWebView shouldDragFile:(NSString *)path dragOperation:(NSDragOperation)operation
{
	NSString * content = [[NSString alloc] initWithContentsOfFile:path usedEncoding:nil error:NULL];
	BOOL containsText = (content.length > 0);
	
	return containsText;
}

- (void)indexWebView:(IndexWebView *)indexWebView didDragFile:(NSString *)path dragOperation:(NSDragOperation)operation
{
	[self saveTextIndexAction:nil];// Save the old index file
	
#if _SANDBOX_SUPPORTED_
	NSURL * fileURL = [NSURL fileURLWithPath:path];
	NSData * bookmarkData = [fileURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
							  includingResourceValuesForKeys:nil
											   relativeToURL:nil
													   error:NULL];
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:bookmarkData forKey:path];
#endif
	
	[_project updateValue:path forKey:@"indexPath"];
	
	NSRect frame = _indexWebView.frame;
	frame.size.width = self.tableView.frame.size.width;
	_indexWebView.frame = frame;
	
#if _SANDBOX_SUPPORTED_
	[fileURL startAccessingSecurityScopedResource];
	[_indexWebView loadIndexAtURL:fileURL];
	[fileURL stopAccessingSecurityScopedResource];
#else
	[_indexWebView loadIndexAtPath:path];
#endif
}

#pragma mark - TableView DataSource -

- (Item *)itemAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger newRow = (indexPath.section - 1);
	if (showsIndexDescription || _editing) newRow--;
	if (newRow != -1)
		return (Item *)((NSArray *)itemsArray[newRow])[indexPath.row];
	return nil;
}

- (Step *)stepForSection:(NSInteger)section
{
	section--;// Remove the "Description" section
	if (showsIndexDescription || _editing) section--;
	if (0 <= section && section < steps.count)
		return steps[section];
	
	return nil;
}

- (NSString *)placeholderForTableView:(TableView *)tableView
{
	return (itemsArray.count == 0)? @"No Steps" : nil;
}

- (NSInteger)numberOfSectionsInTableView:(TableView *)tableView
{
	NSInteger numberOfSections = 1 + ((showsIndexDescription || _editing)? 1: 0) + steps.count;
	return numberOfSections;
}

- (NSArray *)titlesForSectionsInTableView:(TableView *)tableView
{
	NSMutableArray * titles = [NSMutableArray arrayWithCapacity:steps.count];
	[titles addObject:@"Description"];
	
	if (showsIndexDescription || _editing)
		[titles addObject:@"Notes"];
	
	for (Step * step in steps) {
		[titles addObject:step.name];
	}
	return (NSArray *)titles;
}

- (NSInteger)tableView:(TableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0)
		return 1;
	
	if ((showsIndexDescription || _editing) && section == 1)
		return 1;
	
	NSInteger newSection = (section - 1);
	if (showsIndexDescription || _editing) newSection--;
	return ((NSArray *)itemsArray[newSection]).count;
}

- (CGFloat)tableView:(TableView *)tableView rowHeightAtIndex:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0)
		return _descriptionTextField.frame.size.height + (2 * 2.);// Add 2px margin on top and bottom
	else if (showsIndexDescription && indexPath.section == 1)
		return indexWebViewHeight;
	
	return 24.;
}

- (TableViewCell *)tableView:(TableView *)tableView cellForIndexPath:(NSIndexPath *)indexPath
{
	TableViewCell * cell = [[TableViewCell alloc] initWithStyle:TableViewCellStyleDefault reusableIdentifier:nil];
	
	if (indexPath.section == 0) {
		
		NSRect cellFrame = cell.frame;
		cellFrame.size.width = tableView.frame.size.width;
		cell.frame = cellFrame;
		
		NSRect frame = _descriptionTextField.frame;
		frame.size.width = cell.frame.size.width - (2 * 8.);
		_descriptionTextField.frame = frame;
		[cell addSubview:_descriptionTextField];
		
		if (_project.description.length > 0) {
			cell.colorStyle = TableViewCellBackgroundColorStyleWhite;
		} else {
			cell.colorStyle = TableViewCellBackgroundColorStyleGray;
			cell.textField.alignment = NSCenterTextAlignment;
			cell.textField.textColor = [NSColor darkGrayColor];
			cell.title = @"No Description";
		}
		
	} else if ((showsIndexDescription || _editing) && indexPath.section == 1) {
		if (showsIndexDescription) {
			cell.colorStyle = TableViewCellBackgroundColorStyleWhite;
			
			NSRect frame = _indexWebView.frame;
			frame.size.width = cell.frame.size.width - (2 * 2.);
			_indexWebView.frame = frame;
			[cell addSubview:_indexWebView];
			
		} else if (_editing) {
			cell.colorStyle = TableViewCellBackgroundColorStyleGray;
			cell.textField.alignment = NSCenterTextAlignment;
			cell.title = @"Drag & Drop a text (*.txt) file to show it here.";
			cell.textField.textColor = [NSColor darkGrayColor];
		}
		
	} else {
		Item * item = [self itemAtIndexPath:indexPath];
		NSString * path = [_project.library pathForItem:item];
		
		NSInteger index = [types indexOfObject:item.type];
		cell.image = typeImages[index];
		cell.selectedImage = typeSelectedImages[index];
		
		if ([item.type isEqualToString:kItemTypeText]) {// Text
			NSAttributedString * attributedString = [[NSAttributedString alloc] initWithPath:path
																		  documentAttributes:NULL];
			if (attributedString)
				cell.title = [[attributedString string] stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
			else {
				cell.title = @"File not found";
				cell.textField.textColor = [NSColor grayColor];
			}
			
			
		} else if ([item.type isEqualToString:kItemTypeWebURL]) {// URL
			NSString * content = [[NSString alloc] initWithContentsOfFile:path
															 usedEncoding:nil
																	error:NULL];
			if (content)
				cell.title = content;
			else {
				cell.title = @"File not found";
				cell.textField.textColor = [NSColor grayColor];
			}
			
		} else {// Image and File
			
			NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
			if ([userDefaults boolForKey:@"Show Path For Linked Items"]) {
				
				NSString * newPath = [[_project.library pathForItem:item] stringByAbbreviatingWithTildeInPath];
				NSMutableAttributedString * mutableString = [[NSMutableAttributedString alloc] initWithString:newPath attributes:nil];
				
				NSRange rootPathRange = [newPath rangeOfString:[newPath stringByDeletingLastPathComponent]];
				rootPathRange.length++;// Add one to the length for the "/" between the root path and the last path component
				NSDictionary * attributes = @{NSForegroundColorAttributeName: [NSColor grayColor]};
				[mutableString setAttributes:attributes range:rootPathRange];
				[cell.textField.cell setAttributedStringValue:mutableString];
				
			} else {
				NSString * path = [item.library pathForItem:item];
				cell.title = path.lastPathComponent;
			}
			
			
#if _SANDBOX_SUPPORTED_
			[[NSURL fileURLWithPath:path] startAccessingSecurityScopedResource];
#endif
			
			if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
				cell.textField.textColor = [NSColor grayColor];
			}
			
#if _SANDBOX_SUPPORTED_
			[[NSURL fileURLWithPath:path] stopAccessingSecurityScopedResource];
#endif
		}
		
		//cell.colorStyle = (indexPath.row % 2)? TableViewCellBackgroundColorStyleGrayGradient : TableViewCellBackgroundColorStyleWhiteGradient;
		cell.colorStyle = (indexPath.row % 2)? TableViewCellBackgroundColorStyleGray : TableViewCellBackgroundColorStyleWhite;
		cell.selectedColorStyle = TableViewCellSelectedColorDefaultGradient;
	}
	
	return cell;
}

- (BOOL)tableView:(TableView *)tableView shouldSelectCell:(TableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	if (showsIndexDescription || _editing)
		return (indexPath.section >= 2);
	
	return (indexPath.section >= 1);
}

- (BOOL)tableView:(TableView *)tableView couldCloseSection:(NSInteger)section
{
	return YES;
	
	/*
	 if (showsIndexDescription || _editing)
	 return (section < 2);
	 
	 return (section < 1);
	 */
}

#pragma mark - TableView Delegate -

#pragma mark Section and Cell Editing
- (void)tableView:(TableView *)tableView setString:(id)stringValue forSection:(NSInteger)section
{
	Step * step = [self stepForSection:section];
	[step updateValue:stringValue forKey:@"name"];
}

#pragma mark Event
- (TableViewCellEvent)tableView:(TableView *)tableView tracksEventsForSection:(NSInteger)section
{
	if (section >= 2) {
		return (TableViewCellEventMouseEntered | TableViewCellEventMouseExited);
	}
	return 0;
}

- (void)tableView:(TableView *)tableView didReceiveEvent:(TableViewCellEvent)event forSection:(NSInteger)section
{
	[_tableView enableEditing:(event == TableViewCellEventMouseEntered)
				   forSection:section];
}

- (void)tableView:(TableView *)tableView didSelectCell:(TableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	[_quickLookMenuItem setEnabled:YES];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"TableViewDidSelectCell"
														object:tableView];
}

- (void)tableView:(TableView *)tableView didChangeState:(TableViewSectionState)state ofSection:(NSInteger)section
{
	Step * step = [self stepForSection:section];
	if (step) {
		step.closed = (state == TableViewSectionStateClose);
		[step update];
	}
}

#pragma mark Double Click
- (void)tableView:(TableView *)tableView didDoubleClickOnCell:(TableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	Item * item = nil;
	if (showsIndexDescription && indexPath.section >= 2)// From the third section (index = 2) if the "Notes" section is shown
		item = (Item *)((NSArray *)itemsArray[(indexPath.section - 2)])[indexPath.row];
	else if (!showsIndexDescription && indexPath.section >= 1)// From the second section (index = 1) if the "Notes" section is not shown
		item = (Item *)((NSArray *)itemsArray[(indexPath.section - 1)])[indexPath.row];
	
	if (item) {
		NSURL * fileURL = [_project.library URLForItem:item];
		//NSString * path = [_project.library pathForItem:item];
		
#if _SANDBOX_SUPPORTED_
		[fileURL startAccessingSecurityScopedResource];
#endif
		BOOL success = [[NSWorkspace sharedWorkspace] openURL:fileURL];
		
#if _SANDBOX_SUPPORTED_
		[fileURL stopAccessingSecurityScopedResource];
#endif
		if (!success) {
			NSAlert * alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"The file \"%@\" couldn't be openned.", [fileURL path]]
											  defaultButton:@"OK"
											alternateButton:nil
												otherButton:nil
								  informativeTextWithFormat:nil];
			[alert beginSheetModalForWindow:self.view.window
							  modalDelegate:nil
							 didEndSelector:NULL
								contextInfo:nil];
		}
	}
}

#pragma mark Right Click Menu

- (NSMenu *)rightClickMenuForTableView:(TableView *)tableView forSection:(NSInteger)section
{
	NSMenu * menu = nil;
	if ((showsIndexDescription && section >= 2) || (!showsIndexDescription && section >= 1)) {
		menu = [[NSMenu alloc] initWithTitle:@"section-tableView-menu"];
		[menu addItemWithTitle:@"Delete Step..." target:self action:@selector(deleteSelectedStepAction:)];
	}
	return menu;
}

- (NSMenu *)rightClickMenuForTableView:(TableView *)tableView forCellAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger section = indexPath.section - 1;
	if (showsIndexDescription) section--;
	
	if (section >= 0) {
		Item * item = (Item *)((NSArray *)itemsArray[section])[indexPath.row];
		NSString * path = [_project.library pathForItem:item];
		
#if _SANDBOX_SUPPORTED_
		[[NSURL fileURLWithPath:path] startAccessingSecurityScopedResource];
#endif
		
		BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:path];
		
		/*
		 * For "FILE": the menu contains "Open With {Default App}", "Show in Finder", "|", "Export...", "|", "Delete..."
		 * For "FOLD": the menu contains "Show in Finder", "|", "Export...", "|", "Delete..."
		 * The others types contains "FILE" options and theses extra options:
		 * For "IMG": the menu contains "Copy Image to Pasteboard", "|"
		 * For "TEXT": the menu contains "Copy Text to Pasteboard", "|"
		 * For "URL": the menu contains "Copy URL to Pasteboard", "|"
		 * Note: If the default application can't be found, replace the menu item with the disabled one "No Default Applications"
		 *		 If the file doesn't longer exist, just show "Item not found"
		 */
		
		NSMenu * menu = [[NSMenu alloc] initWithTitle:@"tableview-menu"];
		
		if (exist) {
			
			/* Add the "Open with..." at the beginning of the menu */
			NSURL * url = nil;
			if ([item.type isEqualToString:kItemTypeWebURL]) {// Web links
				NSString * webURLString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
				url = [NSURL URLWithString:webURLString];
			} else {// Files, Images and Texts
				url = [NSURL fileURLWithPath:path];
			}
			
			NSString * defaultApplicationPath = [[[NSWorkspace sharedWorkspace] URLForApplicationToOpenURL:url] path];
			if (defaultApplicationPath) {
				/* -[NSWorkspace getInfoForFile:application:type:] returns the path to the application; retreive only the name of the application (i.e.: remove the path and ".app") */
				NSString * defaultApplication = [[defaultApplicationPath lastPathComponent] stringByDeletingPathExtension];
				[menu addItemWithTitle:[NSString stringWithFormat:@"Open With %@", defaultApplication]
								target:self
								action:@selector(openWithDefaultApplicationAction:)];
			} else {
				[menu addItemWithTitle:@"No Default Applications" target:self action:NULL];// "NULL" to disable the item
			}
			
			/* Add "Copy .. to Pasteboard" */
			if ([item.type isEqualToString:kItemTypeImage]) {// Images
				[menu addItemWithTitle:@"Copy Image to Pasteboard" target:self action:@selector(copyToPasteboardSelectedItemAction:)];
				[menu addItem:[NSMenuItem separatorItem]];
			} else if ([item.type isEqualToString:kItemTypeText]) {// Texts
				[menu addItemWithTitle:@"Copy Text to Pasteboard" target:self action:@selector(copyToPasteboardSelectedItemAction:)];
				[menu addItem:[NSMenuItem separatorItem]];
			} else if ([item.type isEqualToString:kItemTypeWebURL]) {// Web links
				[menu addItemWithTitle:@"Copy URL to Pasteboard" target:self action:@selector(copyToPasteboardSelectedItemAction:)];
				[menu addItem:[NSMenuItem separatorItem]];
			}
			
			/* Folders have theses options */
			[menu addItemWithTitle:@"Show in Finder" target:self action:@selector(showInFinderAction:)];
			
			if (!([item.type isEqualToString:kItemTypeFile] && item.filename == nil)) {// Don't show "Export" for linked files
				[menu addItem:[NSMenuItem separatorItem]];
				[menu addItemWithTitle:@"Export..." target:self action:@selector(exportSelectedItemAction:)];
			}
		} else {
			[menu addItemWithTitle:@"File not Found" target:self action:NULL];// "NULL" to disable the item
			
			/* Add a "Locate..." item to let the user select the new location of the file */
			[menu addItemWithTitle:@"Locate..." target:self action:@selector(locateSelectedItemAction:)];
		}
		
		[menu addItem:[NSMenuItem separatorItem]];
		[menu addItemWithTitle:@"Delete..." target:self action:@selector(deleteSelectedItemAction:)];
		
#if _SANDBOX_SUPPORTED_
		[[NSURL fileURLWithPath:path] stopAccessingSecurityScopedResource];
#endif
		
		return menu;
	}
	return nil;
}

#pragma mark TableView Drag & Drop

- (BOOL)tableView:(TableView *)tableView allowsDragOnSection:(NSInteger)section
{
	return (section > 0);// Don't allow drag&Drop for the "Description" section and if no sections are selected

}

- (BOOL)tableView:(TableView *)tableView allowsDragOnCellAtIndexPath:(NSIndexPath *)indexPath
{
	return (indexPath.section > 0);// Don't allow drag&Drop for the "Description" section and if no sections are selected
}

- (BOOL)tableView:(TableView *)tableView shouldDragItems:(NSArray *)pasteboardItems atIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0) {
		return NO;
	} else if ((showsIndexDescription || _editing) && indexPath.section == 1) {
		if (pasteboardItems.count == 1) {
			// @TODO: if plain text is dragged, create a file with the text content then use the file as index
			
			NSString * path = [(NSPasteboardItem *)pasteboardItems[0] filePath];
			if (path) {
				NSString * contentString = [[NSString alloc] initWithContentsOfFile:path
																		usedEncoding:nil
																			   error:NULL];
				return (contentString.length > 0);
			} else {
				return NO;
			}
		}
		return NO;
	} else {
		return YES;
	}
}

- (NSDragOperation)tableView:(TableView *)tableView dragOperationForItems:(NSArray *)items proposedOperation:(NSDragOperation)proposedDragOp atIndexPath:(NSIndexPath *)indexPath
{
	/* If the file is on system volume:
	 *		If "proposedDragOp" is a copy, move or generic (move)
	 *			return "proposedDragOp"
	 *		else
	 *			return the default drag operation from userDefaults
	 * Else show return "NSDragOperationCopy"
	 */
	
	NSPasteboardItem * item = nil;
	if (items.count > 0) { item = items[0]; }
	
	NSURL * volumeURL = nil;
	[item.fileURL getResourceValue:&volumeURL forKey:NSURLVolumeURLKey error:NULL];
	
	if (volumeURL) {
		if (volumeURL.path.length == 1) {// If the path is on system volume (volume equals to "/")
			if (proposedDragOp != NSDragOperationCopy && proposedDragOp != NSDragOperationLink & proposedDragOp != NSDragOperationGeneric) {
				NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
				NSString * defaultDragOp = [userDefaults stringForKey:@"Default-Drag-Operation"];
				if (defaultDragOp) {// If we have a default drag operation
					return ([defaultDragOp isEqualToString:@"Copy"])? NSDragOperationCopy : (([defaultDragOp isEqualToString:@"Link"])? NSDragOperationLink : NSDragOperationMove);
				} else {// "Move" by default
					return NSDragOperationMove;
				}
			}
		} else {
			return NSDragOperationCopy;
		}
	}
	
	return proposedDragOp;
}

- (void)tableView:(TableView *)tableView didDragItems:(NSArray *)pasteboardItems withDraggingInfo:(id <NSDraggingInfo>)draggingInfo atIndexPath:(NSIndexPath *)indexPath
{
	if ((showsIndexDescription || _editing) && indexPath.section == 1) {
		if (pasteboardItems.count == 1) {
			
			NSString * path = [(NSPasteboardItem *)pasteboardItems[0] filePath];
			if (path) {
				[self saveTextIndexAction:nil];// Save the old index file
				[_project updateValue:path forKey:@"indexPath"];
				
#if _SANDBOX_SUPPORTED_
				NSURL * fileURL = [NSURL fileURLWithPath:path];
				NSData * bookmarkData = [fileURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
										  includingResourceValuesForKeys:nil
														   relativeToURL:nil
																   error:NULL];
				NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
				[userDefaults setObject:bookmarkData forKey:path];
				
				[fileURL startAccessingSecurityScopedResource];
				[_indexWebView loadIndexAtURL:fileURL];
				[fileURL stopAccessingSecurityScopedResource];
#else
				[_indexWebView loadIndexAtPath:path];// Reload the webView with the new index file
#endif
			}
		}
	} else {
		NSInteger section = (indexPath.section - 1);
		if (showsIndexDescription || _editing) section--;
		Step * step = steps[section];
		
		NSString * destinationPath = [_project.library pathForStepFolder:step];
		
		/* Best type is, in this order, an image, a RTF text content, a web URL, plain text content (all dragged from an application) or a file/folder (i.e.: a path to a file/folder) */
		NSArray * registeredDraggedTypes = @[@"public.image" /* Images from an application (not on disk) */,
											NSPasteboardTypeRTF /* RTF formatted data (before NSPasteboardTypeString because RTF data are string, so NSPasteboardTypeString will be preferred if it's placed before NSPasteboardTypeRTF) */,
											NSPasteboardTypeString /* Text content */,
											@"public.file-url"];
		
		NSMutableArray * paths = [[NSMutableArray alloc] initWithCapacity:pasteboardItems.count];
		for (NSPasteboardItem * item in pasteboardItems) {
			
			NSString * bestType = [item availableTypeFromArray:registeredDraggedTypes];
			
			NSString * path = nil;
			NSString * itemType = kItemTypeFile;
			
			if (UTTypeConformsTo((__bridge CFStringRef)bestType, CFSTR("public.image"))) {// Images from browser (or else), not on disk
				
				NSData * data = [item dataForType:bestType];
				NSString * extension = [[NSWorkspace sharedWorkspace] preferredFilenameExtensionForType:bestType];
				path = [NSString stringWithFormat:@"%@/%@", destinationPath, [self freeDraggedFilenameForStep:step extension:extension]];
				[data writeToFile:path atomically:YES];
				
				itemType = kItemTypeImage;
				
			} else if ([bestType isEqualToString:NSPasteboardTypeRTF]) {// RTF content
				
				NSData * data = [item dataForType:bestType];
				NSString * extension = [[NSWorkspace sharedWorkspace] preferredFilenameExtensionForType:bestType];
				path = [NSString stringWithFormat:@"%@/%@", destinationPath, [self freeDraggedFilenameForStep:step extension:extension]];
				[data writeToFile:path atomically:YES];
				
				itemType = kItemTypeText;
				
			} else if ([bestType isEqualToString:NSPasteboardTypeString]) {
				
				NSString * stringContent = [item propertyListForType:NSPasteboardTypeString];
				
				/* check if the URL start with "***://", if not, add it to create a valid URL */
				NSMutableString * URLString = [stringContent mutableCopy];
				if ([URLString rangeOfString:@"."].location != NSNotFound) {
					NSRange protocolRange = [URLString rangeOfString:@"://"];
					if (protocolRange.location == NSNotFound)
						[URLString insertString:@"http://" atIndex:0];
				}
				
				NSURL * url = nil;
				if (URLString && (url = [NSURL URLWithString:URLString])
					&& [NSURLConnection canHandleRequest:[NSURLRequest requestWithURL:url]]) {// Valid URL
					
					NSData * data = [item dataForType:bestType];
					path = [NSString stringWithFormat:@"%@/%@", destinationPath, [self freeDraggedFilenameForStep:step extension:@"txt"]];
					[data writeToFile:path atomically:YES];
					
					itemType = kItemTypeWebURL;
					
				} else {// Text content
					NSData * data = [item dataForType:bestType];
					path = [NSString stringWithFormat:@"%@/%@", destinationPath, [self freeDraggedFilenameForStep:step extension:@"txt"]];
					[data writeToFile:path atomically:YES];
					
					itemType = kItemTypeText;
				}
			} else if ([bestType isEqualToString:@"public.file-url"]){// Files and folders
				
				path = item.filePath;
				
				BOOL isDirectory, isBundle, isPackage;
				[[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
				[[NSURL fileURLWithPath:path] fileIsBundle:&isBundle isPackage:&isPackage];
				itemType = (isDirectory && !isBundle && !isPackage)? kItemTypeFolder: kItemTypeFile;
				
			} else {
				[NSException raise:@"ProjectViewControllerException" format:@"Unrecognized or invalid pasteboard type: %@", bestType];
			}
			
			if (path) {
				if ([itemType isEqualToString:kItemTypeFile] || [itemType isEqualToString:kItemTypeFolder]) {
					[paths addObject:path];
				} else {
					Item * item = [[Item alloc] initWithFilename:[path lastPathComponent]
															type:itemType
														rowIndex:(int)indexPath.row
															step:step
											   insertIntoLibrary:_project.library];
				}
			}
			
			// @TODO: if the source is not on the same volume that destination (library), show copy as the only way (see draggingSourceOperationMaskForLocal:)
		}
		
		if (paths.count > 0) {
			
			NSLog(@"paths: %@", paths);
			
			NSDragOperation op = [draggingInfo draggingSourceOperationMask];
			/*
			 BOOL moved = (op & NSDragOperationMove);
			 BOOL copied = (op & NSDragOperationCopy);
			 BOOL linked = (op & NSDragOperationLink);
			 BOOL isGeneric = (op & NSDragOperationGeneric);
			 */
			
			if (op & NSDragOperationGeneric) {
				NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
				NSString * defaultDragOp = [userDefaults stringForKey:@"Default-Drag-Operation"];
				if (defaultDragOp) {
					op = ([defaultDragOp isEqualToString:@"Copy"])? NSDragOperationCopy : (([defaultDragOp isEqualToString:@"Link"])? NSDragOperationLink : NSDragOperationMove);
				} else {
					[self askForDefaultDragOperation:paths step:step atIndex:indexPath.row];
					return;
				}
			}
			
			if (op & NSDragOperationMove){// "Command" (cmd) Key, move items
				// @TODO: show an alert (like when copying) to ask for recursivity => used???
				[self moveItemsFromPaths:paths recursive:NO insertIntoStep:step atRowIndex:(int)indexPath.row];
				
			} else if (op & NSDragOperationCopy) {// "Option" (alt) Key, copy items
				
				BOOL containsDirectory = NO;
				for (NSString * path in paths) {
					NSNumber * isDirectory = nil;
					[[NSURL fileURLWithPath:path] getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
					if ([isDirectory boolValue]) {
						containsDirectory = YES;
						break;
					}
				}
				
				if (containsDirectory) {
					NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
					if ([[userDefaults arrayForKey:@"Alerts to Hide"] containsObject:@"Recursive Alert"]) {
						
						BOOL recursive = [userDefaults boolForKey:@"Use Recursivity"];
						[self copyItemsFromPaths:paths
									   recursive:recursive
								  insertIntoStep:step
									  atRowIndex:-1];
						
					} else {
						
						NSAlert * alert = [NSAlert alertWithMessageText:@"Recursive?"
														  defaultButton:@"Non Recursive"
														alternateButton:@"Recursive"
															otherButton:nil
											  informativeTextWithFormat:@""];
						alert.showsSuppressionButton = YES;
						
						NSDictionary * contextInfo = @{@"paths" : paths, @"step" : step};
						[alert beginSheetModalForWindow:self.view.window
										  modalDelegate:self
										 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
											contextInfo:(__bridge_retained void *)contextInfo];
					}
					
				} else {
					[self copyItemsFromPaths:paths recursive:NO insertIntoStep:step atRowIndex:(int)indexPath.row];
				}
				
			} else if (op & NSDragOperationLink) {// "Control" (ctrl) Key, link items
				[self linkItemsFromPaths:paths recursive:NO insertIntoStep:step atRowIndex:(int)indexPath.row];
			}
		}
		
	}
}

#pragma mark Resizing delegate

- (BOOL)tableView:(TableView *)tableView shouldInvalidateContentLayoutForSize:(NSSize)newSize
{
	/* Get new height from the description's TextField */
	NSRect frame = _descriptionTextField.frame;
	CGFloat oldHeight = frame.size.height;
	
	frame.size.height = INFINITY;
	frame.size.width = newSize.width - (2 * 8.);
	NSSize size = [_descriptionTextField.cell cellSizeForBounds:frame];
	frame.size.height = size.height;
	_descriptionTextField.frame = frame;
	
	/* Get new height from the index's WebView */
	CGFloat oldIndexWebViewHeight = _indexWebView.contentHeight;
	BOOL needsLayout = (indexWebViewHeight != oldIndexWebViewHeight);
	indexWebViewHeight = oldIndexWebViewHeight;
	
	return ((oldHeight != frame.size.height) || needsLayout);
}

#pragma mark TableView Event

- (void)tableView:(TableView *)tableView didReceiveKeyString:(NSString *)keyString
{
	if ([keyString isEqualToString:@" "]) {// "Space" key
		[self showQuickLookAction:nil];
	}
}

#pragma mark - Files and Folders Operations -

- (void)copyDirectoryContentAtPath:(NSString *)path recursive:(BOOL)recursive
{
	NSDirectoryEnumerator * enumerator = [[NSFileManager defaultManager] enumeratorAtURL:[NSURL fileURLWithPath:path]
															  includingPropertiesForKeys:@[NSURLIsDirectoryKey, NSURLNameKey]
																				 options:(NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles)
																			errorHandler:^BOOL(NSURL *url, NSError *error) {
																				NSLog(@"error: %@", [error localizedDescription]);
																				return YES;// Return "YES" to continue enumeration of error
																			}];
	/* Create a step from the directory at "path" */
	NSString * name = [NSString stringWithFormat:@"Step with folder named \"%@\"", [path lastPathComponent]];
	Step * step = [[Step alloc] initWithName:name
								 description:nil
									 project:_project
						   insertIntoLibrary:_project.library];
	
	for (NSURL * fileURL in enumerator) {
		
		NSString * destinationFolder = [_project.library pathForStepFolder:step];
		NSString * newFilename = [self freeFilenameForPath:[NSString stringWithFormat:@"%@/%@", destinationFolder, [path lastPathComponent]]];
		
		/* Generate a path like: {Path to Default Library}/{Project Name}/{Step Name}/{File Name}.{Extension} */
		NSString * destinationPath = [NSString stringWithFormat:@"%@/%@", destinationFolder, newFilename];
		
		NSNumber * isDirectory = nil;
        [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
		if ([isDirectory boolValue]) {
			
			if (recursive) {
				[self copyDirectoryContentAtPath:destinationPath recursive:YES];
			} else {
				/* Create en Item with the folder at "path" */
				Item * item = [[Item alloc] initWithFilename:newFilename
														type:@"FOLD"
													rowIndex:-1
														step:step
										   insertIntoLibrary:_project.library];
			}
			
		} else {
			/* Create en Item with the file at "path" */
			Item * item = [[Item alloc] initWithFilename:newFilename
													type:kItemTypeFile
												rowIndex:-1
													step:step
									   insertIntoLibrary:_project.library];
		}
	}
	
	[self reloadData];
}

- (void)copyItemsFromPaths:(NSArray *)paths defaultStep:(Step *)defaultStep recursive:(BOOL)recursive
{
	[self copyItemsFromPaths:paths recursive:recursive insertIntoStep:defaultStep atRowIndex:-1];
}

- (void)copyItemsFromPaths:(NSArray *)paths recursive:(BOOL)recursive insertIntoStep:(Step *)step atRowIndex:(int)rowIndex
{
	NSFileManager * manager = [[NSFileManager alloc] init];
	
	/* Items are inserted into the database with a reverse order because items are inserted at the same index so the first item will be inserted after the second item (the "rowIndex" of the first item will be greater than the "rowIndex" of the second item) */
	for (NSString * path in [paths reverseObjectEnumerator]) {
		NSNumber * isDirectory = nil;
		// @TODO: get error and do smtg with it
		BOOL success = [[NSURL fileURLWithPath:path] getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
		if (isDirectory.boolValue) {// Directories
			
			[self copyDirectoryContentAtPath:path
								   recursive:recursive];
			
		} else {// Files
			NSString * destinationFolder = [_project.library pathForStepFolder:step];
			NSString * newFilename = [self freeFilenameForPath:[NSString stringWithFormat:@"%@/%@", destinationFolder, [path lastPathComponent]]];
			
			/* Generate a path like: {Path to Default Library}/{Project Name}/{Step Name}/{File Name}.{Extension} */
			NSString * destinationPath = [NSString stringWithFormat:@"%@/%@", destinationFolder, newFilename];
			
			NSError * error = nil;
			BOOL success = [manager createDirectoryAtPath:[destinationPath stringByDeletingLastPathComponent]
							  withIntermediateDirectories:YES
											   attributes:nil
													error:&error];
			if (!success)
				NSLog(@"Create directory error: %@", [error localizedDescription]);
			
			if (success) {
				
				NSNumber * filesize = nil;
				[[NSURL fileURLWithPath:destinationPath] getResourceValue:&filesize forKey:NSURLFileSizeKey error:NULL];
				
				if (filesize.doubleValue >= (50 * 1024 * 1024)) {// For big files (>= 50MB)
					
					__unsafe_unretained NSString * itemNewFilename = newFilename;
					__block int itemRowIndex = rowIndex;
					__unsafe_unretained Step * itemStep = step;
					[manager copyItemAtPath:path
									 toPath:destinationPath
						 progressionHandler:^(float progression) {
							 // @TODO: show a progression alert
							 NSLog(@"Copy progression: %.0f", progression * 100.);
						 } 
						  completionHandler:^{
							  Item * item = [[Item alloc] initWithFilename:itemNewFilename
																	  type:kItemTypeFile
																  rowIndex:itemRowIndex
																	  step:itemStep
														 insertIntoLibrary:_project.library];
						  }
							   errorHandler:^(NSError *error) {
								   [NSApp presentError:error];
							   }];
				} else {
					NSError * error = nil;
					BOOL success = [manager copyItemAtPath:path
													toPath:destinationPath
													 error:&error];
					if (!success && error)
						[NSApp presentError:error];
					
					if (success) {
						Item * item = [[Item alloc] initWithFilename:newFilename
																type:kItemTypeFile
															rowIndex:rowIndex
																step:step
												   insertIntoLibrary:_project.library];
					}
				}
			}
		}
	}
	[self reloadData];
}

- (void)linkItemsFromPaths:(NSArray *)paths defaultStep:(Step *)defaultStep recursive:(BOOL)recursive
{
	[self linkItemsFromPaths:paths recursive:recursive insertIntoStep:defaultStep atRowIndex:-1];
}

- (void)linkItemsFromPaths:(NSArray *)paths recursive:(BOOL)recursive insertIntoStep:(Step *)step atRowIndex:(int)rowIndex
{
	/* Items are inserted into the database with a reverse order because items are inserted at the same index so the first item will be inserted after the second item (the "rowIndex" of the first item will be greater than the "rowIndex" of the second item) */
	for (NSString * path in [paths reverseObjectEnumerator]) {
		NSURL * fileURL = [NSURL fileURLWithPath:path];
		
		NSNumber * isDirectory = nil;
		[fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
		
		BOOL isBundle, isPackage;
		[[NSURL fileURLWithPath:path] fileIsBundle:&isBundle isPackage:&isPackage];
		NSString * itemType = ([isDirectory boolValue] && !isBundle && !isPackage)? kItemTypeFolder: kItemTypeFile;
		
		
		Item * item = [[Item alloc] initWithFilename:nil// Pass nil as filename
												type:itemType
											rowIndex:(int)rowIndex
												step:step
								   insertIntoLibrary:_project.library];
		
		NSURLBookmarkCreationOptions bookmarkOptions = 0;
#if _SANDBOX_SUPPORTED_
		bookmarkOptions = NSURLBookmarkCreationWithSecurityScope;
#endif
		NSError * error = nil;
		NSData * bookmarkData = [fileURL bookmarkDataWithOptions:bookmarkOptions
								  includingResourceValuesForKeys:nil
												   relativeToURL:nil// Use nil for app-scoped bookmark
														   error:&error];
		if (error)
			NSLog(@"error: %@", [error localizedDescription]);
		
		NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
		NSString * key = [NSString stringWithFormat:@"%i/%i/%i", step.project.identifier, step.identifier, item.identifier];// The key looks like "{Project ID}/{Step ID}/{Item ID}"
		[userDefaults setObject:bookmarkData forKey:key];
		
	}
	[self reloadData];
}

- (void)moveItemsFromPaths:(NSArray *)paths defaultStep:(Step *)defaultStep recursive:(BOOL)recursive
{
	[self moveItemsFromPaths:paths recursive:recursive insertIntoStep:defaultStep atRowIndex:-1];
}

- (void)moveItemsFromPaths:(NSArray *)paths recursive:(BOOL)recursive insertIntoStep:(Step *)step atRowIndex:(int)rowIndex
{
	NSFileManager * manager = [[NSFileManager alloc] init];
	
	/* Items are inserted into the database with a reverse order because items are inserted at the same index so the first item will be inserted after the second item (the "rowIndex" of the first item will be greater than the "rowIndex" of the second item) */
	for (NSString * path in [paths reverseObjectEnumerator]) {
		NSNumber * isDirectory = nil;
		// @TODO: get error and do smtg with it
		BOOL success = [[NSURL fileURLWithPath:path] getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
		if (isDirectory.boolValue) {// Directories
			[self copyDirectoryContentAtPath:path
								   recursive:recursive];
		} else {// Files
			
			NSString * destinationFolder = [_project.library pathForStepFolder:step];
			NSString * newFilename = [self freeFilenameForPath:[NSString stringWithFormat:@"%@/%@", destinationFolder, [path lastPathComponent]]];
			
			/* Generate a path like: {Path to Default Library}/{Project Name}/{Step Name}/{File Name}.{Extension} */
			NSString * destinationPath = [NSString stringWithFormat:@"%@/%@", destinationFolder, newFilename];
			
			NSError * error = nil;
			BOOL success = [manager createDirectoryAtPath:destinationFolder
							  withIntermediateDirectories:YES
											   attributes:nil
													error:&error];
			if (!success)
				NSLog(@"Create directory error: %@", [error localizedDescription]);
			
			if (success) {
				error = nil;
				success = [manager moveItemAtPath:path
										   toPath:destinationPath
											error:&error];
				if (!success)
					[NSApp presentError:error];
				
				if (success) {
					Item * item = [[Item alloc] initWithFilename:newFilename
															type:kItemTypeFile
														rowIndex:rowIndex
															step:step
											   insertIntoLibrary:_project.library];
				}
			}
		}
	}
	[self reloadData];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	NSDictionary * dictionary = (__bridge NSDictionary *)contextInfo;
	BOOL recursive = (returnCode == NSAlertAlternateReturn);
	[self copyItemsFromPaths:dictionary[@"paths"]
				   recursive:recursive
			  insertIntoStep:dictionary[@"step"]
				  atRowIndex:-1];
	// "dictionary" need to be released because it passed by "contextInfo"
	
	if (alert.suppressionButton.state == NSOnState) {
		
		NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
		NSMutableArray * alertsToHide = [[userDefaults objectForKey:@"Alerts to Hide"] mutableCopy];
		if (!alertsToHide)
			alertsToHide = [[NSMutableArray alloc] initWithCapacity:1];
		
		[alertsToHide addObject:@"Recursive Alert"];
		[userDefaults setObject:alertsToHide forKey:@"Alerts to Hide"];
		
		[userDefaults setBool:recursive forKey:@"Use Recursivity"];
	}
}

- (NSString *)freeDraggedFilenameForStep:(Step *)step extension:(NSString *)extension
{
	NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"dd-MM-yyyy HH.mm.ss"];
	NSString * dateString = [dateFormatter stringFromDate:[NSDate date]];
	
	NSString * filename = [NSString stringWithFormat:@"Dragged File %@%@", dateString, (extension)? [@"." stringByAppendingString:extension]: @""];
	NSString * stepFolder = [step.library pathForStepFolder:step];
	return [self freeFilenameForPath:[NSString stringWithFormat:@"%@/%@", stepFolder, filename]];
}

- (NSString *)freeFilenameForPath:(NSString *)path
{
	NSString * parentFolder = [path stringByDeletingLastPathComponent];
	NSString * filename = [[path lastPathComponent] stringByDeletingPathExtension];
	NSString * extension = [path pathExtension];
	
	NSFileManager * fileManager = [[NSFileManager alloc] init];
	int index = 2;
	NSString * newFilename = filename;
	while ([fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@/%@%@", parentFolder, newFilename, (extension.length > 0)? [NSString stringWithFormat:@".%@", extension]: @""]]) {
		newFilename = [NSString stringWithFormat:@"%@ (%i)", filename, index++];
	}
	
	NSString * extensionFormat = (extension.length > 0)? [NSString stringWithFormat:@".%@", extension]: @"";
	return [NSString stringWithFormat:@"%@%@", newFilename, extensionFormat];
}

#pragma mark - QLPreviewPanelDelegate

- (NSRect)previewPanel:(QLPreviewPanel *)panel sourceFrameOnScreenForPreviewItem:(id <QLPreviewItem>)item
{
	NSIndexPath * indexPath = self.tableView.indexPathOfSelectedRow;
	TableViewCell * cell = [self.tableView cellAtIndexPath:indexPath];
	NSPoint position = [self.tableView convertLocationFromWindow:cell.frame.origin];
	NSRect frame = cell.frame;
	frame.origin = [self.view.window convertBaseToScreen:position];
	frame.size = CGSizeMake(20., 20.);
	return frame;
}

- (NSImage *)previewPanel:(QLPreviewPanel *)panel transitionImageForPreviewItem:(id <QLPreviewItem>)item contentRect:(NSRect *)contentRect
{
	if (item) {
		NSString * path = [((Item *)item).library pathForItem:item];
		return [[NSWorkspace sharedWorkspace] iconForFile:path];
	}
	
	return nil;
}

#pragma mark - QLPreviewPanelDataSource

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel
{
	return 1;
}

- (id <QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index
{
	NSIndexPath * indexPath = self.tableView.indexPathOfSelectedRow;
	if (indexPath)
		return [self itemAtIndexPath:indexPath];
	return nil;
}

@end
