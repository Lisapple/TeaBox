//
//  NavigationController.h
//  Tea Box
//
//  Created by Max on 04/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

@protocol NavigationControllerDelegate <NSObject>

@optional

- (void)navigationControllerWillPopViewController:(NSViewController *)viewController animated:(BOOL)animated;
- (void)navigationControllerDidPopViewController:(NSViewController *)viewController animated:(BOOL)animated;

- (void)navigationControllerWillPushViewController:(NSViewController *)viewController animated:(BOOL)animated;
- (void)navigationControllerDidPushViewController:(NSViewController *)viewController animated:(BOOL)animated;

@end

@interface NavigationController : NSObject

+ (void)setRootViewController:(NSViewController *)viewController;
+ (void)popViewControllerAnimated:(BOOL)animated;
+ (void)pushViewController:(NSViewController *)viewController animated:(BOOL)animated;

+ (NSArray <id <NavigationControllerDelegate>> *)delegates;
+ (void)addDelegate:(id <NavigationControllerDelegate>)delegate;
+ (void)removeDelegate:(id <NavigationControllerDelegate>)delegate;

@end
