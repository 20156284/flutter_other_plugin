#import "FlutterOtherPlugin.h"
#import "RBDMuteSwitch.h"
#import <AVFoundation/AVFoundation.h>

#ifdef COCOAPODS
@import CoreLocation;
#else
#import <CoreLocation/CoreLocation.h
#endif      

@interface FlutterOtherPlugin() <FlutterStreamHandler, CLLocationManagerDelegate,RBDMuteSwitchDelegate>{
    AVAudioPlayer *_audioPlayer;
}
@property (strong, nonatomic) CLLocationManager *clLocationManager;
@property (copy, nonatomic)   FlutterResult      flutterResult;
@property (assign, nonatomic) BOOL               locationWanted;

@property (copy, nonatomic)   FlutterEventSink   flutterEventSink;
@property (assign, nonatomic) BOOL               flutterListening;
@property (assign, nonatomic) BOOL               hasInit;
@property (strong, nonatomic) NSString           *filePath;
@end

@implementation FlutterOtherPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"flutter_other_plugin"
                                     binaryMessenger:[registrar messenger]];
    FlutterEventChannel *stream = [FlutterEventChannel eventChannelWithName:@"flutter_other_plugin/locationstream" binaryMessenger:registrar.messenger];
    
    FlutterOtherPlugin* instance = [[FlutterOtherPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    [stream setStreamHandler:instance];
}

-(instancetype)init {
    self = [super init];
    
    if (self) {
        self.locationWanted = NO;
        self.flutterListening = NO;
        self.hasInit = NO;
    }
    return self;
}

- (void)beginDetection {
    [[RBDMuteSwitch sharedInstance] setDelegate:self];
    [[RBDMuteSwitch sharedInstance] detectMuteSwitch];
}

#pragma mark RBDMuteSwitchDelegate methods
//这里处理回调即可
- (void)isMuted:(BOOL)muted {
    if (!muted) {
        NSLog(@"有铃声~");
        //初始化播放器对象
        _audioPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL URLWithString:self.filePath] error:nil];
        //设置声音的大小
        _audioPlayer.volume = 0.8;//范围为（0到1）；
        //设置循环次数，如果为负数，就是无限循环
        _audioPlayer.numberOfLoops =0;
        //设置播放进度
        _audioPlayer.currentTime = 0;
        //准备播放
        [_audioPlayer prepareToPlay];
        [_audioPlayer play];
    }
//    NSLog(@"静音哦~");
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);  //震动效果;
}

-(void)initLocation {
    if (!(self.hasInit)) {
        self.hasInit = YES;
        
        if ([CLLocationManager locationServicesEnabled]) {
            self.clLocationManager = [[CLLocationManager alloc] init];
            self.clLocationManager.delegate = self;
            if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"] != nil) {
                [self.clLocationManager requestWhenInUseAuthorization];
            }
            else if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysUsageDescription"] != nil) {
                [self.clLocationManager requestAlwaysAuthorization];
            }
            else {
                [NSException raise:NSInternalInconsistencyException format:@"To use location in iOS8 you need to define either NSLocationWhenInUseUsageDescription or NSLocationAlwaysUsageDescription in the app bundle's Info.plist file"];
            }
            
            self.clLocationManager.desiredAccuracy = kCLLocationAccuracyBest;
        }
    }
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"saveImageToGallery" isEqualToString:call.method]) {
        FlutterStandardTypedData *flutterData =call.arguments;
        if (flutterData.data.bytes > 0) {
            UIImage *image = [UIImage imageWithData:flutterData.data];
            UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
            self.flutterResult =result;
        }
    }
    else if ([call.method isEqualToString:@"getLocation"]) {
        [self initLocation];
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied && [CLLocationManager locationServicesEnabled])
        {
            // Location services are requested but user has denied
            result([FlutterError errorWithCode:@"PERMISSION_DENIED"
                                       message:@"The user explicitly denied the use of location services for this app or location services are currently disabled in Settings."
                                       details:nil]);
            return;
        }
        
        self.flutterResult = result;
        self.locationWanted = YES;
        [self.clLocationManager startUpdatingLocation];
    } else if ([call.method isEqualToString:@"hasPermission"]) {
        NSLog(@"Do has permissions");
        if ([CLLocationManager locationServicesEnabled]) {
            
            if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied)
            {
                // Location services are requested but user has denied
                result(@(0));
            } else {
                // Location services are available
                result(@(1));
            }
            
            
        } else {
            // Location is not yet available
            result(@(0));
        }
        //
    }
    else if ([call.method isEqualToString:@"playBell"]) {
        self.filePath =call.arguments;
        [self beginDetection];
//        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
//        return;
        self.flutterResult =result;
    }else {
        result(FlutterMethodNotImplemented);
    }
}

-(void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSString *msg = nil ;
    if(error){
        msg = @"保存图片失败" ;
        self.flutterResult([NSNumber numberWithBool:NO]);
    }else{
        msg = @"保存图片成功" ;
        self.flutterResult([NSNumber numberWithBool:YES]);
    }
    NSLog(@"%@",msg);
}

-(FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events {
    self.flutterEventSink = events;
    self.flutterListening = YES;
    [self.clLocationManager startUpdatingLocation];
    return nil;
}

-(FlutterError*)onCancelWithArguments:(id)arguments {
    self.flutterListening = NO;
    return nil;
}

-(void)locationManager:(CLLocationManager*)manager didUpdateLocations:(NSArray<CLLocation*>*)locations {
    CLLocation *location = locations.firstObject;
    NSDictionary<NSString*,NSNumber*>* coordinatesDict = @{
                                                           @"latitude": @(location.coordinate.latitude),
                                                           @"longitude": @(location.coordinate.longitude),
                                                           @"accuracy": @(location.horizontalAccuracy),
                                                           @"altitude": @(location.altitude),
                                                           @"speed": @(location.speed),
                                                           @"speed_accuracy": @(0.0),
                                                           @"heading": @(location.course),
                                                           };
    
    if (self.locationWanted) {
        self.locationWanted = NO;
        self.flutterResult(coordinatesDict);
    }
    if (self.flutterListening) {
        self.flutterEventSink(coordinatesDict);
    } else {
        [self.clLocationManager stopUpdatingLocation];
    }
}

@end
