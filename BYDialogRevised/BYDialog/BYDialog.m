//
//  BYDialog.m
//  BYDialog
//
//  Created by Near Xu on 10-11-10.
//  Copyright 2010 xubenyang.me
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "BYDialog.h"
#import <QuartzCore/QuartzCore.h>

#pragma mark -
#pragma mark Global
static CGFloat kTransitionDuration = 0.3;
static NSMutableArray *gDialogStack = nil;
static UIWindow *gPreviouseKeyWindow = nil;
static UIWindow *gMaskWindow = nil;

#define DefaultNfCenter [NSNotificationCenter defaultCenter]
#define SharedApp [UIApplication sharedApplication]


#pragma mark -

@interface BYDialog(PrivateMethods)

- (CGAffineTransform)_transformForOrientation;
- (void)_sizeToFitOrientation:(BOOL)transform;

- (void)_bounce;
- (void)_bounce1AnimationDidStop;
- (void)_bounce2AnimationDidStop;
- (void)_bounceDidStop;

- (void)_registerObservers;
- (void)_unregisterObservers;

- (void)_deviceOrientationDidChange:(NSNotification *)notification;
- (BOOL)_shouldRotateToOrientation:(UIDeviceOrientation)orientation;

- (void)_dismissCleanup;

#pragma mark -

+ (void)_maskWindowPresent;
+ (void)_maskWindowDismiss;
+ (void)_maskWindowAddDialog:(BYDialog *)dialog;
+ (void)_maskWindowRemoveDialog:(BYDialog *)dialog;

+ (void)_dialogStackPush:(BYDialog *)dialog;
+ (void)_dialogStackPop;
+ (BYDialog *)_dialogStackTopItem;

@end
#pragma mark -
@implementation BYDialog(PrivateMethods)

- (CGAffineTransform)_transformForOrientation {
    UIInterfaceOrientation orientation = SharedApp.statusBarOrientation;
    if (orientation == UIInterfaceOrientationLandscapeLeft) {
        return CGAffineTransformMakeRotation(M_PI*1.5);
    } else if (orientation == UIInterfaceOrientationLandscapeRight) {
        return CGAffineTransformMakeRotation(M_PI/2);
    } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
        return CGAffineTransformMakeRotation(M_PI);
    } else {
        return CGAffineTransformIdentity;
    }
}
- (void)_sizeToFitOrientation:(BOOL)transform{
    if (transform) {
        self.transform = CGAffineTransformIdentity;
    }
    
    _orientation = SharedApp.statusBarOrientation;
    [self sizeToFit];
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    self.center = CGPointMake(screenSize.width/2, screenSize.height/2);
    self.frame = CGRectIntegral(self.frame);
    if (transform) {
        self.transform = [self _transformForOrientation];
    }
}

- (void)_bounce{
    // Start dialog pop out animation
    self.transform = CGAffineTransformScale([self _transformForOrientation], 0.001, 0.001);
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:kTransitionDuration/1.5];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(_bounce1AnimationDidStop)];
    self.transform = CGAffineTransformScale([self _transformForOrientation], 1.1, 1.1);
    [UIView commitAnimations];
}

- (void)_bounce1AnimationDidStop{  
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:kTransitionDuration/2];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(_bounce2AnimationDidStop)];
    self.transform = CGAffineTransformScale([self _transformForOrientation], 0.9, 0.9);
    [UIView commitAnimations];
}
- (void)_bounce2AnimationDidStop{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:kTransitionDuration/2];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(_bounceDidStop)];
    self.transform = [self _transformForOrientation];
    [UIView commitAnimations];
}
- (void)_bounceDidStop{
    
    // For the first time 
    if (!_presented) {
        [self didPresentDialog];
        _presented = YES;
    }
    
}

- (void)_registerObservers{
    [DefaultNfCenter addObserver:self
                        selector:@selector(_deviceOrientationDidChange:)
                            name:UIDeviceOrientationDidChangeNotification
                          object:nil];
}
- (void)_unregisterObservers{
    [DefaultNfCenter removeObserver:self
                               name:UIDeviceOrientationDidChangeNotification
                             object:nil];
}

- (void)_deviceOrientationDidChange:(NSNotification *)notification{
    UIDeviceOrientation orientation = SharedApp.statusBarOrientation;
    if ([self _shouldRotateToOrientation:orientation]) {
        CGFloat duration = SharedApp.statusBarOrientationAnimationDuration;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:duration];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [self _sizeToFitOrientation:YES];
        [UIView commitAnimations];
    }
}

- (BOOL)_shouldRotateToOrientation:(UIDeviceOrientation)orientation{
    BOOL result = NO;
    if (_orientation != orientation) {
        // FIXME: using root view controller of key window to make dialog rotating act the same as rootviewcontroller. 
        // But unfortunately, iOS before 4.0 doesn't support window.rootViewController. so you have to change it manually.
        // result = [window.rootViewController shouldAutorotateToInterfaceOrientation:orientation];
        result = (orientation == UIDeviceOrientationPortrait ||
                  orientation == UIDeviceOrientationPortraitUpsideDown ||
                  orientation == UIDeviceOrientationLandscapeLeft ||
                  orientation == UIDeviceOrientationLandscapeRight);
    }
    
    return result;
}

- (void)_dismissCleanup{
    [BYDialog _maskWindowRemoveDialog:self];
    
    // If there are no dialogs visible, dissmiss mask window too.
    if (![BYDialog _dialogStackTopItem]) {
        [BYDialog _maskWindowDismiss];
    }
    
    [self _unregisterObservers];
    
    [self didDismissDialog];
    
    [self release];
}

#pragma mark -

+ (void)_maskWindowPresent{
    
    // Only if mask window is not presented,\
    then prepare mask window and show fading in.
    if (!gMaskWindow) {
        gMaskWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        gMaskWindow.windowLevel = UIWindowLevelStatusBar + 1;
        gMaskWindow.backgroundColor = [UIColor clearColor];
        gMaskWindow.hidden = YES;
        
        UIImage *image = [UIImage imageNamed:@"masque_black.png"];
        UIImageView *backgroundView = [[UIImageView alloc] initWithImage:image];
        [gMaskWindow addSubview:backgroundView];
        [backgroundView release];
        
        // FIXME: window at index 0 is not awalys previous key window.
        gPreviouseKeyWindow = [SharedApp.windows objectAtIndex:0];
        [gMaskWindow makeKeyAndVisible];
        
        
        // Fade in background 
        gMaskWindow.alpha = 0;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        gMaskWindow.alpha = 1;
        [UIView commitAnimations];
    }
}
+ (void)_maskWindowDismiss{
    // make previouse window the key again
    if (gMaskWindow) {
        [gPreviouseKeyWindow makeKeyAndVisible];
        gPreviouseKeyWindow = nil;
        
        [gMaskWindow release];
        gMaskWindow = nil;
    }
}

+ (void)_maskWindowAddDialog:(BYDialog *)dialog{
    if (!gMaskWindow ||
        [gMaskWindow.subviews containsObject:dialog]) {
        return;
    }
    
    [gMaskWindow addSubview:dialog];
    dialog.hidden = NO;
    
    
    BYDialog *previousDialog = [BYDialog _dialogStackTopItem];
    if (previousDialog) {
        previousDialog.hidden = YES;
    }
    [BYDialog _dialogStackPush:dialog];
}
+ (void)_maskWindowRemoveDialog:(BYDialog *)dialog{
    if (!gMaskWindow ||
        ![gMaskWindow.subviews containsObject:dialog]) {
        return;
    }
    
    [dialog removeFromSuperview];
    dialog.hidden = YES;
    
    [BYDialog _dialogStackPop];
    BYDialog *previousDialog = [BYDialog _dialogStackTopItem];
    if (previousDialog) {
        previousDialog.hidden = NO;
        [previousDialog _bounce];
    }
}

+ (void)_dialogStackPush:(BYDialog *)dialog{
    if (!gDialogStack) {
        gDialogStack = [[NSMutableArray alloc] initWithCapacity:8];
    }
    [gDialogStack addObject:dialog];
}
+ (void)_dialogStackPop{
    if (![gDialogStack count]) {
        return;
    }
    
    [gDialogStack removeLastObject];
    
    if ([gDialogStack count] == 0) {
        [gDialogStack release];
        gDialogStack = nil;
    }
}
+ (BYDialog *)_dialogStackTopItem{
    BYDialog *result = nil;
    
    if ([gDialogStack count]) {
        result = [gDialogStack lastObject];
    }
    
    return result;
}

@end


#pragma mark -

@implementation BYDialog

@dynamic visible;
- (BOOL)visible{
    return self.superview && !self.hidden;
}

@synthesize contentView = _contentView;

- (UIView *)contentView{
    return _contentView;
}

- (void)setContentView:(UIView *)contentView
{
    [_contentView autorelease];
    _contentView = [contentView retain];
//    _contentView.autoresizingMask = \
//    UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin |\
//    UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    _containerView.frame = CGRectMake(0, 0, _contentView.frame.size.width, _contentView.frame.size.height);
    [_containerView addSubview:_contentView];
}

#pragma mark -
#pragma mark UIView

- (id)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(close:) name:CLOSE_DIALOG_NOTIFICATION object:nil];
        _containerView = [[UIView alloc] initWithFrame:CGRectZero];
        _containerView.backgroundColor = [UIColor clearColor];
        _containerView.autoresizingMask = \
        UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin |\
        UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [_containerView.layer setShadowRadius:5];
        [_containerView.layer setShadowOpacity:0.5];
        [_containerView.layer setShadowColor:[UIColor blackColor].CGColor];
        [self addSubview:_containerView];
        [_containerView release];
    }
    return self;
}

- (CGSize)sizeThatFits:(CGSize)size{
    return _containerView.frame.size;
}

- (void)dealloc {  
    [super dealloc];
}

- (void)close:(NSNotification *)notification
{
    [self dismissAnimated:YES];
    [notification.object release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark Public

- (void)show{
    if (_showing) {
        return;
    }
    _showing = YES;
    
    // Prepare dialog to show
    [self retain];
    [self _registerObservers];
    [self _sizeToFitOrientation:NO];
    
    [self willPresentDialog];
    
    // If no dialog visible, mask window is invisible, then presetn mask window.
    if (![BYDialog _dialogStackTopItem]) {
        [BYDialog _maskWindowPresent];
    }
    [BYDialog _maskWindowAddDialog:self];
    
    [self _bounce];
}

- (void)dismissAnimated:(BOOL)animated{
    if (!_showing) {
        return;
    }
    _showing = NO;
    
    [self willDismissDialog];
    
    if (animated) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:kTransitionDuration];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(_dismissCleanup)];
        self.alpha = 0;
        [UIView commitAnimations];
    } else {
        [self _dismissCleanup];
    }
}

- (void)willPresentDialog{
    // Do nothing
}
- (void)didPresentDialog{
    // Do nothing
}
- (void)willDismissDialog{
    // Do nothing
}
- (void)didDismissDialog{
    // Do nothing
}

@end
