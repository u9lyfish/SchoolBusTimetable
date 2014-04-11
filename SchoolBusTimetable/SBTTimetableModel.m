//
//  SBTTimetableModel.m
//  SchoolBusTimetable
//
//  Created by Liu Yuyang on 14-4-4.
//  Copyright (c) 2014年 Fudan University. All rights reserved.
//

#import "SBTTimetableModel.h"

@interface SBTTimetableModel()

@property (nonatomic) NSDictionary *timetableForAllRoutes;
@property (nonatomic, readonly) NSArray *campusNames;

@end

@implementation SBTTimetableModel

static SBTTimetableModel *_sharedTimetableModel = nil;

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

+ (SBTTimetableModel *)sharedTimetableModel
{
    @synchronized(self)
    {
        if (_sharedTimetableModel == nil) {
            _sharedTimetableModel = [SBTTimetableModel new];
        }
    }
    return _sharedTimetableModel;
}

- (NSArray *)getTimetableForBusRouteFrom: (NSString *) departure To: (NSString *) arrival
{
    NSAssert([self isValidCampusName:departure], @"Invalid departure campus");
    NSAssert([self isValidCampusName:arrival], @"Invalid arrival campus");
    NSAssert(![departure isEqualToString:arrival], @"Departure campus cannot equal to arrival campus");
    
    NSString *route = [departure stringByAppendingString:arrival];
    return [self.timetableForAllRoutes objectForKey:route];
}

- (NSArray *)getCampusNames
{
    if (!_campusNames) {
        _campusNames = [self fetchCampusNamesFromStorage];
    }
    return _campusNames;
}

- (BOOL)isValidCampusName: (NSString *)name
{
    return [[self getCampusNames] containsObject:name];
}

#pragma mark - Property accessors

- (NSDictionary *)timetableForAllRoutes
{
    if (!_timetableForAllRoutes) {
        _timetableForAllRoutes = [self fetchTimetableForAllRoutesFromStorage];
    }
    return _timetableForAllRoutes;
}

#pragma mark - Data persistency

- (id)fetchDataFromPlist:(NSString *)plist
{
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *plistPath;
    plistPath = [rootPath stringByAppendingPathComponent:[plist stringByAppendingString:@".plist"]];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        plistPath = [[NSBundle mainBundle] pathForResource:plist ofType:@"plist"];
    }
    
    NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
    NSString *errorDesc = nil;
    NSPropertyListFormat format;
    id result = [NSPropertyListSerialization
                                  propertyListFromData:plistXML
                                  mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                  format:&format
                                  errorDescription:&errorDesc];

    if (!result) {
        NSLog(@"Error reading plist: %@, format: %u", errorDesc, format);
    }

    return result;
}

- (NSArray *)fetchCampusNamesFromStorage
{
    NSArray *result = (NSArray *)[self fetchDataFromPlist:@"Campus"];
    return result;
}

- (NSDictionary *)fetchTimetableForAllRoutesFromStorage
{
    NSDictionary *result = (NSDictionary *)[self fetchDataFromPlist:@"Timetable"];
    return result;
}

@end
