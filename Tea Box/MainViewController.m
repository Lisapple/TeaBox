//
//  MainViewController.m
//  Tea Box
//
//  Created by Max on 04/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "MainViewController.h"
#import "SheetWindow.h"

#import "NSIndexPath+additions.h"
#import "NSMenu+additions.h"
#import "Project+additions.h"

@interface MainViewController ()

@property (unsafe_unretained) IBOutlet NavigationBar * navigationBar;
@property (unsafe_unretained) IBOutlet NSTextField * bottomLabel;

@property (unsafe_unretained) IBOutlet SheetWindow * createProjectWindow;
@property (unsafe_unretained) IBOutlet NSTextField * createProjectLabel, * createProjectField;
@property (unsafe_unretained) IBOutlet NSButton * createProjectOKButton;

@end

@implementation MainViewController

@synthesize navigationBar = _navigationBar;
@synthesize tableView = _tableView;
@synthesize bottomLabel = _bottomLabel;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if (!nibNameOrNil) nibNameOrNil = @"MainViewController";
	if (!nibBundleOrNil) nibBundleOrNil = [NSBundle mainBundle];
	
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    }
    
    return self;
}

- (void)loadView
{
	[super loadView];
	
	priorityNames = @[ @"None", @"Low", @"Normal", @"High" ];
	
	_navigationBar.title = @"Tea Box";
	
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.rowHeight = 24.;
	[self reloadData];
	
	_navigationBar.rightBarButton = [[NavigationBarButton alloc] initWithTitle:@"New Project"
																		target:self action:@selector(newProjectAction:)];
	[_navigationBar.rightBarButton registerForDraggedTypes:@[ NSFilenamesPboardType ]]; // Add others types of dragging item
	
	[[NSNotificationCenter defaultCenter] addObserverForName:NSControlTextDidChangeNotification
												  usingBlock:^(NSNotification *notification) {
		_createProjectOKButton.enabled = (_createProjectField.stringValue.length > 0); }];
    
    [NavigationController addDelegate:self];
}

- (void)reloadData
{
	NSArray * fetchArrayOfProjects = [self fetchArrayOfProjects];
	arrayOfProjects = fetchArrayOfProjects;
	
	/* Update the bottom label with the number of projects and the number of shared projects */
	NSInteger projectCount = 0;
	for (NSArray * projects in arrayOfProjects) {
		projectCount += projects.count;
	}
	self.bottomLabel.stringValue = [NSString stringWithFormat:@"%ld Projects", projectCount];
	
	[self.tableView reloadData];
	[self.tableView becomeFirstResponder];
}

- (NSString *)defaultNewProjectName
{
	/* Generate a free name (ex: "Untitled Project (2)", "Untitled Project (3)", etc.) */
	NSString * baseProjectName = @"Untitled Project", * projectName = baseProjectName;
	
	NSMutableArray * allProjectsName = [[NSMutableArray alloc] initWithCapacity:10];
	for (NSArray * projects in arrayOfProjects) {
		for (Project * project in projects) { [allProjectsName addObject:project.name]; }
	}
	
	BOOL exists = NO;
	NSInteger index = 2;
	do {
		exists = NO;
		for (NSString * name in allProjectsName) {
			if ([name isEqualToString:projectName]) {
				exists = YES;
				projectName = [NSString stringWithFormat:@"%@ (%ld)", baseProjectName, index++];
				break;
			}
		}
	} while (exists);
	
	return projectName;
}

- (IBAction)newProjectAction:(id)sender
{
	[NSApp beginSheet:_createProjectWindow modalForWindow:self.view.window
		modalDelegate:self didEndSelector:@selector(createProjectWindowDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)createProjectWindowDidEnd:(NSWindow *)window returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSOKButton) {
		Project * project = [[Project alloc] initWithName:_createProjectField.stringValue
											  description:@"" priority:0 identifier:-1];
		[project insertIntoLibrary:[TBLibrary defaultLibrary]];
		[self reloadData];
	}
}

- (NSArray *)fetchArrayOfProjects
{
	NSMutableArray * array = [NSMutableArray arrayWithCapacity:10];
	NSMutableArray * mutablePriorities = [NSMutableArray arrayWithCapacity:10];
	
	NSArray * allProjects = [Project allProjectsFromLibrary:[TBLibrary defaultLibrary]];
	
	int old_priority = -1;
	NSMutableArray * projects = nil;
	
	for (Project * project in allProjects) {
		int priority = project.priority;
		if (priority != old_priority) {
			if (projects) {
				[array insertObject:(NSArray *)projects atIndex:0]; // Add low priority at the top
			}
			projects = [[NSMutableArray alloc] initWithCapacity:10];
			
			old_priority = priority;
			[mutablePriorities insertObject:@(priority) atIndex:0];
		}
		
		[projects addObject:project];
	}
	
	if (projects) {
		[array insertObject:(NSArray *)projects atIndex:0];
	}
	
	priorities = (NSArray *)mutablePriorities;
	
	return (NSArray *)array;
}

- (NSArray *)allProjects
{
	NSMutableArray * projects = [NSMutableArray arrayWithCapacity:10];
	
	sqlite3 * db = [TBLibrary defaultLibrary].database;
	
	/* create a statement from an SQL string */
	sqlite3_stmt * stmt = NULL;
	const char sql[] = "SELECT name, description, priority, index_path, last_modification_date, Project_id FROM Project ORDER BY priority, Project_id ASC";
	sqlite3_prepare_v2(db, sql, -1, &stmt, NULL);
	
	/* execute statement and step over each row of the result set */
	while (sqlite3_step(stmt) == SQLITE_ROW)
	{
		const char * filename_ptr = (const char *)sqlite3_column_text(stmt, 0);
		const char * path_ptr = (const char *)sqlite3_column_text(stmt, 1);
		int priority = sqlite3_column_int(stmt, 2);
		
		Project * project = [[Project alloc] initWithName:@(filename_ptr)
											  description:@(path_ptr)
												 priority:priority
											   identifier:-1];
		const char * index_path_ptr = (const char *)sqlite3_column_text(stmt, 3);
		if (index_path_ptr)
			project.indexPath = @(index_path_ptr);
		
		const char * last_modification_ptr = (const char *)sqlite3_column_text(stmt, 4);
		NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
		formatter.locale = [NSLocale currentLocale];
		formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
		formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"]; // Set to GMT time zone
		NSString * dateString = @(last_modification_ptr);
		project.lastModificationDate = [formatter dateFromString:dateString];
		
		project.identifier = sqlite3_column_int(stmt, 5);
		
		[projects addObject:project];
	}
	
	/* destroy and release the statement */
	sqlite3_finalize(stmt);
	
	return projects;
}

- (Project *)projectAtIndexPath:(NSIndexPath *)indexPath
{
	return ((NSArray *)arrayOfProjects[indexPath.section])[indexPath.row];
}

#pragma mark - Actions -

- (IBAction)deleteProjectAction:(id)sender
{
	NSIndexPath * selectedIndexPath = self.tableView.indexPathOfSelectedRow;
	Project * project = [self projectAtIndexPath:selectedIndexPath];
	
    if (project.steps.count > 0) { // Show a confirmation if the projet contains steps
		NSAlert * alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"Do you want to keep all files from \"%@\" in the library or move them to the trash?", project.name]
										  defaultButton:@"Keep File"
										alternateButton:@"Move to Trash"
											otherButton:@"Cancel"
							  informativeTextWithFormat:@"This action can't be undone."];
		alert.alertStyle = NSWarningAlertStyle;
		alert.showsSuppressionButton = YES;
		[alert beginSheetModalForWindow:self.view.window
						  modalDelegate:self
						 didEndSelector:@selector(deleteItemAlertDidEnd:returnCode:contextInfo:)
							contextInfo:(__bridge_retained void *)project];
    } else { // Else, remove the projet directly
		[self deleteProjet:project keepFile:NO];
		[self reloadData];
    }
}

- (void)deleteItemAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertDefaultReturn || returnCode == NSAlertAlternateReturn) {
		Project * project = (__bridge Project *)contextInfo;
		BOOL keepFile = (returnCode == NSAlertDefaultReturn);
		[self deleteProjet:project keepFile:keepFile];
		[self reloadData];
	}
}

- (void)deleteProjet:(Project *)aProjet keepFile:(BOOL)keep
{
	BOOL success = YES;
	if (!keep)
		success = [aProjet moveToTrash];
	
	if (success)
		[aProjet delete];
	else {
		NSAlert * alert = [NSAlert alertWithMessageText:@"Error when moving folder to trash"
										  defaultButton:@"OK"
										alternateButton:nil
											otherButton:nil
							  informativeTextWithFormat:@"Try to close others applications and then retry to delete."];
		[alert beginSheetModalForWindow:self.view.window
						  modalDelegate:nil
						 didEndSelector:NULL
							contextInfo:nil];
	}
}

#pragma mark - Navigation Controller Delegate -

- (void)navigationControllerWillPopViewController:(NSViewController *)viewController animated:(BOOL)animated
{
    [self reloadData];
}

#pragma mark - TableView DataSource -

- (NSString *)placeholderForTableView:(TableView *)tableView
{
	return (arrayOfProjects.count == 0)? @"No Projects" : nil;
}

- (NSInteger)numberOfSectionsInTableView:(TableView *)tableView
{
	return sharedHostNames.count + arrayOfProjects.count;
}

- (NSArray *)titlesForSectionsInTableView:(TableView *)tableView
{
	NSMutableArray * titles = [NSMutableArray arrayWithCapacity:10];
	for (NSString * name in sharedHostNames)
		[titles addObject:name];
	
	NSInteger count = arrayOfProjects.count;
	for (int i = 0; i < count; i++) {
		NSNumber * index = priorities[i];
		[titles addObject:[NSString stringWithFormat:@"Priority: %@", priorityNames[index.intValue]]];
	}
	
	return titles;
}

- (NSInteger)tableView:(TableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section < sharedHostNames.count) {
		return ((NSArray *)arrayOfSharedProjects[section]).count;
	}
	
	NSInteger newSection = section - sharedHostNames.count;
	return ((NSArray *)arrayOfProjects[newSection]).count;
}

- (TableViewCell *)tableView:(TableView *)tableView cellForIndexPath:(NSIndexPath *)indexPath
{
	TableViewCell * cell = [[TableViewCell alloc] initWithStyle:TableViewCellStyleDefault reusableIdentifier:nil];
	cell.colorStyle = (indexPath.row % 2)? TableViewCellBackgroundColorStyleGray : TableViewCellBackgroundColorStyleWhite;
	cell.selectedColorStyle = TableViewCellSelectedColorDefaultGradient;
	
	NSInteger section = indexPath.section;
	if (indexPath.section < sharedHostNames.count) {
		NSDictionary * attributes = ((NSArray *)arrayOfSharedProjects[section])[indexPath.row];
		cell.title = [attributes valueForKey:@"name"];
	} else {
		NSInteger newSection = section - sharedHostNames.count;
		Project * project = ((NSArray *)arrayOfProjects[newSection])[indexPath.row];
		cell.title = project.name;
	}
	
	return cell;
}

- (BOOL)tableView:(TableView *)tableView couldCloseSection:(NSInteger)section
{
	if (section < sharedHostNames.count)// If the section is into shared projects
		return YES;
	
	return NO;
}

#pragma mark - TableView Delegate -

- (void)tableView:(TableView *)tableView didSelectCell:(TableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	NSInteger section = indexPath.section - sharedHostNames.count;
	Project * project = ((NSArray *)arrayOfProjects[section])[indexPath.row];
	ProjectViewController * projectViewController = [(AppDelegate *)NSApp.delegate projectViewController];
	projectViewController.project = project;
	[NavigationController pushViewController:projectViewController animated:YES];
}

- (NSMenu *)rightClickMenuForTableView:(TableView *)tableView forCellAtIndexPath:(NSIndexPath *)indexPath
{
	NSMenu * menu = [[NSMenu alloc] initWithTitle:@"right-tableView"];
	Project * project = ((NSArray *)arrayOfProjects[indexPath.section])[indexPath.row];
	[menu addItemWithTitle:(project.steps.count > 0) ? @"Delete..." : @"Delete"
					target:self
					action:@selector(deleteProjectAction:)];
	return menu;
}

@end
