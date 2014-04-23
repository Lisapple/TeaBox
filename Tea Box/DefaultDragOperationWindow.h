//
//  DefaultDragOperationWindow.h
//  Tea Box
//
//  Created by Max on 14/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface DefaultDragOperationWindow : NSWindow

@property (nonatomic, strong) IBOutlet NSMatrix * choiceMatrix;

- (IBAction)okAction:(id)sender;
- (IBAction)cancelAction:(id)sender;

@end
