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
#import "NSAlert+additions.h"

@interface MainViewController ()

@property (unsafe_unretained) IBOutlet NavigationBar * navigationBar;
@property (unsafe_unretained) IBOutlet NSTextField * bottomLabel;

@property (unsafe_unretained) IBOutlet SheetWindow * createProjectWindow;
@property (unsafe_unretained) IBOutlet NSTextField * createProjectLabel, * createProjectField;
@property (unsafe_unretained) IBOutlet NSButton * createProjectOKButton;

@property (strong, nonnull) TBLibrary * library;

- (IBAction)newProjectAction:(id)sender;

@end

@implementation MainViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if (!nibNameOrNil) nibNameOrNil = @"MainViewController";
	if (!nibBundleOrNil) nibBundleOrNil = [NSBundle mainBundle];
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) { }
	return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
	if ((self = [super initWithCoder:coder])) { }
	return self;
}

- (void)loadView
{
	self.library = [TBLibrary defaultLibrary];
	NSAssert(self.library != nil, @"");
	
	[super loadView];
	
	_navigationBar.title = self.library.name ?: @"Tea Box";
	
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.rowHeight = 24.;
	[self reloadData];
	
	_navigationBar.rightBarButton = [[NavigationBarButton alloc] initWithTitle:@"New Project"
																		target:self action:@selector(newProjectAction:)];
	[_navigationBar.rightBarButton registerForDraggedTypes:@[ NSFilenamesPboardType ]]; // Add others types of dragging item
	
	[[NSNotificationCenter defaultCenter] addObserverForName:NSControlTextDidChangeNotification
												  usingBlock:^(NSNotification * notification) {
		_createProjectOKButton.enabled = (_createProjectField.stringValue.length > 0); }];
	
	[NavigationController addDelegate:self];
}

- (void)reloadData
{
	NSArray <NSArray <Project *> *> * fetchArrayOfProjects = [self fetchArrayOfProjects];
	arrayOfProjects = fetchArrayOfProjects;
	
	/* Update the bottom label with the number of projects and the number of shared projects */
	NSInteger projectCount = 0;
	for (NSArray <Project *> * projects in arrayOfProjects)
		projectCount += projects.count;
	
	self.bottomLabel.stringValue = [NSString stringWithFormat:@"%ld Projects", projectCount];
	
	[self.tableView reloadData];
	[self.tableView becomeFirstResponder];
}

- (NSString *)defaultNewProjectName
{
	// Generate a free name (ex: "Untitled Project (2)", "Untitled Project (3)", etc.)
	NSString * baseProjectName = @"Untitled Project", * projectName = baseProjectName;
	
	NSMutableArray <NSString *> * allProjectsName = [[NSMutableArray alloc] initWithCapacity:10];
	for (NSArray <Project *> * projects in arrayOfProjects) {
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
	[self.view.window beginSheet:_createProjectWindow completionHandler:^(NSModalResponse returnCode) {
		if (returnCode == NSModalResponseOK) {
			NSString * const name = _createProjectField.stringValue;
			if ([self.library projectWithName:name]) { // Disallow duplicate project name
				NSString * message = [NSString stringWithFormat:@"Project name \"%@\" already existing.", name];
				[[NSAlert alertWithStyle:NSAlertStyleWarning messageText:message
						 informativeText:@"Try with another name." buttonTitles:@[ @"OK" ]] runModal];
			} else {
				Project * project = [[Project alloc] initWithName:_createProjectField.stringValue description:nil];
				[self.library addProject:project];
				[self reloadData];
			}
		}
	}];
}

- (NSArray <NSArray <Project *> *> *)fetchArrayOfProjects
{
	NSMutableArray <NSArray <Project *> *> * array = [NSMutableArray arrayWithCapacity:10];
	NSMutableArray <NSNumber *> * mutablePriorities = [NSMutableArray arrayWithCapacity:10];
	
	ProjectPriority old_priority = -1;
	NSMutableArray * projects = nil;
	
	NSArray <Project *> * sortedProjects = self.library.projects; // @TODO: Sort by priority (desc)
	for (Project * project in sortedProjects) {
		ProjectPriority priority = project.projectPriority;
		if (priority != old_priority) {
			if (projects)
				[array insertObject:projects atIndex:0]; // Add higher priority at the top
			
			projects = [[NSMutableArray alloc] initWithCapacity:10];
			
			old_priority = priority;
			[mutablePriorities insertObject:@(priority) atIndex:0];
		}
		
		[projects addObject:project];
	}
	
	if (projects)
		[array insertObject:projects atIndex:0];
	
	priorities = mutablePriorities;
	
	return array;
}

- (Project *)projectAtIndexPath:(NSIndexPath *)indexPath
{
	return arrayOfProjects[indexPath.section][indexPath.row];
}

#pragma mark - Actions

- (IBAction)deleteProjectAction:(id)sender
{
	NSIndexPath * selectedIndexPath = self.tableView.indexPathOfSelectedRow;
	Project * project = [self projectAtIndexPath:selectedIndexPath];
	
	if (project.steps.count > 0) { // Show a confirmation if the projet contains steps
		NSString * message = [NSString stringWithFormat:@"Do you want to keep all files from \"%@\" in the library or move them to the trash?", project.name];
		NSAlert * alert = [NSAlert alertWithStyle:NSAlertStyleWarning
									  messageText:message informativeText:@"This action can't be undone."
									 buttonTitles:@[ @"Move to Trash", @"Cancel", @"Keep File" ]];
		alert.showsSuppressionButton = YES;
		[alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
			if (returnCode != NSAlertSecondButtonReturn/*Cancel*/) {
				BOOL keepFile = (returnCode == NSAlertThirdButtonReturn/*Keep File*/);
				[self deleteProjet:project keepFile:keepFile];
				[self reloadData];
			}
		}];
	} else { // Else, remove the projet directly
		[self deleteProjet:project keepFile:NO];
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
		NSAlert * alert = [NSAlert alertWithStyle:NSAlertStyleCritical
									  messageText:@"Error when moving folder to trash"
								  informativeText:@"Try to close others applications and then retry to delete."
									 buttonTitles:@[ @"OK" ]];
		[alert runModal];
	}
}

#pragma mark - Navigation Controller Delegate

- (void)navigationControllerWillPopViewController:(NSViewController *)viewController animated:(BOOL)animated
{
	[self reloadData];
}

#pragma mark - TableView DataSource

- (NSString *)placeholderForTableView:(TableView *)tableView
{
	return (arrayOfProjects.count == 0)? @"No Projects" : nil;
}

- (NSInteger)numberOfSectionsInTableView:(TableView *)tableView
{
	return sharedHostNames.count + arrayOfProjects.count;
}

- (NSArray <NSArray *> *)titlesForSectionsInTableView:(TableView *)tableView
{
	NSMutableArray * titles = [NSMutableArray arrayWithCapacity:10];
	for (NSString * name in sharedHostNames)
		[titles addObject:name];
	
	NSInteger count = arrayOfProjects.count;
	for (int i = 0; i < count; i++) {
		NSNumber * index = priorities[i];
		[titles addObject:[NSString stringWithFormat:@"Priority: %@", ProjectPriorityDescription(index.intValue)]];
	}
	
	return titles;
}

- (NSInteger)tableView:(TableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section < sharedHostNames.count)
		return arrayOfSharedProjects[section].count;
	
	NSInteger newSection = section - sharedHostNames.count;
	return arrayOfProjects[newSection].count;
}

- (TableViewCell *)tableView:(TableView *)tableView cellForIndexPath:(NSIndexPath *)indexPath
{
	TableViewCell * cell = [[TableViewCell alloc] initWithStyle:TableViewCellStyleDefault reusableIdentifier:nil];
	cell.colorStyle = (indexPath.row % 2)? TableViewCellBackgroundColorStyleGray : TableViewCellBackgroundColorStyleWhite;
	cell.selectedColorStyle = TableViewCellSelectedColorDefaultGradient;
	
	NSInteger section = indexPath.section;
	if (indexPath.section < sharedHostNames.count) {
		NSDictionary * attributes = arrayOfSharedProjects[section][indexPath.row];
		cell.title = [attributes valueForKey:@"name"];
	} else {
		NSInteger newSection = section - sharedHostNames.count;
		Project * project = arrayOfProjects[newSection][indexPath.row];
		cell.title = project.name;
	}
	
	return cell;
}

- (BOOL)tableView:(TableView *)tableView couldCloseSection:(NSInteger)section
{
	return (section < sharedHostNames.count); // Only shared projects sections
}

#pragma mark - TableView Delegate

- (void)tableView:(TableView *)tableView didSelectCell:(TableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	NSInteger section = indexPath.section - sharedHostNames.count;
	Project * project = arrayOfProjects[section][indexPath.row];
	ProjectViewController * projectViewController = [(AppDelegate *)NSApp.delegate projectViewController];
	projectViewController.library = self.library;
	projectViewController.project = project;
	[NavigationController pushViewController:projectViewController animated:YES];
}

- (NSMenu *)rightClickMenuForTableView:(TableView *)tableView forCellAtIndexPath:(NSIndexPath *)indexPath
{
	NSMenu * menu = [[NSMenu alloc] initWithTitle:@"right-tableView"];
	Project * project = arrayOfProjects[indexPath.section][indexPath.row];
	[menu addItemWithTitle:(project.steps.count > 0) ? @"Delete..." : @"Delete"
					target:self action:@selector(deleteProjectAction:)];
	return menu;
}

@end
