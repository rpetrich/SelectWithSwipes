//
//  SWSAppDelegate.h
//  SelectWithSwipes
//
//  Created by Ryan Petrich on 12-05-05.
//  Copyright (c) 2012 Ryan Petrich. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SWSViewController;

@interface SWSAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) SWSViewController *viewController;

@end
