//
//  ImportFormWindow.h
//  Tea Box
//
//  Created by Max on 17/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "SheetWindow.h"
#import "Step.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ImportType) {
	ImportTypeImage,
	ImportTypeText,
	ImportTypeWebURL,
	ImportTypeTask,
	ImportTypeCountdown
};

@class ImportFormWindow;
@protocol ImportFormWindowDelegate <NSObject>

@optional
/// FileItemType: Image, Text, WebURL, Countdown or Task
- (void)importFormWindow:(ImportFormWindow *)window didEndWithObject:(id)object ofType:(ImportType)type proposedFilename:(nullable NSString *)filename;
- (void)importFormWindowDidCancel:(ImportFormWindow *)window;

@end

@interface ImportFormWindow : SheetWindow

@property (strong) id <ImportFormWindowDelegate> importDelegate;

@property (unsafe_unretained, readonly) id objectValue;
@property (strong) Step * target;

@end


@class _ImportFormImageView;
@protocol _ImportFormImageViewDelegate <NSObject>

- (void)importFormImageView:(_ImportFormImageView *)imageView didReceivedURL:(NSURL *)imageURL;
- (void)importFormImageView:(_ImportFormImageView *)imageView didReceivedImage:(NSImage *)image fromFileURL:(NSURL *)fileURL;

@end

@interface _ImportFormImageView : NSImageView

@property (strong) id <_ImportFormImageViewDelegate> delegate;

@end


@interface ImageImportFormWindow : ImportFormWindow <_ImportFormImageViewDelegate>

@property (unsafe_unretained) IBOutlet _ImportFormImageView * imageView;
@property (unsafe_unretained) IBOutlet NSProgressIndicator * progressIndicator;
@property (unsafe_unretained) IBOutlet NSTextField * descriptionLabel;

// Private
- (void)startDownloadingImageAtURL:(NSURL *)imageURL;

@end


@interface URLImportFormWindow : ImportFormWindow <NSTextFieldDelegate>

@property (unsafe_unretained) IBOutlet NSTextField * inputTextField;
@property (unsafe_unretained) IBOutlet NSTextField * descriptionLabel;
@property (nonatomic, nullable, strong) WebURLItem * editingItem;

- (NSURL *)URLFromString:(NSString *)string;

@end


@interface TextImportFormWindow : ImportFormWindow

@property (unsafe_unretained) IBOutlet NSTextView * inputTextView;
@property (nonatomic, nullable, strong) TextItem * editingItem;

@end


@interface TaskImportFormWindow : ImportFormWindow

@property (unsafe_unretained) IBOutlet NSButton * okButton;
@property (unsafe_unretained) IBOutlet NSTextField * nameField;

@end


@interface CountdownImportFormWindow : ImportFormWindow

@property (unsafe_unretained) IBOutlet NSButton * okButton;

@property (unsafe_unretained) IBOutlet NSTextField * nameField;
@property (unsafe_unretained) IBOutlet NSTextField * valueField;
@property (unsafe_unretained) IBOutlet NSStepper * valueStepper;
@property (unsafe_unretained) IBOutlet NSTextField * maximumField;
@property (unsafe_unretained) IBOutlet NSStepper * maximumStepper;

@end

NS_ASSUME_NONNULL_END
