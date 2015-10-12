//
//  NavigationBar.h
//  Tea Box
//
//  Created by Max on 19/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

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

typedef NS_ENUM(NSUInteger, NavigationBarButtonType) {
	NavigationBarButtonTypeDefault = 0,
	NavigationBarButtonTypeDone,
	NavigationBarButtonTypeDelete,
	NavigationBarButtonTypeBack
};

@interface NavigationBarButton : NSButton

@property (nonatomic, assign) BOOL disabled;
@property (getter=isHighlighted) BOOL highlighted;

@property (nonatomic, strong) NavigationBar * navigationBar;

- (instancetype)initWithFrame:(NSRect)frameRect UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithCoder:(NSCoder *)coder UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithType:(NavigationBarButtonType)type target:(id)target action:(SEL)action NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithTitle:(NSString *)title target:(id)target action:(SEL)action NS_DESIGNATED_INITIALIZER;

@end

@interface NavigationBar : NSView <NSTextFieldDelegate, NavigationBar>
{
	CGImageRef backgroundImage;
	NSView * previousDraggedViewDestination;
}

@property (nonatomic, strong) NSString * title;
@property (nonatomic, readonly) NSTextField * titleLabel, * textField;
@property (nonatomic, assign) BOOL editable;
@property (nonatomic, strong) NavigationBarButton * leftBarButton, * rightBarButton;
@property (nonatomic, strong) NSArray * leftBarButtons, * rightBarButtons; // Array of NavigationBarButton objects
@property (nonatomic, strong) NSObject <NavigationBarDelegate> * delegate;

@end
