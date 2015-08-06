//
//  MainViewController.h
//  Tea Box
//
//  Created by Max on 04/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "AppDelegate.h"

#import "Project.h"
#import "Step.h"

#import "TBLibrary.h"

#import "NavigationController.h"
#import "ProjectViewController.h"

#import "NavigationBar.h"
#import "TableView.h"

@interface MainViewController : NSViewController <TableViewDelegate, TableViewDataSource, NavigationControllerDelegate>
{
	NSArray * sharedHostNames;
	NSArray * arrayOfSharedProjects;
	
	NSArray * arrayOfProjects;
	
	NSUInteger numberOfRows;
	NSArray * priorities;
	NSArray * priorityNames;
}

@property (unsafe_unretained) IBOutlet TableView * tableView;

- (void)reloadData;

- (NSArray *)allProjects;
- (NSArray *)fetchArrayOfProjects;

- (IBAction)newProjectAction:(id)sender;

@end
