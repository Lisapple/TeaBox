//
//  ImportFormWindow.h
//  Tea Box
//
//  Created by Max on 17/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "SheetWindow.h"
#import "Step.h"

@class ImportFormWindow;
@protocol ImportFormWindowDelegate <NSObject>

@optional
- (void)importFormWindow:(ImportFormWindow *)window didEndWithObject:(id)object;
- (void)importFormWindowDidCancel:(ImportFormWindow *)window;

@end

@interface ImportFormWindow : SheetWindow
{
	@protected
	id __unsafe_unretained objectValue;
}

@property (nonatomic, strong) id <ImportFormWindowDelegate> importDelegate;

@property (unsafe_unretained, nonatomic, readonly) id objectValue;
@property (strong) Step * target;

@end


@class _ImportFormImageView;
@protocol _ImportFormImageViewDelegate <NSObject>

- (void)importFormImageView:(_ImportFormImageView *)imageView didReceivedURL:(NSURL *)imageURL;
- (void)importFormImageView:(_ImportFormImageView *)imageView didReceivedImage:(NSImage *)image;

@end

@interface _ImportFormImageView : NSView
{
	NSImageView * imageView;
}

@property (nonatomic, copy) NSImage * image;
@property (nonatomic, strong) id <_ImportFormImageViewDelegate> delegate;

@end


@interface ImageImportFormWindow : ImportFormWindow <_ImportFormImageViewDelegate>
{
	NSURLConnection * _connection;
	NSMutableData * receivedData;
}

@property (unsafe_unretained) IBOutlet _ImportFormImageView * imageView;
@property (unsafe_unretained) IBOutlet NSProgressIndicator * progressIndicator;
@property (unsafe_unretained) IBOutlet NSTextField * descriptionLabel;

// Private
- (void)startDownloadingImageAtURL:(NSURL *)imageURL;

@end


@interface URLImportFormWindow : ImportFormWindow <NSTextFieldDelegate>

@property (unsafe_unretained) IBOutlet NSTextField * inputTextField;
@property (unsafe_unretained) IBOutlet NSTextField * descriptionLabel;

- (NSURL *)URLFromString:(NSString *)string;

@end


@interface TextImportFormWindow : ImportFormWindow

@property (unsafe_unretained) IBOutlet NSTextView * inputTextView;

@end