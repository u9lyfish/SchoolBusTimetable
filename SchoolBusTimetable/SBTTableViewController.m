//
//  SBTTableViewController.m
//  SchoolBusTimetable
//
//  Created by Liu Yuyang on 14-4-2.
//  Copyright (c) 2014年 Fudan University. All rights reserved.
//

#import "SBTTimetableModel.h"
#import "SBTTableViewController.h"
#import "SBTCampusPickerViewController.h"
#import "SBTBusDetailViewController.h"
#import "SBTNotificationHelper.h"
#import "SBTDateTimeHelper.h"
#import "SBTConstants.h"

//#define ___DEBUG___

@interface SBTTableViewController ()


#pragma mark - Model classes
@property (nonatomic, strong) SBTTimetableModel *timetableModel;


#pragma mark - Internal statuses
// the bus that is currently chosen
@property (nonatomic, strong) NSString *chosenBus;

// a nested dictionary to manage notifications with following structure:
// self.alarms = @{route: @{busTime: @{@"minutesAhead":minutesAhead, @"notification":notification}}}
@property (nonatomic, strong) NSMutableDictionary *alarms;


#pragma - UI components
@property (nonatomic, strong) UIView *header;
@property (nonatomic, strong) UIButton *placeholderForRoute;
@property (nonatomic, strong) UIButton *buttonReturnRoute;

@end

@implementation SBTTableViewController

@synthesize departure = _departure;
@synthesize arrival = _arrival;

- (void)viewDidLoad {
#ifdef ___DEBUG___
    NSLog(@"viewDidLoad");
#endif
    
    [super viewDidLoad];
    self.title = @"校车时刻表";
}

- (NSString *)getChosenBusTime
{
    return self.chosenBus;
}

- (void)setDeparture:(NSString *)departure andArrival:(NSString *)arrival
{
    self.departure = departure;
    self.arrival = arrival;
    
    [self.tableView reloadData];
}

- (void)setAlarmForChosenBusWithMinutesAhead:(NSString *)minutes
{
    // alarm settings for certain route, e.g. "邯郸江湾"
    NSMutableDictionary *alarmsForRoute = [self.alarms objectForKey:[self getCurrentRoute]];
    
    // create alarm setting dictionary if it doesn't exist
    if (alarmsForRoute == nil) {
        alarmsForRoute = [NSMutableDictionary dictionary];
    }
    
    // cancel any notification for current bus before setting up new one
    NSDictionary *oldAlarmForBus = [alarmsForRoute objectForKey:self.chosenBus];
    if (oldAlarmForBus != nil) {
        UILocalNotification *oldNotification = [oldAlarmForBus objectForKey:@"notification"];
        [SBTNotificationHelper cancelNotification:oldNotification];
    }
    
    // add local notification for chosen bus
    NSDate *timeOfToday = [SBTDateTimeHelper todayAt:minutes AheadOf:self.chosenBus];
    NSString *notificationMessage = [NSString stringWithFormat:@"%@ %@ 的校车即将发车",
                                     [self getReadableCurrentRoute],
                                     self.chosenBus];
    UILocalNotification *notification = [SBTNotificationHelper addNotificationWithMessage:notificationMessage andActionButtonTitle:@"关闭" atTimeOfDay:timeOfToday];
    
    // set up alarm for certain bus (of chosen route)
    NSDictionary *alarmForBus = @{@"minutesAhead":minutes, @"notification":notification};
    
    // add alarm to route
    [alarmsForRoute setObject:alarmForBus forKey:self.chosenBus];
    [self.alarms setObject:alarmsForRoute forKey:[self getCurrentRoute]];
    
    // update corresponding table view cell
    NSInteger index = [[self getCurrentTimetable] indexOfObject:self.chosenBus];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)cancelAlarmForChosenBus
{
    // alarm settings for certain route, e.g. "邯郸江湾"
    NSMutableDictionary *alarmsForRoute = [self.alarms objectForKey:[self getCurrentRoute]];
    
    // set up alarm for certain bus (of chosen route)
    [alarmsForRoute removeObjectForKey:self.chosenBus];
    [self.alarms setObject:alarmsForRoute forKey:[self getCurrentRoute]];
    
    // update corresponding table view cell
    NSInteger index = [[self getCurrentTimetable] indexOfObject:self.chosenBus];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (NSString *)getAlarmMinutesAheadForChosenBus
{
    return [[self getAlarmMinutesAheadForBusOfCurrentRoute:self.chosenBus] objectForKey:@"minutesAhead"];
}


#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.chosenBus = [self getCurrentTimetable][indexPath.row];
    if (self.chosenBus != nil && ![SBTDateTimeHelper timeOfDayEarlierThanNow:self.chosenBus]) {
        SBTBusDetailViewController *busDetailViewController = [[SBTBusDetailViewController alloc] initWithTimetableViewController:self];
        [self.navigationController pushViewController:busDetailViewController animated:YES];
    }
}


#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#ifdef ___DEBUG___
    NSLog(@"numberOfRowsInSection called");
#endif
    
    NSInteger count = [self getCurrentTimetable].count;
    return count > 0 ? count : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
#ifdef ___DEBUG___
    NSLog(@"cellForRowAtIndexPath called");
#endif
    
    if ([self getCurrentTimetable].count > 0) {
        static NSString *defaultTimetableCellIdentifier = @"default timetable cell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:defaultTimetableCellIdentifier];
        
        NSString * busTime = [self getCurrentTimetable][indexPath.row];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:defaultTimetableCellIdentifier];
        }

        // check if alarm has been set up for this bus
        BOOL alarmSet = ([self getAlarmMinutesAheadForBusOfCurrentRoute:busTime] != nil);
        BOOL timePassed = [SBTDateTimeHelper timeOfDayEarlierThanNow:busTime];
        
        if (alarmSet) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            if (timePassed) {
                cell.accessoryType = UITableViewCellAccessoryNone;
            } else {
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
        }
        
        // check if this bus has gone (bus time earlier than now)
        if (timePassed) {
            cell.textLabel.textColor = [UIColor grayColor];
        } else {
            cell.textLabel.textColor = [UIColor blackColor];
        }
        
        cell.textLabel.text = busTime;
        return cell;
    } else {
        static NSString *noBusAvailableCellIdentifier = @"no bus available cell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:noBusAvailableCellIdentifier];

        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:noBusAvailableCellIdentifier];
            cell.textLabel.text = @"（两校区间尚未开通校车）";
        }
        return cell;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // turn off for auto layout
    [self.placeholderForRoute setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.buttonReturnRoute setTranslatesAutoresizingMaskIntoConstraints:NO];

    [self.header addSubview:self.placeholderForRoute];
    [self.header addSubview:self.buttonReturnRoute];
    
    // use auto layout to set size and position
    NSMutableArray *constraints = [NSMutableArray array];
    
    // must use local variables instead of properties in visual format string
    UIButton *placeholderForRoute = self.placeholderForRoute;
    UIButton *buttonReturnRoute = self.buttonReturnRoute;
    
    NSDictionary *metrics = @{@"rowHeight": [NSNumber numberWithFloat:[SBTConstants UIRowHeight]]};
    
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[placeholderForRoute]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(placeholderForRoute)]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[buttonReturnRoute]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(buttonReturnRoute)]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[placeholderForRoute(==rowHeight)][buttonReturnRoute(==rowHeight)]" options:0 metrics:metrics views:NSDictionaryOfVariableBindings(placeholderForRoute, buttonReturnRoute)]];

    [self.header addConstraints:constraints];
    
    [self.header sizeToFit];
    return self.header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [SBTConstants UIRowHeight] * 2;
}


#pragma mark - Event handlers

- (void)placeholderForRoutePressed
{
    SBTCampusPickerViewController *campusPickerViewController = [[SBTCampusPickerViewController alloc] initWithTimetableViewController:self];
    [self.navigationController pushViewController:campusPickerViewController animated:YES];
}

- (void)buttonReturnRoutePressed
{
    [self setDeparture:self.arrival andArrival:self.departure];
}


#pragma mark - Helper routines

- (NSString *)getCurrentRoute
{
    return [self.departure stringByAppendingString:self.arrival];
}

- (NSArray *)getCurrentTimetable
{
    return [self.timetableModel getTimetableForBusRouteFrom:self.departure To:self.arrival];
}

- (NSDictionary *)getAlarmMinutesAheadForBusOfCurrentRoute:(NSString *)bus
{
    return [[self.alarms objectForKey:[self getCurrentRoute]] objectForKey:bus];
}

- (NSString *)getReadableCurrentRoute
{
    return [NSString stringWithFormat:@"%@  ▸  %@",
            self.departure,
            self.arrival
            ];
}


#pragma mark - Property accessors

- (SBTTimetableModel *)timetableModel
{
    return [SBTTimetableModel sharedTimetableModel];
}

- (NSString *)departure
{
    if (!_departure) {
        _departure = @"邯郸";
    }
    
    return _departure;
}

- (void)setDeparture:(NSString *)departure
{
    NSAssert([self.timetableModel isValidCampusName:departure], @"Invalid departure campus");
    _departure = departure;
}

- (NSString *)arrival
{
    if (!_arrival) {
        _arrival = @"江湾";
    }
    
    return _arrival;
}

- (void)setArrival:(NSString *)arrival
{
    NSAssert([self.timetableModel isValidCampusName:arrival], @"Invalid arrival campus");
    _arrival = arrival;
}

- (NSDictionary *)alarms
{
    if (_alarms == nil) {
        _alarms = [NSMutableDictionary dictionary];
    }
    return _alarms;
}


#pragma mark - UI components

- (UIView *)header
{
    if (_header == nil) {
        _header = [UIView new];
        UIColor *defaultBGColor = [UIColor colorWithRed:(247/255.0) green:(247/255.0) blue:(247/255.0) alpha:1];
        _header.backgroundColor = defaultBGColor;
    }
    return _header;
}

- (UIButton *)placeholderForRoute
{
    if (_placeholderForRoute == nil) {
        _placeholderForRoute = [UIButton buttonWithType:UIButtonTypeCustom];
        _placeholderForRoute.backgroundColor = [SBTConstants UIDefaultBackgroundColor];
        [_placeholderForRoute setTitleColor:_placeholderForRoute.tintColor forState:UIControlStateNormal];
        [_placeholderForRoute addTarget:self action:@selector(placeholderForRoutePressed) forControlEvents:UIControlEventTouchUpInside];
    }
    [_placeholderForRoute setTitle:[self getReadableCurrentRoute] forState:UIControlStateNormal];
    return _placeholderForRoute;
}

- (UIButton *)buttonReturnRoute
{
    if (_buttonReturnRoute == nil) {
        _buttonReturnRoute = [UIButton buttonWithType:UIButtonTypeCustom];
        _buttonReturnRoute.backgroundColor = [SBTConstants UIDefaultBackgroundColor];
        [_buttonReturnRoute setTitleColor:_buttonReturnRoute.tintColor forState:UIControlStateNormal];
        _buttonReturnRoute.titleLabel.font = [UIFont systemFontOfSize: 13];
        [_buttonReturnRoute addTarget:self action:@selector(buttonReturnRoutePressed) forControlEvents:UIControlEventTouchUpInside];
    }
    NSString *returnRouteString = [NSString stringWithFormat:@"查看返程 ( %@ ▸ %@ )", self.arrival, self.departure];
    [_buttonReturnRoute setTitle:returnRouteString forState:UIControlStateNormal];
    return _buttonReturnRoute;
}

@end
