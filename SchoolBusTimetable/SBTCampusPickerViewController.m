//
//  SBTCampusPickerViewController.m
//  SchoolBusTimetable
//
//  Created by Liu Yuyang on 14-4-6.
//  Copyright (c) 2014年 Fudan University. All rights reserved.
//

#import "SBTCampusPickerViewController.h"
#import "SBTTimetableModel.h"
#import "SBTConstants.h"

@interface SBTCampusPickerViewController ()

@property (nonatomic, strong) SBTTimetableModel *timetableModel;
@property (nonatomic) SBTTableViewController *timetableViewController;

@property (nonatomic) UIPickerView *campusPicker;
@property (nonatomic) UIButton *placeholderForDepartureCampus;
@property (nonatomic) UIButton *placeholderForArrivalCampus;

@end

@implementation SBTCampusPickerViewController

static SBTTimetableModel *_sharedTimetableModel = nil;
UIButton *currentlyPressed;

- (void)loadView {
    // not calling super, use scroll view to solve navigation bar overlapping: http://blog.motioninmotion.tv/fixing-the-ios-7-navigation-bar-overlap-problem
    self.view = [UIScrollView new];
}

- (id)initWithTimetableViewController:(SBTTableViewController *)timetableViewController
{
    self = [super init];
    if (self) {
        self.timetableViewController = timetableViewController;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"选择路线";
    self.view.backgroundColor = [UIColor whiteColor];
    
    // Done button on nav bar
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    UILabel *labelArrow = [UILabel new];
    labelArrow.textAlignment = NSTextAlignmentCenter;
    labelArrow.text = @" ▸ ";

    self.campusPicker.hidden = YES;

    [self.view addSubview:labelArrow];
    [self.view addSubview:self.placeholderForDepartureCampus];
    [self.view addSubview:self.placeholderForArrivalCampus];
    [self.view addSubview:self.campusPicker];

    // turn off for auto layout
    [labelArrow setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.placeholderForDepartureCampus setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.placeholderForArrivalCampus setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.campusPicker setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    // use auto layout to set size and position
    NSMutableArray *constraints = [NSMutableArray array];
    
    // must use local variables instead of properties in visual format string
    UIButton *placeholderForDepartureCampus = self.placeholderForDepartureCampus;
    UIButton *placeholderForArrivalCampus = self.placeholderForArrivalCampus;
    UIPickerView *campusPicker = self.campusPicker;
    
    NSDictionary *metrics = @{
                              @"buttonWidth": @145.0,
                              @"labelWidth": @30.0,
                              @"hMargin": @12.0,
                              @"rowHeight": [NSNumber numberWithFloat:[SBTConstants UIRowHeight]]
                              };

    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[placeholderForDepartureCampus(==buttonWidth)][labelArrow(==labelWidth)][placeholderForArrivalCampus(==buttonWidth)]|" options:0 metrics:metrics views:NSDictionaryOfVariableBindings(placeholderForDepartureCampus, placeholderForArrivalCampus, labelArrow)]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[placeholderForDepartureCampus(==rowHeight)][campusPicker]" options:0 metrics:metrics views:NSDictionaryOfVariableBindings(placeholderForDepartureCampus, campusPicker)]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[placeholderForArrivalCampus(==rowHeight)]" options:0 metrics:metrics views:NSDictionaryOfVariableBindings(placeholderForArrivalCampus)]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[labelArrow(==rowHeight)]" options:0 metrics:metrics views:NSDictionaryOfVariableBindings(labelArrow)]];

    [self.view addConstraints:constraints];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Property accessors

- (SBTTimetableModel *)timetableModel
{
    return [SBTTimetableModel sharedTimetableModel];
}

#pragma mark - PickerView delegate

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSString *selectedCampus = [self.timetableModel getCampusNames][[pickerView selectedRowInComponent:component]];
    [currentlyPressed setTitle:selectedCampus forState:UIControlStateNormal];
}

#pragma mark - PickerView data source

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [self.timetableModel getCampusNames].count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [self.timetableModel getCampusNames][row];
}

#pragma mark - Event handlers
- (void)placeholderForCampusPressed:(UIButton *)sender
{
    self.campusPicker.hidden = YES;

    NSInteger index = [[self.timetableModel getCampusNames] indexOfObject:[(UIButton *)sender currentTitle]];
    [self.campusPicker selectRow:index inComponent:0 animated:NO];

    self.campusPicker.hidden = NO;
    
    currentlyPressed = sender;
}

- (void)doneButtonPressed:(UIButton *)sender
{
    NSString *departure = [self.placeholderForDepartureCampus currentTitle];
    NSString *arrival = [self.placeholderForArrivalCampus currentTitle];
    
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
    
    [self.timetableViewController setDeparture:departure andArrival:arrival];
    
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - UI components

- (UIPickerView *)campusPicker
{
    if (!_campusPicker) {
        _campusPicker = [UIPickerView new];
        _campusPicker.delegate = self;
        _campusPicker.dataSource = self;
        _campusPicker.showsSelectionIndicator = YES;
    }
    return _campusPicker;
}

- (UIButton *)placeholderForDepartureCampus
{
    if (!_placeholderForDepartureCampus) {
        _placeholderForDepartureCampus = [UIButton buttonWithType:UIButtonTypeCustom];
        [_placeholderForDepartureCampus setTitleColor:_placeholderForDepartureCampus.tintColor forState:UIControlStateNormal];
        [_placeholderForDepartureCampus setTitle:self.timetableViewController.departure forState:UIControlStateNormal];
        _placeholderForDepartureCampus.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        [_placeholderForDepartureCampus addTarget:self action:@selector(placeholderForCampusPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _placeholderForDepartureCampus;
}

- (UIButton *)placeholderForArrivalCampus
{
    if (!_placeholderForArrivalCampus) {
        _placeholderForArrivalCampus = [UIButton buttonWithType:UIButtonTypeCustom];
        [_placeholderForArrivalCampus setTitle:self.timetableViewController.arrival forState:UIControlStateNormal];
        [_placeholderForArrivalCampus setTitleColor:_placeholderForArrivalCampus.tintColor forState:UIControlStateNormal];
        _placeholderForArrivalCampus.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [_placeholderForArrivalCampus addTarget:self action:@selector(placeholderForCampusPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _placeholderForArrivalCampus;
}

@end
