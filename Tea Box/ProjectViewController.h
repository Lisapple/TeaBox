//
//  ProjectViewController.h
//  Tea Box
//
//  Created by Max on 04/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

@import Quartz; // For QuickLook

#import "Project.h"
#import "Step.h"
#import "Item.h"

#import "NavigationController.h"
#import "NavigationBar.h"

#import "IndexWebView.h"

#import "TableView.h"

#import "TBLibrary.h"

#import "SandboxHelper.h"

#import "NSPasteboardItem+additions.h"

#import "ImportFormWindow.h"

@interface Item (QLPreviewItem) <QLPreviewItem>
@end

@interface ProjectViewController : NSViewController <TableViewDelegate, TableViewDataSource, NSTextFieldDelegate, IndexWebViewDelegate, NavigationBarDelegate, ImportFormWindowDelegate, QLPreviewPanelDelegate, QLPreviewPanelDataSource, WebFrameLoadDelegate>
{
	NSArray * steps;
	NSArray * itemsArray;
	
	NSAttributedString * string;
	CGFloat height;
	
	NSArray * typeImages, * typeSelectedImages, * types;
	
	int editSavepoint;
	BOOL _editing;
	
	BOOL showsIndexDescription;
	
	IndexWebView * _indexWebView;
	CGFloat indexWebViewHeight;
	
	NSArray * priorityNames;
}

@property (unsafe_unretained) IBOutlet NavigationBar * navigationBar;
@property (unsafe_unretained) IBOutlet TableView * tableView;
@property (unsafe_unretained) IBOutlet NSTextField * bottomLabel;
@property (unsafe_unretained) IBOutlet NSButton * priorityButton;

@property (nonatomic, strong) Project * project;

@property (strong) IBOutlet NSTextField * descriptionTextField;

@property (unsafe_unretained) IBOutlet NSWindow * defaultDragOperationWindow;

@property (unsafe_unretained) IBOutlet NSTextField * projectNameLabel;
@property (unsafe_unretained) IBOutlet NSPopUpButton * priorityPopUpButton;

@property (unsafe_unretained) IBOutlet ImageImportFormWindow * imageImportFormWindow;
@property (unsafe_unretained) IBOutlet URLImportFormWindow * urlImportFormWindow;
@property (unsafe_unretained) IBOutlet TextImportFormWindow * textImportFormWindow;

@property (unsafe_unretained) IBOutlet NSMenuItem * quickLookMenuItem;

- (void)reloadData;

// Private
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

- (void)copyItemsFromPaths:(NSArray *)paths recursive:(BOOL)recursive insertIntoStep:(Step *)step atRowIndex:(int)rowIndex;
- (void)linkItemsFromPaths:(NSArray *)paths recursive:(BOOL)recursive insertIntoStep:(Step *)step atRowIndex:(int)rowIndex;
- (void)moveItemsFromPaths:(NSArray *)paths recursive:(BOOL)recursive insertIntoStep:(Step *)step atRowIndex:(int)rowIndex;

- (NSString *)freeDraggedFilenameForStep:(Step *)step extension:(NSString *)extension;
- (NSString *)freeFilenameForPath:(NSString *)path;

- (Item *)itemAtIndexPath:(NSIndexPath *)indexPath;
- (Step *)stepForSection:(NSInteger)section;

- (void)deleteItemAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
- (void)deleteItemConfirmationAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;

@end
