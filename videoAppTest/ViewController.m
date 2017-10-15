//
//  ViewController.m
//  videoAppTest
//
//  Created by Ervina's MacBook on 10/13/17.
//  Copyright © 2017 HackXagonal. All rights reserved.
//

#import "ViewController.h"
#import "VKVideoPlayerViewController.h"
#import "VKVideoPlayer.h"

#import<AssetsLibrary/AssetsLibrary.h>
#import<AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreMedia/CoreMedia.h>
#import <MediaPlayer/MediaPlayer.h>

@interface ViewController () <VKVideoPlayerDelegate,VKControlDelegate>
{
    int numberOfCurrentVideo;
}

@property (nonatomic,retain) VKVideoPlayer *player;
@property (nonatomic,retain) NSArray *trackList;

@property (nonatomic,retain) UIButton *nextButton;
@property (nonatomic,retain) UIButton *previousButton;
@property (nonatomic,retain) UIButton *screenshotButton;

@property (nonatomic,retain) UIImageView *tvLogo;

@property (nonatomic,retain) VKVideoPlayer *adsPlayer;

@property (nonatomic) BOOL isShowAds;

@property (nonatomic,retain) NSURL *currentTrackURL;
@property (nonatomic) float currentTrackTime;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationController.navigationBarHidden = YES;
    [self initializePlayer];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(orientationChanged:)    name:UIDeviceOrientationDidChangeNotification  object:nil];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (void)initializePlayer{
    self.player = [[VKVideoPlayer alloc] init];
    self.player.delegate = self;
    self.player.view.controlDelegate = self;
    self.player.view.frame = self.view.bounds;
    self.player.view.playerControlsAutoHideTime = @5;
    self.player.forceRotate = YES;
    self.player.view.topPortraitCloseButton.hidden = YES;
    self.player.view.rewindButton.hidden = YES;
    self.player.view.doneButton.hidden = YES;
    self.player.view.videoQualityButton.hidden = YES;
    [self.player.view.videoQualityButton setTitle:@"" forState:UIControlStateNormal];
    [self.view addSubview:self.player.view];
    
    [self createTrackControl];
    
    [self createTrackList];
    [self checkAvailabilityTrack];
    
    if (_trackList.count > 0) {
        numberOfCurrentVideo = 0;
        _isShowAds = YES;
        [self playStreamWIthPlayer:self.player withURL:[_trackList firstObject]];
    }
    
    [self setupImageOnTrack];
}

- (void)createTrackList{
    NSString *video1Path = [[NSBundle mainBundle] pathForResource:@"video1" ofType:@"mp4"];
    NSURL *urlvideo1 = [NSURL fileURLWithPath:video1Path];
    
    NSString *video2Path = [[NSBundle mainBundle] pathForResource:@"video2" ofType:@"mp4"];
    NSURL *urlvideo2 = [NSURL fileURLWithPath:video2Path];
    
    _trackList = @[urlvideo1,urlvideo2];
}

- (void)playStreamWIthPlayer:(VKVideoPlayer*)player withURL:(NSURL*)url {
    VKVideoPlayerTrack *track = [[VKVideoPlayerTrack alloc] initWithStreamURL:url];
    [player loadVideoWithTrack:track];
}

- (void)checkAvailabilityTrack{
    if (_trackList.count == 1) {
        _nextButton.hidden = YES;
        _previousButton.hidden = YES;
        return;
    }
    
    if ([self isLastTrack]) {
        _nextButton.hidden = YES;
        _previousButton.hidden = NO;
    }
    else if ([self isFirstTrack]){
        _nextButton.hidden = NO;
        _previousButton.hidden = YES;
    }
    else{
        _nextButton.hidden = NO;
        _previousButton.hidden = NO;
    }
}

- (BOOL)isLastTrack{
    if (numberOfCurrentVideo == _trackList.count-1) {
        return YES;
    }
    else{
        return NO;
    }
}

- (BOOL)isFirstTrack{
    if (numberOfCurrentVideo == 0) {
        return YES;
    }
    else{
        return NO;
    }
}

- (void)createTrackControl {
    _screenshotButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_screenshotButton setBackgroundImage:[UIImage imageNamed:@"camera-icon"] forState:UIControlStateNormal];
    [_screenshotButton addTarget:self action:@selector(screenshotFunction) forControlEvents:UIControlEventTouchUpInside];
    
    _nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_nextButton setBackgroundImage:[UIImage imageNamed:@"next-button"] forState:UIControlStateNormal];
    [_nextButton addTarget:self action:@selector(playNextVideo) forControlEvents:UIControlEventTouchUpInside];
    
    _previousButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_previousButton setBackgroundImage:[UIImage imageNamed:@"previous-button"] forState:UIControlStateNormal];
    [_previousButton addTarget:self action:@selector(playPreviousVideo) forControlEvents:UIControlEventTouchUpInside];
    
    [self setTrackControlFrameWithOrientation:UIInterfaceOrientationUnknown];
    [self addTrackControl];
}

- (void)setTrackControlFrameWithOrientation:(UIInterfaceOrientation)orientation{
    CGRect containerFrame = self.player.view.topControlOverlay.frame;
    
    float buttonSize = containerFrame.size.height/2;
    float buttonPadding = 10;
    float middlePosition = (containerFrame.size.height/2) - (buttonSize/2);
    
    _nextButton.frame = CGRectMake(containerFrame.size.width-buttonPadding-buttonSize,middlePosition,buttonSize,buttonSize);
    
    _previousButton.frame = CGRectMake(buttonPadding,middlePosition,buttonSize,buttonSize);
    
    _screenshotButton.frame = CGRectMake((containerFrame.size.width/2)-(buttonSize/2), middlePosition, buttonSize, buttonSize);
}

- (void)addTrackControl{
    [self.player.view addSubviewForControl:_nextButton];
    [self.player.view addSubviewForControl:_previousButton];
    [self.player.view addSubviewForControl:_screenshotButton];
}

#pragma mark - VKVideoPlayerControllerDelegate
- (void)videoPlayer:(VKVideoPlayer*)videoPlayer didPlayToEnd:(id<VKVideoPlayerTrackProtocol>)track{
        if (videoPlayer == self.adsPlayer) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                _isShowAds = NO;
                [self.view bringSubviewToFront:self.player.view];
                [self.player playContent];
            });
        }
}

- (void)videoPlayer:(VKVideoPlayer*)videoPlayer didPlayFrame:(id<VKVideoPlayerTrackProtocol>)track time:(NSTimeInterval)time lastTime:(NSTimeInterval)lastTime{
    if (_isShowAds) {
        if (videoPlayer == self.player) {
            if (time > 30) {
                [videoPlayer pauseContentWithCompletionHandler:^{
                    _currentTrackTime = time;
                    _currentTrackURL = videoPlayer.streamURL;
                    [self initializeAdsPlayer];
                }];
                
            }
        }
    }
}

- (void)videoPlayer:(VKVideoPlayer*)videoPlayer didChangeStateFrom:(VKVideoPlayerState)fromState{
    NSLog(@"%@ %u",videoPlayer,fromState);
}

- (void)videoPlayer:(VKVideoPlayer*)videoPlayer didControlByEvent:(VKVideoPlayerControlEvent)event {
    NSLog(@"%s event:%d", __FUNCTION__, event);
    
    if (event == VKVideoPlayerControlEventTapPlayerView) {
        _tvLogo.hidden = NO;
    }
    
    if (event == VKVideoPlayerControlEventTapNext) {
        [self playNextVideo];
    }
    
    if (event == VKVideoPlayerControlEventTapPrevious) {
        [self playPreviousVideo];
    }
}

- (void)playNextVideo{
    if (numberOfCurrentVideo+1 == _trackList.count) {
        numberOfCurrentVideo = 0;
    }
    else{
        numberOfCurrentVideo+=1;
    }
    
    _isShowAds = YES;
    [self playStreamWIthPlayer:self.player withURL:[_trackList objectAtIndex:numberOfCurrentVideo]];
    [self checkAvailabilityTrack];
}

- (void)playPreviousVideo{
    if (numberOfCurrentVideo-1 < 0) {
        numberOfCurrentVideo = _trackList.count-1;
    }
    else{
        numberOfCurrentVideo-=1;
    }
    
    _isShowAds = YES;
    [self playStreamWIthPlayer:self.player withURL:[_trackList objectAtIndex:numberOfCurrentVideo]];
    [self checkAvailabilityTrack];
}

- (void)orientationChanged:(NSNotification *)notification{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    [UIView animateWithDuration:0.2 animations:^{
        [self setTrackControlFrameWithOrientation:orientation];
    }];
    
    if (self.player.view.isControlsHidden) {
        [UIView animateWithDuration:0.1 animations:^{
            [self logoImageFrame];
        }];
    }
    else{
        [UIView animateWithDuration:0.1 animations:^{
            [self logoImageFrameWhenControlVisible];
        }];
    }
}

#pragma mark - Logo on Track
- (void)setupImageOnTrack{
    _tvLogo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tv-logo"]];
    _tvLogo.alpha = 0.6 ;
    
    [self logoImageFrameWhenControlVisible];
    [self showLogo];
}

- (void)logoImageFrame{
    float logoSize = 50;
    _tvLogo.frame = CGRectMake(self.player.view.topControlOverlay.frame.size.width-logoSize, 0, logoSize, logoSize);
}

- (void)logoImageFrameWhenControlVisible{
    float logoSize = 50;
    _tvLogo.frame = CGRectMake(self.player.view.topControlOverlay.frame.size.width-logoSize, self.player.view.topControlOverlay.frame.size.height, logoSize, logoSize);
}

- (void)showLogo{
    [self.player.view addSubview:_tvLogo];
}

#pragma mark - VKControlDelegate
- (void)controlHiddenState:(BOOL)isHidden{
    if(isHidden){
        [UIView animateWithDuration:0.1 animations:^{
            [self logoImageFrame];
        }];
    }
    else{
        [UIView animateWithDuration:0.1 animations:^{
            [self logoImageFrameWhenControlVisible];
        }];
    }
    _tvLogo.hidden = NO;
}


#pragma mark - Ads setup
- (void)initializeAdsPlayer{
    self.adsPlayer = [[VKVideoPlayer alloc] init];
    self.adsPlayer.delegate = self;
    self.adsPlayer.view.frame = self.view.bounds;
    self.adsPlayer.forceRotate = YES;
    self.adsPlayer.view.topPortraitCloseButton.hidden = YES;
    self.adsPlayer.view.rewindButton.hidden = YES;
    self.adsPlayer.view.doneButton.hidden = YES;
    self.adsPlayer.view.videoQualityButton.hidden = YES;
    [self.adsPlayer.view.videoQualityButton setTitle:@"" forState:UIControlStateNormal];
    self.adsPlayer.view.scrubber.userInteractionEnabled = NO;
    [self.view addSubview:self.adsPlayer.view];
    
    NSString *video3Path = [[NSBundle mainBundle] pathForResource:@"video3" ofType:@"mp4"];
    NSURL *urlvideo3 = [NSURL fileURLWithPath:video3Path];
    
    [self playStreamWIthPlayer:self.adsPlayer withURL:urlvideo3];
    [self addAdsLabel];
}

- (void)addAdsLabel{
    UILabel *adsLabel = [[UILabel alloc] init];
    adsLabel.text = @"THIS IS ADS";
    adsLabel.frame = self.view.frame;
    adsLabel.alpha = 0.6;
    adsLabel.textAlignment = NSTextAlignmentCenter;
    [self.adsPlayer.view addSubview:adsLabel];
}

#pragma mark - Screenshot
- (void)screenshotFunction{
    UIImage *image = [self extractFirstFrameFromFilepath:[_trackList objectAtIndex:numberOfCurrentVideo] atTime:_player.currentTime];
    if (image == nil) {
        [self createPopupWIthTitle:@"Oops..." withMessage:@"Failed to get screenshot"];
    }
    else{
        UIImageWriteToSavedPhotosAlbum(image,self,@selector(image:didFinishSavingWithError:contextInfo:),nil);
    }
    
}

- (UIImage *)extractFirstFrameFromFilepath:(NSURL *)filepath atTime:(NSTimeInterval)time
{
    AVURLAsset *movieAsset = [[AVURLAsset alloc] initWithURL:filepath options:nil];
    AVAssetImageGenerator *assetImageGemerator = [[AVAssetImageGenerator alloc] initWithAsset:movieAsset];
    assetImageGemerator.appliesPreferredTrackTransform = YES;
    CGImageRef frameRef = [assetImageGemerator copyCGImageAtTime:CMTimeMake(time, 1) actualTime:nil error:nil];
    return [[UIImage alloc] initWithCGImage:frameRef];
}

- (void)createPopupWIthTitle:(NSString *)title withMessage:(NSString *)message{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
     message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        
    }];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:^{
        
    }];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error) {
        [self createPopupWIthTitle:@"Error" withMessage:@"Unable to save image to Photo Album."];
    }else {
        [self createPopupWIthTitle:@"Yaayy!!" withMessage:@"Screenshot saved to your gallery."];
    }
}
@end

