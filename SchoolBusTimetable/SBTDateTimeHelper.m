//
//  SBTDateTimeHelper.m
//  SchoolBusTimetable
//
//  Created by Liu Yuyang on 14-4-11.
//  Copyright (c) 2014年 Fudan University. All rights reserved.
//

#import "SBTDateTimeHelper.h"

@implementation SBTDateTimeHelper

+ (NSDate *)todayAt:(NSString *)minutes AheadOf:(NSString *)timeOfDay
{
    NSDate *originalDate = [SBTDateTimeHelper todayAt:timeOfDay];
    
    NSInteger secondsInAMinute = 60;
    NSInteger secondsAhead = [minutes integerValue] * secondsInAMinute;

    NSDate *date = [originalDate dateByAddingTimeInterval:-secondsAhead];
    
    return date;
}

+ (BOOL)timeOfDayEarlierThanNow:(NSString *)timeOfDay
{
    NSDate *now = [NSDate new];
    NSDate *date = [SBTDateTimeHelper todayAt:timeOfDay];
    return [date compare:now] == NSOrderedAscending;
}

+ (NSDate *)todayAt:(NSString *)timeOfDay
{
    NSArray *hourAndMinute = [timeOfDay componentsSeparatedByString:@":"];
    NSInteger hour = [hourAndMinute[0] integerValue];
    NSInteger minute = [hourAndMinute[1] integerValue];
    
    NSCalendar *calendar= [NSCalendar currentCalendar];
    NSDate *today = [NSDate new];
    NSDateComponents *componentsOfTimeOfDay = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:today];
    [componentsOfTimeOfDay setHour:hour];
    [componentsOfTimeOfDay setMinute:minute];
    
    NSDate *date = [calendar dateFromComponents:componentsOfTimeOfDay];

    return date;
}

@end
