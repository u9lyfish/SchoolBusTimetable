//
//  SBTBusDetailViewController.h
//  SchoolBusTimetable
//
//  Created by Liu Yuyang on 14-4-7.
//  Copyright (c) 2014年 Fudan University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SBTTableViewController.h"

@interface SBTBusDetailViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource>

- (id)initWithTimetableViewController:(SBTTableViewController *)timetableViewController;

@end
