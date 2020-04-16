//
//  LSIWeatherViewController.m
//
//  Created by Paul Solt on 2/6/20.
//  Copyright © 2020 Lambda, Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "LSIWeatherViewController.h"
#import "LSIWeatherIcons.h"
#import "LSIErrors.h"
#import "LSILog.h"
#import "LSIWeatherForecast.h"
#import "LSICurrentForecast.h"
#import "LSIWeatherIcons.h"
#import "LSISettingsTableVC.h"

@interface LSIWeatherViewController () {
    BOOL _requestedLocation;
}

// Properties

@property CLLocationManager *locationManager;
@property CLLocation *location;
@property (nonatomic) CLPlacemark *placemark;
@property (nonatomic) LSICurrentForecast *forecast;

// Outlets

@property (weak, nonatomic) IBOutlet UITableView *dailyForecastTableView;
@property (weak, nonatomic) IBOutlet UICollectionView *hourlyForecastCollectionView;


//Daily forecast outlets
@property (weak, nonatomic) IBOutlet UILabel *daylLabel;
@property (weak, nonatomic) IBOutlet UILabel *hiTempLabel;
@property (weak, nonatomic) IBOutlet UILabel *loTempLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *summaryLabel;
@property (weak, nonatomic) IBOutlet UILabel *tempLabel;

@end

// NOTE: You must declare the Category before the main implementation,
// otherwise you'll see errors about the type not being correct if you
// try to move delegate methods out of the main implementation body
@interface LSIWeatherViewController (CLLocationManagerDelegate) <CLLocationManagerDelegate>

@end

@implementation LSIWeatherViewController

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        _locationManager = [[CLLocationManager alloc] init];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _locationManager = [[CLLocationManager alloc] init];
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [self.dailyForecastTableView setDelegate:self];
//    [_dailyForecastTableView setDelegate:LSIWeatherViewController];
//    self.dailyForecastTableView.delegate = self;
//    self.hourlyForecastCollectionView.delegate = self;
//    self.locationManager.delegate = self;
    [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager startUpdatingLocation];
    
}


- (IBAction)settingsTapped:(UIBarButtonItem *)sender {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    
    LSISettingsTableVC *settingsVC = [storyboard instantiateViewControllerWithIdentifier:@"LSISettingsTableVC"];
    
    UINavigationController *navigationVC = [[UINavigationController alloc] initWithRootViewController:settingsVC];
    
    [self presentViewController:navigationVC animated:YES completion:nil];
    
}


//https://developer.apple.com/documentation/corelocation/converting_between_coordinates_and_user-friendly_place_names
- (void)requestCurrentPlacemarkForLocation:(CLLocation *)location
                            withCompletion:(void (^)(CLPlacemark *, NSError *))completionHandler {
    if (location) {
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
                
        [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
            if (error) {
                completionHandler(nil, error);
                return;
            }
            
            if (placemarks.count >= 1) {
                CLPlacemark *place = placemarks.firstObject;
                
                completionHandler(place, nil);
                return;
                
            } else {
                NSError *placeError = errorWithMessage(@"No places match current location", LSIPlaceError);
                
                completionHandler(nil, placeError);
                return;
            }
        }];
        
    } else {
        NSLog(@"ERROR: Missing location, please provide location");
    }
}

- (void)requestUserFriendlyLocation:(CLLocation *)location {
    if(!_requestedLocation) {
        _requestedLocation = YES;
        __block BOOL requestedLocation = _requestedLocation;
        
        [self requestCurrentPlacemarkForLocation:location withCompletion:^(CLPlacemark *place, NSError *error) {
            
            NSLog(@"Location: %@, %@", place.locality, place.administrativeArea);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.location = location;
                self.placemark = place;
                [self updateViews];
            });
            requestedLocation = NO;
        }];
    }
}

- (void)requestWeatherForLocation:(CLLocation *)location {
    
 NSURL *currentWeatherURL = [[NSBundle mainBundle] URLForResource:@"CurrentWeather" withExtension:@"json"];
 NSData *jsonData = [NSData dataWithContentsOfURL:currentWeatherURL];
 
 NSError *error = nil;
 NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
 
 self.forecast = [[LSICurrentForecast alloc] initWithDictionary:json];
 if (error) {
     NSLog(@"JSON Parsing Error: %@", error);
 }
    
}

- (void)updateViews {
    if (self.placemark) {
       self.locationLabel.text = [NSString stringWithFormat:@"%@, %@",
                               self.placemark.locality,
                               self.placemark.administrativeArea];
        self.summaryLabel.text = self.forecast.summary;
    }
    
    if (self.forecast) {
        
        NSLog(@"TEMP: %@", self.forecast);
        self.tempLabel.text = [NSString stringWithFormat: @"%0.0fºF", self.forecast.temperature];
        // Need to get day out of time
//        self.daylLabel.text = [NSString stringWithFormat:@"%@", self.forecast.time];
        self.hiTempLabel.text = [NSString stringWithFormat:@"%dºF", self.forecast.]
        
        @property (weak, nonatomic) IBOutlet UILabel *hiTempLabel;
        @property (weak, nonatomic) IBOutlet UILabel *loTempLabel;
        @property (weak, nonatomic) IBOutlet UILabel *locationLabel;
        @property (weak, nonatomic) IBOutlet UILabel *summaryLabel;
        @property (weak, nonatomic) IBOutlet UILabel *tempLabel;
        
    }
}

@end

/// MARK: CLLocationManagerDelegate Methods

@implementation LSIWeatherViewController(CLLocationManagerDelegate)

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"locationManager Error: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    NSLog(@"locationManager: found location %@", locations.firstObject);
    
    CLLocation *location = locations.firstObject;
    
    // 1. Request Weather for location
    
    [self requestWeatherForLocation: location];
    
    // 2. Request User-Friendly Place Names for Lat/Lon coordinate
    
    [self requestUserFriendlyLocation: location];
    
    // Stop updating location after getting one (NOTE: this is faster than doing a single location request)
    [manager stopUpdatingLocation];
}

@end
