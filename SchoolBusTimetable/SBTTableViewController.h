//
//  SBTTableViewController.h
//  SchoolBusTimetable
//
//  Created by Liu Yuyang on 14-4-2.
//  Copyright (c) 2014年 Fudan University. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SBTTableViewController : UITableViewController

@property (nonatomic, readonly, strong) NSString *departure;
@property (nonatomic, readonly, strong) NSString *arrival;

- (NSString *)getChosenBusTime;

- (NSString *)getReadableCurrentRoute;

// We force departure and arrival to be set at the same time to avoid the very case when departure equal to arrival in some temporary process,
// e.g., when switching value with each other. This will also trigger table view reload data.
- (void)setDeparture:(NSString *)departure andArrival:(NSString *)arrival;

// Set alarm for certain bus in current timetable
- (void)setAlarmForChosenBusWithMinutesAhead:(NSString *)minutes;

- (void)cancelAlarmForChosenBus;

- (NSString *)getAlarmMinutesAheadForChosenBus;

@end
