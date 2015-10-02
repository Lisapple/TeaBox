//
//  TutorialWindow.h
//  Tea Box
//
//  Created by Max on 01/10/15.
//
//

#import "MainWindow.h"

typedef void (^TutorialWindowCompletionHandler)(NSURL * choosenURL, BOOL skipped);

@interface TutorialWindow : MainWindow

@property (strong) TutorialWindowCompletionHandler completionHandler;
@property (unsafe_unretained) IBOutlet NSButton * skipOrDoneButton;
@property (unsafe_unretained) IBOutlet NSTextField * pathDescriptionLabel;

- (IBAction)choosePathAction:(id)sender;
- (IBAction)skipOrDoneAction:(id)sender;
- (IBAction)showHelpAction:(id)sender;

@end
