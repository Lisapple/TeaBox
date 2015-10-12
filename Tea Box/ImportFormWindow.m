//
//  ImportFormWindow.m
//  Tea Box
//
//  Created by Max on 17/11/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "ImportFormWindow.h"

@implementation ImportFormWindow

@synthesize importDelegate = _importDelegate;
@synthesize objectValue;

- (IBAction)cancelAction:(id)sender
{
	if ([self.importDelegate respondsToSelector:@selector(importFormWindowDidCancel:)]) {
		[self.importDelegate importFormWindowDidCancel:self];
	}
	[super cancelAction:sender];
}

@end


@implementation _ImportFormImageView

@synthesize delegate;

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
	NSString * bestType = [item availableTypeFromArray:@[ @"public.image", @"public.url", NSPasteboardTypePNG, NSPasteboardTypeTIFF, NSPasteboardTypeString ]];
	
	if (UTTypeConformsTo((__bridge CFStringRef)bestType, CFSTR("public.image"))) { // Images from browser (or else), not on disk
		
		NSData * imageData = [item dataForType:bestType];
		self.image = [[NSImage alloc] initWithData:imageData];
		dragged = (self.image != nil);
		
	} else if ([@[ @"public.url", NSPasteboardTypeString ] containsObject:bestType]) { // Web URL
		
		NSString * webURLString = [item stringForType:bestType];
		NSURL * imageURL = [NSURL URLWithString:webURLString];
		if (imageURL) {
			if ([self.delegate respondsToSelector:@selector(importFormImageView:didReceivedURL:)])
				[self.delegate importFormImageView:self didReceivedURL:imageURL];
		}
		dragged = (imageURL != nil);
	}
	return dragged;
}

@end


@interface ImageImportFormWindow ()

@property (nonatomic, strong) NSURLConnection * connection;
@property (nonatomic, strong) NSMutableData * receivedData;
@property (nonatomic, strong) NSURL * imageURL;

@end

@implementation ImageImportFormWindow

- (BOOL)makeFirstResponder:(nullable NSResponder *)aResponder
{
	_imageView.delegate = self;
	return [super makeFirstResponder:aResponder];
}

- (IBAction)okAction:(id)sender
{
	_descriptionLabel.stringValue = @"";
	
	if ([self.importDelegate respondsToSelector:@selector(importFormWindow:didEndWithObject:ofType:proposedFilename:)]) {
		[self.importDelegate importFormWindow:self didEndWithObject:_imageView.image ofType:kItemTypeImage proposedFilename:_imageURL.lastPathComponent];
	}
	
	[super okAction:sender];
}

#pragma mark - Import Image View Delegate

- (void)importFormImageView:(_ImportFormImageView *)imageView didReceivedImage:(NSImage *)image
{
	// Do nothing
}

- (void)importFormImageView:(_ImportFormImageView *)imageView didReceivedURL:(NSURL *)imageURL
{
	[self startDownloadingImageAtURL:imageURL];
}

#pragma mark - Download Image

- (void)startDownloadingImageAtURL:(NSURL *)imageURL
{
	/* Start the spinning wheel */
	[_progressIndicator startAnimation:nil];
	
	/* Disable the "OK" button */
	// @TODO: Disable the "OK" button
	
	/* Remove the previous image */
	_imageView.image = nil;
	
	/* Download the image asynchronously */
	_imageURL = imageURL;
	_receivedData = [[NSMutableData alloc] initWithCapacity:(1024 * 1024 * 4)]; // 4 Mb sized
	
	NSURLRequest * request = [[NSURLRequest alloc] initWithURL:imageURL];
	_connection = [[NSURLConnection alloc] initWithRequest:request
												 delegate:self
										 startImmediately:YES];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[_receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	// @TODO: Re-enable the "OK" button
	
	NSImage * image = [[NSImage alloc] initWithData:_receivedData];
	if (image) {
		_descriptionLabel.stringValue = @"";
		_imageView.image = image;
	} else {
		_descriptionLabel.stringValue = @"The image can be downloaded.";
	}
	
	/* Stop the spinning wheel */
	[_progressIndicator stopAnimation:nil];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	/* Stop the spinning wheel */
	[_progressIndicator stopAnimation:nil];
	
	_descriptionLabel.stringValue = error.localizedDescription;
}

@end


@implementation URLImportFormWindow

@synthesize inputTextField = _inputTextField;
@synthesize descriptionLabel = _descriptionLabel;

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
		_inputTextField.delegate = self;
    }
    
    return self;
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
		if ([self.importDelegate respondsToSelector:@selector(importFormWindow:didEndWithObject:ofType:proposedFilename:)]) {
			[self.importDelegate importFormWindow:self didEndWithObject:webURL ofType:kItemTypeWebURL proposedFilename:webURL.lastPathComponent];
		}
		
		[super okAction:sender];
	} else {
		_descriptionLabel.stringValue = @"Error on URL format.";
	}
}

@end


@implementation TextImportFormWindow

@synthesize inputTextView = _inputTextView;

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
    }
    
    return self;
}

- (IBAction)okAction:(id)sender
{
	if ([self.importDelegate respondsToSelector:@selector(importFormWindow:didEndWithObject:ofType:proposedFilename:)]) {
		NSAttributedString * attrString = _inputTextView.attributedString;
		// Get five first words from text as filename
		NSArray * words = [attrString.string componentsSeparatedByString:@" "];
		NSRange range = NSMakeRange(0, MIN(words.count, 5));
		NSString * filename = [[words subarrayWithRange:range] componentsJoinedByString:@" "];
		[self.importDelegate importFormWindow:self didEndWithObject:attrString ofType:kItemTypeText proposedFilename:filename];
	}
	
	[super okAction:sender];
}

@end