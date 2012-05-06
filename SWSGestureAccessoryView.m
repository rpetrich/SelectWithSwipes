//
//  SWSGestureAccessoryView.m
//  SelectWithSwipes
//
//  Created by Ryan Petrich on 12-05-05.
//  Copyright (c) 2012 Ryan Petrich. All rights reserved.
//

#import "SWSGestureAccessoryView.h"
#import "SWSGestureRecognizer.h"

@implementation SWSGestureAccessoryView

@synthesize recognizer;

- (id)initWithInputView:(UIView<UITextInput> *)inputView
{
    if ((self = [super initWithFrame:CGRectZero])) {
        recognizer = [[SWSGestureRecognizer alloc] initWithInputView:inputView];
    }
    return self;
}

- (void)dealloc
{
    [recognizer release];
    [super dealloc];
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    [self.window removeGestureRecognizer:recognizer];
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    [self.window addGestureRecognizer:recognizer];
}

@end
