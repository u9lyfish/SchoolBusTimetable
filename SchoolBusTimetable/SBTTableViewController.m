//
//  SBTTableViewController.m
//  SchoolBusTimetable
//
//  Created by Liu Yuyang on 14-4-2.
//  Copyright (c) 2014年 Fudan University. All rights reserved.
//

#import "SBTTimetableModel.h"
#import "SBTTableViewController.h"
#import "SBTBusDetailViewController.h"
#import "SBTNotificationHelper.h"
#import "SBTDateTimeHelper.h"
#import "SBTConstants.h"
#import "UIView+CGLibrary.h"

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
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *header;
@property (nonatomic, strong) UIButton *placeholderForRoute;
@property (nonatomic, strong) UIButton *buttonReturnRoute;
@property (nonatomic, strong) UIView *promptView;
@property (nonatomic, strong) UIButton *doneButton;
@property (nonatomic, strong) UIPickerView *campusPicker;


@end

@implementation SBTTableViewController

{
    BOOL pickerHidden;
}

@synthesize departure = _departure;
@synthesize arrival = _arrival;


// view structure:
//  UIVIew
//  - UITableView
//      - placeholders for bus route
//      - UITableViewCell
//  - UIView (prompt view)
//      - title and done button
//      - UIPickerView
//
- (void)viewDidLoad {
#ifdef ___DEBUG___
    NSLog(@"viewDidLoad");
#endif
    
    [super viewDidLoad];
    self.title = @"校车时刻表";
    self.view.backgroundColor = [UIColor whiteColor];
    
    CGFloat buttonHeight = 30.0f;
    CGFloat buttonWidth = 45.0f;
    CGFloat hMargin = 12.0f;
    CGFloat vMargin = 6.0f;
    
    [self.doneButton setFrame:CGRectMake([SBTConstants UIScreenWidth] - hMargin - buttonWidth,
                                        vMargin,
                                        buttonWidth,
                                         buttonHeight)];
    [self.campusPicker setY:buttonHeight + vMargin * 2];    // UIPickerView will always adjust its size itself
    [self.promptView setFrame:CGRectMake(0.0f,
                                        [SBTConstants UIScreenHeight],
                                        [SBTConstants UIScreenWidth],
                                         vMargin * 2 + buttonHeight + self.campusPicker.height)];
    
    [self.promptView addSubview:self.doneButton];
    [self.promptView addSubview:self.campusPicker];
    
    // auto layout is buggy, don't know why.
    /*
    // turn off for auto layout
    [self.doneButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.campusPicker setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.promptView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    // use auto layout to set size and position
    NSMutableArray *constraints = [NSMutableArray array];
    
    UIButton *doneButton = self.doneButton;
    UIPickerView *campusPicker = self.campusPicker;
    
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[doneButton]-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(doneButton)]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[doneButton(==30)]-[campusPicker]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(doneButton, campusPicker)]];
    
    [self.promptView addConstraints:constraints];
     */

    [self.view addSubview:self.tableView];
    [self.view addSubview:self.promptView];
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
    UILocalNotification *notification = [SBTNotificationHelper addNotificationWithMessage:notificationMessage andActionButtonTitle:nil atTimeOfDay:timeOfToday];
    
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

- (NSString *)getChosenBusTime
{
    return self.chosenBus;
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
    
    return self.header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [SBTConstants UIRowHeight] * 2;
}


#pragma mark - Picker view delegate

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (component == 1) {
        // the middle row shows an arrow ("▸") only
        return @"▸";
    } else {
        return [self.timetableModel getCampusNames][row];
    }
}


#pragma mark - Picker view data source
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    // | departure | ▸ | arrival |
    return 3;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (component == 1) {
        // the middle row shows an arrow ("▸") only
        return 1;
    } else {
        return [self.timetableModel getCampusNames].count;
    }
}


#pragma mark - Event handlers
- (void)placeholderForRoutePressed
{
    if (pickerHidden) {
        [self showPrompt];
        pickerHidden = NO;
    } else {
        [self hidePrompt];
        pickerHidden = YES;
    }
    
}

- (void)buttonReturnRoutePressed
{
    [self setDeparture:self.arrival andArrival:self.departure];
}

- (void)doneButtonPressed
{
    NSString *departure = [self.timetableModel getCampusNames][[self.campusPicker selectedRowInComponent:0]];
    NSString *arrival = [self.timetableModel getCampusNames][[self.campusPicker selectedRowInComponent:2]];
    
    if ([departure isEqualToString:arrival]) {
        // alert?
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                        message:@"请选择一个不同的校区作为终点"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    [self setDeparture:departure andArrival:arrival];
    [self hidePrompt];
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

// We force departure and arrival to be set at the same time to avoid the very case when departure equal to arrival in some temporary process,
// e.g., when switching value with each other. This will also trigger table view reload data.
- (void)setDeparture:(NSString *)departure andArrival:(NSString *)arrival
{
    self.departure = departure;
    self.arrival = arrival;
    
    [self.tableView reloadData];
}

- (void)showPrompt
{
    // scroll to currently chosen campuses
    NSInteger departureIndex = [[self.timetableModel getCampusNames] indexOfObject:self.departure];
    [self.campusPicker selectRow:departureIndex inComponent:0 animated:NO];

    NSInteger arrivalIndex = [[self.timetableModel getCampusNames] indexOfObject:self.arrival];
    [self.campusPicker selectRow:arrivalIndex inComponent:2 animated:NO];

    // show prompt view with animation
    CGFloat tableViewHeight = [SBTConstants UIScreenHeight] - self.promptView.height;
    
    if (DeviceSystemMajorVersion() == 6) {
        tableViewHeight = tableViewHeight - [SBTConstants UITopOffset];
    }
    
    [UIView beginAnimations:nil context:NULL];
    [self.tableView setHeight:tableViewHeight];
    [self.promptView setY:tableViewHeight];
    [UIView commitAnimations];
}

- (void)hidePrompt
{
    // show prompt view with animation
    CGFloat tableViewHeight = [SBTConstants UIScreenHeight];
    
    if (DeviceSystemMajorVersion() == 6) {
        tableViewHeight = tableViewHeight - [SBTConstants UITopOffset];
    }

    [UIView beginAnimations:nil context:NULL];
    [self.tableView setHeight:tableViewHeight];
    [self.promptView setY:tableViewHeight];
    [UIView commitAnimations];
}

/*! Returns the major version of iOS, (i.e. for iOS 6.1.3 it returns 6)
 */
NSUInteger DeviceSystemMajorVersion()
{
    static NSUInteger _deviceSystemMajorVersion = -1;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        _deviceSystemMajorVersion = [[[[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."] objectAtIndex:0] intValue];
    });
    
    return _deviceSystemMajorVersion;
}


#pragma mark - Property accessors

- (SBTTimetableModel *)timetableModel
{
    return [SBTTimetableModel sharedTimetableModel];
}

- (NSString *)departure
{
    if (_departure == nil) {
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
    if (_arrival == nil) {
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

- (UIView *)tableView
{
    if (_tableView == nil) {
        CGFloat tableViewHeight = [SBTConstants UIScreenHeight];
        if (DeviceSystemMajorVersion() == 6) {
            tableViewHeight = tableViewHeight - [SBTConstants UITopOffset];
        }
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0f,
                                                                   0.0f,
                                                                   [SBTConstants UIScreenWidth],
                                                                   tableViewHeight)];
        _tableView.dataSource = self;
        _tableView.delegate = self;
    }
    return _tableView;
}

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

- (UIPickerView *)campusPicker
{
    if (_campusPicker == nil) {
        // hide campusPicker under the bottom of screen
        _campusPicker = [UIPickerView new];
        _campusPicker.showsSelectionIndicator = YES;
        _campusPicker.delegate = self;
        _campusPicker.dataSource = self;
        pickerHidden = true;
    }
    return _campusPicker;
}

- (UIButton *)doneButton
{
    if (_doneButton == nil) {
        _doneButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_doneButton setTitle:@"完成" forState:UIControlStateNormal];
        [_doneButton addTarget:self action:@selector(doneButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _doneButton;
}

- (UIView *)promptView
{
    if (_promptView == nil) {
        _promptView = [UIView new];
    }
    return _promptView;
}

@end
