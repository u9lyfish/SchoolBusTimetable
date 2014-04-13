//
//  SBTBusDetailViewController.m
//  SchoolBusTimetable
//
//  Created by Liu Yuyang on 14-4-7.
//  Copyright (c) 2014年 Fudan University. All rights reserved.
//

#import "SBTBusDetailViewController.h"
#import "SBTTimetableModel.h"
#import "SBTConstants.h"

@interface SBTBusDetailViewController ()

@property (nonatomic) SBTTableViewController *timetableViewController;


#pragma mark - Model classes
@property (nonatomic, strong) SBTTimetableModel *timetableModel;


#pragma mark - UI components
@property (nonatomic, strong) UILabel *labelForRoute;
@property (nonatomic, strong) UILabel *labelForBusTime;
@property (nonatomic, strong) UILabel *labelForReminderSwitch;
@property (nonatomic, strong) UISwitch *reminderSwitch;
@property (nonatomic, strong) UILabel *minuteLabel;     // UILabel to display remind time ahead
@property (nonatomic, strong) UIPickerView *minutePicker;       // UIPicker to choose remind time ahead in minutes


@end

@implementation SBTBusDetailViewController

- (id)initWithTimetableViewController:(SBTTableViewController *)timetableViewController
{
    self = [super init];
    if (self) {
        self.timetableViewController = timetableViewController;
    }
    return self;
}

- (void)loadView {
    // not calling super, use scroll view to solve navigation bar overlapping: http://blog.motioninmotion.tv/fixing-the-ios-7-navigation-bar-overlap-problem
    self.view = [UIScrollView new];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"设置提醒";
    self.view.backgroundColor = [UIColor whiteColor];
    
    // Done button on top right of navigation bar
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    // UILabel for reminder switch
    UILabel *labelForReminderSwitch = [UILabel new];
    labelForReminderSwitch.text = @"为这班校车设置提醒";

    // alarm setting for chosen bus
    NSString *alarmMinutesAhead = [self.timetableViewController getAlarmMinutesAheadForChosenBus];
    BOOL alarmSet = (alarmMinutesAhead != nil);

    if (alarmSet) {
        NSInteger index = [[SBTBusDetailViewController minutePickerRows] indexOfObject:alarmMinutesAhead];
        [self.minutePicker selectRow:index inComponent:0 animated:NO];
    }
    [self.minutePicker setHidden:!alarmSet];
    [self.minuteLabel setHidden:!alarmSet];
    self.reminderSwitch.on = alarmSet;
    [self.reminderSwitch addTarget:self action:@selector(reminderSwitchFliped:) forControlEvents:UIControlEventValueChanged];
    
    [self.view addSubview:self.labelForRoute];
    [self.view addSubview:self.labelForBusTime];
    [self.view addSubview:labelForReminderSwitch];
    [self.view addSubview:self.reminderSwitch];
    [self.view addSubview:self.minutePicker];
    [self.view addSubview:self.minuteLabel];

    // turn off for auto layout
    [self.labelForRoute setTranslatesAutoresizingMaskIntoConstraints:NO];   // for auto layout
    [self.labelForBusTime setTranslatesAutoresizingMaskIntoConstraints:NO];   // for auto layout
    [labelForReminderSwitch setTranslatesAutoresizingMaskIntoConstraints:NO];   // for auto layout
    [self.reminderSwitch setTranslatesAutoresizingMaskIntoConstraints:NO];   // for auto layout
    [self.minutePicker setTranslatesAutoresizingMaskIntoConstraints:NO];   // for auto layout
    [self.minuteLabel setTranslatesAutoresizingMaskIntoConstraints:NO];   // for auto layout

    // use auto layout to set size and position
    NSMutableArray *constraints = [NSMutableArray array];
    
    // must use local variables instead of properties in visual format string
    UILabel *labelForRoute = self.labelForRoute;
    UILabel *labelForBusTime = self.labelForBusTime;
    UISwitch *reminderSwitch = self.reminderSwitch;
    UILabel *minuteLabel = self.minuteLabel;
    UIPickerView *minutePicker = self.minutePicker;

    NSDictionary *metrics = @{
                              @"screenWidth": [NSNumber numberWithFloat:[SBTConstants UIScreenWidth]],
                              @"hMargin": @12.0f,
                              @"vMargin": @18.0f,
                              @"rowHeight": [NSNumber numberWithFloat:[SBTConstants UIRowHeight]]
                              };

    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[labelForRoute(==screenWidth)]|" options:0 metrics:metrics views:NSDictionaryOfVariableBindings(labelForRoute)]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[labelForBusTime]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(labelForBusTime)]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-hMargin-[labelForReminderSwitch]-[reminderSwitch]-hMargin-|" options:0 metrics:metrics views:NSDictionaryOfVariableBindings(labelForReminderSwitch, reminderSwitch)]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-hMargin-[minuteLabel]-hMargin-|" options:0 metrics:metrics views:NSDictionaryOfVariableBindings(minuteLabel)]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[labelForRoute(==rowHeight)][labelForBusTime(==rowHeight)]-vMargin-[labelForReminderSwitch]-vMargin-[minuteLabel]-vMargin-[minutePicker]" options:0 metrics:metrics views:NSDictionaryOfVariableBindings(labelForRoute, labelForBusTime, labelForReminderSwitch, minuteLabel, minutePicker)]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[labelForRoute][labelForBusTime]-vMargin-[reminderSwitch]" options:0 metrics:metrics views:NSDictionaryOfVariableBindings(labelForRoute, labelForBusTime, reminderSwitch)]];
    
    [self.view addConstraints:constraints];
}


#pragma mark - PickerView delegate

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSString *minute = [SBTBusDetailViewController minutePickerRows][row];
    self.minuteLabel.text = [self minuteLabelText:minute];
}


#pragma mark - PickerView data source

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [SBTBusDetailViewController minutePickerRows].count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [SBTBusDetailViewController minutePickerRows][row];
}


#pragma mark - Event handlers

- (void)doneButtonPressed:(UIBarButtonItem *)sender
{
    if (self.reminderSwitch.on) {
        [self.timetableViewController setAlarmForChosenBusWithMinutesAhead:[self selectedMinute]];
    } else {
        [self.timetableViewController cancelAlarmForChosenBus];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)reminderSwitchFliped:(UISwitch *)sender
{
    if (sender.on) {
        [self.minuteLabel setHidden:NO];
        [self.minutePicker setHidden:NO];
    } else {
        [self.minuteLabel setHidden:YES];
        [self.minutePicker setHidden:YES];
    }
}


#pragma mark - Helper routines

- (NSString *)minuteLabelText:(NSString *)minute
{
    return [NSString stringWithFormat: @"在发车前 %@ 分钟提醒我", minute];
}

- (NSString *)selectedMinute
{
    return [SBTBusDetailViewController minutePickerRows][[self.minutePicker selectedRowInComponent:0]];
}


#pragma mark - Constant wrappers

+ (NSArray *)minutePickerRows
{
    return @[@"5", @"10", @"15", @"20", @"25", @"30"];
}


#pragma mark - UI components

- (UILabel *)labelForRoute
{
    if (_labelForRoute == nil) {
        _labelForRoute = [UILabel new];
        _labelForRoute.text = [self.timetableViewController getReadableCurrentRoute];
        _labelForRoute.textAlignment = NSTextAlignmentCenter;
        _labelForRoute.font = [UIFont systemFontOfSize:18.0];
        _labelForRoute.backgroundColor = [SBTConstants UIDefaultBackgroundColor];
    }
    return _labelForRoute;
}

- (UILabel *)labelForBusTime
{
    if (_labelForBusTime == nil) {
        _labelForBusTime = [UILabel new];
        _labelForBusTime.text = [self.timetableViewController getChosenBusTime];
        _labelForBusTime.textAlignment = NSTextAlignmentCenter;
        _labelForBusTime.font = [UIFont systemFontOfSize: 15];
        _labelForBusTime.backgroundColor = [SBTConstants UIDefaultBackgroundColor];
    }
    return _labelForBusTime;
}

- (UISwitch *)reminderSwitch
{
    if (_reminderSwitch == nil) {
        _reminderSwitch = [UISwitch new];
    }
    return _reminderSwitch;
}

- (UIPickerView *)minutePicker
{
    if (_minutePicker == nil) {
        _minutePicker = [UIPickerView new];
        _minutePicker.delegate = self;
        _minutePicker.dataSource = self;
        _minutePicker.showsSelectionIndicator = YES;
    }
    return _minutePicker;
}

- (UILabel *)minuteLabel
{
    if (_minuteLabel == nil) {
        _minuteLabel = [UILabel new];
        _minuteLabel.text = [self minuteLabelText:[self selectedMinute]];
    }
    return _minuteLabel;
}

@end
