//
//  HNTMob.m
//  HNTMob
//
//  Created by hainuo on 2021/4/25.
//

#import "HNTMob.h"
#import "TMob/GDTSplashAd.h"
#import "TMob/GDTSDKConfig.h"
#import "TMob/GDTSplashZoomOutView.h"
#import "TMob/GDTUnifiedNativeAd.h"
#import "UnifiedNativeAdCustomView.h"

@interface HNTMob ()<GDTSplashAdDelegate,GDTUnifiedNativeAdDelegate, GDTUnifiedNativeAdViewDelegate, GDTMediaViewDelegate>
//splashAd
@property (nonatomic, strong)  GDTSplashAd *splashAd;
@property (nonatomic,strong) NSString *splashAdType;
@property (nonatomic, strong) NSObject *splashAdObserver;
@property (nonatomic, strong) UIView *bottomView;

//unifiedNativeAd
@property (nonatomic, strong) GDTVideoConfig *videoConfig;
@property (nonatomic, strong) NSObject *uniFiedNativeAdObserver;
@property (nonatomic, strong) UIView *videoContainerView;
@property (nonatomic, strong) GDTUnifiedNativeAd *unifiedNativeAd;
@property (nonatomic, strong) UnifiedNativeAdCustomView *nativeAdCustomView;
@property (nonatomic, strong) GDTUnifiedNativeAdDataObject *dataObject;
@property (nonatomic, strong) UILabel *countdownLabel;
@property (nonatomic, strong) UIButton *skipButton;
@property (nonatomic, strong) NSTimer *timer;


@end

@implementation HNTMob
#pragma mark - Override UZEngine
+ (void)onAppLaunch:(NSDictionary *)launchOptions {
	// 方法在应用启动时被调用
	NSLog(@"HNTMob 被调用了");


}

- (id)initWithUZWebView:(UZWebView *)webView {
	if (self = [super initWithUZWebView:webView]) {
		// 初始化方法
		NSLog(@"HNTMobUZWebView  被调用了");
	}
	return self;
}

- (void)dispose {
	// 方法在模块销毁之前被调用
	NSLog(@"HNTMob  被销毁了");
    [self removeSplashNotification];
}
#pragma mark - HNTMOB INIT
JS_METHOD_SYNC(init:(UZModuleMethodContext *)context){

	NSDictionary *params = context.param;
	NSString *appId  = [params stringValueForKey:@"appId" defaultValue:nil];
	if(!appId) {
		return @{@"code":@0,@"msg":@"appId有误！"};
	}

	BOOL result = [GDTSDKConfig registerAppId:appId];
	NSMutableDictionary *ret=[NSMutableDictionary new];
	if (result) {
		NSLog(@"注册成功");
		[ret setValue:@1 forKey:@"code"];
		[ret setValue:@"appId注册成功" forKey:@"msg"];
		[ret setValue:[GDTSDKConfig sdkVersion] forKey:@"version"];
	}else{
		NSLog(@"注册失败");

		[ret setValue:@0 forKey:@"code"];
		[ret setValue:@"appId注册失败" forKey:@"msg"];
		[ret setValue:[GDTSDKConfig sdkVersion] forKey:@"version"];
	}
	return ret;
}

#pragma mark - HNTMob SplashAD
JS_METHOD(loadSplashAd:(UZModuleMethodContext *)context){
	self.splashAdType = @"loadSplashAd";
	NSDictionary *params = context.param;
	NSString *adId  = [params stringValueForKey:@"adId" defaultValue:nil];
	BOOL isFullAd = [params boolValueForKey:@"isFullAd" defaultValue:NO];
	self.splashAd = [[GDTSplashAd alloc] initWithPlacementId:adId];
	self.splashAd.delegate = self;
	self.splashAd.needZoomOut = NO;
	self.splashAd.fetchDelay = 3;

	if(isFullAd) {
		NSLog(@"加载全屏广告！");
		[self.splashAd loadFullScreenAd];
	}else{
		NSLog(@"加载普通广告！");
		[self.splashAd loadAd];
	}

	if(!self.splashAdObserver) {
		__weak typeof(self) _self = self;
		self.splashAdObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"loadSplashAdObserver" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
		                                 NSLog(@"接收到loadSplashAdObserver通知，%@",note.object);
		                                 __strong typeof(_self) self = _self;
		                                 if(!self) return;
		                                 [context callbackWithRet:note.object err:nil delete:NO];
					 }];
	}

	[context callbackWithRet:@{@"code":@1,@"splashAdType":self.splashAdType,@"eventType":@"doLoad",@"msg":@"广告加载命令执行成功"} err:nil delete:NO];
}
JS_METHOD_SYNC(showSplashAd:(UZModuleMethodContext *)context){
	if(!self.splashAd) {
		self.splashAdType = nil;
		[self removeSplashNotification];
		return @{@"code":@0,@"msg":@"处理失败"};
	}
	self.splashAdType = @"showSplashAd";
	NSDictionary *params = context.param;
	BOOL isFullAd = [params boolValueForKey:@"isFullAd" defaultValue:NO];

	NSString *logoPath = [params stringValueForKey:@"logoPath" defaultValue:nil];
	NSString *fullLogoPath = nil;
	if (logoPath) {
		fullLogoPath = [self getPathWithUZSchemeURL:logoPath];
	}
	UIWindow *window = [UIApplication sharedApplication].windows[0];
	if(fullLogoPath) {
		if(isFullAd) {
			[self.splashAd showFullScreenAdInWindow:window withLogoImage:[UIImage imageWithContentsOfFile:fullLogoPath] skipView:nil];
		}else{
			CGFloat logoHeight = [[UIScreen mainScreen] bounds].size.height * 0.25;
			self.bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, logoHeight)];
			self.bottomView.backgroundColor = [UIColor whiteColor];
			UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:fullLogoPath]];
			logo.accessibilityIdentifier = @"splash_logo";
			logo.frame = CGRectMake(0, 0, 311, 47);
			logo.center = self.bottomView.center;
			[self.bottomView addSubview:logo];
			[self.splashAd showAdInWindow:window withBottomView:self.bottomView skipView:nil];
		}
	}else{
		if(isFullAd) {

			[self.splashAd showFullScreenAdInWindow:window withLogoImage:nil skipView:nil];
		}else{
			[self.splashAd showAdInWindow:window withBottomView:nil skipView:nil];
		}
	}


	return @{@"code":@1,@"splashAdType":self.splashAdType,@"eventType":@"doShow",@"msg":@"开屏广告展示命令成功！"};
}
-(void) removeSplashNotification {
	if(self.splashAdObserver) {
		NSLog(@"移除通知监听");
		[[NSNotificationCenter defaultCenter] removeObserver:self.splashAdObserver name:@"loadSplashAdObserver" object:nil];
		self.splashAdObserver = nil;
	}
//	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"code":@1,@"splashAdType":self.splashAdType,@"eventType":@"doLoad",@"msg":@"广告加载命令执行成功"}];
}

#pragma mark - TMob SplashAD delegate
/**
 *  开屏广告成功展示
 */
- (void)splashAdSuccessPresentScreen:(GDTSplashAd *)splashAd {
	NSLog(@"开屏广告展示成功！");
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"code":@1,@"splashAdType":self.splashAdType,@"eventType":@"ispresented",@"msg":@"开屏广告展示成功！"}];
}

/**
 *  开屏广告素材加载成功
 */
- (void)splashAdDidLoad:(GDTSplashAd *)splashAd {
	NSLog(@"开屏广告素材加载成功！");
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"code":@1,@"splashAdType":self.splashAdType,@"eventType":@"adLoaded",@"msg":@"开屏广告素材加载成功！"}];
}

/**
 *  开屏广告展示失败
 */
- (void)splashAdFailToPresent:(GDTSplashAd *)splashAd withError:(NSError *)error {
	NSLog(@"开屏广告加载失败！%@ %@",error,splashAd);
	NSString *eventType = nil;
	NSString *msg = nil;
	if([self.splashAdType isEqualToString:@"loadSplashAd"]) {
		eventType = @"adLoadFailed";
		msg = @"开屏广告素材加载失败";
	}else{
		eventType = @"adShowFailed";
		msg = @"开屏广告素材显示失败";
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"code":@0,@"splashAdType":self.splashAdType,@"eventType":eventType,@"msg":msg}];
	[self removeSplashNotification];
	self.splashAdType = nil;
}

/**
 *  应用进入后台时回调
 *  详解: 当点击下载应用时会调用系统程序打开，应用切换到后台
 */
- (void)splashAdApplicationWillEnterBackground:(GDTSplashAd *)splashAd {
	NSLog(@"应用进入后台，开屏广告被点击下载了！");
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"code":@1,@"splashAdType":self.splashAdType,@"eventType":@"enterBackground",@"msg":@"应用进入后台"}];
}

/**
 *  开屏广告曝光回调
 */
- (void)splashAdExposured:(GDTSplashAd *)splashAd {
	NSLog(@"开屏广告曝光 被用户看到！");
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"code":@1,@"splashAdType":self.splashAdType,@"eventType":@"adShowed",@"msg":@"开屏广告曝光了"}];
}

/**
 *  开屏广告点击回调
 */
- (void)splashAdClicked:(GDTSplashAd *)splashAd {
	NSLog(@"开屏广告被点击了！");

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"code":@1,@"splashAdType":self.splashAdType,@"eventType":@"adClicked",@"msg":@"开屏广告被点击了"}];
}

/**
 *  开屏广告将要关闭回调
 */
- (void)splashAdWillClosed:(GDTSplashAd *)splashAd {
	NSLog(@"开屏广告即将关闭了！");
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"code":@1,@"splashAdType":self.splashAdType,@"eventType":@"adWillClose",@"msg":@"开屏广告即将关闭"}];

}

/**
 *  开屏广告关闭回调
 */
- (void)splashAdClosed:(GDTSplashAd *)splashAd {
	NSLog(@"开屏广告关闭了！");

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"code":@1,@"splashAdType":self.splashAdType,@"eventType":@"adClosed",@"msg":@"开屏广告关闭了"}];

	[self removeSplashNotification];
	self.splashAd = nil;
}

/**
 *  开屏广告点击以后即将弹出全屏广告页
 */
- (void)splashAdWillPresentFullScreenModal:(GDTSplashAd *)splashAd {
	NSLog(@"开屏广告 被点击了！ 即将打开全屏广告页面");
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"code":@1,@"splashAdType":self.splashAdType,@"eventType":@"adPageWillShow",@"msg":@"开屏广告 全屏广告页面即将被展示"}];
}

/**
 *  开屏广告点击以后弹出全屏广告页
 */
- (void)splashAdDidPresentFullScreenModal:(GDTSplashAd *)splashAd {

	NSLog(@"开屏广告 全屏广告页面被展示了");
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"code":@1,@"splashAdType":self.splashAdType,@"eventType":@"adPageShowed",@"msg":@"开屏广告 全屏广告页面展示了"}];
}

/**
 *  点击以后全屏广告页将要关闭
 */
- (void)splashAdWillDismissFullScreenModal:(GDTSplashAd *)splashAd {
	NSLog(@"开屏广告 全屏广告页面 即将关闭");
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"code":@1,@"splashAdType":self.splashAdType,@"eventType":@"adPageWillClosed",@"msg":@"开屏广告 全屏广告页面即将关闭"}];
}

/**
 *  点击以后全屏广告页已经关闭
 */
- (void)splashAdDidDismissFullScreenModal:(GDTSplashAd *)splashAd {
	NSLog(@"开屏广告 全屏广告页面关闭");
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"code":@1,@"splashAdType":self.splashAdType,@"eventType":@"adPageClosed",@"msg":@"开屏广告 全屏广告页面关闭"}];
}

/**
 * 开屏广告剩余时间回调
 */
- (void)splashAdLifeTime:(NSUInteger)time {
	NSLog(@"开屏广告 倒计时时间 %lu", (unsigned long)time);
	NSString *timeText = [NSString stringWithFormat:@"倒计时剩余%lu秒",time];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadSplashAdObserver" object:@{@"code":@1,@"splashAdType":self.splashAdType,@"eventType":@"countdown",@"time":[@(time) stringValue],@"msg":timeText}];
}

#pragma mark - 贴片广告 HNTMob unifiedNativeAd
JS_METHOD(showUnifiedNativeAd:(UZModuleMethodContext *)context){
	NSDictionary *params = context.param;
	NSString *adId  = [params stringValueForKey:@"adId" defaultValue:nil];
	NSString *fixedOn  = [params stringValueForKey:@"fixedOn" defaultValue:nil];
    NSDictionary *rect = [params dictValueForKey:@"rect" defaultValue:@{}];
    NSInteger minVideoDuration  = [params intValueForKey:@"minVideoDuration" defaultValue:(int)1];
    NSInteger maxVideoDuration  = [params intValueForKey:@"maxVideoDuration" defaultValue:(int)300];
	BOOL fixed = [params boolValueForKey:@"fixed" defaultValue:NO];

    float x = [rect floatValueForKey:@"x" defaultValue:0];
    float y = [rect floatValueForKey:@"y" defaultValue:0];
    float width = [rect floatValueForKey:@"width" defaultValue:[UIScreen mainScreen].bounds.size.width];
    float height = [rect floatValueForKey:@"height" defaultValue:width/16.0 * 9];
    
    NSLog(@"rect %@ %f %f %f %f",rect,x,y,width,height);
    
    
//    UIView *frameView= [[UIView alloc] initWithFrame:CGRectMake(x, y, width, height)];
//    frameView.backgroundColor  = [UIColor blueColor];
//    [self addSubview:frameView fixedOn:fixedOn fixed:fixed];
    
    self.videoConfig = [[GDTVideoConfig alloc] init];
    self.videoConfig.videoMuted = NO;
    self.videoConfig.autoPlayPolicy = GDTVideoAutoPlayPolicyAlways;
    self.videoConfig.userControlEnable = YES;
    self.videoConfig.autoResumeEnable = NO;
    self.videoConfig.detailPageEnable = NO;
    self.videoConfig.coverImageEnable = YES;
    self.videoConfig.progressViewEnable = NO;
    

    self.unifiedNativeAd = [[GDTUnifiedNativeAd alloc] initWithPlacementId:adId];
    self.unifiedNativeAd.delegate = self;
    self.unifiedNativeAd.minVideoDuration = minVideoDuration;
    self.unifiedNativeAd.maxVideoDuration = maxVideoDuration;

    [self.unifiedNativeAd setVastClassName:@"IMAGDT_VASTVideoAdAdapter"]; // 如果需要支持 VAST 广告，拉取广告前设置

    [self.unifiedNativeAd loadAdWithAdCount:1];
    
    [self addSubview:self.videoContainerView fixedOn:fixedOn fixed:fixed];
    // 播放器容器
//    self.videoContainerView.translatesAutoresizingMaskIntoConstraints = NO;
//    UIView *view = self.viewController.view;
//    [self.videoContainerView.leftAnchor constraintEqualToAnchor:view.leftAnchor].active = YES;
//    [self.videoContainerView.rightAnchor constraintEqualToAnchor:view.rightAnchor].active = YES;
//    [self.videoContainerView.topAnchor constraintEqualToAnchor:view.topAnchor].active = YES;
//    [self.videoContainerView.heightAnchor constraintEqualToAnchor:self.videoContainerView.widthAnchor multiplier:9/16.0].active = YES;
    [self view:self.videoContainerView addConstraintsWithRect:rect];
    
    [self.videoContainerView addSubview:self.nativeAdCustomView];
    // 贴片广告布局
    self.nativeAdCustomView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.nativeAdCustomView.leftAnchor constraintEqualToAnchor:self.videoContainerView.leftAnchor].active = YES;
    [self.nativeAdCustomView.rightAnchor constraintEqualToAnchor:self.videoContainerView.rightAnchor].active = YES;
    [self.nativeAdCustomView.topAnchor constraintEqualToAnchor:self.videoContainerView.topAnchor].active = YES;
    [self.nativeAdCustomView.bottomAnchor constraintEqualToAnchor:self.videoContainerView.bottomAnchor].active = YES;
    
    self.nativeAdCustomView.clickButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.nativeAdCustomView.clickButton.rightAnchor constraintEqualToAnchor:self.nativeAdCustomView.rightAnchor constant:-10].active = YES;
    [self.nativeAdCustomView.clickButton.bottomAnchor constraintEqualToAnchor:self.nativeAdCustomView.bottomAnchor constant:-10].active = YES;
    [self.nativeAdCustomView.clickButton.widthAnchor constraintEqualToConstant:80].active = YES;
    [self.nativeAdCustomView.clickButton.heightAnchor constraintEqualToConstant:44].active = YES;
    self.nativeAdCustomView.clickButton.backgroundColor = [UIColor orangeColor];

    self.countdownLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.nativeAdCustomView addSubview:self.countdownLabel];
    [self.countdownLabel.rightAnchor constraintEqualToAnchor:self.nativeAdCustomView.rightAnchor constant:-10].active = YES;
    [self.countdownLabel.topAnchor constraintEqualToAnchor:self.nativeAdCustomView.topAnchor constant:10].active = YES;
    [self.countdownLabel.widthAnchor constraintEqualToConstant:40].active = YES;
    [self.countdownLabel.heightAnchor constraintEqualToConstant:40].active = YES;

    self.skipButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.nativeAdCustomView addSubview:self.skipButton];
    [self.skipButton.rightAnchor constraintEqualToAnchor:self.countdownLabel.leftAnchor constant:-10].active = YES;
    [self.skipButton.topAnchor constraintEqualToAnchor:self.countdownLabel.topAnchor].active = YES;
    [self.skipButton.widthAnchor constraintEqualToConstant:60].active = YES;
    [self.skipButton.heightAnchor constraintEqualToConstant:40].active = YES;
    
    [self.nativeAdCustomView addSubview:self.nativeAdCustomView.logoView];
    self.nativeAdCustomView.logoView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.nativeAdCustomView.logoView.rightAnchor constraintEqualToAnchor:self.nativeAdCustomView.rightAnchor].active = YES;
    [self.nativeAdCustomView.logoView.bottomAnchor constraintEqualToAnchor:self.nativeAdCustomView.bottomAnchor].active = YES;
    [self.nativeAdCustomView.logoView.widthAnchor constraintEqualToConstant:kGDTLogoImageViewDefaultWidth].active = YES;
    [self.nativeAdCustomView.logoView.heightAnchor constraintEqualToConstant:kGDTLogoImageViewDefaultHeight].active = YES;
    
	if(!self.uniFiedNativeAdObserver) {
		__weak typeof(self) _self = self;
		self.uniFiedNativeAdObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"loadUnifiedNativeAd" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
		                                 NSLog(@"接收到loadUniFiedNativeAdObserver通知，%@",note.object);
		                                 __strong typeof(_self) self = _self;
		                                 if(!self) return;
		                                 [context callbackWithRet:note.object err:nil delete:NO];
					 }];
	}

	[context callbackWithRet:@{@"code":@1,@"unifiedNativeAd":@"loadUniFiedNativeAd",@"eventType":@"doLoad",@"msg":@"广告加载命令执行成功"} err:nil delete:NO];
}
- (void)clickSkip
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedNativeAd" object:@{@"code":@1,@"unifiedNativeAd":@"loadUniFiedNativeAd",@"eventType":@"adClickSkip",@"msg":@"贴片广告点击跳过"}];
    
    [self closeAd];
    
}
-(void) closeAd{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedNativeAd" object:@{@"code":@1,@"unifiedNativeAd":@"showUniFiedNativeAd",@"eventType":@"adClosed",@"msg":@"贴片广告关闭"}];
    [self.timer invalidate];
    self.timer = nil;
    [self.nativeAdCustomView removeFromSuperview];
    [self.nativeAdCustomView unregisterDataObject];
    
    [self.videoContainerView removeFromSuperview];
    
    _nativeAdCustomView = nil;
    _videoContainerView = nil;
    [self removeUnifiedNativeAdNotification];
}
- (void)reloadAd
{
    self.dataObject.videoConfig = self.videoConfig;
    self.nativeAdCustomView.viewController = self.viewController;
    
    [self.nativeAdCustomView registerDataObject:self.dataObject clickableViews:@[self.nativeAdCustomView.clickButton]];
    if (self.dataObject.isAppAd) {
        [self.nativeAdCustomView.clickButton setTitle:@"点击下载" forState:UIControlStateNormal];
    } else {
        [self.nativeAdCustomView.clickButton setTitle:@"查看详情" forState:UIControlStateNormal];
    }
    self.nativeAdCustomView.mediaView.delegate = self;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timeUpdate) userInfo:nil repeats:YES];
}

- (void)timeUpdate
{
    CGFloat playTime = [self.nativeAdCustomView.mediaView videoPlayTime];
    CGFloat duration = [self.nativeAdCustomView.mediaView videoDuration];
    if (duration > 0) {
        self.countdownLabel.hidden = NO;
    }
    if (playTime > 5000) {
        // 播放 5 秒展示跳过按钮
        self.skipButton.hidden = NO;
    }
    if (playTime < duration) {
        self.countdownLabel.text =  [NSString stringWithFormat:@"%@", @((NSInteger)(duration - playTime) / 1000)];
        NSLog(@"总时长：%@， 已播放：%@", @(duration), @(playTime));
    }
}
-(void)removeUnifiedNativeAdNotification{
    [self.timer invalidate];
    self.timer = nil;
    [self.nativeAdCustomView removeFromSuperview];
    [self.nativeAdCustomView unregisterDataObject];
    
    [self.videoContainerView removeFromSuperview];
    
    _nativeAdCustomView = nil;
    _videoContainerView = nil;
    if(self.uniFiedNativeAdObserver) {
        NSLog(@"移除通知监听");
        [[NSNotificationCenter defaultCenter] removeObserver:self.uniFiedNativeAdObserver name:@"loadUnifiedNativeAd" object:nil];
        self.uniFiedNativeAdObserver = nil;
    }
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedNativeAd" object:@{@"code":@1,@"unifiedNativeAd":@"loadUniFiedNativeAd",@"eventType":@"doLoad",@"msg":@"广告加载命令执行成功"}];
}
#pragma mark - 贴片广告  getter setter
- (UnifiedNativeAdCustomView *)nativeAdCustomView
{
	if (!_nativeAdCustomView) {
		_nativeAdCustomView = [[UnifiedNativeAdCustomView alloc] init];
		_nativeAdCustomView.delegate = self;
		_nativeAdCustomView.accessibilityIdentifier = @"nativeAdCustomView_id";
	}
	return _nativeAdCustomView;
}

- (UIView *)videoContainerView
{
	if (!_videoContainerView) {
		_videoContainerView = [[UIView alloc] init];
		_videoContainerView.backgroundColor = [UIColor grayColor];
		_videoContainerView.accessibilityIdentifier = @"videoContainerView_id";
	}
	return _videoContainerView;
}

- (UILabel *)countdownLabel
{
	if (!_countdownLabel) {
		_countdownLabel = [[UILabel alloc] init];
		_countdownLabel.hidden = YES;
		_countdownLabel.textColor = [UIColor redColor];
		_countdownLabel.backgroundColor = [UIColor blueColor];
		_countdownLabel.textAlignment = NSTextAlignmentCenter;
		_countdownLabel.accessibilityIdentifier = @"countdownLabel_id";
	}
	return _countdownLabel;
}

- (UIButton *)skipButton
{
	if (!_skipButton) {
		_skipButton = [[UIButton alloc] init];
		_skipButton.backgroundColor = [UIColor grayColor];
		_skipButton.hidden = YES;
		[_skipButton setTitle:@"跳过" forState:UIControlStateNormal];
		[_skipButton addTarget:self action:@selector(clickSkip) forControlEvents:UIControlEventTouchUpInside];
		_skipButton.accessibilityIdentifier = @"skipButton_id";
	}
	return _skipButton;
}

#pragma mark - GDTUnifiedNativeAdDelegate
- (void)gdt_unifiedNativeAdLoaded:(NSArray<GDTUnifiedNativeAdDataObject *> *)unifiedNativeAdDataObjects error:(NSError *)error
{
	if (!error && unifiedNativeAdDataObjects.count > 0) {
		NSLog(@"成功请求到广告数据");
		self.dataObject = unifiedNativeAdDataObjects[0];
		NSLog(@"eCPM:%ld eCPMLevel:%@", [self.dataObject eCPM], [self.dataObject eCPMLevel]);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedNativeAd" object:@{@"code":@1,@"unifiedNativeAdType":@"loadUnifiedNativeAd",@"eventType":@"doLoad",@"msg":@"广告加载命令执行成功"}];
		if (self.dataObject.isVideoAd) {
			[self reloadAd];
			return;
		} else if (self.dataObject.isVastAd) {
			[self reloadAd];
			return;
		}
	}

    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedNativeAd" object:@{@"code":@1,@"unifiedNativeAdType":@"loadUnifiedNativeAd",@"eventType":@"doLoad",@"msg":error.userInfo}];
	if (error.code == 5004) {
		NSLog(@"没匹配的广告，禁止重试，否则影响流量变现效果");
	} else if (error.code == 5005) {
		NSLog(@"流量控制导致没有广告，超过日限额，请明天再尝试");
	} else if (error.code == 5009) {
		NSLog(@"流量控制导致没有广告，超过小时限额");
	} else if (error.code == 5006) {
		NSLog(@"包名错误");
	} else if (error.code == 5010) {
		NSLog(@"广告样式校验失败");
	} else if (error.code == 3001) {
		NSLog(@"网络错误");
	} else if (error.code == 5013) {
		NSLog(@"请求太频繁，请稍后再试");
	} else if (error) {
		NSLog(@"ERROR: %@", error);
	}
    [self removeUnifiedNativeAdNotification];
}

#pragma mark - GDTMediaViewDelegate
- (void)gdt_mediaViewDidPlayFinished:(GDTMediaView *)mediaView
{
	NSLog(@"%s",__FUNCTION__);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedNativeAd" object:@{@"code":@1,@"unifiedNativeAd":@"showUniFiedNativeAd",@"eventType":@"adPlayFinished",@"msg":@"贴片广告视频播放结束"}];
	[self closeAd];
}

#pragma mark - GDTUnifiedNativeAdViewDelegate
- (void)gdt_unifiedNativeAdViewDidClick:(GDTUnifiedNativeAdView *)unifiedNativeAdView
{
	NSLog(@"%s",__FUNCTION__);
	NSLog(@"%@ 广告被点击", unifiedNativeAdView.dataObject);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedNativeAd" object:@{@"code":@1,@"unifiedNativeAd":@"showUniFiedNativeAd",@"eventType":@"adClicked",@"msg":@"贴片广告被点击了"}];
    
}

- (void)gdt_unifiedNativeAdViewWillExpose:(GDTUnifiedNativeAdView *)unifiedNativeAdView
{
	NSLog(@"%s",__FUNCTION__);
	NSLog(@"广告被曝光");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedNativeAd" object:@{@"code":@1,@"unifiedNativeAd":@"showUniFiedNativeAd",@"eventType":@"adShowed",@"msg":@"贴片广告曝光了"}];
}

- (void)gdt_unifiedNativeAdDetailViewClosed:(GDTUnifiedNativeAdView *)unifiedNativeAdView
{
	NSLog(@"%s",__FUNCTION__);
	NSLog(@"广告详情页已关闭");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedNativeAd" object:@{@"code":@1,@"unifiedNativeAd":@"showUniFiedNativeAd",@"eventType":@"adPageClosed",@"msg":@"贴片广告详情页关闭了"}];
}

- (void)gdt_unifiedNativeAdViewApplicationWillEnterBackground:(GDTUnifiedNativeAdView *)unifiedNativeAdView
{
	NSLog(@"%s",__FUNCTION__);
	NSLog(@"广告进入后台");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedNativeAd" object:@{@"code":@1,@"unifiedNativeAd":@"showUniFiedNativeAd",@"eventType":@"enterBackground",@"msg":@"贴片广告进入后台"}];
}

- (void)gdt_unifiedNativeAdDetailViewWillPresentScreen:(GDTUnifiedNativeAdView *)unifiedNativeAdView
{
	NSLog(@"%s",__FUNCTION__);
	NSLog(@"广告详情页面即将打开");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedNativeAd" object:@{@"code":@1,@"unifiedNativeAd":@"showUniFiedNativeAd",@"eventType":@"adPageShowed",@"msg":@"贴片广告详情页打开了"}];
}

- (void)gdt_unifiedNativeAdView:(GDTUnifiedNativeAdView *)unifiedNativeAdView playerStatusChanged:(GDTMediaPlayerStatus)status userInfo:(NSDictionary *)userInfo
{
 
	NSLog(@"%s",__FUNCTION__);
	NSLog(@"视频广告状态变更");
	switch (status) {
	case GDTMediaPlayerStatusInitial:
		NSLog(@"视频初始化");
		break;
	case GDTMediaPlayerStatusLoading:
		NSLog(@"视频加载中");
		break;
	case GDTMediaPlayerStatusStarted:
		NSLog(@"视频开始播放");
		break;
	case GDTMediaPlayerStatusPaused:
		NSLog(@"视频暂停");
		break;
	case GDTMediaPlayerStatusStoped:
		NSLog(@"视频停止");
		break;
	case GDTMediaPlayerStatusError:
		NSLog(@"视频播放出错");
	default:
		break;
	}
	if (userInfo) {
		long videoDuration = [userInfo[kGDTUnifiedNativeAdKeyVideoDuration] longValue];
		NSLog(@"视频广告长度为 %ld s", videoDuration);
	}
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedNativeAd" object:@{@"code":@1,@"unifiedNativeAd":@"showUniFiedNativeAd",@"eventType":@"videoStatusChange",@"msg":@"贴片广告 视频广告状态变更",@"userInfo":userInfo,@"status": @(status)}];
}

@end
