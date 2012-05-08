//
//  SWSGestureAccessory.m
//  SelectWithSwipes
//
//  Created by Ryan Petrich on 12-05-05.
//  Copyright (c) 2012 Ryan Petrich. All rights reserved.
//

#import "SWSGestureRecognizer.h"

#import <UIKit/UIGestureRecognizerSubclass.h>

@implementation SWSGestureRecognizer

- (id)initWithInputView:(UIView<UITextInput> *)_inputView
{
    if ((self = [super init])) {
        inputView = [_inputView retain];
        self.cancelsTouchesInView = YES;
    }
    return self;
}

- (void)dealloc
{
    [referenceView release];
    [ignoredSelectionTouch release];
    [selectionStartPosition release];
    [inputView release];
    [super dealloc];
}

static inline CGPoint SWSAverageLocationOfActiveTouchesInView(id<NSFastEnumeration> touches, UIView *view, UITouch *ignoredTouch, NSInteger *outActiveCount)
{
    CGPoint result = CGPointZero;
    NSInteger count = 0;
    for (UITouch *touch in touches) {
        if (touch != ignoredTouch) {
            switch (touch.phase) {
                case UITouchPhaseBegan:
                case UITouchPhaseMoved:
                case UITouchPhaseStationary: {
                    CGPoint location = [touch locationInView:view];
                    result.x += location.x;
                    result.y += location.y;
                    count++;
                }
                case UITouchPhaseCancelled:
                case UITouchPhaseEnded:
                    break;
            }
        }
    }
    if (count) {
        result.x /= count;
        result.y /= count;
    }
    if (outActiveCount) {
        *outActiveCount = count;
    }
    return result;
}

- (void)processTouchesFromEvent:(UIEvent *)event
{
    if (self.state == UIGestureRecognizerStateFailed)
        return;
    NSSet *allTouches = [event allTouches];
    for (UITouch *touch in allTouches) {
        if (touch.phase == UITouchPhaseBegan) {
            // A touch was added, start/restart the gesture
            UIView *newReferenceView = touch.view;
            UIWindow *window = newReferenceView.window;
            UIView *superview = newReferenceView;
            // Find and ignore scrollview superviews
            Class scrollViewClass = [UIScrollView class];
            while (superview) {
                if ([superview isKindOfClass:scrollViewClass]) {
                    self.state = UIGestureRecognizerStateFailed;
                    return;
                }
                superview = superview.superview;
            }
            // Search the superviews for a view that is at least the screen width and prefer it if found
            superview = newReferenceView;
            CGSize screenSize = [window.screen ?: [UIScreen mainScreen] bounds].size;
            CGFloat minimumWidth = (screenSize.width > screenSize.height) ? screenSize.height : screenSize.width;
            while (superview && (superview != window) && (newReferenceView.bounds.size.width < minimumWidth)) {
                newReferenceView = superview;
                superview = newReferenceView.superview;
            }
            [referenceView release];
            referenceView = [newReferenceView retain];
            locationToCompare = SWSAverageLocationOfActiveTouchesInView(allTouches, newReferenceView, ignoredSelectionTouch, NULL).x;
            if (locationToCompare < 20.0f) {
                [ignoredSelectionTouch release];
                ignoredSelectionTouch = [touch retain];
                [self ignoreTouch:touch forEvent:event];
            }
            return;
        }
    }
    NSInteger activeTouchCount;
    CGFloat location = SWSAverageLocationOfActiveTouchesInView(allTouches, referenceView, ignoredSelectionTouch, &activeTouchCount).x;
    UITextGranularity granularity;
    CGFloat distanceRequired;
    switch (activeTouchCount) {
        case 1:
            granularity = UITextGranularityCharacter;
            distanceRequired = 5.0f;
            break;
        case 2:
            granularity = UITextGranularityWord;
            distanceRequired = 8.0f;
            self.state = UIGestureRecognizerStateBegan;
            break;
        default:
            return;
    }
    UITextDirection direction;
    if (location < locationToCompare - distanceRequired) {
        direction = UITextStorageDirectionBackward;
    } else if (location > locationToCompare + distanceRequired) {
        direction = UITextStorageDirectionForward;
    } else {
        return;
    }
    locationToCompare = location;
    UITextRange *range = inputView.selectedTextRange;
    UITextPosition *start = range.start;
    UITextPosition *end = range.end;
    UITextRange *newRange;
    if (ignoredSelectionTouch) {
        if (range.isEmpty) {
            UITextPosition *newPosition = [inputView.tokenizer positionFromPosition:start toBoundary:granularity inDirection:direction];
            if (!newPosition)
                return;
            if ((isMovingStartPosition = direction == UITextStorageDirectionBackward)) {
                newRange = [inputView textRangeFromPosition:newPosition toPosition:end];
            } else {
                newRange = [inputView textRangeFromPosition:start toPosition:newPosition];
            }
        } else if (isMovingStartPosition) {
            UITextPosition *newStart = [inputView.tokenizer positionFromPosition:start toBoundary:granularity inDirection:direction];
            if (!newStart)
                return;
            if ([inputView comparePosition:newStart toPosition:end] == NSOrderedDescending) {
                newRange = [inputView textRangeFromPosition:newStart toPosition:newStart];
            } else {
                newRange = [inputView textRangeFromPosition:newStart toPosition:end];
            }
        } else {
            UITextPosition *newEnd = [inputView.tokenizer positionFromPosition:end toBoundary:granularity inDirection:direction];
            if (!newEnd)
                return;
            if ([inputView comparePosition:newEnd toPosition:start] == NSOrderedAscending) {
                newRange = [inputView textRangeFromPosition:newEnd toPosition:newEnd];
            } else {
                newRange = [inputView textRangeFromPosition:start toPosition:newEnd];
            }
        }
    } else {
        UITextPosition *position = (direction == UITextStorageDirectionForward) ? end : start;
        UITextPosition *newPosition;
        if (range.isEmpty) {
            newPosition = [inputView.tokenizer positionFromPosition:position toBoundary:granularity inDirection:direction];
            if (!newPosition)
                return;
        } else {
            newPosition = position;
        }
        newRange = [inputView textRangeFromPosition:newPosition toPosition:newPosition];
    }
    // Sanity check to make sure we have a new selection
    if (newRange && (([inputView comparePosition:start toPosition:newRange.start] != NSOrderedSame) || ([inputView comparePosition:end toPosition:newRange.end] != NSOrderedSame))) {
        inputView.selectedTextRange = newRange;
        self.state = UIGestureRecognizerStateBegan;
    }
}

- (void)processTouchesFromEvent:(UIEvent *)event withPotentialCompletionState:(UIGestureRecognizerState)completionState
{
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [self processTouchesFromEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    [self processTouchesFromEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    for (UITouch *touch in [event allTouches]) {
        if (touch != ignoredSelectionTouch) {
            switch (touch.phase) {
                case UITouchPhaseCancelled:
                case UITouchPhaseEnded:
                    break;
                default:
                    [self processTouchesFromEvent:event];
                    return;
            }
        }
    }
    [referenceView release];
    referenceView = nil;
    [ignoredSelectionTouch release];
    ignoredSelectionTouch = nil;
    [selectionStartPosition release];
    selectionStartPosition = nil;
    switch (self.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged: {
            self.state = UIGestureRecognizerStateEnded;
            UITextRange *range = inputView.selectedTextRange;
            if (range && ([inputView comparePosition:range.start toPosition:range.end] != NSOrderedSame)) {
                UIMenuController *mc = [UIMenuController sharedMenuController];
                [mc setTargetRect:[inputView firstRectForRange:range] inView:inputView];
                [mc setMenuVisible:YES animated:YES];
            }
            break;
        }
        default:
            self.state = UIGestureRecognizerStateFailed;
            break;
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    for (UITouch *touch in [event allTouches]) {
        if (touch != ignoredSelectionTouch) {
            switch (touch.phase) {
                case UITouchPhaseCancelled:
                case UITouchPhaseEnded:
                    break;
                default:
                    [self processTouchesFromEvent:event];
                    return;
            }
        }
    }
    [referenceView release];
    referenceView = nil;
    [ignoredSelectionTouch release];
    ignoredSelectionTouch = nil;
    [selectionStartPosition release];
    selectionStartPosition = nil;
    self.state = UIGestureRecognizerStateCancelled;
}

- (void)reset
{
    [super reset];
    [referenceView release];
    referenceView = nil;
    [ignoredSelectionTouch release];
    ignoredSelectionTouch = nil;
    [selectionStartPosition release];
    selectionStartPosition = nil;
    self.state = UIGestureRecognizerStatePossible;
}

- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer
{
    return YES;
}

- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)preventedGestureRecognizer
{
    if ([preventedGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        self.state = UIGestureRecognizerStateCancelled;
    }
    return NO;
}

@end
