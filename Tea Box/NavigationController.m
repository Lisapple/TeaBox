//
//  NavigationController.m
//  Tea Box
//
//  Created by Max on 04/10/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "NavigationController.h"
#import "MainWindow.h"

#define kPushAnimationDuration 0.35
#define kPopAnimationDuration kPushAnimationDuration

@implementation NavigationController

static BOOL isPushingOrPoping = NO;
static NSMutableArray * _viewControllers = nil;
static NSMutableArray * _delegates = nil;

+ (void)initialize
{
	static BOOL initialized = NO;
	if (!initialized) {
		_viewControllers = [[NSMutableArray alloc] initWithCapacity:5];
		_delegates = [[NSMutableArray alloc] initWithCapacity:3];
		initialized = YES;
	}
}


+ (NSArray *)delegates
{
	return (NSArray *)_delegates;
}

+ (void)addDelegate:(id <NavigationControllerDelegate>)delegate
{
    if (![_delegates containsObject:delegate])
        [_delegates addObject:delegate];
}

+ (void)removeDelegate:(id <NavigationControllerDelegate>)delegate
{
	[_delegates removeObject:delegate];
}


+ (void)setRootViewController:(NSViewController *)viewController
{
	// @TODO: implement it (if needed)
}

+ (void)popViewControllerAnimated:(BOOL)animated
{
	if (isPushingOrPoping)
		return ;
	
	if (_viewControllers.count <= 1) {
		NSLog(@"No more view to pop, %@ is le last one", [_viewControllers lastObject]);
		return;
	}
	
	MainWindow * window = (MainWindow *)[[NSApp delegate] window];
	
	NSViewController * nextToLastViewController = _viewControllers[(_viewControllers.count - 2)];// Get the next to last view controller from stack
	NSViewController * lastViewController = [_viewControllers lastObject];
	
	/* Call delegates */
	for (id <NavigationControllerDelegate> delegate in _delegates) {
		if ([delegate respondsToSelector:@selector(navigationControllerWillPopViewController:animated:)])
			[delegate navigationControllerWillPopViewController:lastViewController animated:animated];
	}
	
	/* Add the new view controller to the window with good offset (to avoid the "blink" effect during the moment of the view is added and the animation started) */
	NSRect frame = nextToLastViewController.view.frame;
	frame.origin.x = -window.frame.size.width;
	nextToLastViewController.view.frame = frame;
	[window addSubview:nextToLastViewController.view];
	
	if (animated) {
		isPushingOrPoping = YES;
		
		/* Animation informations for the currently shown view controller */
		NSViewController * oldViewController = [_viewControllers lastObject];
		NSRect oldFrame = oldViewController.view.frame;
		oldFrame.origin.x = 0.;// Move view controller x position from 0 to window's width
		NSRect newFrame = oldViewController.view.frame;
		newFrame.origin.x = window.frame.size.width;
		
		NSDictionary * oldViewDictionary = @{NSViewAnimationTargetKey : oldViewController.view,
									   NSViewAnimationStartFrameKey : [NSValue valueWithRect:oldFrame],
									   NSViewAnimationEndFrameKey : [NSValue valueWithRect:newFrame]};
		
		/* Animation informations for the view controller to show */
		oldFrame = nextToLastViewController.view.frame;
		oldFrame.origin.x = -window.frame.size.width;// Move view controller x position from -window's width to 0
		newFrame = nextToLastViewController.view.frame;
		newFrame.origin.x = 0.;
		
		NSDictionary * newViewDictionary = @{NSViewAnimationTargetKey : nextToLastViewController.view,
									   NSViewAnimationStartFrameKey : [NSValue valueWithRect:oldFrame],
									   NSViewAnimationEndFrameKey : [NSValue valueWithRect:newFrame]};
		
		/* Creat and set up the animation */
		NSViewAnimation * animation = [[NSViewAnimation alloc] initWithViewAnimations:@[oldViewDictionary, newViewDictionary]];
		[animation setDuration:kPopAnimationDuration];
		[animation setAnimationCurve:NSAnimationEaseInOut];
		
		[animation startAnimation];
		
		
		double delayInSeconds = kPopAnimationDuration;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			/* Remove the current view */
			[lastViewController.view removeFromSuperview];
			[_viewControllers removeObject:lastViewController];
			
			isPushingOrPoping = NO;
			
			/* Call delegates */
			for (id <NavigationControllerDelegate> delegate in _delegates) {
				if ([delegate respondsToSelector:@selector(navigationControllerDidPopViewController:animated:)])
					[delegate navigationControllerDidPopViewController:lastViewController animated:animated];
			}
		});
		
	} else { // Not animated
		
		/* Remove the current view */
		[lastViewController.view removeFromSuperview];
		[_viewControllers removeObject:lastViewController];
		
		/* Call delegates */
		for (id <NavigationControllerDelegate> delegate in _delegates) {
			if ([delegate respondsToSelector:@selector(navigationControllerDidPopViewController:animated:)])
				[delegate navigationControllerDidPopViewController:lastViewController animated:animated];
		}
	}
}

+ (void)pushViewController:(NSViewController *)viewController animated:(BOOL)animated
{
	if (isPushingOrPoping)
		return ;
	
	/* Call delegates */
	for (id <NavigationControllerDelegate> delegate in _delegates) {
		if ([delegate respondsToSelector:@selector(navigationControllerWillPushViewController:animated:)])
			[delegate navigationControllerWillPushViewController:viewController animated:animated];
	}
	
	MainWindow * window = (MainWindow *)[[NSApp delegate] window];
	
	viewController.view.frame = ((NSView *)window.contentView).bounds;
	
	if (animated) {
		isPushingOrPoping = YES;
		
		/* Add the new view controller to the window with good offset (to avoid the "blink" effect during the moment of the view is added and the animation started) */
		NSRect frame = viewController.view.frame;
		frame.origin.x = window.frame.size.width;
		viewController.view.frame = frame;
		[window addSubview:viewController.view];
		
		/* Animation informations for the currently shown view controller */
		NSViewController * oldViewController = [_viewControllers lastObject];
		NSRect oldFrame = oldViewController.view.frame;
		oldFrame.origin.x = 0.;// Move view controller x position from 0 to -window's width
		NSRect newFrame = oldViewController.view.frame;
		newFrame.origin.x = -window.frame.size.width;
		
		NSDictionary * oldViewDictionary = @{NSViewAnimationTargetKey : oldViewController.view,
														  NSViewAnimationStartFrameKey : [NSValue valueWithRect:oldFrame],
															NSViewAnimationEndFrameKey : [NSValue valueWithRect:newFrame]};
		
		/* Animation informations for the view controller to show */
		oldFrame = viewController.view.frame;
		oldFrame.origin.x = window.frame.size.width;// Move view controller x position from window's width to 0
		newFrame = viewController.view.frame;
		newFrame.origin.x = 0.;
		
		NSDictionary * newViewDictionary = @{NSViewAnimationTargetKey : viewController.view,
									   NSViewAnimationStartFrameKey : [NSValue valueWithRect:oldFrame],
									   NSViewAnimationEndFrameKey : [NSValue valueWithRect:newFrame]};
		
		/* Create and set up the animation */
		NSViewAnimation * animation = [[NSViewAnimation alloc] initWithViewAnimations:@[oldViewDictionary, newViewDictionary]];
		[animation setDuration:kPushAnimationDuration];
		[animation setAnimationCurve:NSAnimationEaseInOut];
		
		[animation startAnimation];
		
		
		double delayInSeconds = kPushAnimationDuration;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			/* Remove the current view */
			NSViewController * lastViewController = [_viewControllers lastObject];
			[lastViewController.view removeFromSuperview];
			
			/* Add the new view controller to "viewController" */
			[_viewControllers addObject:viewController];
			
			isPushingOrPoping = NO;
			
			/* Call delegates */
			for (id <NavigationControllerDelegate> delegate in _delegates) {
				if ([delegate respondsToSelector:@selector(navigationControllerDidPushViewController:animated:)])
					[delegate navigationControllerDidPushViewController:viewController animated:animated];
			}
		});
		
	} else { // Not animated
		
		/* Remove the current view */
		NSViewController * lastViewController = [_viewControllers lastObject];
		[lastViewController.view removeFromSuperview];
		
		/* Add the new view controller (to the window and to "_viewControllers") */
		[window addSubview:viewController.view];
		[_viewControllers addObject:viewController];
		
		/* Call delegates */
		for (id <NavigationControllerDelegate> delegate in _delegates) {
			if ([delegate respondsToSelector:@selector(navigationControllerDidPushViewController:animated:)])
				[delegate navigationControllerDidPushViewController:viewController animated:animated];
		}
	}
}

- (void)dealloc
{
	[_viewControllers removeAllObjects];
	[_delegates removeAllObjects];
	
}

@end
