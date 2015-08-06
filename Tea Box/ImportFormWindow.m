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
	
	[NSApp endSheet:self returnCode:NSCancelButton];
	[self orderOut:nil];
}

- (IBAction)okAction:(id)sender
{
	[NSApp endSheet:self returnCode:NSOKButton];
	[self orderOut:nil];
}

@end


@implementation _ImportFormImageView

@synthesize image = _image;
@synthesize delegate;

- (instancetype)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect])) {
		[self registerForDraggedTypes:@[@"public.image", @"public.url", NSPasteboardTypePNG, NSPasteboardTypeTIFF, NSPasteboardTypeString]];
		
		imageView = [[NSImageView alloc] initWithFrame:self.bounds];
		imageView.image = _image;
		[imageView setEditable:NO];
		imageView.imageFrameStyle = NSImageFrameGrayBezel;
		[self addSubview:imageView];
	}
	
	return self;
}

- (void)setImage:(NSImage *)image
{
	_image = [image copy];
	
	imageView.image = _image;
}

- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender
{
	return [sender draggingSourceOperationMask];
}

- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender
{
	return YES;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
	BOOL dragged = NO;
	
	NSPasteboard * pasteboard = [sender draggingPasteboard];
	NSPasteboardItem * item = (pasteboard.pasteboardItems)[0];
	NSString * bestType = [item availableTypeFromArray:@[@"public.image", @"public.url", NSPasteboardTypePNG, NSPasteboardTypeTIFF, NSPasteboardTypeString]];
	
	if (UTTypeConformsTo((__bridge CFStringRef)bestType, CFSTR("public.image"))) {// Images from browser (or else), not on disk
		
		NSData * imageData = [item dataForType:bestType];
		NSImage * image = [[NSImage alloc] initWithData:imageData];
		self.image = image;
		
		dragged = (self.image != nil);
		
	} else if ([bestType isEqualToString:@"public.url"] || [bestType isEqualToString:NSPasteboardTypeString]){// Web URL
		
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


@implementation ImageImportFormWindow

@synthesize imageView = _imageView;
@synthesize progressIndicator = _progressIndicator;
@synthesize descriptionLabel = _descriptionLabel;

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
    }
    
    return self;
}

- (IBAction)okAction:(id)sender
{
	_descriptionLabel.stringValue = @"";
	
	if ([self.importDelegate respondsToSelector:@selector(importFormWindow:didEndWithObject:)]) {
		[self.importDelegate importFormWindow:self didEndWithObject:_imageView.image];
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
	receivedData = [[NSMutableData alloc] initWithCapacity:(1024 * 1024 * 4)]; // 4 Mb sized
	
	NSURLRequest * request = [[NSURLRequest alloc] initWithURL:imageURL];
	_connection = [[NSURLConnection alloc] initWithRequest:request
												 delegate:self
										 startImmediately:YES];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	/* Stop the spinning wheel */
	[_progressIndicator stopAnimation:nil];
	
	[receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	// @TODO: Re-enable the "OK" button
	
	/* Stop the spinning wheel */
	[_progressIndicator stopAnimation:nil];
	
	
	NSImage * image = [[NSImage alloc] initWithData:receivedData];
	
	if (!image) {
		_descriptionLabel.stringValue = @"The image can be downloaded.";
	} else {
		_descriptionLabel.stringValue = @"";
		
		_imageView.image = image;
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	/* Stop the spinning wheel */
	[_progressIndicator stopAnimation:nil];
	
	
	_descriptionLabel.stringValue = [error localizedDescription];
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
		if ([self.importDelegate respondsToSelector:@selector(importFormWindow:didEndWithObject:)]) {
			[self.importDelegate importFormWindow:self didEndWithObject:webURL];
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
	if ([self.importDelegate respondsToSelector:@selector(importFormWindow:didEndWithObject:)]) {
		[self.importDelegate importFormWindow:self didEndWithObject:_inputTextView.attributedString];
	}
	
	[super okAction:sender];
}

@end