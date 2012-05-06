//
//  SWSGestureAccessory.h
//  SelectWithSwipes
//
//  Created by Ryan Petrich on 12-05-05.
//  Copyright (c) 2012 Ryan Petrich. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SWSGestureRecognizer : UIGestureRecognizer {
@private
    UIView<UITextInput> *inputView;
    CGFloat locationToCompare;
    UIView *referenceView;
    UITouch *ignoredSelectionTouch;
    UITextPosition *selectionStartPosition;
    BOOL isMovingStartPosition;
}

- (id)initWithInputView:(UIView<UITextInput> *)inputView;

@end
