//
//  SBTTableViewController.h
//  SchoolBusTimetable
//
//  Created by Liu Yuyang on 14-4-2.
//  Copyright (c) 2014年 Fudan University. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SBTTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, readonly, strong) NSString *departure;
@property (nonatomic, readonly, strong) NSString *arrival;

- (NSString *)getChosenBusTime;

- (NSString *)getReadableCurrentRoute;

- (void)setAlarmForChosenBusWithMinutesAhead:(NSString *)minutes;

- (void)cancelAlarmForChosenBus;

- (NSString *)getAlarmMinutesAheadForChosenBus;

@end
