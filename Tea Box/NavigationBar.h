//
//  NavigationBar.h
//  Tea Box
//
//  Created by Max on 19/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#ifndef kNavigationBarButtonType
#define kNavigationBarButtonType
#define kNavigationBarButtonTypeDefault @""
#define kNavigationBarButtonTypeDone @"DONE"
#define kNavigationBarButtonTypeDelete @"DELETE"
#define kNavigationBarButtonTypeBack @"BACK"
#endif

@class NavigationBar, NavigationBarButton;
@protocol NavigationBar <NSObject>

- (void)navigationBarButton:(NavigationBarButton *)button didBeginDrag:(NSObject <NSDraggingInfo> *)sender;
- (void)navigationBarButton:(NavigationBarButton *)button didReceiveDrag:(NSObject <NSDraggingInfo> *)sender;
- (void)navigationBarButton:(NavigationBarButton *)button didEndDrag:(NSObject <NSDraggingInfo> *)sender;

@end

@protocol NavigationBarDelegate <NSObject>

@optional
// @TODO: add the shouldXXX method
//- (void)navigationBar:(NavigationBar *)navigationBar shouldDragItems:(NSArray *)items onBarButton:(NavigationBarButton *)button;
- (void)navigationBar:(NavigationBar *)navigationBar didBeginDragOnBarButton:(NavigationBarButton *)button;
- (void)navigationBar:(NavigationBar *)navigationBar didDragItems:(NSArray *)items onBarButton:(NavigationBarButton *)button;
- (void)navigationBar:(NavigationBar *)navigationBar didEndDragOnBarButton:(NavigationBarButton *)button;

@end

@interface NavigationBarButton : NSButton
{
	NSString * type;
	NSTextField * _textField;
}

@property (nonatomic, strong) NSString * title;
@property (nonatomic, assign) BOOL disabled;
@property (nonatomic, readonly) BOOL highlighted;

@property (nonatomic, strong) NavigationBar * navigationBar;

- (id)initWithType:(NSString *)type target:(id)target action:(SEL)action;
- (id)initWithTitle:(NSString *)title target:(id)target action:(SEL)action;

@end

@interface NavigationBar : NSView <NSTextFieldDelegate, NavigationBar>
{
	CGImageRef backgroundImage;
	
	NSView * previousDraggedViewDestination;
}

@property (nonatomic, strong) NSString * title;
@property (nonatomic, readonly) NSTextField * textField;
@property (nonatomic, assign) BOOL editable;
@property (nonatomic, strong) NavigationBarButton * leftBarButton, * rightBarButton;
@property (nonatomic, strong) NSObject <NavigationBarDelegate> * delegate;

@end
