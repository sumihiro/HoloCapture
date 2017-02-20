//
//  LibararyItemViewController.m
//  HoloCapture
//
//  Created by 上田 澄博 on 2017/02/20.
//  Copyright © 2017年 Sumihiro Ueda. All rights reserved.
//

#import "LibararyItemViewController.h"
#import "IJKMediaPlayer.h"
#import "IJKFFMoviePlayerController.h"
#import <SDWebImageManager.h>
#import <UIImageView+WebCache.h>
#import <SVProgressHUD.h>

@interface LibararyItemViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *moviePlaceholder;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *pauseButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *playItemButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *fixedSpaceButton;

@property (nonatomic,strong) UIBarButtonItem *playButtonBackup;
@property (nonatomic,strong) UIBarButtonItem *deleteButtonBackup;
@property (nonatomic,strong) UIBarButtonItem *fixedSpaceButtonBackup;

@property (nonatomic,strong) id<IJKMediaPlayback> playback;
@property (nonatomic,readwrite) IJKMPMoviePlaybackState lastPlaybackState;
@property (nonnull,strong) NSTimer *playbackMonitor;

@end

@implementation LibararyItemViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.playButtonBackup = self.playItemButton;
    self.deleteButtonBackup = self.deleteButton;
    self.fixedSpaceButtonBackup = self.fixedSpaceButton;
    [self updateToolbar];
    [self updateViews];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setToolbarHidden:NO];
    [self reload];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateViews {
    if (self.reording.mediaType == HoloMrcRecordingMediaTypePhoto) {
        self.playButton.hidden = YES;
    } else {
        self.playButton.hidden = NO;
    }
}

- (void)updateToolbar {
    UIBarButtonItem *sp1,*sp2;
    
    sp1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    sp2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    if (self.reording.mediaType == HoloMrcRecordingMediaTypePhoto) {
        NSArray *items = @[sp1,self.deleteButtonBackup,sp2];
        [self setToolbarItems:items animated:YES];
    } else {
        NSArray *items = @[sp1,self.playButtonBackup,self.fixedSpaceButtonBackup,self.deleteButtonBackup,sp2];
        [self setToolbarItems:items animated:YES];
    }
}

#pragma mark -

- (void)reload {
    if (self.reording.mediaType == HoloMrcRecordingMediaTypePhoto) {
        [self.imageView sd_setImageWithURL:[self.client mrcFileURL:self.reording]
                        placeholderImage:nil
                                 options:SDWebImageAllowInvalidSSLCertificates
         ];
        self.playButton.hidden = YES;
    } else {
        [self.imageView sd_setImageWithURL:[self.client mrcThumbnailURL:self.reording]
                          placeholderImage:nil
                                   options:SDWebImageAllowInvalidSSLCertificates
         ];
        self.playButton.hidden = NO;
    }
}

- (void)play {
    if (self.playback) {
        [self.playback.view removeFromSuperview];
        self.playback = nil;
    }
    NSURL *url = [self.client mrcFileURL:self.reording];
    
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
    
    self.playButton.hidden = YES;
    self.pauseButton.hidden = YES;
    self.moviePlaceholder.hidden = NO;
}

- (void)pause {
    if (self.playback) {
        if (self.playback.playbackState == IJKMPMoviePlaybackStatePlaying) {
            [self.playback pause];
            self.pauseButton.hidden = NO;
        } else if (self.playback.playbackState == IJKMPMoviePlaybackStatePaused) {
            [self.playback play];
            self.pauseButton.hidden = YES;
        } else if (self.playback.playbackState == IJKMPMoviePlaybackStateStopped) {
            self.playback.currentPlaybackTime = 0.;
            [self.playback play];
            self.pauseButton.hidden = YES;
        }
    }
}

- (void)confirmToDelete {
    UIAlertController *vc = [UIAlertController alertControllerWithTitle:@"Delete" message:@"Do you really want to delete this? This operation can not be undone." preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *delete = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [SVProgressHUD showWithStatus:@"deleting"];
        [self.client mrcDelete:self.reording success:^{
            [SVProgressHUD showSuccessWithStatus:nil];
            [self.navigationController popViewControllerAnimated:YES];
        } failure:^(NSError *error) {
            [SVProgressHUD showErrorWithStatus:error.localizedDescription];
        }];
    }];
    [vc addAction:delete];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    [vc addAction:cancel];
    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark -


- (IBAction)tapView:(id)sender {
//    BOOL hidden = self.navigationController.toolbarHidden;
//    hidden = !hidden;
//    [self.navigationController setToolbarHidden:hidden animated:YES];
//    [self.navigationController setNavigationBarHidden:hidden animated:YES];
}

- (IBAction)tapMovie:(id)sender {
    [self pause];
}

- (IBAction)pushPause:(id)sender {
    [self pause];
}

- (IBAction)pushPlay:(id)sender {
    [self play];
}

- (IBAction)pushDelete:(id)sender {
    [self confirmToDelete];
}

@end
