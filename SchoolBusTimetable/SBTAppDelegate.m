//
//  SBTAppDelegate.m
//  SchoolBusTimetable
//
//  Created by Liu Yuyang on 14-4-1.
//  Copyright (c) 2014年 Fudan University. All rights reserved.
//

#import "SBTAppDelegate.h"
#import "SBTTableViewController.h"

@interface SBTAppDelegate ()

@end

@implementation SBTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    UINavigationController *navigationController = [UINavigationController new];
    SBTTableViewController *tableViewController = [SBTTableViewController new];
    [navigationController pushViewController:tableViewController animated:NO];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
