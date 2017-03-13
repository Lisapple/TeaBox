//
//  ProjectViewController.m
//  Tea Box
//
//  Created by Max on 04/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "ProjectViewController.h"
#import "SheetWindow.h"

#import "NSIndexPath+additions.h"
#import "NSMenu+additions.h"
#import "NSNotificationCenter+additions.h"
#import "NSURL+additions.h"
#import "NSFileManager+additions.h"
#import "NSAlert+additions.h"
#import "TBLibrary+Coding.h"

#import "Step+additions.h"
#import "Item+additions.h"

@interface CountdownItem (NSImage)

- (NSImage *)progressImageForStyle:(TableViewCellBackgroundColorStyle)style highlighted:(BOOL)highlighted;

@end

@implementation CountdownItem (NSImage)

- (NSImage *)progressImageForStyle:(TableViewCellBackgroundColorStyle)style highlighted:(BOOL)highlighted
{
	NSString * name = @"countdown";
	if (highlighted)
		name = [name stringByAppendingString:@"-highlighted"];
	else if (style == TableViewCellBackgroundColorStyleWhite)
		name = [name stringByAppendingString:@"-dark"];
	
	NSImage * image = [NSImage imageNamed:name];
	NSSize size = image.size;
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(NULL, (size_t)size.width, (size_t)size.height,
												 8, 0, colorSpace, kCGImageAlphaPremultipliedLast);
	
	CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), [image CGImageForProposedRect:nil context:nil hints:nil]);
	
	CGContextBeginPath(context);
	CGPoint center = CGPointMake(size.width / 2., size.height / 2.);
	CGContextMoveToPoint(context, center.x, center.y);
	CGContextAddLineToPoint(context, center.x, 0);
	
	const CGFloat radius = 6.;
	CGContextAddArc(context, center.x, center.y, radius, M_PI_2, M_PI_2 - 2*M_PI*(self.value / (CGFloat)self.maximumValue), true);
	CGContextClosePath(context);
	
	NSColor * color = [NSColor colorWithWhite:(highlighted) ? 1. : (151./255.) alpha:1.];
	CGContextSetFillColorWithColor(context, color.CGColor);
	CGContextFillPath(context);
	
	return [[NSImage alloc] initWithCGImage:CGBitmapContextCreateImage(context) size:size];
}

@end


@interface ProjectViewController ()

@property (unsafe_unretained) IBOutlet NSWindow * createStepWindow;
@property (unsafe_unretained) IBOutlet NSTextField * createStepLabel, * createStepField;
@property (unsafe_unretained) IBOutlet NSButton * createStepOKButton;

@property (unsafe_unretained) IBOutlet NavigationBar * navigationBar;
@property (unsafe_unretained) IBOutlet TableView * tableView;
@property (unsafe_unretained) IBOutlet NSTextField * bottomLabel;
@property (unsafe_unretained) IBOutlet NSButton * priorityButton;

@property (strong) IBOutlet NSTextField * descriptionTextField;

@property (unsafe_unretained) IBOutlet NSWindow * defaultDragOperationWindow;

@property (unsafe_unretained) IBOutlet NSTextField * projectNameLabel;
@property (unsafe_unretained) IBOutlet NSPopUpButton * priorityPopUpButton;

@property (unsafe_unretained) IBOutlet ImageImportFormWindow * imageImportFormWindow;
@property (unsafe_unretained) IBOutlet URLImportFormWindow * urlImportFormWindow;
@property (unsafe_unretained) IBOutlet TextImportFormWindow * textImportFormWindow;
@property (unsafe_unretained) IBOutlet TaskImportFormWindow * taskImportFormWindow;
@property (unsafe_unretained) IBOutlet CountdownImportFormWindow * countdownImportFormWindow;

@property (unsafe_unretained) IBOutlet NSMenuItem * quickLookMenuItem;

/// Is currently showing description from index file
@property (assign) BOOL showsIndexDescription;

/// Should show description from index file when editing
@property (assign) BOOL shouldShowIndexDescription;

@property(readonly) NSArray <Step *> * steps;

- (void)reloadBottomLabel;

- (IBAction)newStepAction:(id)sender;

- (IBAction)backAction:(id)sender;
- (IBAction)bottomButtonDidClickedAction:(id)sender;

- (IBAction)loadIndexAction:(id)sender;
- (IBAction)saveTextIndexAction:(id)sender;

- (void)setEditing:(BOOL)editing;
- (IBAction)editAction:(id)sender;
- (IBAction)doneAction:(id)sender;
- (IBAction)cancelAction:(id)sender;

- (IBAction)openWithDefaultApplicationAction:(id)sender;
- (IBAction)copyToPasteboardSelectedItemAction:(id)sender;
- (IBAction)exportSelectedItemAction:(id)sender;
- (IBAction)locateSelectedItemAction:(id)sender;
- (IBAction)deleteSelectedItemAction:(id)sender;

- (IBAction)deleteSelectedStepAction:(id)sender;

- (IBAction)priorityPopUpDidChangeAction:(id)sender;

- (IBAction)importImageAction:(id)sender;
- (IBAction)importURLAction:(id)sender;
- (IBAction)importTextAction:(id)sender;
- (IBAction)importFilesAndFoldersAction:(id)sender;

- (void)copyItemsFromPaths:(NSArray <NSString *> *)paths recursive:(BOOL)recursive insertIntoStep:(Step *)step atRowIndex:(NSInteger)rowIndex;
- (void)linkItemsFromPaths:(NSArray <NSString *> *)paths recursive:(BOOL)recursive insertIntoStep:(Step *)step atRowIndex:(NSInteger)rowIndex;
- (void)moveItemsFromPaths:(NSArray <NSString *> *)paths recursive:(BOOL)recursive insertIntoStep:(Step *)step atRowIndex:(NSInteger)rowIndex;

- (NSString *)freeDraggedFilenameForStep:(Step *)step extension:(NSString *)extension;
- (NSString *)freeFilenameForPath:(NSString *)path;

- (Item *)itemAtIndexPath:(NSIndexPath *)indexPath;
- (Step *)stepForSection:(NSInteger)section;

@end

@implementation ProjectViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if (!nibNameOrNil) nibNameOrNil = @"ProjectViewController";
	if (!nibBundleOrNil) nibBundleOrNil = [NSBundle mainBundle];
	
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) { }
    
    return self;
}

- (void)loadView
{
	NSAssert(self.project != nil, @"");
	NSAssert(self.library != nil, @"");
	
	[super loadView];
	
	NSArray <NSString *> * draggedTypes = @[ @"public.image", // Images from an application (not on disk)
											 NSPasteboardTypeRTF, // RTF formatted data (before NSPasteboardTypeString because RTF data are string, so NSPasteboardTypeString will be preferred if it's placed before NSPasteboardTypeRTF)
											 NSPasteboardTypeString, // Text content
											 @"public.file-url" ];
	[self.tableView registerForDraggedTypes:draggedTypes];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.rowHeight = 24.;
	
	self.navigationBar.leftBarButton = [[NavigationBarButton alloc] initWithType:NavigationBarButtonTypeBack
																		  target:self action:@selector(backAction:)];
	
	NavigationBarButton * importButton = [[NavigationBarButton alloc] initWithTitle:@"Add..."
																			 target:self action:@selector(importAction:)];
	NavigationBarButton * editButton = [[NavigationBarButton alloc] initWithTitle:@"Edit"
																		   target:self action:@selector(editAction:)];
	[editButton registerForDraggedTypes:draggedTypes];
	self.navigationBar.rightBarButtons = @[ editButton, importButton ];
	
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
		[SandboxHelper executeWithSecurityScopedAccessToPath:path block:^(NSError * error) {
			if (!error) {
				[_indexWebView loadIndexAtPath:path];
			}
		}];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResize:)
												 name:NSWindowDidResizeNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserverForName:NSControlTextDidChangeNotification
												  usingBlock:^(NSNotification *notification) {
		_createStepOKButton.enabled = (_createStepField.stringValue.length > 0); }];
	
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
	return YES;
}

- (BOOL)resignFirstResponder
{
	return YES;
}

- (void)setProject:(Project *)project
{
	_project = project;
	
	if (_project) {
		NSString * path = _project.indexPath;
		if (path.length > 0) {
			[SandboxHelper executeWithSecurityScopedAccessToPath:path block:^(NSError * error) {
				if (!error) {
					[_indexWebView loadIndexAtPath:path];
				}
			}];
		}
		
		[self reloadData];
	}
}

- (NSArray <Step *> *)steps
{
	return _project.steps;
}

- (void)reloadData
{
	_showsIndexDescription = (_project.indexPath != nil);
	_shouldShowIndexDescription = (_project.indexPath != nil);
	
	_navigationBar.title = _project.name;
	
	_descriptionTextField.editable = _editing;
	_descriptionTextField.stringValue = _project.description ?: @"";
	NSRect frame = _descriptionTextField.frame;
	frame.size.height = INFINITY;
	NSSize size = [_descriptionTextField.cell cellSizeForBounds:frame];
	frame.size.height = size.height;
	_descriptionTextField.frame = frame;
	
	NSMutableArray <NSArray <Item *> *> * _itemsArray = [[NSMutableArray alloc] initWithCapacity:self.steps.count];
	
	for (Step * step in self.steps)
		[_itemsArray addObject:step.items ?: @[]]; // `itemsArray` has the form: [[Item 1, Item 2], [], [Item]...]
	
	itemsArray = _itemsArray;
	
	[self.tableView reloadData];
	
	// Update section closed state
	NSInteger section = 1 + ((_showsIndexDescription || (_editing && _shouldShowIndexDescription))? 1: 0);
	for (Step * step in self.steps)
		[self.tableView setState:(step.closed)? TableViewSectionStateClose : TableViewSectionStateOpen
					  forSection:section++];
	
	[self reloadBottomLabel];
	
	[self.tableView becomeFirstResponder];
	
	_quickLookMenuItem.enabled = (self.tableView.indexPathOfSelectedRow != nil);
}

- (void)reloadBottomLabel
{
	if (_editing) {
		NSString * bottomString = [NSString stringWithFormat:@"Priority: %@", ProjectPriorityDescription(_project.projectPriority)];
		_bottomLabel.stringValue = bottomString;
		
		NSSize size = [bottomString sizeWithAttributes:@{NSFontAttributeName: _bottomLabel.font}];
		NSRect frame = _priorityButton.frame;
		frame.origin.x = (self.view.frame.size.width - size.width) / 2. - frame.size.width;
		_priorityButton.frame = frame;
	} else {
		NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
		formatter.dateStyle = NSDateFormatterShortStyle;
		formatter.timeStyle = NSDateFormatterShortStyle;
		_bottomLabel.stringValue = [NSString stringWithFormat:@"Priority: %@ - Modified: %@",
									ProjectPriorityDescription(_project.projectPriority),
									[formatter stringFromDate:_project.lastModificationDate]];
	}
	
	_priorityButton.hidden = !_editing;
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	indexWebViewHeight = _indexWebView.contentHeight;
	[self.tableView reloadDataForSection:1];
}

- (void)setEditing:(BOOL)editing
{
	if (editing) { // "Cancel" and "Done"
		NavigationBarButton * cancelButton = [[NavigationBarButton alloc] initWithTitle:@"Cancel"
																				 target:self action:@selector(cancelAction:)];
		_navigationBar.leftBarButton = cancelButton;
		
		NavigationBarButton * doneButton = [[NavigationBarButton alloc] initWithType:NavigationBarButtonTypeDone
																			  target:self action:@selector(doneAction:)];
		_navigationBar.rightBarButton = doneButton;
	} else { // "Back" and "Add" "Edit"
		NavigationBarButton * backButton = [[NavigationBarButton alloc] initWithType:NavigationBarButtonTypeBack
																			  target:self action:@selector(backAction:)];
		_navigationBar.leftBarButton = backButton;
		
		NavigationBarButton * addButton = [[NavigationBarButton alloc] initWithTitle:@"Add..."
																			  target:self action:@selector(importAction:)];
		NavigationBarButton * editButton = [[NavigationBarButton alloc] initWithTitle:@"Edit"
																			   target:self action:@selector(editAction:)];
		_navigationBar.rightBarButtons = @[ editButton, addButton ];
	}
	
	_navigationBar.editable = editing;
	
	_descriptionTextField.editable = editing;
	_descriptionTextField.drawsBackground = editing;
	
	if (editing) {
		[self.tableView startTrackingSections];
		[NSApp.mainWindow makeFirstResponder:_navigationBar.textField];
	} else {
		[self.tableView stopTrackingSections];
		[NSApp.mainWindow makeFirstResponder:nil];
	}
	
	_editing = editing;
	[self reloadData];
}

- (void)askForDefaultDragOperation:(NSArray <NSString *> *)paths step:(Step *)step atIndex:(NSInteger)rowIndex
{
	[self.view.window beginSheet:_defaultDragOperationWindow completionHandler:^(NSModalResponse returnCode) {
		if (returnCode == NSModalResponseOK) {
			NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
			NSString * defaultDragOp = [userDefaults stringForKey:@"Default-Drag-Operation"];
			if ([defaultDragOp isEqualToString:@"Copy"]) {
				
				BOOL containsDirectory = NO;
				for (NSString * path in paths) {
					NSNumber * isDirectory = nil;
					[[NSURL fileURLWithPath:path] getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
					if (isDirectory.boolValue) { containsDirectory = YES; break; }
				}
				
				if (containsDirectory) {
					if ([[userDefaults arrayForKey:@"Alerts to Hide"] containsObject:@"Recursive Alert"]) {
						BOOL recursive = [userDefaults boolForKey:@"Use Recursivity"];
						[self copyItemsFromPaths:paths recursive:recursive insertIntoStep:step atRowIndex:-1];
						
					} else {
						NSAlert * alert = [NSAlert alertWithStyle:NSAlertStyleWarning
													  messageText:@"Should Tea Box add all files recursively or add only files and folder at the root of this folder?"
												  informativeText:nil
													 buttonTitles:@[ @"Recursive", @"Cancel", @"Non Recursive" ]];
						alert.showsSuppressionButton = YES;
						[alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
							if (returnCode != NSAlertSecondButtonReturn/*Cancel*/) {
								BOOL recursive = (returnCode == NSAlertFirstButtonReturn/*Recursive*/);
								[self copyItemsFromPaths:paths recursive:recursive insertIntoStep:step atRowIndex:-1];
								
								if (alert.suppressionButton.state == NSOnState) {
									
									NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
									NSMutableArray<NSString *> * alertsToHide = [[userDefaults objectForKey:@"Alerts to Hide"] mutableCopy];
									if (!alertsToHide)
										alertsToHide = [[NSMutableArray alloc] initWithCapacity:1];
									
									[alertsToHide addObject:@"Recursive Alert"];
									[userDefaults setObject:alertsToHide forKey:@"Alerts to Hide"];
									
									[userDefaults setBool:recursive forKey:@"Use Recursivity"];
								}
							}
						}];
					}
				} else
					[self copyItemsFromPaths:paths recursive:NO insertIntoStep:step atRowIndex:rowIndex];
				
			} else if ([defaultDragOp isEqualToString:@"Link"])
				[self linkItemsFromPaths:paths recursive:NO insertIntoStep:step atRowIndex:rowIndex];
			else // Move, by default
				[self moveItemsFromPaths:paths recursive:NO insertIntoStep:step atRowIndex:rowIndex];
		}
	}];
}

#pragma mark - Description TextField Delegate

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

#pragma mark - Actions

- (NSString *)defaultNewStepName
{
	/* Generate a free name (ex: "Untitled Step (2)", "Untitled Step (3)", etc.) */
	NSString * baseStepName = @"Untitled Step", * stepName = baseStepName;
	
	NSArray <Step *> * allSteps = _project.steps;
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
	[self createStepAction:sender];
}

- (IBAction)createStepAction:(id)sender
{
	[self.view.window beginSheet:_createStepWindow completionHandler:^(NSModalResponse returnCode) {
		if (returnCode == NSModalResponseOK) {
			Step * step = [[Step alloc] initWithName:_createStepField.stringValue];
			[_project addStep:step];
			[self reloadData];
			
			NSInteger section = 1 + (_showsIndexDescription || (_editing && _shouldShowIndexDescription)) + self.steps.count;
			[self.tableView scrollToSection:section openSection:NO position:TableViewPositionNone];
		}
	}];
}

- (IBAction)backAction:(id)sender
{
	/* Remoevt the QuickLook panel */
	QLPreviewPanel * previewPanel = [QLPreviewPanel sharedPreviewPanel];
    if ([QLPreviewPanel sharedPreviewPanelExists] && previewPanel.visible)
        [previewPanel orderOut:nil];
	
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
	ProjectPriority priorities[] = { ProjectPriorityHigh, ProjectPriorityNormal, ProjectPriorityLow, ProjectPriorityNone };
	for (int i = 0, count = sizeof(priorities) / sizeof(priorities[0]); i < count; ++i) {
		ProjectPriority priority = priorities[i];
		NSMenuItem * item = [menu addItemWithTitle:ProjectPriorityDescription(priority)
											target:self action:selector tag:priority];
		item.state = (priority == _project.projectPriority) ? NSOnState : NSOffState;
	}
	
	NSMenuItem * selectedItem = [menu itemWithTag:_project.projectPriority];
	[menu popUpMenuPositioningItem:selectedItem
						atLocation:NSMakePoint(_priorityButton.frame.origin.x, -5.)
							inView:self.view];
}

- (IBAction)priorityPopUpDidChangeAction:(id)sender
{
	NSMenuItem * item = (NSMenuItem *)sender;
	NSInteger index = ([item.menu indexOfItem:item] - 1); // Minus one for "Priority"
	NSInteger count = (item.menu.numberOfItems - 1); // Minus one for "Priority"
	if (0 <= index && index < count) {
		_project.projectPriority = item.tag;
		[self reloadBottomLabel];
	}
}

- (IBAction)importAction:(NSButton *)sender
{
	NSMenu * menu = [[NSMenu alloc] initWithTitle:@""];
	[menu addItemWithTitle:@"Image..." target:self action:@selector(importImageAction:) tag:-1];
	[menu addItemWithTitle:@"Web Link..." target:self action:@selector(importURLAction:) tag:-1];
	[menu addItemWithTitle:@"Text..." target:self action:@selector(importTextAction:) tag:-1];
	[menu addItemWithTitle:@"Files and Folders..." target:self action:@selector(importFilesAndFoldersAction:) tag:-1];
	[menu addItem:[NSMenuItem separatorItem]];
	[menu addItemWithTitle:@"Task..." target:self action:@selector(importTaskAction:) tag:-1];
	[menu addItemWithTitle:@"Countdown..." target:self action:@selector(importCountdownAction:) tag:-1];
	
	[menu popUpMenuPositioningItem:nil
						atLocation:NSMakePoint(sender.frame.origin.x, sender.frame.origin.y + sender.frame.size.height + 5.)
							inView:sender.superview];
}

- (IBAction)editAction:(id)sender
{
	[self.library save];
	
	[self setEditing:YES];
}

- (IBAction)doneAction:(id)sender
{
	_project.name = _navigationBar.textField.stringValue; // Get the value of the navigationBar's textField and not the navigationBar's title because at this point, the textField is editing so the new value have not been saved
	_project.description = _descriptionTextField.stringValue;
	
	[self setEditing:NO];
}

- (IBAction)cancelAction:(id)sender
{
	_descriptionTextField.stringValue = _project.description;
	
	// @TODO: Load project from disk (to cancel changes)
	
	[self setEditing:NO];
	[self.library reloadFromDisk];
	[self reloadData];
}

- (IBAction)openWithDefaultApplicationAction:(id)sender
{
	FileItem * item = (FileItem *)[self itemAtIndexPath:self.tableView.indexPathOfSelectedRow];
	NSAssert([item isKindOfClass:FileItem.class], @"");
	NSString * path = [_library pathForItem:item];
	[SandboxHelper executeWithSecurityScopedAccessToURL:item.URL block:^(NSError * error) {
		if (!error) {
			NSURL * fileURL = [NSURL fileURLWithPath:path];
			if (item.itemType == FileItemTypeWebURL) {
				NSString * content = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
				if (content)
					fileURL = [NSURL URLWithString:content];
				else return ;
			}
			[[NSWorkspace sharedWorkspace] openURL:fileURL];
		}
	}];
}

- (IBAction)showInFinderAction:(id)sender
{
	FileItem * item = (FileItem *)[self itemAtIndexPath:self.tableView.indexPathOfSelectedRow];
	NSAssert([item isKindOfClass:FileItem.class], @"");
	[SandboxHelper executeWithSecurityScopedAccessToURL:item.URL block:^(NSError * error) {
		if (!error) {
			NSString * path = [_library pathForItem:item];
			if (path)
				[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[ [NSURL fileURLWithPath:path] ]];
		}
	}];
}

- (IBAction)copyToPasteboardSelectedItemAction:(id)sender
{
	NSPasteboard * pasteboard = [NSPasteboard generalPasteboard];
	[pasteboard clearContents];
	
	NSIndexPath * indexPath = [self.tableView indexPathOfSelectedRow];
	Item * item = [self itemAtIndexPath:indexPath];
	if ([item isKindOfClass:TextItem.class]) {
		[pasteboard writeObjects:@[ [(TextItem *)item content] ]];
	}
	else {
		FileItem * fileItem = (FileItem *)item;
		NSAssert([fileItem isKindOfClass:FileItem.class], @"");
		
		__block BOOL success = NO;
		[SandboxHelper executeWithSecurityScopedAccessToURL:fileItem.URL block:^(NSError * error) {
			if (!error) {
				if (fileItem.itemType == FileItemTypeImage) {
					NSImage * image = [[NSImage alloc] initWithContentsOfURL:fileItem.URL];
					if (image)
						success = [pasteboard writeObjects:@[ image ]];
					
				} else if (fileItem.itemType == FileItemTypeWebURL) {
					NSString * content = [[NSString alloc] initWithContentsOfURL:fileItem.URL
																		encoding:NSUTF8StringEncoding error:nil];
					if (content)
						success = [pasteboard writeObjects:@[ [NSURL URLWithString:content] ]];
				}
			}
		}];
		
		if (!success) {
			NSLog(@"Error when adding data to pasteboard");
		}
	}
}

- (IBAction)exportSelectedItemAction:(id)sender
{
	NSIndexPath * indexPath = [self.tableView indexPathOfSelectedRow];
	FileItem * item = (FileItem *)[self itemAtIndexPath:indexPath];
	NSString * path = [_library pathForItem:item];
	
	NSSavePanel * savePanel = [NSSavePanel savePanel];
	savePanel.nameFieldStringValue = item.URL.lastPathComponent;
	[savePanel beginSheetModalForWindow:self.view.window
					  completionHandler:^(NSInteger result) {
						  if (result == NSFileHandlingPanelOKButton) {
							  NSString * destinationPath = savePanel.URL.path;
							  [SandboxHelper executeWithSecurityScopedAccessToURL:item.URL block:^(NSError * error) {
								  if (!error) {
									  NSError * copyError = nil;
									  BOOL success = [[NSFileManager defaultManager] copyItemAtPath:path toPath:destinationPath error:&copyError];
									  if (!success)
										  [NSApp presentError:copyError];
								  }
							  }];
						  }
					  }];
}

- (IBAction)locateSelectedItemAction:(id)sender
{
	NSIndexPath * indexPath = [self.tableView indexPathOfSelectedRow];
	FileItem * item = (FileItem *)[self itemAtIndexPath:indexPath];
	NSAssert([item isKindOfClass:FileItem.class], @"");
	NSString * path = [_library pathForItem:item];
	
	NSOpenPanel * openPanel = [NSOpenPanel openPanel];
	if (path.stringByDeletingLastPathComponent)
		openPanel.directoryURL = [NSURL fileURLWithPath:path.stringByDeletingLastPathComponent];
	
	openPanel.allowsMultipleSelection = NO;
	openPanel.canChooseDirectories = YES;
	openPanel.canChooseFiles = YES;
	[openPanel beginSheetModalForWindow:self.view.window
					  completionHandler:^(NSInteger result) {
						  if (result == NSFileHandlingPanelOKButton) {
							  NSString * newPath = openPanel.URL.path;
							  
							  Step * step = [_project stepForItem:item];
							  NSString * stepFolder = [_library pathForStepFolder:step];
							  NSString * libraryPath = _library.path;
							  
							  if ([newPath.lastPathComponent isEqualToString:stepFolder]) {
								  /* Just set "item.filename" with the new selected file */
								  //item.filename = newPath.lastPathComponent;
								  
							  } else if (newPath.length >= libraryPath.length && [[newPath substringToIndex:libraryPath.length] isEqualToString:libraryPath]) {
								  /* Copy the file to the step folder and set "item.filename" with the selected file */
								  
								  NSError * error = NULL;
								  NSString * destinationPath = [NSString stringWithFormat:@"%@/%@", stepFolder, newPath.lastPathComponent];
								  BOOL success = [[NSFileManager defaultManager] copyItemAtPath:newPath toPath:destinationPath error:&error];
								  if (!success)
									  [NSApp presentError:error];
								  
								  //item.filename = newPath.lastPathComponent;
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
								  
								  NSString * const key = item.URL.absoluteString;
								  [[NSUserDefaults standardUserDefaults] setObject:bookmarkData forKey:key];
							  }
							  
							  [self.tableView reloadData];
						  }
					  }];
}

- (IBAction)deleteSelectedItemAction:(id)sender
{
	NSIndexPath * indexPath = [self.tableView indexPathOfSelectedRow];
	Step * step = [self stepForSection:indexPath.section];
	Item * item = [self itemAtIndexPath:indexPath];
	
	if ([item isKindOfClass:FileItem.class]) {
		FileItem * fileItem = (FileItem *)item;
		NSString * path = [_library pathForItem:item];
		if (!fileItem.isLinked) { // If the item is located into the library...
			if ([[NSFileManager defaultManager] fileExistsAtPath:path]) { // If the file exists, ask the user to delete the item folder
				NSAlert * alert = [NSAlert alertWithStyle:NSAlertStyleWarning
											  messageText:@"Do you want to keep the file in the library or move it to the trash?"
										  informativeText:@"This action can't be undone."
											 buttonTitles:@[ @"Move to Trash", @"Cancel", @"Keep File" ]];
				[alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
					if (returnCode != NSAlertSecondButtonReturn/*Cancel*/) {
						BOOL success = YES;
						BOOL keepFiles = (returnCode == NSAlertThirdButtonReturn/*Keep File*/);
						if (!keepFiles)
							success = [fileItem removeFromDisk];
						
						if (success)
							[step removeItem:item];
						else {
							// @TODO: on fail (the folder can't be moved to trash, by example), show an alert to ask to re-try later (after close all applications, etc.).
						}
						
						[self reloadData];
					}
				}];
			} else { // If the file no longer exists at the specified path, juste ask to delete the entry
				NSAlert * alert = [NSAlert alertWithStyle:NSAlertStyleWarning
											  messageText:[NSString stringWithFormat:@"Do you really want to delete the entry for %@", fileItem.filename]
										  informativeText:@"This action can't be undone."
											 buttonTitles:@[ @"Cancel", @"Delete" ]];
				[alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
					if (returnCode != NSAlertSecondButtonReturn/*Delete*/) {
						if ([fileItem removeFromDisk])
							[step removeItem:item];
						
						[self reloadData];
					}
				}];
			}
		} else { // ...else, if the item is linked
			NSAlert * alert = [NSAlert alertWithStyle:NSAlertStyleWarning
										  messageText:[NSString stringWithFormat:@"Do you really want to delete the entry for %@", path.lastPathComponent]
									  informativeText:@"The file will not be deleted." @"\n" @"This action can't be undone."
										 buttonTitles:@[ @"Cancel", @"Delete" ]];
			[alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
				if (returnCode != NSAlertSecondButtonReturn/*Delete*/) {
					if ([fileItem removeFromDisk])
						[step removeItem:item];
					
					[self reloadData];
				}
			}];
		}
	} else {
		[step removeItem:item];
		[self reloadData];
	}
}

- (IBAction)deleteSelectedStepAction:(id)sender
{
	NSInteger section = [self.tableView selectedSection];
	if (section != -1) {
		section--; // Remove the "Description" section
		if (_showsIndexDescription || (_editing && _shouldShowIndexDescription)) section--; // Remove the "Notes" section
		Step * step = self.steps[section];
		
		/* Don't show this alert if no files have been added */
		BOOL containsItemFromLibrary = NO;
		for (Item * item in step.items) {
			if ([item isKindOfClass:FileItem.class] && [(FileItem *)item isLinked]) { containsItemFromLibrary = YES; break; }
		}
		
		NSAlert * alert = [[NSAlert alloc] init];
		alert.alertStyle = NSAlertStyleWarning;
		if (containsItemFromLibrary) {
			alert.messageText = [NSString stringWithFormat:@"Do you want to keep all files from \"%@\" in the library or move them to the trash?", step.name];
			[alert addButtonWithTitle:@"Keep Files"];
			[alert addButtonWithTitle:@"Cancel"];
			[alert addButtonWithTitle:@"Move to Trash"];
		} else {
			alert.messageText = [NSString stringWithFormat:@"Do you really want to delete \"%@\"?", step.name];
			[alert addButtonWithTitle:@"Delete"];
			[alert addButtonWithTitle:@"Cancel"];
		}
		alert.informativeText = @"This action can't be undone.";
		[alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
			if (returnCode != NSAlertSecondButtonReturn/*Cancel*/) {
				
				BOOL shouldKeepFiles = (returnCode == NSAlertFirstButtonReturn/*Keep Files*/);
				BOOL success = YES;
				if (!shouldKeepFiles)
					success = [step moveToTrash];
				
				if (success)
					[step delete];
				else {
					NSAlert * alert = [[NSAlert alloc] init];
					alert.messageText = @"Error when moving folder to trash!";
					alert.informativeText = @"Try to close others applications and then retry to delete.";
					alert.alertStyle = NSAlertStyleWarning;
					[alert addButtonWithTitle:@"OK"];
					[alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) { }];
				}
				[self reloadData];
			}
		}];
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
		[self.tableView reloadDataForSection:1];
	}
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
		[fileURL startAccessingSecurityScopedResource];
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
	if ([QLPreviewPanel sharedPreviewPanelExists] && previewPanel.visible) {
		[previewPanel orderOut:nil];
	} else {
		[previewPanel makeKeyAndOrderFront:nil];
	}
}

- (void)moveSelectedItemToAnotherStepAction:(NSMenuItem *)sender
{
	NSIndexPath * indexPath = [self.tableView indexPathOfSelectedRow];
	Item * item = [self itemAtIndexPath:indexPath];
	
	NSInteger destinationStepIndex = sender.tag;
	Step * destStep = _project.steps[destinationStepIndex];
	[destStep addItem:item];
	
	Step * step = [self stepForSection:indexPath.section];
	[step removeItem:item];
	[self reloadData];
}

- (void)toggleTaskStateAction:(NSMenuItem *)item
{
	NSIndexPath * indexPath = [self.tableView indexPathOfSelectedRow];
	TaskItem * task = (TaskItem *)[self itemAtIndexPath:indexPath];
	(task.isCompleted) ? [task markAsActive] : [task markAsCompleted];
	[self.tableView reloadDataForSection:indexPath.section];
}

- (void)incrementCountdownAction:(NSMenuItem *)item
{
	NSIndexPath * indexPath = [self.tableView indexPathOfSelectedRow];
	CountdownItem * task = (CountdownItem *)[self itemAtIndexPath:indexPath];
	[task incrementBy:item.tag];
	[self.tableView reloadDataForSection:indexPath.section];
}

- (void)resetCountdownStateAction:(NSMenuItem *)item
{
	NSIndexPath * indexPath = [self.tableView indexPathOfSelectedRow];
	CountdownItem * task = (CountdownItem *)[self itemAtIndexPath:indexPath];
	[task reset];
	[self.tableView reloadDataForSection:indexPath.section];
}

#pragma mark Import Actions

- (IBAction)importImageAction:(NSMenuItem *)sender
{
	if (sender.tag != -1)
		_imageImportFormWindow.target = self.steps[sender.tag];
	
	_imageImportFormWindow.importDelegate = self;
	[self.view.window beginSheet:_imageImportFormWindow completionHandler:^(NSModalResponse returnCode) { }];
}

- (IBAction)importURLAction:(NSMenuItem *)sender
{
	_urlImportFormWindow.inputTextField.stringValue = @"";
	if (sender.tag != -1)
		_urlImportFormWindow.target = self.steps[sender.tag];
	
	_urlImportFormWindow.importDelegate = self;
	[self.view.window beginSheet:_urlImportFormWindow completionHandler:^(NSModalResponse returnCode) { }];
}

- (IBAction)importTextAction:(NSMenuItem *)sender
{
	_textImportFormWindow.inputTextView.string = @"";
	if (sender.tag != -1)
		_textImportFormWindow.target = self.steps[sender.tag];
	
	_textImportFormWindow.importDelegate = self;
	[self.view.window beginSheet:_textImportFormWindow completionHandler:^(NSModalResponse returnCode) { }];
}

- (void)editTextAction:(NSMenuItem *)sender
{
	NSIndexPath * indexPath = [self.tableView indexPathOfSelectedRow];
	TextItem * textItem = (TextItem *)[self itemAtIndexPath:indexPath];
	_textImportFormWindow.editingItem = textItem;
	_textImportFormWindow.importDelegate = self;
	[self.view.window beginSheet:_textImportFormWindow completionHandler:^(NSModalResponse returnCode) { }];
}

- (IBAction)importTaskAction:(NSMenuItem *)sender
{
	if (sender.tag != -1)
		_taskImportFormWindow.target = self.steps[sender.tag];
	
	_taskImportFormWindow.importDelegate = self;
	[self.view.window beginSheet:_taskImportFormWindow completionHandler:^(NSModalResponse returnCode) { }];
}

- (IBAction)importCountdownAction:(NSMenuItem *)sender
{
	if (sender.tag != -1)
		_countdownImportFormWindow.target = self.steps[sender.tag];
	
	_countdownImportFormWindow.importDelegate = self;
	[self.view.window beginSheet:_countdownImportFormWindow completionHandler:^(NSModalResponse returnCode) { }];
}

- (void)importFormWindow:(ImportFormWindow *)window didEndWithObject:(id)object ofType:(FileItemType)itemType proposedFilename:(NSString *)filename
{
	if (window == _textImportFormWindow && _textImportFormWindow.editingItem) {
		_textImportFormWindow.editingItem.content = (NSString *)object;
		[self reloadData];
		return;
	}
	
	Step * step = window.target;
	NSIndexPath * indexPath = self.tableView.indexPathOfSelectedRow;
	if (!step) {
		if (indexPath && indexPath.section != NSNotFound)
			step = [self stepForSection:indexPath.section];
		else if (_project.steps.lastObject)
			step = _project.steps.lastObject;
		else {
			step = [[Step alloc] initWithName:[self defaultNewStepName]];
			[_project addStep:step];
		}
	}
	
	if (itemType == FileItemTypeTask) {
		TaskItem * item = [[TaskItem alloc] initWithName:object];
		[step addItem:item];
	}
	else if (itemType == FileItemTypeCountdown) {
		NSDictionary * attributes = (NSDictionary *)object;
		NSString * name = attributes[@"name"];
		NSNumber * value = attributes[@"value"];
		NSNumber * maximumValue = attributes[@"maximum"];
		
		CountdownItem * item = [[CountdownItem alloc] initWithName:name];
		item.maximumValue = maximumValue.integerValue;
		[item incrementBy:value.integerValue];
		[step addItem:item];
	}
	else if (itemType == FileItemTypeText) {
		TextItem * item = [[TextItem alloc] initWithContent:(NSString *)object];
		[step addItem:item];
	}
	else {
		NSString * destinationPath = [_library pathForStepFolder:step];
		
		NSString * extension = (itemType == FileItemTypeWebURL) ? @"txt" : @"rtf";
		if (itemType == FileItemTypeImage) {
			extension = ([filename.lastPathComponent rangeOfString:@"."].location == NSNotFound) ? @"png" : nil;
		}
		NSString * path = [NSString stringWithFormat:@"%@/%@", destinationPath, filename];
		if (extension) {
			path = [path stringByAppendingFormat:@".%@", extension];
		}
		if (filename) {
			filename = [self freeFilenameForPath:path];
			path = [NSString stringWithFormat:@"%@/%@", destinationPath, filename];
		} else {
			filename = [self freeDraggedFilenameForStep:step extension:extension];
			path = [NSString stringWithFormat:@"%@/%@.%@", destinationPath, filename, extension];
		}
		
		[SandboxHelper executeWithSecurityScopedAccessToPath:path block:^(NSError * error) {
			if (!error) {
				if (itemType == FileItemTypeImage) {
					NSArray <NSImageRep *> * representations = ((NSImage *)object).representations;
					if (representations.count == 0 || [representations.firstObject isKindOfClass:NSBitmapImageRep.class]) return ;
					NSData * data = [(NSBitmapImageRep *)representations.firstObject representationUsingType:NSPNGFileType properties:@{}];
					[data writeToFile:path atomically:YES];
					
				} else if (itemType == FileItemTypeWebURL) {
					NSData * data = [((NSURL *)object).absoluteString dataUsingEncoding:NSUTF8StringEncoding];
					[data writeToFile:path atomically:YES];
					
				} else if (itemType == FileItemTypeText) {
					NSAttributedString * attributedString = (NSAttributedString *)object;
					NSData * data = [attributedString RTFFromRange:NSMakeRange(0, attributedString.length)
												documentAttributes:@{}];
					[data writeToFile:path atomically:YES];
				}
			}
		}];
		
		Item * item = [[FileItem alloc] initWithType:itemType fileURL:[NSURL fileURLWithPath:path]];
		[step addItem:item];
	}
	
	[self reloadData];
	
	if (indexPath) {
		/* Scroll to the new cell */
		NSIndexPath * newIndexPath = [NSIndexPath indexPathWithSection:indexPath.section row:(indexPath.row + 1)];
		[self.tableView scrollToRowAtIndexPath:newIndexPath
									  position:TableViewPositionNone];
		[self.tableView selectRowAtIndexPath:newIndexPath];
	}
}

- (IBAction)importFilesAndFoldersAction:(NSMenuItem *)sender
{
	NSOpenPanel * openPanel = [NSOpenPanel openPanel];
	openPanel.allowsMultipleSelection = YES;
	openPanel.canChooseDirectories = YES;
	openPanel.canChooseFiles = YES;
	
	[openPanel beginSheetModalForWindow:self.view.window
					  completionHandler:^(NSInteger result) {
						  if (result == NSModalResponseOK) {
							  
							  Step * step = nil;
							  NSIndexPath * indexPath = nil;
							  if (sender.tag != -1) {
								  step = self.steps[sender.tag];
							  } else {
								  indexPath = self.tableView.indexPathOfSelectedRow;
								  if (indexPath && indexPath.section != NSNotFound) {
									  step = [self stepForSection:indexPath.section];
								  } else {
									  step = [[Step alloc] initWithName:[self defaultNewStepName]];
									  [_project addStep:step];
								  }
							  }
							  
							  NSMutableArray <NSString *> * paths = [NSMutableArray arrayWithCapacity:openPanel.URLs.count];
							  for (NSURL * fileURL in openPanel.URLs) [paths addObject:fileURL.path];
							  
							  int rowIndex = (indexPath) ? (int)indexPath.row : -1;
							  NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
							  NSString * defaultDragOp = [userDefaults stringForKey:@"Default-Drag-Operation"];
							  if (defaultDragOp) {
								  if ([defaultDragOp isEqualToString:@"Copy"]) {
									  
									  BOOL containsDirectory = NO;
									  for (NSString * path in paths) {
										  NSNumber * isDirectory = nil;
										  if (path) [[NSURL fileURLWithPath:path] getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
										  if (isDirectory.boolValue) { containsDirectory = YES; break; }
									  }
									  
									  if (containsDirectory) {
										  if ([[userDefaults arrayForKey:@"Alerts to Hide"] containsObject:@"Recursive Alert"]) {
											  
											  BOOL recursive = [userDefaults boolForKey:@"Use Recursivity"];
											  [self copyItemsFromPaths:paths
															 recursive:recursive
														insertIntoStep:step
															atRowIndex:-1];
											  
										  } else {
											  NSAlert * alert = [NSAlert alertWithStyle:NSAlertStyleWarning
																			messageText:@"Should Tea Box add all files recursively or add only files and folder at the root of this folder?"
																		informativeText:nil
																		   buttonTitles:@[ @"Recursive", @"Cancel", @"Non Recursive" ]];
											  alert.showsSuppressionButton = YES;
											  [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
												  if (returnCode != NSAlertSecondButtonReturn/*Cancel*/) {
													  BOOL recursive = (returnCode == NSAlertFirstButtonReturn/*Recursive*/);
													  [self copyItemsFromPaths:paths recursive:recursive insertIntoStep:step atRowIndex:-1];
													  
													  if (alert.suppressionButton.state == NSOnState) {
														  
														  NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
														  NSMutableArray<NSString *> * alertsToHide = [[userDefaults objectForKey:@"Alerts to Hide"] mutableCopy];
														  if (!alertsToHide)
															  alertsToHide = [[NSMutableArray alloc] initWithCapacity:1];
														  
														  [alertsToHide addObject:@"Recursive Alert"];
														  [userDefaults setObject:alertsToHide forKey:@"Alerts to Hide"];
														  
														  [userDefaults setBool:recursive forKey:@"Use Recursivity"];
													  }
												  }
											  }];
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

#pragma mark - NavigationBar Delegate

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

- (void)navigationBar:(NavigationBar *)navigationBar didDragItems:(NSArray <NSPasteboardItem *> *)items onBarButton:(NavigationBarButton *)button
{
	if (button.tag == 1234) {
		Step * step = [[Step alloc] initWithName:[self defaultNewStepName]];
		[_project addStep:step];
		
		NSMutableArray <NSString *> * paths = [NSMutableArray arrayWithCapacity:items.count];
		for (NSPasteboardItem * item in items) {
			if (item.filePath)
				[paths addObject:item.filePath];
		}
		[self moveItemsFromPaths:paths recursive:NO insertIntoStep:step atRowIndex:-1];
		
		[self reloadData];
	}
}

- (void)navigationBar:(NavigationBar *)navigationBar didEndDragOnBarButton:(NavigationBarButton *)button
{
	_navigationBar.leftBarButton = [[NavigationBarButton alloc] initWithType:NavigationBarButtonTypeBack
																	  target:self action:@selector(backAction:)];
	_navigationBar.rightBarButton = [[NavigationBarButton alloc] initWithTitle:@"Edit"
																		target:self action:@selector(editAction:)];
}

#pragma mark - IndexWebView Delegate

- (void)indexWebView:(IndexWebView *)indexWebView didSelectLinkedStepWithName:(NSString *)stepName
{
	BOOL founds = NO;
	NSInteger index = 1; // Begin at "one" for the description section
	if (_showsIndexDescription) index++; // Add a section for the index
	for (Step * step in self.steps) {
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
		NSAlert * alert = [NSAlert alertWithStyle:NSAlertStyleCritical
									  messageText:@"The URL can't be opened"
								  informativeText:[NSString stringWithFormat:@"Check the URL: %@", webURL.absoluteString]
									 buttonTitles:@[ @"OK" ]];
		[alert runModal];
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
	[self saveTextIndexAction:nil]; // Save the old index file
	
#if _SANDBOX_SUPPORTED_
	NSURL * fileURL = [NSURL fileURLWithPath:path];
	NSData * bookmarkData = [fileURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
							  includingResourceValuesForKeys:nil
											   relativeToURL:nil
													   error:NULL];
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:bookmarkData forKey:path];
#endif
	
	_project.indexPath = path;
	
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

#pragma mark - TableView DataSource

- (Item *)itemAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger newRow = (indexPath.section - 1);
	if (_showsIndexDescription || (_editing && _shouldShowIndexDescription)) newRow--;
	if (newRow != -1)
		return itemsArray[newRow][indexPath.row];
	
	return nil;
}

- (Step *)stepForSection:(NSInteger)section
{
	section--; // Remove the "Description" section
	if (_showsIndexDescription || (_editing && _shouldShowIndexDescription)) section--;
	if (0 <= section && section < self.steps.count)
		return self.steps[section];
	
	return nil;
}

- (NSString *)placeholderForTableView:(TableView *)tableView
{
	return (itemsArray.count == 0)? @"No Steps" : nil;
}

- (NSView *)placeholderAccessoryViewForTableView:(TableView *)tableView
{
	if (itemsArray.count == 0) {
		NSButton * createStepButton = [[NSButton alloc] initWithFrame:NSZeroRect];
		[createStepButton setButtonType:NSMomentaryLightButton];
		createStepButton.bezelStyle = NSRoundedBezelStyle;
		createStepButton.target = self;
		createStepButton.action = @selector(createStepAction:);
		createStepButton.title = @"Create Step";
		[createStepButton sizeToFit];
		return createStepButton;
	}
	return nil;
}

- (NSInteger)numberOfSectionsInTableView:(TableView *)tableView
{
	NSInteger numberOfSections = 1 + (_showsIndexDescription || (_editing && _shouldShowIndexDescription)) + self.steps.count;
	return numberOfSections;
}

- (NSArray <NSString *> *)titlesForSectionsInTableView:(TableView *)tableView
{
	NSMutableArray <NSString *> * titles = [NSMutableArray arrayWithCapacity:self.steps.count];
	[titles addObject:@"Description"];
	
	if (_showsIndexDescription || (_editing && _shouldShowIndexDescription))
		[titles addObject:@"Notes"];
	
	for (Step * step in self.steps)
		[titles addObject:step.name];
	
	return titles;
}

- (NSInteger)tableView:(TableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0)
		return 1;
	
	if ((_showsIndexDescription || (_editing && _shouldShowIndexDescription)) && section == 1)
		return 1;
	
	NSInteger newSection = (section - 1);
	if (_showsIndexDescription || (_editing && _shouldShowIndexDescription)) newSection--;
	return itemsArray[newSection].count;
}

- (CGFloat)tableView:(TableView *)tableView rowHeightAtIndex:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0)
		return _descriptionTextField.frame.size.height + (2 * 2.); // Add 2px margin on top and bottom
	else if (_showsIndexDescription && indexPath.section == 1)
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
			cell.textField.alignment = NSTextAlignmentCenter;
			cell.textField.textColor = [NSColor darkGrayColor];
			cell.title = @"No Description";
		}
		
	} else if ((_showsIndexDescription || (_editing && _shouldShowIndexDescription)) && indexPath.section == 1) {
		if (_showsIndexDescription) {
			cell.colorStyle = TableViewCellBackgroundColorStyleWhite;
			
			NSRect frame = _indexWebView.frame;
			frame.size.width = cell.frame.size.width - (2 * 2.);
			_indexWebView.frame = frame;
			[cell addSubview:_indexWebView];
			
		} else if (_editing && _shouldShowIndexDescription) {
			cell.colorStyle = TableViewCellBackgroundColorStyleGray;
			cell.textField.alignment = NSTextAlignmentCenter;
			cell.title = @"Drag & Drop a text (*.txt) file to show it here.";
			cell.textField.textColor = [NSColor darkGrayColor];
		}
		
	} else {
		cell.textField.textColor = [NSColor blackColor];
		cell.colorStyle = (indexPath.row % 2)? TableViewCellBackgroundColorStyleGray : TableViewCellBackgroundColorStyleWhite;
		cell.selectedColorStyle = TableViewCellSelectedColorDefaultGradient;
		
		NSDictionary * grayAttributes = @{ NSForegroundColorAttributeName : [NSColor grayColor] };
		
		Item * item = [self itemAtIndexPath:indexPath];
		if ([item isKindOfClass:TaskItem.class]) {
			TaskItem * taskItem = (TaskItem *)item;
			
			if (taskItem.isCompleted) {
				cell.image = [NSImage imageNamed:@"task-done"];
				cell.selectedImage = [NSImage imageNamed:@"task-done-highlighted"];
			} else {
				BOOL useDarken = (cell.colorStyle == TableViewCellBackgroundColorStyleWhite);
				cell.image = [NSImage imageNamed:(useDarken) ? @"task-dark" : @"task"];
				cell.selectedImage = [NSImage imageNamed:@"task-highlighted"];
			}
			
			NSMutableDictionary * doneAttributes = @{ NSStrikethroughStyleAttributeName : @(NSUnderlineStyleSingle) }.mutableCopy;
			[doneAttributes addEntriesFromDictionary:grayAttributes];
			
			NSAttributedString * title = [[NSAttributedString alloc] initWithString:taskItem.name
																		 attributes:(taskItem.isCompleted) ? doneAttributes : nil];
			cell.attributedTitle = title;
		}
		else if ([item isKindOfClass:CountdownItem.class]) {
			CountdownItem * countdown = (CountdownItem *)item;
			
			if (countdown.isCompleted) {
				cell.image = [NSImage imageNamed:@"countdown-done"];
				cell.selectedImage = [NSImage imageNamed:@"countdown-done-highlighted"];
			} else {
				cell.image = [countdown progressImageForStyle:cell.colorStyle highlighted:NO];
				cell.selectedImage = [countdown progressImageForStyle:cell.colorStyle highlighted:YES];
			}
			
			NSMutableDictionary * doneAttributes = @{ NSStrikethroughStyleAttributeName : @(NSUnderlineStyleSingle) }.mutableCopy;
			[doneAttributes addEntriesFromDictionary:grayAttributes];
			
			NSMutableAttributedString * title = [[NSMutableAttributedString alloc] initWithString:countdown.name
																					   attributes:(countdown.isCompleted) ? doneAttributes : nil];
			[title appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %li / %li", countdown.value, countdown.maximumValue]
																		  attributes:grayAttributes]];
			cell.attributedTitle = title;
		}
		else if ([item isKindOfClass:TextItem.class]) {
			TextItem * textItem = (TextItem *)item;
			cell.title = textItem.content;
			cell.image = [NSImage imageNamed:@"text-type"];
			cell.selectedImage = [NSImage imageNamed:@"text-type-active"];
		}
		else {
			FileItem * fileItem = (FileItem *)item;
			NSAssert([fileItem isKindOfClass:FileItem.class], @"");
			
			cell.image = ImageForFileItemType(fileItem.itemType);
			cell.selectedImage = SelectedImageForFileItemType(fileItem.itemType);
			
			NSString * path = fileItem.URL.path;
			
			if (fileItem.itemType == FileItemTypeWebURL) { // URL
				[SandboxHelper executeWithSecurityScopedAccessToURL:fileItem.URL block:^(NSError * error) {
					if (!error) {
						cell.title = [[NSString alloc] initWithContentsOfFile:path usedEncoding:nil error:NULL];
					} else {
						cell.title = @"File not found";
						cell.textField.textColor = [NSColor grayColor];
					}
				}];
			} else { // Image, file and folder
				
				NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
				if ([userDefaults boolForKey:@"Show Path For Linked Items"]) {
					
					NSString * newPath = [_library pathForItem:fileItem].stringByAbbreviatingWithTildeInPath;
					if (newPath) {
						NSString * basePath = [newPath.stringByDeletingLastPathComponent stringByAppendingString:@"/"];
						NSMutableAttributedString * title = [[NSMutableAttributedString alloc] initWithString:basePath
																								   attributes:grayAttributes];
						[title appendAttributedString:[[NSAttributedString alloc] initWithString:newPath.lastPathComponent
																					  attributes:nil]];
						cell.attributedTitle = title;
					}
				} else
					cell.title = (path) ? path.lastPathComponent : @"???";
				
				__block BOOL fileExists = NO;
				[SandboxHelper executeWithSecurityScopedAccessToURL:fileItem.URL block:^(NSError * error) {
					if (!error)
						fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path];
				}];
				cell.textField.textColor = (fileExists) ? [NSColor blackColor] : [NSColor grayColor];
			}
		}
	}
	
	return cell;
}

- (BOOL)tableView:(TableView *)tableView shouldSelectCell:(TableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	if (_showsIndexDescription || (_editing && _shouldShowIndexDescription))
		return (indexPath.section >= 2);
	
	return (indexPath.section >= 1);
}

- (BOOL)tableView:(TableView *)tableView couldCloseSection:(NSInteger)section
{
	return YES;
}

#pragma mark - TableView Delegate

#pragma mark Section and Cell Editing

- (void)tableView:(TableView *)tableView setString:(id)stringValue forSection:(NSInteger)section
{
	Step * step = [self stepForSection:section];
	step.name = stringValue;
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
	[self stepForSection:section].closed = (state == TableViewSectionStateClose);
}

#pragma mark Double Click
- (void)tableView:(TableView *)tableView didDoubleClickOnCell:(TableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	Item * item = nil;
	if (_showsIndexDescription && indexPath.section >= 2)// From the third section (index = 2) if the "Notes" section is shown
		item = itemsArray[(indexPath.section - 2)][indexPath.row];
	else if (!_showsIndexDescription && indexPath.section >= 1)// From the second section (index = 1) if the "Notes" section is not shown
		item = itemsArray[(indexPath.section - 1)][indexPath.row];
	
	if (item) {
		if ([item isKindOfClass:TaskItem.class]) {
			TaskItem * taskItem = (TaskItem *)item;
			(taskItem.isCompleted) ? [taskItem markAsActive] : [taskItem markAsCompleted];
			[self.tableView reloadDataForSection:indexPath.section]; // @TODO: Should only reload cell (but `reloadDataForCellAtIndexPath:` do not reload cell data)
		}
		else if ([item isKindOfClass:CountdownItem.class]) {
			CountdownItem * countdown = (CountdownItem *)item;
			[countdown increment];
			[self.tableView reloadDataForSection:indexPath.section];
		}
		else if ([item isKindOfClass:TextItem.class]) {
			[self editTextAction:nil];
		}
		else {
			FileItem * fileItem = (FileItem *)item;
			NSAssert([fileItem isKindOfClass:FileItem.class], @"");
			__block BOOL success = NO;
			if (fileItem.itemType == FileItemTypeWebURL) {
				[SandboxHelper executeWithSecurityScopedAccessToURL:fileItem.URL block:^(NSError * error) {
					if (!error) {
						NSString * path = [_library pathForItem:item];
						NSString * content = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
						if (content) {
							NSURL * url = [NSURL URLWithString:content];
							if (url)
								success = [[NSWorkspace sharedWorkspace] openURL:url];
						}
					}
				}];
			} else {
				[SandboxHelper executeWithSecurityScopedAccessToURL:fileItem.URL block:^(NSError * error) {
					if (!error)
						success = [[NSWorkspace sharedWorkspace] openURL:fileItem.URL];
				}];
			}
			if (!success) {
				[[NSAlert alertWithStyle:NSAlertStyleCritical
							 messageText:@"The URL can't be opened"
						 informativeText:nil
							buttonTitles:@[ @"OK" ]] runModal];
			}
		}
	}
}

#pragma mark Right Click Menu

- (NSMenu *)rightClickMenuForTableView:(TableView *)tableView forSection:(NSInteger)section
{
	NSMenu * menu = nil;
	if ((_showsIndexDescription && section >= 2) || (!_showsIndexDescription && section >= 1)) {
		menu = [[NSMenu alloc] initWithTitle:@"section-tableView-menu"];
		
		const NSInteger index = section - (_showsIndexDescription) - 1;
		NSMenuItem * importItem = [[NSMenuItem alloc] init];
		importItem.title = @"Add";
		
		NSMenu * importSubmenu = [[NSMenu alloc] initWithTitle:@""];
		[importSubmenu addItemWithTitle:@"Image..." target:self action:@selector(importImageAction:) tag:index];
		[importSubmenu addItemWithTitle:@"Web Link..." target:self action:@selector(importURLAction:) tag:index];
		[importSubmenu addItemWithTitle:@"Text..." target:self action:@selector(importTextAction:) tag:index];
		[importSubmenu addItemWithTitle:@"Files and Folders..." target:self action:@selector(importFilesAndFoldersAction:) tag:index];
		importItem.submenu = importSubmenu;
		
		[menu addItem:importItem];
		
		[menu addItem:[NSMenuItem separatorItem]];
		[menu addItemWithTitle:@"Delete Step..." target:self action:@selector(deleteSelectedStepAction:)];
	}
	return menu;
}

- (NSMenu *)rightClickMenuForTableView:(TableView *)tableView forCellAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger section = indexPath.section - 1;
	if (_showsIndexDescription || (_editing && _shouldShowIndexDescription)) section--;
	
	if (section >= 0) {
		NSMenu * menu = [[NSMenu alloc] initWithTitle:@"tableview-menu"];
		Item * item = itemsArray[section][indexPath.row];
		
		BOOL canMove = YES;
		if ([item isKindOfClass:TaskItem.class]) {
			TaskItem * task = (TaskItem *)item;
			NSString * const title = (task.isCompleted) ? @"Mark as Active" : @"Mark as Completed";
			[menu addItemWithTitle:title target:self action:@selector(toggleTaskStateAction:)];
		}
		else if ([item isKindOfClass:CountdownItem.class]) {
			
			// increment, incrementBy: 5% 10% 20% si > 1, decrement, reset
			
			CountdownItem * countdown = (CountdownItem *)item;
			[menu addItemWithTitle:@"Increment" target:self action:@selector(incrementCountdownAction:) tag:1];
			
			NSInteger maximum = countdown.maximumValue;
			if (maximum > 50) {
				NSMenuItem * incrementByItem = [menu addItemWithTitle:@"Increment By" target:nil action:NULL tag:0];
				NSMenu * incrementByMenu = [[NSMenu alloc] initWithTitle:@"increment-by-submenu"];
				
				SEL action = @selector(incrementCountdownAction:);
				[incrementByMenu addItemWithTitle:@"10" target:self action:action tag:10];
				[incrementByMenu addItemWithTitle:@"20" target:self action:action tag:20];
				[incrementByMenu addItemWithTitle:@"50" target:self action:action tag:50];
				incrementByItem.submenu = incrementByMenu;
			}
			[menu addItemWithTitle:@"Decrement" target:self action:@selector(incrementCountdownAction:) tag:-1];
			
			[menu addItem:[NSMenuItem separatorItem]];
			
			[menu addItemWithTitle:@"Mark as Completed" target:self action:@selector(incrementCountdownAction:) tag:countdown.maximumValue];
			[menu addItemWithTitle:@"Reset" target:self action:@selector(resetCountdownStateAction:)];
		}
		else if ([item isKindOfClass:TextItem.class]) {
			[menu addItemWithTitle:@"Edit..." target:self action:@selector(editTextAction:)];
			[menu addItemWithTitle:@"Copy Text to Pasteboard" target:self action:@selector(copyToPasteboardSelectedItemAction:)];
		}
		else {
			FileItem * fileItem = (FileItem *)item;
			NSAssert([item isKindOfClass:item.class], @"");
			NSString * path = [_library pathForItem:item];
			
			__block BOOL exist = NO;
			[SandboxHelper executeWithSecurityScopedAccessToURL:fileItem.URL block:^(NSError * error) {
				if (!error)
					exist = [[NSFileManager defaultManager] fileExistsAtPath:path];
			}];
			canMove = (exist);
			
			/*
			 * For files: the menu contains "Open With {Default App}", "Show in Finder", "|", "Export...", "|", "Delete..."
			 * For folders: the menu contains "Show in Finder", "|", "Export...", "|", "Delete..."
			 * The others types contains "FILE" options and theses extra options:
			 * For images: the menu contains "Copy Image to Pasteboard", "|"
			 * For texts: the menu contains "Copy Text to Pasteboard", "|"
			 * For web URL: the menu contains "Copy URL to Pasteboard", "|"
			 * Note: If the default application can't be found, replace the menu item with the disabled one "No Default Applications"
			 *		 If the file doesn't longer exist, just show "Item not found"
			 */
			if (exist) {
				
				// Add "Open with..." at the beginning of the menu
				__block NSURL * url = nil;
				if (fileItem.itemType == FileItemTypeWebURL) {
					[SandboxHelper executeWithSecurityScopedAccessToURL:fileItem.URL block:^(NSError * error) {
						if (!error) {
							NSString * webURLString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
							if (webURLString) {
								url = [NSURL URLWithString:webURLString];
							}
						} }];
				} else { // Files, Images and Texts
					url = [NSURL fileURLWithPath:path];
				}
				
				__block NSString * defaultApplicationPath = nil;
				[SandboxHelper executeWithSecurityScopedAccessToURL:fileItem.URL block:^(NSError * error) {
					if (!error)
						defaultApplicationPath = [[NSWorkspace sharedWorkspace] URLForApplicationToOpenURL:url].path;
				}];
				
				if (defaultApplicationPath) {
					// -[NSWorkspace getInfoForFile:application:type:] returns the path to the application; retreive only the name of the application (i.e.: remove the path and ".app")
					NSString * defaultApplication = defaultApplicationPath.lastPathComponent.stringByDeletingPathExtension;
					if (![defaultApplication isEqualToString:@"Finder"]) { // Do not show "Open with Finder"
						[menu addItemWithTitle:[NSString stringWithFormat:@"Open With %@", defaultApplication]
										target:self action:@selector(openWithDefaultApplicationAction:)];
					}
				} else {
					[menu addItemWithTitle:@"No Default Applications" target:self action:NULL]; // "NULL" to disable the item
				}
				
				/* Add "Copy .. to Pasteboard" */
				if (fileItem.itemType == FileItemTypeImage) {
					[menu addItemWithTitle:@"Copy Image to Pasteboard" target:self action:@selector(copyToPasteboardSelectedItemAction:)];
					[menu addItem:[NSMenuItem separatorItem]];
				} else if (fileItem.itemType == FileItemTypeWebURL) {
					[menu addItemWithTitle:@"Copy URL to Pasteboard" target:self action:@selector(copyToPasteboardSelectedItemAction:)];
					[menu addItem:[NSMenuItem separatorItem]];
				}
				
				/* Folders have theses options */
				[menu addItemWithTitle:@"Show in Finder" target:self action:@selector(showInFinderAction:)];
				
				if (!(fileItem.itemType == FileItemTypeFile && fileItem.isLinked)) { // Don't show "Export" for linked files
					[menu addItem:[NSMenuItem separatorItem]];
					[menu addItemWithTitle:@"Export..." target:self action:@selector(exportSelectedItemAction:)];
				}
			} else {
				[menu addItemWithTitle:@"File not Found" target:self action:NULL]; // "NULL" to disable the item
				
				/* Add a "Locate..." item to let the user select the new location of the file */
				[menu addItemWithTitle:@"Locate..." target:self action:@selector(locateSelectedItemAction:)];
			}
		}
		
		if (canMove && self.steps.count > 1) { // If we can move to another step
			[menu addItem:[NSMenuItem separatorItem]];
			
			NSMenuItem * moveItem = [[NSMenuItem alloc] init];
			moveItem.title = @"Move to";
			NSMenu * moveSubmenu = [[NSMenu alloc] initWithTitle:@""];
			Step * selectedStep = [_project stepForItem:item];
			for (Step * step in _project.steps) {
				if (step != selectedStep) {
					NSInteger section = [_project.steps indexOfObject:step];
					[moveSubmenu addItemWithTitle:step.name
										   target:self action:@selector(moveSelectedItemToAnotherStepAction:)
											  tag:section];
				}
			}
			moveItem.submenu = moveSubmenu;
			[menu addItem:moveItem];
		}
		
		[menu addItem:[NSMenuItem separatorItem]];
		[menu addItemWithTitle:@"Delete..." target:self action:@selector(deleteSelectedItemAction:)];
		return menu;
	}
	return nil;
}

#pragma mark TableView Drag & Drop

- (BOOL)tableView:(TableView *)tableView allowsDragOnSection:(NSInteger)section
{
	return (section > 0); // Don't allow drag&Drop for the "Description" section and if no sections are selected
}

- (BOOL)tableView:(TableView *)tableView allowsDragOnCellAtIndexPath:(NSIndexPath *)indexPath
{
	return (indexPath.section > 0); // Don't allow drag&Drop for the "Description" section and if no sections are selected
}

- (BOOL)tableView:(TableView *)tableView shouldDragItems:(NSArray *)pasteboardItems atIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0) {
		return NO;
	} else if ((_showsIndexDescription || (_editing && _shouldShowIndexDescription)) && indexPath.section == 1) {
		if (pasteboardItems.count == 1) {
			// @TODO: if plain text is dragged, create a file with the text content then use the file as index
			
			NSString * path = [(NSPasteboardItem *)pasteboardItems.firstObject filePath];
			if (path) {
				// It's dragged content, don't need to start sandbox access
				NSString * contentString = [[NSString alloc] initWithContentsOfFile:path usedEncoding:nil error:NULL];
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
	if (items.count > 0) { item = items.firstObject; }
	
	NSURL * volumeURL = nil;
	[item.fileURL getResourceValue:&volumeURL forKey:NSURLVolumeURLKey error:NULL];
	
	if (volumeURL) {
		if (volumeURL.path.length == 1) {// If the path is on system volume (volume equals to "/")
			if (proposedDragOp != NSDragOperationCopy && proposedDragOp != NSDragOperationLink && proposedDragOp != NSDragOperationGeneric) {
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
	if ((_showsIndexDescription || (_editing && _shouldShowIndexDescription)) && indexPath.section == 1) {
		if (pasteboardItems.count == 1) {
			
			NSString * path = [(NSPasteboardItem *)pasteboardItems.firstObject filePath];
			if (path) {
				[self saveTextIndexAction:nil]; // Save the old index file
				_project.indexPath = path;

				NSURL * fileURL = [NSURL fileURLWithPath:path];
				NSData * bookmarkData = [fileURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope
										  includingResourceValuesForKeys:nil
														   relativeToURL:nil
																   error:NULL];
				NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
				[userDefaults setObject:bookmarkData forKey:path];
				
				[SandboxHelper executeWithSecurityScopedAccessToPath:path block:^(NSError * error) {
					if (!error) {
						[_indexWebView loadIndexAtPath:path]; // Reload the webView with the new index file
					}
				}];
			}
		}
	} else {
		NSInteger section = (indexPath.section - 1);
		if (_showsIndexDescription || (_editing && _shouldShowIndexDescription)) section--;
		Step * step = self.steps[section];
		
		NSString * destinationPath = [_library pathForStepFolder:step];
		
		/* Best type is, in this order, an image, a RTF text content, a web URL, plain text content (all dragged from an application) or a file/folder (i.e.: a path to a file/folder) */
		NSArray <NSString *> * registeredDraggedTypes = @[@"public.image" /* Images from an application (not on disk) */,
														  NSPasteboardTypeRTF /* RTF formatted data (before NSPasteboardTypeString because RTF data are string, so NSPasteboardTypeString will be preferred if it's placed before NSPasteboardTypeRTF) */,
														  NSPasteboardTypeString /* Text content */,
														  @"public.file-url"];
		
		NSMutableArray <NSString *> * paths = [[NSMutableArray alloc] initWithCapacity:pasteboardItems.count];
		for (NSPasteboardItem * item in pasteboardItems) {
			NSString * path = nil;
			FileItemType itemType = FileItemTypeFile;
			NSString * bestType = [item availableTypeFromArray:registeredDraggedTypes];
			if (UTTypeConformsTo((__bridge CFStringRef)bestType, CFSTR("public.image"))) {// Images from browser (or else), not on disk
				
				NSData * data = [item dataForType:bestType];
				NSString * extension = [[NSWorkspace sharedWorkspace] preferredFilenameExtensionForType:bestType];
				path = [NSString stringWithFormat:@"%@/%@", destinationPath, [self freeDraggedFilenameForStep:step extension:extension]];
				[data writeToFile:path atomically:YES];
				
				itemType = FileItemTypeImage;
				
			} else if ([bestType isEqualToString:NSPasteboardTypeRTF]) {// RTF content
				
				NSData * data = [item dataForType:bestType];
				NSString * extension = [[NSWorkspace sharedWorkspace] preferredFilenameExtensionForType:bestType];
				path = [NSString stringWithFormat:@"%@/%@", destinationPath, [self freeDraggedFilenameForStep:step extension:extension]];
				[data writeToFile:path atomically:YES];
				
				itemType = FileItemTypeText;
				
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
					
					itemType = FileItemTypeWebURL;
					
				} else {// Text content
					NSData * data = [item dataForType:bestType];
					path = [NSString stringWithFormat:@"%@/%@", destinationPath, [self freeDraggedFilenameForStep:step extension:@"rtf"]];
					[data writeToFile:path atomically:YES];
					
					itemType = FileItemTypeText;
				}
			} else if ([bestType isEqualToString:@"public.file-url"]){// Files and folders
				
				path = item.filePath;
				
				BOOL isDirectory, isBundle, isPackage;
				[[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
				if (path) [[NSURL fileURLWithPath:path] fileIsBundle:&isBundle isPackage:&isPackage];
				itemType = (isDirectory && !isBundle && !isPackage)? FileItemTypeFolder: FileItemTypeFile;
				
			} else {
				[NSException raise:@"ProjectViewControllerException" format:@"Unrecognized or invalid pasteboard type: %@", bestType];
			}
			
			if (path) {
				if (itemType == FileItemTypeFile || itemType == FileItemTypeFolder) {
					[paths addObject:path];
				} else {
					FileItem * item = [[FileItem alloc] initWithType:itemType fileURL:[NSURL fileURLWithPath:path]];
					[step addItem:item];
				}
			}
			
			// @TODO: if the source is not on the same volume that destination (library), show copy as the only way (see draggingSourceOperationMaskForLocal:)
		}
		
		if (paths.count > 0) {
			
			NSDragOperation op = [draggingInfo draggingSourceOperationMask];
			if (op & NSDragOperationGeneric) { // No key modifier, use the defaull action (or ask to it)
				NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
				NSString * defaultDragOp = [userDefaults stringForKey:@"Default-Drag-Operation"];
				if (defaultDragOp) {
					op = ([defaultDragOp isEqualToString:@"Copy"])? NSDragOperationCopy : (([defaultDragOp isEqualToString:@"Link"])? NSDragOperationLink : NSDragOperationMove);
				} else {
					[self askForDefaultDragOperation:paths step:step atIndex:indexPath.row];
					return;
				}
			}
			
			if (op & NSDragOperationMove){ // "Command" (cmd) Key, move items
				// @TODO: show an alert (like when copying) to ask for recursivity => used???
				[self moveItemsFromPaths:paths recursive:NO insertIntoStep:step atRowIndex:(int)indexPath.row];
				
			} else if (op & NSDragOperationCopy) { // "Option" (alt) Key, copy items
				
				BOOL containsDirectory = NO;
				for (NSString * path in paths) {
					NSNumber * isDirectory = nil;
					[[NSURL fileURLWithPath:path] getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
					if (isDirectory.boolValue) {
						containsDirectory = YES;
						break;
					}
				}
				
				if (containsDirectory) {
					NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
					if ([[userDefaults arrayForKey:@"Alerts to Hide"] containsObject:@"Recursive Alert"]) {
						BOOL recursive = [userDefaults boolForKey:@"Use Recursivity"];
						[self copyItemsFromPaths:paths recursive:recursive insertIntoStep:step atRowIndex:-1];
					} else {
						NSAlert * alert = [NSAlert alertWithStyle:NSAlertStyleWarning
													  messageText:@"Should Tea Box add all files recursively or add only files and folder at the root of this folder?"
												  informativeText:nil
													 buttonTitles:@[ @"Recursive", @"Cancel", @"Non Recursive" ]];
						alert.showsSuppressionButton = YES;
						[alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
							if (returnCode != NSAlertSecondButtonReturn/*Cancel*/) {
								BOOL recursive = (returnCode == NSAlertFirstButtonReturn/*Recursive*/);
								[self copyItemsFromPaths:paths recursive:recursive insertIntoStep:step atRowIndex:-1];
								
								if (alert.suppressionButton.state == NSOnState) {
									
									NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
									NSMutableArray<NSString *> * alertsToHide = [[userDefaults objectForKey:@"Alerts to Hide"] mutableCopy];
									if (!alertsToHide)
										alertsToHide = [[NSMutableArray alloc] initWithCapacity:1];
									
									[alertsToHide addObject:@"Recursive Alert"];
									[userDefaults setObject:alertsToHide forKey:@"Alerts to Hide"];
									
									[userDefaults setBool:recursive forKey:@"Use Recursivity"];
								}
							}
						}];
					}
				} else {
					[self copyItemsFromPaths:paths recursive:NO insertIntoStep:step atRowIndex:(int)indexPath.row];
				}
				
			} else if (op & NSDragOperationLink) { // "Control" (ctrl) Key, link items
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

#pragma mark - Files and Folders Operations

- (void)copyDirectoryContentAtPath:(NSString *)path recursive:(BOOL)recursive
{
	NSDirectoryEnumerator * enumerator = [[NSFileManager defaultManager] enumeratorAtURL:[NSURL fileURLWithPath:path]
															  includingPropertiesForKeys:@[NSURLIsDirectoryKey, NSURLNameKey]
																				 options:(NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles)
																			errorHandler:^BOOL(NSURL *url, NSError *error) {
																				NSLog(@"error: %@", error.localizedDescription);
																				return YES; // Return "YES" to continue enumeration of error
																			}];
	/* Create a step from the directory at "path" */
	NSString * name = [NSString stringWithFormat:@"Step with folder named \"%@\"", path.lastPathComponent];
	Step * step = [[Step alloc] initWithName:name];
	[_project addStep:step];
	
	for (NSURL * fileURL in enumerator) {
		
		NSString * destinationFolder = [_library pathForStepFolder:step];
		NSString * newFilename = [self freeFilenameForPath:[NSString stringWithFormat:@"%@/%@", destinationFolder, path.lastPathComponent]];
		
		/* Generate a path like: {Path to Default Library}/{Project Name}/{Step Name}/{File Name}.{Extension} */
		NSString * destinationPath = [NSString stringWithFormat:@"%@/%@", destinationFolder, newFilename];
		
		NSNumber * isDirectory = nil;
		[fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
		if (isDirectory.boolValue) {
			if (recursive) {
				[self copyDirectoryContentAtPath:destinationPath recursive:YES];
			} else {
				Item * item = [[FileItem alloc] initWithType:FileItemTypeFolder fileURL:fileURL];
				[step addItem:item];
			}
		} else {
			Item * item = [[FileItem alloc] initWithType:FileItemTypeFile fileURL:fileURL];
			[step addItem:item];
		}
	}
	
	[self reloadData];
}

- (void)copyItemsFromPaths:(NSArray <NSString *> *)paths defaultStep:(Step *)defaultStep recursive:(BOOL)recursive
{
	[self copyItemsFromPaths:paths recursive:recursive insertIntoStep:defaultStep atRowIndex:-1];
}

- (void)copyItemsFromPaths:(NSArray <NSString *> *)paths recursive:(BOOL)recursive insertIntoStep:(Step *)step atRowIndex:(NSInteger)rowIndex
{
	NSFileManager * manager = [[NSFileManager alloc] init];
	
	/* Items are inserted into the database with a reverse order because items are inserted at the same index so the first item will be inserted after the second item (the "rowIndex" of the first item will be greater than the "rowIndex" of the second item) */
	for (NSString * path in paths.reverseObjectEnumerator) {
		NSNumber * isDirectory = nil;
		BOOL success = [[NSURL fileURLWithPath:path] getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
		if (!success) {
			// @TODO: get error and do smtg with it
			return ;
		}
		if (isDirectory.boolValue) { // Directories
			
			[self copyDirectoryContentAtPath:path
								   recursive:recursive];
			
		} else {// Files
			NSString * destinationFolder = [_library pathForStepFolder:step];
			NSString * newFilename = [self freeFilenameForPath:[NSString stringWithFormat:@"%@/%@", destinationFolder, path.lastPathComponent]];
			
			/* Generate a path like: {Path to Default Library}/{Project Name}/{Step Name}/{File Name}.{Extension} */
			NSString * destinationPath = [NSString stringWithFormat:@"%@/%@", destinationFolder, newFilename];
			
			NSError * error = nil;
			BOOL success = [manager createDirectoryAtPath:destinationPath.stringByDeletingLastPathComponent
							  withIntermediateDirectories:YES
											   attributes:nil
													error:&error];
			if (!success)
				NSLog(@"Create directory error: %@", error.localizedDescription);
			
			if (success) {
				
				NSNumber * filesize = nil;
				[[NSURL fileURLWithPath:destinationPath] getResourceValue:&filesize forKey:NSURLFileSizeKey error:NULL];
				
				if (filesize.doubleValue >= (50 * 1024 * 1024)) {// For big files (>= 50MB)
					
					__unsafe_unretained NSString * itemNewFilename = newFilename;
					__block NSInteger itemRowIndex = rowIndex;
					__unsafe_unretained Step * itemStep = step;
					[manager copyItemAtPath:path
									 toPath:destinationPath
						 progressionHandler:^(float progression) {
							 // @TODO: show a progression alert
							 NSLog(@"Copy progression: %.0f", progression * 100.);
						 } 
						  completionHandler:^{
							  Item * item = [[FileItem alloc] initWithType:FileItemTypeFile
																   fileURL:[NSURL fileURLWithPath:destinationPath]];
							  [itemStep addItem:item];
						  }
							   errorHandler:^(NSError *error) { [NSApp presentError:error]; }];
				} else {
					NSError * error = nil;
					BOOL success = [manager copyItemAtPath:path toPath:destinationPath error:&error];
					if (!success && error)
						[NSApp presentError:error];
					
					if (success) {
						Item * item = [[FileItem alloc] initWithType:FileItemTypeFile
															 fileURL:[NSURL fileURLWithPath:destinationPath]];
						[step addItem:item];
					}
				}
			}
		}
	}
	[self reloadData];
}

- (void)linkItemsFromPaths:(NSArray <NSString *> *)paths defaultStep:(Step *)defaultStep recursive:(BOOL)recursive
{
	[self linkItemsFromPaths:paths recursive:recursive insertIntoStep:defaultStep atRowIndex:-1];
}

- (void)linkItemsFromPaths:(NSArray <NSString *> *)paths recursive:(BOOL)recursive insertIntoStep:(Step *)step atRowIndex:(NSInteger)rowIndex
{
	/* Items are inserted into the database with a reverse order because items are inserted at the same index so the first item will be inserted after the second item (the "rowIndex" of the first item will be greater than the "rowIndex" of the second item) */
	for (NSString * path in [paths reverseObjectEnumerator]) {
		NSURL * fileURL = [NSURL fileURLWithPath:path];
		
		NSNumber * isDirectory = nil;
		[fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
		
		BOOL isBundle, isPackage;
		[[NSURL fileURLWithPath:path] fileIsBundle:&isBundle isPackage:&isPackage];
		FileItemType itemType = (isDirectory.boolValue && !isBundle && !isPackage) ? FileItemTypeFolder : FileItemTypeFile;
		
		FileItem * item = [[FileItem alloc] initWithType:itemType fileURL:fileURL];
		[step addItem:item];
		
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
			NSLog(@"error: %@", error.localizedDescription);
		
		NSString * const key = item.URL.absoluteString;
		[[NSUserDefaults standardUserDefaults] setObject:bookmarkData forKey:key];
	}
	[self reloadData];
}

- (void)moveItemsFromPaths:(NSArray <NSString *> *)paths defaultStep:(Step *)defaultStep recursive:(BOOL)recursive
{
	[self moveItemsFromPaths:paths recursive:recursive insertIntoStep:defaultStep atRowIndex:-1];
}

- (void)moveItemsFromPaths:(NSArray <NSString *> *)paths recursive:(BOOL)recursive insertIntoStep:(Step *)step atRowIndex:(NSInteger)rowIndex
{
	NSFileManager * manager = [[NSFileManager alloc] init];
	
	/* Items are inserted into the database with a reverse order because items are inserted at the same index so the first item will be inserted after the second item (the "rowIndex" of the first item will be greater than the "rowIndex" of the second item) */
	for (NSString * path in paths.reverseObjectEnumerator) {
		NSNumber * isDirectory = nil;
		BOOL success = [[NSURL fileURLWithPath:path] getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
		if (!success)
			return ; // @TODO: get error and do smtg with it
		
		if (isDirectory.boolValue) { // Directories
			[self copyDirectoryContentAtPath:path recursive:recursive];
		} else { // Files
			
			NSString * destinationFolder = [_library pathForStepFolder:step];
			NSString * newFilename = [self freeFilenameForPath:[NSString stringWithFormat:@"%@/%@", destinationFolder, path.lastPathComponent]];
			
			/* Generate a path like: {Path to Default Library}/{Project Name}/{Step Name}/{File Name}.{Extension} */
			NSString * destinationPath = [NSString stringWithFormat:@"%@/%@", destinationFolder, newFilename];
			
			NSError * error = nil;
			BOOL success = [manager createDirectoryAtPath:destinationFolder
							  withIntermediateDirectories:YES
											   attributes:nil
													error:&error];
			if (!success)
				NSLog(@"Create directory error: %@", error.localizedDescription);
			
			if (success) {
				error = nil;
				success = [manager moveItemAtPath:path
										   toPath:destinationPath
											error:&error];
				if (!success)
					[NSApp presentError:error];
				
				if (success) {
					Item * item = [[FileItem alloc] initWithType:FileItemTypeFile
														 fileURL:[NSURL fileURLWithPath:path]];
					[step addItem:item];
				}
			}
		}
	}
	[self reloadData];
}

- (NSString *)freeDraggedFilenameForStep:(Step *)step extension:(NSString *)extension
{
	NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.dateFormat = @"dd-MM-yyyy HH.mm.ss";
	NSString * dateString = [dateFormatter stringFromDate:[NSDate date]];
	
	NSString * filename = [NSString stringWithFormat:@"Dragged File %@%@", dateString, (extension)? [@"." stringByAppendingString:extension]: @""];
	NSString * stepFolder = [_library pathForStepFolder:step];
	return [self freeFilenameForPath:[NSString stringWithFormat:@"%@/%@", stepFolder, filename]];
}

- (NSString *)freeFilenameForPath:(NSString *)path
{
	NSString * parentFolder = path.stringByDeletingLastPathComponent;
	NSString * filename = path.lastPathComponent.stringByDeletingPathExtension;
	__block NSString * extension = path.pathExtension;
	__block NSString * newFilename = filename;
	[SandboxHelper executeWithSecurityScopedAccessToPath:path block:^(NSError * error) {
		if (!error) {
			NSFileManager * fileManager = [[NSFileManager alloc] init];
			int index = 2;
			extension = (extension.length > 0) ? [NSString stringWithFormat:@".%@", extension] : @"";
			while ([fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@/%@%@", parentFolder, newFilename, extension]])
				newFilename = [NSString stringWithFormat:@"%@ (%i)", filename, index++];
		}
	}];
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
	frame.origin = NSMakePoint(position.x + self.view.window.frame.origin.x + 10., position.y + self.view.window.frame.origin.y - 20.);
	frame.size = CGSizeMake(20., 20.);
	return frame;
}

- (NSImage *)previewPanel:(QLPreviewPanel *)panel transitionImageForPreviewItem:(id <QLPreviewItem>)item contentRect:(NSRect *)contentRect
{
	__block NSImage * image = nil;
	if ([item isKindOfClass:FileItem.class]) { // @TODO: Support other item type
		NSString * path = [_library pathForItem:(Item *)item];
		[SandboxHelper executeWithSecurityScopedAccessToURL:[(FileItem *)item URL] block:^(NSError * error) {
			if (!error)
				image = [[NSWorkspace sharedWorkspace] iconForFile:path];
		}];
	}
	return image;
}

#pragma mark - QLPreviewPanelDataSource

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel
{
	return 1;
}

- (id <QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index
{
	NSIndexPath * indexPath = self.tableView.indexPathOfSelectedRow;
	return (indexPath) ? [self itemAtIndexPath:indexPath] : nil;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
