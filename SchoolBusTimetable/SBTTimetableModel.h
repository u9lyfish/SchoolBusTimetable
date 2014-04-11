//
//  SBTTimetableModel.h
//  SchoolBusTimetable
//
//  Created by Liu Yuyang on 14-4-4.
//  Copyright (c) 2014年 Fudan University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SBTTimetableModel : NSObject

+ (SBTTimetableModel *)sharedTimetableModel;

- (NSArray *)getCampusNames;

- (BOOL)isValidCampusName: (NSString *)name;

- (NSArray *)getTimetableForBusRouteFrom: (NSString *) departure To: (NSString *) destination;

@end
