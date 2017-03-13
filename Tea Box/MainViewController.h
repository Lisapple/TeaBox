//
//  MainViewController.h
//  Tea Box
//
//  Created by Max on 04/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "AppDelegate.h"

#import "Project.h"
#import "Step.h"

#import "TBLibrary.h"

#import "NavigationController.h"
#import "ProjectViewController.h"

#import "NavigationBar.h"
#import "TableView.h"

@interface MainViewController : NSViewController <TableViewDelegate, TableViewDataSource, NavigationControllerDelegate, NSTextFieldDelegate>
{
	NSArray <NSString *> * sharedHostNames;
	NSArray <NSArray <NSDictionary *> *> * arrayOfSharedProjects;
	
	NSArray <NSArray <Project *> *> * arrayOfProjects;
	
	NSUInteger numberOfRows;
	NSArray <NSNumber/*ProjectPriory*/ *> * priorities;
}

@property (unsafe_unretained) IBOutlet TableView * tableView;

- (void)reloadData;

- (NSArray <Project *> *)allProjects UNAVAILABLE_ATTRIBUTE;
- (NSArray <NSArray <Project *> *> *)fetchArrayOfProjects;

@end
