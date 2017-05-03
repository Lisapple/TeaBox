//
//  ImportFormWindow.m
//  Tea Box
//
//  Created by Max on 17/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "ImportFormWindow.h"
#import <TBIndexParser/NSPasteboardItem+additions.h>

@implementation ImportFormWindow

- (IBAction)cancelAction:(id)sender
{
	if ([self.importDelegate respondsToSelector:@selector(importFormWindowDidCancel:)]) {
		[self.importDelegate importFormWindowDidCancel:self];
	}
	[super cancelAction:sender];
}

@end


@implementation _ImportFormImageView

- (instancetype)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect])) {
		[self registerForDraggedTypes:@[ @"public.image", @"public.url", NSPasteboardTypePNG, NSPasteboardTypeTIFF, NSPasteboardTypeString ]];
		
		self.editable = NO;
		self.imageFrameStyle = NSImageFrameGrayBezel;
	}
	
	return self;
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)becomeFirstResponder
{
	return YES;
}

- (BOOL)canBecomeKeyView
{
	return YES;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	return [sender draggingSourceOperationMask];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	BOOL dragged = NO;
	
	NSPasteboard * pasteboard = [sender draggingPasteboard];
	NSPasteboardItem * item = pasteboard.pasteboardItems.firstObject;
	NSString * bestType = [item availableTypeFromArray:@[ @"public.image", NSPasteboardTypePNG, NSPasteboardTypeTIFF, NSPasteboardTypeString,
														  @"public.url", @"public.file-url" ]];
	
	if (UTTypeConformsTo((__bridge CFStringRef)bestType, CFSTR("public.image"))) { // Images from browser (or else), not on disk
		NSData * imageData = [item dataForType:bestType];
		self.image = [[NSImage alloc] initWithData:imageData];
		dragged = (self.image != nil);
		
	} else if ([@[ @"public.url", NSPasteboardTypeString ] containsObject:bestType]) { // Web URL
		NSString * webURLString = [item stringForType:bestType];
		NSURL * imageURL = [NSURL URLWithString:webURLString];
		if (imageURL && [self.delegate respondsToSelector:@selector(importFormImageView:didReceivedURL:)])
			[self.delegate importFormImageView:self didReceivedURL:imageURL];
		dragged = (imageURL != nil);
		
	} else if ([bestType isEqualToString:@"public.file-url"]) {
		NSURL * fileURL = [item fileURL];
		self.image = [[NSImage alloc] initWithContentsOfFile:fileURL.path];
		dragged = (self.image != nil);
		if (self.image && [self.delegate respondsToSelector:@selector(importFormImageView:didReceivedImage:fromFileURL:)])
			[self.delegate importFormImageView:self didReceivedImage:self.image fromFileURL:fileURL];
	}
	return dragged;
}

@end


@interface ImageImportFormWindow ()

@property (nonatomic, strong) NSURLConnection * connection;
@property (nonatomic, strong) NSURL * imageURL;

@end

@implementation ImageImportFormWindow

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	_imageView.image = nil;
	[_progressIndicator stopAnimation:nil];
}

- (BOOL)makeFirstResponder:(nullable NSResponder *)aResponder
{
	_imageView.delegate = self;
	return [super makeFirstResponder:aResponder];
}

- (IBAction)okAction:(id)sender
{
	_descriptionLabel.stringValue = @"";
	
	if ([self.importDelegate respondsToSelector:@selector(importFormWindow:didEndWithObject:ofType:proposedFilename:)])
		[self.importDelegate importFormWindow:self didEndWithObject:_imageView.image ofType:ImportTypeImage proposedFilename:_imageURL.lastPathComponent];
	
	[super okAction:sender];
}

#pragma mark - Import Image View Delegate

- (void)importFormImageView:(_ImportFormImageView *)imageView didReceivedImage:(NSImage *)image fromFileURL:(NSURL *)fileURL
{
	_imageURL = fileURL;
}

- (void)importFormImageView:(_ImportFormImageView *)imageView didReceivedURL:(NSURL *)imageURL
{
	[self startDownloadingImageAtURL:imageURL];
}

#pragma mark - Download Image

- (void)startDownloadingImageAtURL:(NSURL *)imageURL
{
	[_progressIndicator startAnimation:nil];
	
	// @TODO: Disable the "OK" button
	
	_imageView.image = nil;
	_imageURL = imageURL;
	
	NSURLSessionConfiguration * configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
	NSURLSession * session = [NSURLSession sessionWithConfiguration:configuration];
	NSURLRequest * request = [[NSURLRequest alloc] initWithURL:imageURL];
	[[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			_imageView.image = [[NSImage alloc] initWithData:data];
			if (_imageView.image)
				_descriptionLabel.stringValue = @"";
			else if (error)
				_descriptionLabel.stringValue = error.localizedDescription;
			else
				_descriptionLabel.stringValue = @"The image can be downloaded.";
			
			[_progressIndicator stopAnimation:nil];
		});
	}] resume];
}

@end


@implementation URLImportFormWindow

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		_inputTextField.delegate = self;
	}
	return self;
}

- (void)setEditingItem:(WebURLItem *)editingItem
{
	_editingItem = editingItem;
	if (editingItem)
		_inputTextField.stringValue = editingItem.URL.absoluteString;
}

- (NSURL *)URLFromString:(NSString *)string
{
	/* check if the URL start with "***://", if not, add it to create a valid URL */
	if ([string rangeOfString:@"."].location != NSNotFound) {
		NSRange protocolRange = [string rangeOfString:@"://"];
		if (protocolRange.location == NSNotFound)
			string = [@"http://" stringByAppendingString:string];
		
		NSURL * url = nil;
		if (string && (url = [NSURL URLWithString:string])
			&& [NSURLConnection canHandleRequest:[NSURLRequest requestWithURL:url]]) {// Valid URL
			return url;
		}
	}
	return nil;
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
	return YES;
}

- (IBAction)okAction:(id)sender
{
	NSURL * webURL = [self URLFromString:_inputTextField.stringValue];
	if (webURL) {
		if ([self.importDelegate respondsToSelector:@selector(importFormWindow:didEndWithObject:ofType:proposedFilename:)])
			[self.importDelegate importFormWindow:self didEndWithObject:webURL ofType:ImportTypeWebURL proposedFilename:webURL.lastPathComponent];
		
		[super okAction:sender];
	} else
		_descriptionLabel.stringValue = @"Error on URL format.";
}

@end


@implementation TextImportFormWindow

- (void)setEditingItem:(TextItem *)editingItem
{
	_editingItem = editingItem;
	if (editingItem)
		_inputTextView.string = editingItem.content;
}

- (IBAction)okAction:(id)sender
{
	if ([self.importDelegate respondsToSelector:@selector(importFormWindow:didEndWithObject:ofType:proposedFilename:)]) {
		NSString * string = _inputTextView.string;
		// Get five first words from text as filename
		NSArray <NSString *> * words = [string componentsSeparatedByString:@" "];
		NSRange range = NSMakeRange(0, MIN(words.count, 5));
		NSString * filename = [[words subarrayWithRange:range] componentsJoinedByString:@" "];
		[self.importDelegate importFormWindow:self didEndWithObject:string ofType:ImportTypeText proposedFilename:filename];
	}
	
	[super okAction:sender];
}

@end


@implementation TaskImportFormWindow

- (void)awakeFromNib
{
	[super awakeFromNib];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nameFieldDidChange:)
												 name:NSControlTextDidChangeNotification object:self.nameField];
}

- (void)nameFieldDidChange:(NSNotification *)notification
{
	self.okButton.enabled = (self.nameField.stringValue.length > 0);
}

- (IBAction)okAction:(id)sender
{
	if ([self.importDelegate respondsToSelector:@selector(importFormWindow:didEndWithObject:ofType:proposedFilename:)]) {
		[self.importDelegate importFormWindow:self didEndWithObject:self.nameField.stringValue ofType:ImportTypeTask proposedFilename:nil];
	}
	[super okAction:sender];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end


@implementation CountdownImportFormWindow

- (void)awakeFromNib
{
	[super awakeFromNib];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:)
												 name:NSControlTextDidChangeNotification object:nil];
}

- (IBAction)textFieldDidChange:(NSNotification *)notification
{
	if (notification.object == self.valueField)
		[self valueFieldDidChange:notification];
	else if (notification.object == self.maximumField)
		[self maximumFieldDidChange:notification];
	
	[self updateUI];
}

- (void)valueFieldDidChange:(NSNotification *)notification
{
	self.valueStepper.integerValue = self.valueField.integerValue;
}

- (IBAction)valueStepperDidChangeAction:(id)sender
{
	self.valueField.integerValue = self.valueStepper.integerValue;
}

- (void)maximumFieldDidChange:(NSNotification *)notification
{
	self.maximumStepper.integerValue = self.maximumField.integerValue;
	[self updateUI];
}

- (IBAction)maximumStepperDidChangeAction:(id)sender
{
	self.maximumField.integerValue = self.maximumStepper.integerValue;
	[self updateUI];
}

- (void)updateUI
{
	self.okButton.enabled = (self.nameField.stringValue.length
							 && self.valueField.stringValue.length
							 && self.maximumField.stringValue.length);
}

- (IBAction)okAction:(id)sender
{
	if ([self.importDelegate respondsToSelector:@selector(importFormWindow:didEndWithObject:ofType:proposedFilename:)]) {
		NSDictionary * object = @{ @"name" : self.nameField.stringValue,
								   @"value" : @(self.valueField.integerValue),
								   @"maximum" : @(self.maximumField.integerValue) };
		[self.importDelegate importFormWindow:self didEndWithObject:object ofType:ImportTypeCountdown proposedFilename:nil];
	}
	[super okAction:sender];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
