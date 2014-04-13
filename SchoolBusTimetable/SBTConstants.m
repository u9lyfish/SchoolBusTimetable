//
//  SBTConstants.m
//  SchoolBusTimetable
//
//  Created by Liu Yuyang on 14-4-11.
//  Copyright (c) 2014年 Fudan University. All rights reserved.
//

#import "SBTConstants.h"

@implementation SBTConstants

+ (CGFloat)UITopOffset
{
    return 64.0f;
}

+ (CGFloat)UIRowHeight
{
    return 30.0f;
}

+ (CGFloat)UIPickerHeight
{
    return 216.0f;
}

+ (CGFloat)UIScreenWidth
{
    return [[UIScreen mainScreen] bounds].size.width;
}

+ (CGFloat)UIScreenHeight
{
    return [[UIScreen mainScreen] bounds].size.height;
}

+ (CGRect)UIScreenFrame
{
    return [[UIScreen mainScreen] bounds];
}

+ (UIColor *)UIDefaultBackgroundColor
{
    return [UIColor colorWithRed:(247/255.0) green:(247/255.0) blue:(247/255.0) alpha:1];
}

@end
