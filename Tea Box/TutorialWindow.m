//
//  TutorialWindow.m
//  Tea Box
//
//  Created by Max on 01/10/15.
//
//

#import "TutorialWindow.h"

@interface TutorialWindow ()

@property (strong) NSURL * choosenURL;

@end

@implementation TutorialWindow

- (IBAction)choosePathAction:(id)sender
{
	NSOpenPanel * openPanel = [NSOpenPanel openPanel];
	openPanel.title = @"Choose the location of the library, or an existing library:";
	openPanel.prompt = @"Select";
	openPanel.canChooseDirectories = YES;
	openPanel.canChooseFiles = YES;
	openPanel.allowedFileTypes = @[ @"teaboxdb" ];
	[openPanel beginSheetModalForWindow:self
					  completionHandler:^(NSInteger result) {
						  if (result == NSFileHandlingPanelOKButton) {
							  self.choosenURL = openPanel.URL;
							  
							  BOOL existingLibraryChoosen = [_choosenURL.pathExtension isEqualToString:@"teaboxdb"];
							  if (!existingLibraryChoosen) {
								  NSDirectoryEnumerationOptions options = NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles;
								  NSDirectoryEnumerator * enumerator = [[NSFileManager defaultManager] enumeratorAtURL:_choosenURL
																							includingPropertiesForKeys:nil
																											   options:options
																										  errorHandler:^ BOOL (NSURL * _Nonnull url, NSError * _Nonnull error) {
																											  return YES; /* Continue on error */ }];
								  NSURL * fileURL = nil;
								  while ((fileURL = enumerator.nextObject)) {
									  if ([fileURL.pathExtension isEqualToString:@"teaboxdb"]) {
										  _choosenURL = fileURL;
										  existingLibraryChoosen = YES;
										  break;
									  }
								  }
							  }
							  
							  // Update |pathDescriptionLabel| with choosen path or with "Use XXX.teaboxdb"
							  _pathDescriptionLabel.stringValue = (existingLibraryChoosen) ? [NSString stringWithFormat:@"Use %@", _choosenURL.lastPathComponent] : [NSString stringWithFormat:@"Creating at %@", _choosenURL.path];
							  [_skipOrDoneButton setTitle:@"Done"];
						  }
					  }];
}

- (void)close
{
	if (self.completionHandler) {
		self.completionHandler(_choosenURL, (_choosenURL == nil));
	}
	[super close];
}

- (IBAction)skipOrDoneAction:(id)sender
{
	if (self.completionHandler) {
		self.completionHandler(_choosenURL, (_choosenURL == nil));
	}
	[self orderOut:nil];
}

- (IBAction)showHelpAction:(id)sender
{
	NSString * helpBookName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleHelpBookName"];
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"main_interface" inBook:helpBookName];
}

@end
