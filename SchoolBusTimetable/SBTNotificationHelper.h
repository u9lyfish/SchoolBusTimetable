//
//  SBTNotificationManager.h
//  SchoolBusTimetable
//
//  Created by Liu Yuyang on 14-4-9.
//  Copyright (c) 2014年 Fudan University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SBTNotificationHelper : NSObject

+ (UILocalNotification *)addNotificationWithMessage:(NSString *)message andActionButtonTitle:(NSString *)title atTimeOfDay:(NSDate *)timeOfDay;

+ (void)cancelNotification:(UILocalNotification *)notification;

@end
