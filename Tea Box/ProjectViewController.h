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

#import "TBLibrary.h"
#import "SandboxHelper.h"

#import "NavigationController.h"
#import "NavigationBar.h"
#import "IndexWebView.h"
#import "TableView.h"
#import "ImportFormWindow.h"

#import "NSPasteboardItem+additions.h"

NS_ASSUME_NONNULL_BEGIN

@interface ProjectViewController : NSViewController <TableViewDelegate, TableViewDataSource, NSTextFieldDelegate, IndexWebViewDelegate, NavigationBarDelegate, ImportFormWindowDelegate, QLPreviewPanelDelegate, QLPreviewPanelDataSource, WebFrameLoadDelegate>
{
	NSArray <NSArray <Item *> *> * itemsArray;
	
	NSAttributedString * string;
	CGFloat height;
	
	int editSavepoint;
	BOOL _editing;
	
	IndexWebView * _indexWebView;
	CGFloat indexWebViewHeight;
}

@property (strong, nonnull) Project * project;
@property (strong, nonnull) TBLibrary * library;

- (void)reloadData;

@end

NS_ASSUME_NONNULL_END
