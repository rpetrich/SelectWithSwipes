//
//  SWSGestureAccessoryView.h
//  SelectWithSwipes
//
//  Created by Ryan Petrich on 12-05-05.
//  Copyright (c) 2012 Ryan Petrich. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SWSGestureRecognizer;

@interface SWSGestureAccessoryView : UIView

- (id)initWithInputView:(UIView<UITextInput> *)inputView;

@property (nonatomic, readonly) SWSGestureRecognizer *recognizer;

@end
