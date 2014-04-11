//
//  SBTDateTimeHelper.h
//  SchoolBusTimetable
//
//  Created by Liu Yuyang on 14-4-11.
//  Copyright (c) 2014年 Fudan University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SBTDateTimeHelper : NSObject

+ (NSDate *)todayAt:(NSString *)timeOfDay;

+ (NSDate *)todayAt:(NSString *)minutes AheadOf:(NSString *)timeOfDay;

+ (BOOL)timeOfDayEarlierThanNow:(NSString *)timeOfDay;

@end
