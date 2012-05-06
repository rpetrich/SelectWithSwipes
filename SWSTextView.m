//
//  SWSTextView.m
//  SelectWithSwipes
//
//  Created by Ryan Petrich on 12-05-05.
//  Copyright (c) 2012 Ryan Petrich. All rights reserved.
//

#import "SWSTextView.h"

#import "SWSGestureAccessoryView.h"

@implementation SWSTextView

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    if (!self.inputAccessoryView) {
        self.inputAccessoryView = [[[SWSGestureAccessoryView alloc] initWithInputView:self] autorelease];
    }
}

@end
