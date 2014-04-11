//
//  SBTNotificationManager.m
//  SchoolBusTimetable
//
//  Created by Liu Yuyang on 14-4-9.
//  Copyright (c) 2014年 Fudan University. All rights reserved.
//

#import "SBTNotificationHelper.h"

@interface SBTNotificationHelper()

@end

@implementation SBTNotificationHelper

+ (UILocalNotification *)addNotificationWithMessage:(NSString *)message andActionButtonTitle:(NSString *)title atTimeOfDay:(NSDate *)timeOfDay
{
    UILocalNotification *localNotification = [UILocalNotification new];
    
    NSAssert(localNotification != nil, @"localNotification initialization failed");

    localNotification.fireDate = timeOfDay;

    // TODO: according to the documentation, timezone should be properly set, figure this out.
//    localNotification.timeZone = [NSTimeZone systemTimeZone];
    
	// Notification details
    localNotification.alertBody = message;

	// Set the action button title
    localNotification.alertAction = title;
    
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    
	// Schedule the notification
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    
    return localNotification;
}

+ (void)cancelNotification:(UILocalNotification *)notification
{
    [[UIApplication sharedApplication] cancelLocalNotification:notification];
}

@end
