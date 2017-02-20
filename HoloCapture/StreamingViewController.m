//
//  StreamingViewController.m
//  HoloCapture
//
//  Created by Sumihiro Ueda on 2017/02/14.
//

#import "StreamingViewController.h"
#import "IJKMediaPlayer.h"
#import "IJKFFMoviePlayerController.h"
#import <SVProgressHUD.h>

NSString *StreamingSettingQualityKey = @"StreamingSettingQualityKey";
NSString *StreamingSettingHoloKey = @"StreamingSettingHoloKey";
NSString *StreamingSettingPVKey = @"StreamingSettingPVKey";
NSString *StreamingSettingMicKey = @"StreamingSettingMicKey";
NSString *StreamingSettingLoopbackKey = @"StreamingSettingLoopbackKey";

@interface StreamingViewController () <AVAssetDownloadDelegate>

@property (weak, nonatomic) IBOutlet UIView *moviePlaceholder;

@property (nonatomic,strong) id<IJKMediaPlayback> playback;

@property (readwrite) HoloDeviceClientStremQuality quality;
@property (readwrite) BOOL holo;
@property (readwrite) BOOL pv;
@property (readwrite) BOOL mic;
@property (readwrite) BOOL loopback;

@end

@implementation StreamingViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self loadDefaults];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self updateToolbar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO];
    
    [self play];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.playback) {
        [self.playback shutdown];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateToolbar {
    NSString *image;
    UIBarButtonItem *i1,*i2,*i3,*i4,*i5,*i6,*i7;
    
    i1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    switch (self.quality) {
        case HoloDeviceClientStremQualityHigh:
            image = @"quality_high";
            break;
        case HoloDeviceClientStremQualityNormal:
            image = @"quality_medium";
            break;
        case HoloDeviceClientStremQualityLow:
            image = @"quality_low";
            break;
            
        default:
            break;
    }
    i2 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:image] style:UIBarButtonItemStylePlain target:self action:@selector(pushquality:)];
    
    image = self.holo ? @"holo_on" : @"holo_off";
    i3 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:image] style:UIBarButtonItemStylePlain target:self action:@selector(pushHolo:)];
    
    image = self.pv ? @"pv_on" : @"pv_off";
    i4 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:image] style:UIBarButtonItemStylePlain target:self action:@selector(pushPV:)];
    
    image = self.mic ? @"mic_on" : @"mic_off";
    i5 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:image] style:UIBarButtonItemStylePlain target:self action:@selector(pushMic:)];
    
    image = self.loopback ? @"loopback_on" : @"loopback_off";
    i6 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:image] style:UIBarButtonItemStylePlain target:self action:@selector(pushLoopback:)];
    
    
    i7 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    NSArray *items = @[i1,i2,i3,i4,i5,i6,i7];
    [self setToolbarItems:items animated:YES];
}

- (void)loadDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:@{
                                 StreamingSettingQualityKey: @(HoloDeviceClientStremQualityNormal),
                                 StreamingSettingHoloKey: @(YES),
                                 StreamingSettingPVKey: @(YES),
                                 StreamingSettingMicKey: @(NO),
                                 StreamingSettingLoopbackKey: @(YES),
                                 }];
    self.quality = [defaults integerForKey:StreamingSettingQualityKey];
    self.holo = [defaults integerForKey:StreamingSettingHoloKey];
    self.pv = [defaults integerForKey:StreamingSettingPVKey];
    self.mic = [defaults integerForKey:StreamingSettingMicKey];
    self.loopback = [defaults integerForKey:StreamingSettingLoopbackKey];
}

- (void)saveDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:self.quality forKey:StreamingSettingQualityKey];
    [defaults setInteger:self.holo forKey:StreamingSettingHoloKey];
    [defaults setInteger:self.pv forKey:StreamingSettingPVKey];
    [defaults setInteger:self.mic forKey:StreamingSettingMicKey];
    [defaults setInteger:self.loopback forKey:StreamingSettingLoopbackKey];
    [defaults synchronize];
}

- (void)update:(NSString*)message {
    [self saveDefaults];
    [self showMessage:message];
    [self updateToolbar];
    [self play];
}

#pragma mark -

- (void)play {
    if (self.playback) {
        [self.playback.view removeFromSuperview];
        self.playback = nil;
    }
    NSURL *url = [self.client streamingURL:self.quality
                                      holo:self.holo
                                        pv:self.pv
                                       mic:self.mic
                                  loopback:self.loopback];
    
    IJKFFOptions *options = [IJKFFOptions optionsByDefault];
    id<IJKMediaPlayback> playback = [[IJKFFMoviePlayerController alloc] initWithContentURL:url  withOptions:options];
    self.playback = playback;
    
    playback.shouldAutoplay = YES;
    
    UIView *view = playback.view;
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.contentMode = UIViewContentModeScaleAspectFit;
    view.frame = self.moviePlaceholder.bounds;
    [self.moviePlaceholder addSubview:view];
    
    [playback prepareToPlay];
    [playback play];
}

#pragma mark -

- (IBAction)pushquality:(id)sender {
    NSString *qualityText;
    switch (self.quality) {
        case HoloDeviceClientStremQualityNormal:
            self.quality = HoloDeviceClientStremQualityLow;
            qualityText = @"Low";
            break;
        case HoloDeviceClientStremQualityLow:
            self.quality = HoloDeviceClientStremQualityHigh;
            qualityText = @"High";
            break;
        case HoloDeviceClientStremQualityHigh:
            self.quality = HoloDeviceClientStremQualityNormal;
            qualityText = @"Medium";
            break;
            
        default:
            break;
    }

    [self showMessage:[NSString stringWithFormat:@"Quality: %@",qualityText]];

    
    [self updateToolbar];
    [self play];
}

- (IBAction)pushHolo:(id)sender {
    self.holo = !self.holo;
    [self update:[NSString stringWithFormat:@"Holograms: %@",
                  self.holo ? @"ON" : @"OFF"]];
}

- (IBAction)pushPV:(id)sender {
    self.pv = !self.pv;
    [self update:[NSString stringWithFormat:@"PV camera: %@",
                  self.pv ? @"ON" : @"OFF"]];
}

- (IBAction)pushMic:(id)sender {
    self.mic = !self.mic;
    [self update:[NSString stringWithFormat:@"Mic Audio: %@",
                  self.mic ? @"ON" : @"OFF"]];
}

- (IBAction)pushLoopback:(id)sender {
    self.loopback = !self.loopback;
    [self update:[NSString stringWithFormat:@"Loopback Audio: %@",
                  self.loopback ? @"ON" : @"OFF"]];
}


#pragma mark -

- (IBAction)tapView:(id)sender {
    BOOL hidden = self.navigationController.toolbarHidden;
    hidden = !hidden;
    [self.navigationController setToolbarHidden:hidden animated:YES];
    [self.navigationController setNavigationBarHidden:hidden animated:YES];
}

#pragma mark -

- (void)showMessage:(NSString*)message {
    SVProgressHUDMaskType oldType = [SVProgressHUD new].defaultMaskType;
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];

    [SVProgressHUD dismiss];
    [SVProgressHUD showSuccessWithStatus:message];
    [SVProgressHUD dismissWithDelay:2.];
    
    [SVProgressHUD setDefaultMaskType:oldType];
}

@end
