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
#import "TMob/GDTUnifiedInterstitialAd.h"
#import "TMob/GDTUnifiedBannerView.h"
#import "TMob/GDTNativeExpressAd.h"
#import "TMob/GDTNativeExpressAdView.h"
#import <objc/runtime.h>

@interface GDTNativeExpressAdView (HNTMob)
@property (nonatomic, assign) NSString *adId;
@end

@implementation GDTNativeExpressAdView (HNTMob)
static void *nl_sqlite_adId_key = &nl_sqlite_adId_key;
- (void)setAdId:(NSString *)adId {
	objc_setAssociatedObject(self, nl_sqlite_adId_key, adId, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)adId {
	return [objc_getAssociatedObject(self,nl_sqlite_adId_key) stringValue];
}
@end


@interface HNTMob ()<GDTSplashAdDelegate,GDTUnifiedNativeAdDelegate, GDTUnifiedNativeAdViewDelegate, GDTMediaViewDelegate, GDTUnifiedInterstitialAdDelegate,GDTUnifiedBannerViewDelegate,GDTNativeExpressAdDelegete>
//splashAd 开屏
@property (nonatomic, strong)  GDTSplashAd *splashAd;
@property (nonatomic,strong) NSString *splashAdType;
@property (nonatomic, strong) NSObject *splashAdObserver;
@property (nonatomic, strong) UIView *bottomView;

//unifiedNativeAd 贴片
@property (nonatomic, strong) GDTVideoConfig *videoConfig;
@property (nonatomic, strong) NSObject *uniFiedNativeAdObserver;
@property (nonatomic, strong) UIView *videoContainerView;
@property (nonatomic, strong) GDTUnifiedNativeAd *unifiedNativeAd;
@property (nonatomic, strong) UnifiedNativeAdCustomView *nativeAdCustomView;
@property (nonatomic, strong) GDTUnifiedNativeAdDataObject *dataObject;
@property (nonatomic, strong) UILabel *countdownLabel;
@property (nonatomic, strong) UIButton *skipButton;
@property (nonatomic, strong) NSTimer *timer;

//UnifiedIterstitialAd //插屏2.0
@property (nonatomic, strong) GDTUnifiedInterstitialAd *interstitialAd;
@property (nonatomic, strong) NSObject *unifiedInterstitialAdObserver;

//banner
@property (nonatomic, strong) GDTUnifiedBannerView *bannerView;
@property (nonatomic, strong) NSObject *unifiedBannerViewObserver;

//nativeExpress  模版1.0
@property (nonatomic, strong) GDTNativeExpressAd *nativeExpressAd;
@property (nonatomic, strong) NSObject *nativeExpressAdObserver;
@property (nonatomic, strong) GDTNativeExpressAdView *expressView;


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
	[self removeNativeExpressAdObserver];
	[self removeNativeExpressAdObserver];
	[self removeUnifiedNativeAdNotification];
	[self removeUnifiedBannerViewObserver];
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

	NSOperationQueue *waitQueue = [[NSOperationQueue alloc] init];
	[waitQueue addOperationWithBlock:^{
	         // 同步到主线程
	         dispatch_async(dispatch_get_main_queue(), ^{

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
				});
	 }];


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

	[context callbackWithRet:@{@"code":@1,@"unifiedNativeAdType":@"loadUniFiedNativeAd",@"eventType":@"doLoad",@"msg":@"广告加载命令执行成功"} err:nil delete:NO];
}
- (void)clickSkip
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedNativeAd" object:@{@"code":@1,@"unifiedNativeAdType":@"loadUniFiedNativeAd",@"eventType":@"adClickSkip",@"msg":@"贴片广告点击跳过"}];

	[self closeAd];

}
-(void) closeAd {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedNativeAd" object:@{@"code":@1,@"unifiedNativeAdType":@"showUniFiedNativeAd",@"eventType":@"adClosed",@"msg":@"贴片广告关闭"}];
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
-(void)removeUnifiedNativeAdNotification {
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
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedNativeAd" object:@{@"code":@1,@"unifiedNativeAdType":@"loadUniFiedNativeAd",@"eventType":@"doLoad",@"msg":@"广告加载命令执行成功"}];
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

#pragma mark - 信息流广告自渲染 GDTUnifiedNativeAdDelegate
- (void)gdt_unifiedNativeAdLoaded:(NSArray<GDTUnifiedNativeAdDataObject *> *)unifiedNativeAdDataObjects error:(NSError *)error
{
	if (!error && unifiedNativeAdDataObjects.count > 0) {
		NSLog(@"成功请求到广告数据");
		self.dataObject = unifiedNativeAdDataObjects[0];
		NSLog(@"eCPM:%ld eCPMLevel:%@", [self.dataObject eCPM], [self.dataObject eCPMLevel]);
		[[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedNativeAd" object:@{@"code":@1,@"unifiedNativeAdType":@"loadUnifiedNativeAd",@"eventType":@"adLoaded",@"msg":@"信息流广告加载成功"}];
		if (self.dataObject.isVideoAd) {
			[self reloadAd];
			return;
		} else if (self.dataObject.isVastAd) {
			[self reloadAd];
			return;
		}
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedNativeAd" object:@{@"code":@1,@"unifiedNativeAdType":@"loadUnifiedNativeAd",@"eventType":@"adLoadFailed",@"msg":error.userInfo}];
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

#pragma mark - 信息流广告自渲染 GDTMediaViewDelegate
- (void)gdt_mediaViewDidPlayFinished:(GDTMediaView *)mediaView
{
	NSLog(@"%s",__FUNCTION__);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedNativeAd" object:@{@"code":@1,@"unifiedNativeAdType":@"showUniFiedNativeAd",@"eventType":@"adPlayFinished",@"msg":@"信息流广告视频播放结束"}];
	[self closeAd];
}

#pragma mark - 信息流广告自渲染 GDTUnifiedNativeAdViewDelegate
- (void)gdt_unifiedNativeAdViewDidClick:(GDTUnifiedNativeAdView *)unifiedNativeAdView
{
	NSLog(@"%s",__FUNCTION__);
	NSLog(@"%@ 广告被点击", unifiedNativeAdView.dataObject);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedNativeAd" object:@{@"code":@1,@"unifiedNativeAdType":@"showUniFiedNativeAd",@"eventType":@"adClicked",@"msg":@"贴片广告被点击了"}];

}

- (void)gdt_unifiedNativeAdViewWillExpose:(GDTUnifiedNativeAdView *)unifiedNativeAdView
{
	NSLog(@"%s",__FUNCTION__);
	NSLog(@"广告被曝光");
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedNativeAd" object:@{@"code":@1,@"unifiedNativeAdType":@"showUniFiedNativeAd",@"eventType":@"adShowed",@"msg":@"贴片广告曝光了"}];
}

- (void)gdt_unifiedNativeAdDetailViewClosed:(GDTUnifiedNativeAdView *)unifiedNativeAdView
{
	NSLog(@"%s",__FUNCTION__);
	NSLog(@"广告详情页已关闭");
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedNativeAd" object:@{@"code":@1,@"unifiedNativeAdType":@"showUniFiedNativeAd",@"eventType":@"adPageClosed",@"msg":@"贴片广告详情页关闭了"}];
}

- (void)gdt_unifiedNativeAdViewApplicationWillEnterBackground:(GDTUnifiedNativeAdView *)unifiedNativeAdView
{
	NSLog(@"%s",__FUNCTION__);
	NSLog(@"广告进入后台");
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedNativeAd" object:@{@"code":@1,@"unifiedNativeAdType":@"showUniFiedNativeAd",@"eventType":@"enterBackground",@"msg":@"贴片广告进入后台"}];
}

- (void)gdt_unifiedNativeAdDetailViewWillPresentScreen:(GDTUnifiedNativeAdView *)unifiedNativeAdView
{
	NSLog(@"%s",__FUNCTION__);
	NSLog(@"广告详情页面即将打开");
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedNativeAd" object:@{@"code":@1,@"unifiedNativeAdType":@"showUniFiedNativeAd",@"eventType":@"adPageShowed",@"msg":@"贴片广告详情页打开了"}];
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

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedNativeAd" object:@{@"code":@1,@"unifiedNativeAdType":@"showUniFiedNativeAd",@"eventType":@"videoStatusChange",@"msg":@"信息流广告 视频广告状态变更",@"userInfo":userInfo,@"status": @(status)}];
}

#pragma mark -- 插屏2.0
JS_METHOD(loadUnifiedInterstitialAd:(UZModuleMethodContext *)context){
	NSDictionary *params = context.param;
	NSString *adId  = [params stringValueForKey:@"adId" defaultValue:nil];
//    NSString *fixedOn  = [params stringValueForKey:@"fixedOn" defaultValue:nil];
//    NSDictionary *rect = [params dictValueForKey:@"rect" defaultValue:@{}];
	BOOL isFullScreen = [params boolValueForKey:@"isFullScreen" defaultValue:YES];
	NSInteger minVideoDuration  = [params intValueForKey:@"minVideoDuration" defaultValue:(int)1];
	NSInteger maxVideoDuration  = [params intValueForKey:@"maxVideoDuration" defaultValue:(int)300];
//    BOOL fixed = [params boolValueForKey:@"fixed" defaultValue:NO];
	if (_interstitialAd) {
		_interstitialAd.delegate = nil;
	}
	_interstitialAd = [[GDTUnifiedInterstitialAd alloc] initWithPlacementId:adId];
	_interstitialAd.delegate = self;
	_interstitialAd.videoMuted = NO;
	_interstitialAd.minVideoDuration = minVideoDuration;
	_interstitialAd.maxVideoDuration = maxVideoDuration; // 如果需要设置视频最大时长，可以通过这个参数来进行设置
	NSOperationQueue *waitQueue = [[NSOperationQueue alloc] init];
	[waitQueue addOperationWithBlock:^{
	         // 同步到主线程
	         dispatch_async(dispatch_get_main_queue(), ^{
					if(isFullScreen) {
						[self->_interstitialAd loadFullScreenAd];
					}else{
						[self->_interstitialAd loadAd];
					}
				});
	 }];

	if(!self.unifiedInterstitialAdObserver) {
		__weak typeof(self) _self = self;
		self.unifiedInterstitialAdObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"loadUnifiedInterstitialAd" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
		                                              NSLog(@"接收到loadUnifiedInterstitialAdObserver通知，%@",note.object);
		                                              __strong typeof(_self) self = _self;
		                                              if(!self) return;
		                                              [context callbackWithRet:note.object err:nil delete:NO];
						      }];
	}

	[context callbackWithRet:@{@"code":@1,@"unifiedInterstitialAdType":@"loadUnifiedInterstitialAd",@"eventType":@"doLoad",@"msg":@"广告加载命令执行成功"} err:nil delete:NO];
}

JS_METHOD_SYNC(showUnifiedInterstitialAd:(UZModuleMethodContext *)context){
	NSDictionary *params = context.param;

	BOOL isFullScreen = [params boolValueForKey:@"isFullScreen" defaultValue:YES];
	NSOperationQueue *waitQueue = [[NSOperationQueue alloc] init];
	[waitQueue addOperationWithBlock:^{
	         // 同步到主线程
	         dispatch_async(dispatch_get_main_queue(), ^{
					if(isFullScreen) {
						[self->_interstitialAd presentFullScreenAdFromRootViewController:self.viewController];
					}else{
						[self->_interstitialAd presentAdFromRootViewController:self.viewController];
					}
				});
	 }];



	return @{@"code":@1,@"unifiedInterstitialAdType":@"showUnifiedInterstitialAd",@"eventType":@"doShow",@"msg":@"插屏广告展示命令执行成功"};
}

#pragma mark 插屏广告 HNTMob 方法
-(void)removeUnifiedInterstitialAdNotification {

	if(self.unifiedInterstitialAdObserver) {
		NSLog(@"移除通知监听");
		[[NSNotificationCenter defaultCenter] removeObserver:self.unifiedInterstitialAdObserver name:@"loadUnifiedInterstitialAd" object:nil];
		self.unifiedInterstitialAdObserver = nil;
	}
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedInterstitialAd" object:@{@"code":@1,@"unifiedInterstitialAdType":@"loadUnifiedInterstitialAd",@"eventType":@"doLoad",@"msg":@"广告加载命令执行成功"}];
}

#pragma mark 插屏广告 GDTUnifiedInterstitialAdDelegate
/**
 *  插屏2.0广告预加载成功回调
 *  当接收服务器返回的广告数据成功且预加载后调用该函数
 */
- (void)unifiedInterstitialSuccessToLoadAd:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
	NSLog(@"%s %@",__FUNCTION__,@"Load Success." );
	NSLog(@"eCPM:%ld eCPMLevel:%@", [unifiedInterstitial eCPM], [unifiedInterstitial eCPMLevel]);
	NSLog(@"videoDuration:%lf isVideo: %@", unifiedInterstitial.videoDuration, @(unifiedInterstitial.isVideoAd));
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedInterstitialAd" object:@{@"code":@1,@"unifiedInterstitialAdType":@"loadUnifiedInterstitialAd",@"eventType":@"adLoaded",@"msg":@"插屏广告加载成功",@"isVideoAd":@(unifiedInterstitial.isVideoAd),@"eCPM": @([unifiedInterstitial eCPM]),@"eCPMLevel":[unifiedInterstitial eCPMLevel]?:@"",@"videoDuration":@(unifiedInterstitial.videoDuration)}];
}

/**
 *  插屏2.0广告预加载失败回调
 *  当接收服务器返回的广告数据失败后调用该函数
 */
- (void)unifiedInterstitialFailToLoadAd:(GDTUnifiedInterstitialAd *)unifiedInterstitial error:(NSError *)error {
	NSLog(@"%s Error : %@",__FUNCTION__,error);
	NSLog(@"interstitial fail to load, Error : %@",error);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedInterstitialAd" object:@{@"code":@0,@"unifiedInterstitialAdType":@"loadUnifiedInterstitialAd",@"eventType":@"adLoadFailed",@"msg":@"插屏广告加载失败"}];
	[self removeUnifiedInterstitialAdNotification];
}

/**
 *  插屏2.0广告将要展示回调
 *  插屏2.0广告即将展示回调该函数
 */
- (void)unifiedInterstitialWillPresentScreen:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
	NSLog(@"%s %@",__FUNCTION__,@"Going to present.");

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedInterstitialAd" object:@{@"code":@1,@"unifiedInterstitialAdType":@"showUnifiedInterstitialAd",@"eventType":@"adWillShow",@"msg":@"插屏广告即将被展示"}];
}

/**
 *  插屏2.0广告视图展示成功回调
 *  插屏2.0广告展示成功回调该函数
 */
- (void)unifiedInterstitialDidPresentScreen:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
	NSLog(@"%s %@",__FUNCTION__,@"Success Presented.");
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedInterstitialAd" object:@{@"code":@1,@"unifiedInterstitialAdType":@"showUnifiedInterstitialAd",@"eventType":@"isPresented",@"msg":@"插屏广告展示了"}];

}

/**
 *  插屏2.0广告视图展示失败回调
 *  插屏2.0广告展示失败回调该函数
 */
- (void)unifiedInterstitialFailToPresent:(GDTUnifiedInterstitialAd *)unifiedInterstitial error:(NSError *)error {
	NSLog(@"%s 插屏展示失败 %@",__FUNCTION__,error);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedInterstitialAd" object:@{@"code":@0,@"unifiedInterstitialAdType":@"showUnifiedInterstitialAd",@"eventType":@"presentFailed",@"msg":@"插屏广告展示失败了",@"isAdValid":@(unifiedInterstitial.isAdValid)}];
	if(!unifiedInterstitial.isAdValid) {
		[self removeUnifiedInterstitialAdNotification];
		_interstitialAd = nil;
	}
}

/**
 *  插屏2.0广告展示结束回调
 *  插屏2.0广告展示结束回调该函数
 */
- (void)unifiedInterstitialDidDismissScreen:(GDTUnifiedInterstitialAd *)unifiedInterstitial; {
	NSLog(@"%s 插屏展示结束",__FUNCTION__);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedInterstitialAd" object:@{@"code":@1,@"unifiedInterstitialAdType":@"showUnifiedInterstitialAd",@"eventType":@"presentFinished",@"msg":@"插屏广告展示结束"}];
	[self removeUnifiedInterstitialAdNotification];
	_interstitialAd = nil;
}

/**
 *  当点击下载应用时会调用系统程序打开其它App或者Appstore时回调
 */
- (void)unifiedInterstitialWillLeaveApplication:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
	NSLog(@"%s 插屏广告打开其他app或者App Store",__FUNCTION__);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedInterstitialAd" object:@{@"code":@1,@"unifiedInterstitialAdType":@"showUnifiedInterstitialAd",@"eventType":@"openOtherApp",@"msg":@"插屏打开其他应用"}];
}

/**
 *  插屏2.0广告曝光回调
 */
- (void)unifiedInterstitialWillExposure:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
	NSLog(@"%s 插屏广告 即将曝光 ",__FUNCTION__);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedInterstitialAd" object:@{@"code":@1,@"unifiedInterstitialAdType":@"showUnifiedInterstitialAd",@"eventType":@"adShowed",@"msg":@"插屏广告即将曝光"}];
}

/**
 *  插屏2.0广告点击回调
 */
- (void)unifiedInterstitialClicked:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
	NSLog(@"%s 插屏广告 被点击了 ",__FUNCTION__);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedInterstitialAd" object:@{@"code":@1,@"unifiedInterstitialAdType":@"showUnifiedInterstitialAd",@"eventType":@"adClicked",@"msg":@"插屏广告被点击了"}];
}

/**
 *  点击插屏2.0广告以后即将弹出全屏广告页
 */
- (void)unifiedInterstitialAdWillPresentFullScreenModal:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
	NSLog(@"%s 插屏广告即将弹出广告详情页 ",__FUNCTION__);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedInterstitialAd" object:@{@"code":@1,@"unifiedInterstitialAdType":@"showUnifiedInterstitialAd",@"eventType":@"adPageWillShow",@"msg":@"插屏广告即将弹出广告详情页"}];
}

/**
 *  点击插屏2.0广告以后弹出全屏广告页
 */
- (void)unifiedInterstitialAdDidPresentFullScreenModal:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
	NSLog(@"%s 插屏广告弹出广告详情页 ",__FUNCTION__);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedInterstitialAd" object:@{@"code":@1,@"unifiedInterstitialAdType":@"showUnifiedInterstitialAd",@"eventType":@"adPageShowed",@"msg":@"插屏广告弹出广告详情页"}];
}

/**
 *  全屏广告页将要关闭
 */
- (void)unifiedInterstitialAdWillDismissFullScreenModal:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
	NSLog(@"%s 插屏广告详情页将要关闭 ",__FUNCTION__);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedInterstitialAd" object:@{@"code":@1,@"unifiedInterstitialAdType":@"showUnifiedInterstitialAd",@"eventType":@"adPageWillClosed",@"msg":@"插屏广告详情页将要关闭"}];
}

/**
 *  全屏广告页被关闭
 */
- (void)unifiedInterstitialAdDidDismissFullScreenModal:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
	NSLog(@"%s 插屏广告详情页关闭 ",__FUNCTION__);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedInterstitialAd" object:@{@"code":@1,@"unifiedInterstitialAdType":@"showUnifiedInterstitialAd",@"eventType":@"adPageClosed",@"msg":@"插屏广告详情页关闭"}];

}

/**
 * 插屏2.0视频广告 player 播放状态更新回调
 */
- (void)unifiedInterstitialAd:(GDTUnifiedInterstitialAd *)unifiedInterstitial playerStatusChanged:(GDTMediaPlayerStatus)status {
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

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedInterstitialAd" object:@{@"code":@1,@"unifiedNativeAdType":@"showUnifiedInterstitialAd",@"eventType":@"videoStatusChange",@"msg":@"插屏广告 视频广告状态变更",@"status": @(status)}];
}

/**
 * 插屏2.0视频广告详情页 WillPresent 回调 即将展示
 */
- (void)unifiedInterstitialAdViewWillPresentVideoVC:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
	NSLog(@"%s %@",__FUNCTION__,@"Going to present.");

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedInterstitialAd" object:@{@"code":@1,@"unifiedInterstitialAdType":@"showUnifiedInterstitialAd",@"eventType":@"adPageWillShow",@"msg":@"插屏广告详情页即将被展示"}];
}

/**
 * 插屏2.0视频广告详情页 DidPresent 回调 展示
 */
- (void)unifiedInterstitialAdViewDidPresentVideoVC:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
	NSLog(@"%s %@",__FUNCTION__,@"present.");

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedInterstitialAd" object:@{@"code":@1,@"unifiedInterstitialAdType":@"showUnifiedInterstitialAd",@"eventType":@"adPageShowed",@"msg":@"插屏广告详情页展示"}];
}

/**
 * 插屏2.0视频广告详情页 WillDismiss 回调 即将关闭
 */
- (void)unifiedInterstitialAdViewWillDismissVideoVC:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
	NSLog(@"%s %@",__FUNCTION__,@"Going to present.");

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedInterstitialAd" object:@{@"code":@1,@"unifiedInterstitialAdType":@"showUnifiedInterstitialAd",@"eventType":@"adPageWillClose",@"msg":@"插屏广告视频广告详情页即将关闭"}];
}

/**
 * 插屏2.0视频广告详情页 DidDismiss 回调 关闭
 */
- (void)unifiedInterstitialAdViewDidDismissVideoVC:(GDTUnifiedInterstitialAd *)unifiedInterstitial {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadUnifiedInterstitialAd" object:@{@"code":@1,@"unifiedInterstitialAdType":@"showUnifiedInterstitialAd",@"eventType":@"adPageClosed",@"msg":@"插屏广告视频广告详情页关闭"}];
}

#pragma mark  banner 广告  HNTMob GDTUnifiedBannerView

JS_METHOD(loadBannerAd:(UZModuleMethodContext *)context){
	NSDictionary *params = context.param;
	NSString *adId  = [params stringValueForKey:@"adId" defaultValue:nil];

	BOOL animationSwitch = [params boolValueForKey:@"animationSwitch" defaultValue:YES];
	int refreshInterval = [params intValueForKey:@"refreshInterval" defaultValue:0];
	NSDictionary *ret = [params dictValueForKey:@"ret" defaultValue:@{@"x":@0,@"y":@0,@"width":@375,@"height":@100}];

	BOOL fixed = [params boolValueForKey:@"fixed" defaultValue:NO];
	NSString *fixedOn = [params stringValueForKey:@"fixedOn" defaultValue:nil];

	float x = [ret floatValueForKey:@"x" defaultValue:0];
	float y = [ret floatValueForKey:@"y" defaultValue:0];
	float width = [ret floatValueForKey:@"width" defaultValue:375];
	float height = [ret floatValueForKey:@"height" defaultValue:100];
	if(refreshInterval>0 && refreshInterval<30) {
		refreshInterval = 30;
	}else if (refreshInterval>120) {
		refreshInterval = 120;
	}
	if (_bannerView.superview) {
		[self removeBannerView];
	}


	CGRect rect = CGRectMake(x, y, width, height);
	_bannerView = [[GDTUnifiedBannerView alloc]
	               initWithFrame:rect
	               placementId:adId
	               viewController:self.viewController];
	_bannerView.delegate = self;


	_bannerView.accessibilityIdentifier = @"banner_ad";
	_bannerView.animated = animationSwitch;
	_bannerView.autoSwitchInterval = refreshInterval;

	[self addSubview:self.bannerView fixedOn:fixedOn fixed:fixed];

	[self.bannerView loadAdAndShow];

	if(!self.unifiedBannerViewObserver) {
		__weak typeof(self) _self = self;
		self.unifiedBannerViewObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"loadBannerAdObserver" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
		                                          NSLog(@"接收到loadBannerAdObserver通知，%@",note.object);
		                                          __strong typeof(_self) self = _self;
		                                          if(!self) return;
		                                          [context callbackWithRet:note.object err:nil delete:NO];
						  }];
	}
	[context callbackWithRet:@{@"code":@1,@"bannerAdType":@"loadBannerAd",@"eventType":@"doLoad",@"msg":@"banner广告加载命令执行成功"} err:nil delete:NO];
}
JS_METHOD(closeBannerAd:(UZModuleMethodContext *)context){

//    if (_bannerView.superview) {
//        [_bannerView removeFromSuperview];
//        _bannerView = nil;
//    }
	[self removeBannerView];
	[context callbackWithRet:@{@"code":@1,@"bannerAdType":@"closeBannerAd",@"eventType":@"doClose",@"msg":@"banner广告关闭命令执行成功"} err:nil delete:YES];
}

#pragma mark banner action GDTUnifiedBannerView
-(void) removeBannerView {
	[self removeUnifiedBannerViewObserver];
	NSLog(@" 移除banner广告 ");

	// 同步到主线程
	dispatch_async(dispatch_get_main_queue(), ^{
		[self->_bannerView removeFromSuperview];
		self->_bannerView = nil;
	});
}

-(void) removeUnifiedBannerViewObserver {
	if(self.unifiedBannerViewObserver) {
		NSLog(@"移除通知监听");
		[[NSNotificationCenter defaultCenter] removeObserver:self.unifiedBannerViewObserver name:@"loadBannerAdObserver" object:nil];
		self.unifiedBannerViewObserver = nil;
	}
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"code":@1,@"bannerAdType":@"loadBannerAd",@"eventType":@"doLoad",@"msg":@"广告加载命令执行成功"}];

}

#pragma mark delegate
/**
 *  请求广告条数据成功后调用
 *  当接收服务器返回的广告数据成功后调用该函数
 */
- (void)unifiedBannerViewDidLoad:(GDTUnifiedBannerView *)unifiedBannerView {
	NSLog(@"%s",__FUNCTION__);
	NSLog(@"unified banner did load");
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"code":@1,@"bannerAdType":@"loadBannerAd",@"eventType":@"adLoaded",@"msg":@"广告加载成功"}];
}

/**
 *  请求广告条数据失败后调用
 *  当接收服务器返回的广告数据失败后调用该函数
 */
- (void)unifiedBannerViewFailedToLoad:(GDTUnifiedBannerView *)unifiedBannerView error:(NSError *)error {

	NSLog(@"unified banner did load failed");
	NSLog(@"error %@",error);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"code":@0,@"bannerAdType":@"loadBannerAd",@"eventType":@"adLoadFaild",@"msg":@"广告加载失败",@"userInfo":error.userInfo}];
	[self removeBannerView];
	[self removeUnifiedBannerViewObserver];

}

/**
 *  banner2.0曝光回调
 */
- (void)unifiedBannerViewWillExpose:(GDTUnifiedBannerView *)unifiedBannerView {
	NSLog(@"unified banner will expose ");

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"code":@1,@"bannerAdType":@"showBannerAd",@"eventType":@"adWillShow",@"msg":@"广告即将曝光"}];

}

/**
 *  banner2.0点击回调
 */
- (void)unifiedBannerViewClicked:(GDTUnifiedBannerView *)unifiedBannerView {
	NSLog(@"unified banner clicked ");

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"code":@1,@"bannerAdType":@"showBannerAd",@"eventType":@"adClicked",@"msg":@"广告被点击了"}];

}

/**
 *  banner2.0广告点击以后即将弹出全屏广告页
 */
- (void)unifiedBannerViewWillPresentFullScreenModal:(GDTUnifiedBannerView *)unifiedBannerView {
	NSLog(@"unified banner will open full ad page ");

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"code":@1,@"bannerAdType":@"showBannerAd",@"eventType":@"adPageWillShow",@"msg":@"广告详情页即将打开"}];
}

/**
 *  banner2.0广告点击以后弹出全屏广告页完毕
 */
- (void)unifiedBannerViewDidPresentFullScreenModal:(GDTUnifiedBannerView *)unifiedBannerView {
	NSLog(@"unified banner did open full ad page ");

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"code":@1,@"bannerAdType":@"showBannerAd",@"eventType":@"adPageShowed",@"msg":@"广告详情页打开了"}];
}

/**
 *  全屏广告页即将被关闭
 */
- (void)unifiedBannerViewWillDismissFullScreenModal:(GDTUnifiedBannerView *)unifiedBannerView {
	NSLog(@"unified banner will close full ad page ");

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"code":@1,@"bannerAdType":@"showBannerAd",@"eventType":@"adPageWillClosed",@"msg":@"广告详情页即将关闭"}];
}

/**
 *  全屏广告页已经被关闭
 */
- (void)unifiedBannerViewDidDismissFullScreenModal:(GDTUnifiedBannerView *)unifiedBannerView {
	NSLog(@"unified banner did close full ad page ");

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"code":@1,@"bannerAdType":@"showBannerAd",@"eventType":@"adPageClosed",@"msg":@"广告详情页关闭"}];
}

/**
 *  当点击应用下载或者广告调用系统程序打开
 */
- (void)unifiedBannerViewWillLeaveApplication:(GDTUnifiedBannerView *)unifiedBannerView {
	NSLog(@"unified banner will close full ad page ");

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"code":@1,@"bannerAdType":@"showBannerAd",@"eventType":@"openOtherApp",@"msg":@"banner打开其他app"}];
}

/**
 *  banner2.0被用户关闭时调用
 */
- (void)unifiedBannerViewWillClose:(GDTUnifiedBannerView *)unifiedBannerView {
	NSLog(@"unified banner will close by user ");

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadBannerAdObserver" object:@{@"code":@1,@"bannerAdType":@"showBannerAd",@"eventType":@"adClosedByUser",@"msg":@"banner被用户关闭"}];
}


#pragma mark 信息流 模版广告1.0
JS_METHOD(loadNativeExpressAd:(UZModuleMethodContext *)context){

	NSDictionary *params = context.param;
	NSString *adId  = [params stringValueForKey:@"adId" defaultValue:nil];
	NSString *fixedOn = [params stringValueForKey:@"fixedOn" defaultValue:nil];
	BOOL fixed = [params boolValueForKey:@"fixed" defaultValue:NO];
	float x = [params floatValueForKey:@"x" defaultValue:0];
	float y = [params floatValueForKey:@"y" defaultValue:0];
	float width  = [params floatValueForKey:@"width" defaultValue:414];
	float height  = [params floatValueForKey:@"height" defaultValue:50];

	self.nativeExpressAd = [[GDTNativeExpressAd alloc] initWithPlacementId:adId
	                        adSize:CGSizeMake(width,height)];
	self.nativeExpressAd.delegate = self;
	[self.nativeExpressAd loadAd:1];

	if(!self.nativeExpressAdObserver) {
		__weak typeof(self) _self = self;
		self.nativeExpressAdObserver = [[NSNotificationCenter defaultCenter] addObserverForName:@"loadNativeExpressAdObserver" object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
		                                        NSLog(@"接收到loadNativeExpressAdObserver通知，%@",note.object);
		                                        __strong typeof(_self) self = _self;
		                                        if(!self) return;
		                                        NSString *placeId = [note.object stringValueForKey:@"adId" defaultValue:nil];
		                                        if([placeId isEqualToString:adId]) {
								if([[note.object valueForKey:@"isNativeExpressAd"] boolValue]) {
									if(self->_expressView) {
										[self addSubview:self->_expressView fixedOn:fixedOn fixed:fixed];
										self->_expressView.controller = self.viewController;
										self->_expressView.frame = CGRectMake(x, y, self->_expressView.bounds.size.width, self->_expressView.bounds.size.height);
										[self->_expressView render];
									}else{
										[context callbackWithRet:@{@"code":@0,@"nativeExpressAdType":@"showNativeExpressAd",@"eventType":@"doShowFaild",@"msg":@"没有可以添加的信息流界面"} err:nil delete:YES];
										[self removeNativeExpressAdObserver];
										return;

									}
								}
								[context callbackWithRet:note.object err:nil delete:NO];
							}
						}];
	}
	[context callbackWithRet:@{@"code":@1,@"nativeExpressAdType":@"loadNativeExpressAd",@"eventType":@"doLoad",@"msg":@"信息流广告加载命令执行成功"} err:nil delete:NO];


}
JS_METHOD(closeNativeExpressAd:(UZModuleMethodContext *)context){
    
    if(_expressView.superview){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->_expressView removeFromSuperview];
            self->_expressView=nil;
            NSLog(@" 移除 expressView");
        });
    }
	[self removeNativeExpressAdObserver];
   
	[context callbackWithRet:@{@"code":@1,@"nativeExpressAdType":@"closeNativeExpressAd",@"eventType":@"doClose",@"msg":@"广告关闭命令执行成功"} err:nil delete:YES];
}
#pragma mark 信息流 模版1.0 action
-(void) removeNativeExpressAdObserver {
	if(self.nativeExpressAdObserver) {
		NSLog(@"移除 信息流 通知监听");
		[[NSNotificationCenter defaultCenter] removeObserver:self.nativeExpressAdObserver name:@"loadNativeExpressAdObserver" object:nil];
		self.nativeExpressAdObserver = nil;
	}
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"loadNativeExpressAdObserver" object:@{@"code":@1,@"nativeExpressAdType":@"loadNativeExpressAd",@"eventType":@"doLoad",@"msg":@"广告加载命令执行成功"}];

}


#pragma mark 信息流 模版广告 1.0 GDTNativeExpressAdDelegete

/**
 * 拉取原生模板广告成功
 */
- (void)nativeExpressAdSuccessToLoad:(GDTNativeExpressAd *)nativeExpressAd views:(NSArray<__kindof GDTNativeExpressAdView *> *)views {
	NSString *adId = [nativeExpressAd placementId];
	NSLog(@"%@",nativeExpressAd);
	NSLog(@"adId %@",[nativeExpressAd placementId]);

	if (views.count) {
        if(_expressView ){
            [_expressView removeFromSuperview];
            _expressView = nil;
        }
		_expressView = (GDTNativeExpressAdView *)views[0];
		_expressView.adId = adId;
		NSLog(@"eCPM:%ld eCPMLevel:%@", [_expressView eCPM], [_expressView eCPMLevel]);
		[[NSNotificationCenter defaultCenter] postNotificationName:@"loadNativeExpressAdObserver" object:@{@"code":@1,@"nativeExpressAdType":@"loadNativeExpressAd",@"adId":adId,@"eventType":@"adLoaded",@"isNativeExpressAd":@YES,@"msg":@"广告加载成功"}];
	}else{
		[[NSNotificationCenter defaultCenter] postNotificationName:@"loadNativeExpressAdObserver" object:@{@"code":@0,@"nativeExpressAdType":@"loadNativeExpressAd",@"adId":adId,@"eventType":@"adLoadedError",@"msg":@"广告加载数据为空"}];

		[self removeNativeExpressAdObserver];
	}
}

/**
 * 拉取原生模板广告失败
 */
- (void)nativeExpressAdFailToLoad:(GDTNativeExpressAd *)nativeExpressAd error:(NSError *)error {
	NSString *adId = nativeExpressAd.placementId;
	NSLog(@"nativeExpressAd load failed %@",error);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadNativeExpressAdObserver" object:@{@"code":@0,@"nativeExpressAdType":@"loadNativeExpressAd",@"adId":adId,@"eventType":@"adLoadedFailed",@"msg":@"广告加载失败",@"userInfo":error.userInfo}];

	[self removeNativeExpressAdObserver];
}

/**
 * 原生模板广告渲染成功, 此时的 nativeExpressAdView.size.height 根据 size.width 完成了动态更新。
 */
- (void)nativeExpressAdViewRenderSuccess:(GDTNativeExpressAdView *)nativeExpressAdView {
	NSString *adId = nativeExpressAdView.adId;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadNativeExpressAdObserver" object:@{@"code":@1,@"nativeExpressAdType":@"showNativeExpressAd",@"adId":adId,@"eventType":@"adRendered",@"msg":@"广告渲染成功"}];
}

/**
 * 原生模板广告渲染失败
 */
- (void)nativeExpressAdViewRenderFail:(GDTNativeExpressAdView *)nativeExpressAdView {
	NSString *adId = nativeExpressAdView.adId;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadNativeExpressAdObserver" object:@{@"code":@0,@"nativeExpressAdType":@"showNativeExpressAd",@"adId":adId,@"eventType":@"adRenderFaild",@"msg":@"广告渲染失败"}];
	//TODO 需要确认是否清理掉 异步通知
	[self removeNativeExpressAdObserver];
}

/**
 * 原生模板广告曝光回调
 */
- (void)nativeExpressAdViewExposure:(GDTNativeExpressAdView *)nativeExpressAdView {
	NSString *adId = nativeExpressAdView.adId;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadNativeExpressAdObserver" object:@{@"code":@1,@"nativeExpressAdType":@"showNativeExpressAd",@"adId":adId,@"eventType":@"adShowed",@"msg":@"广告曝光了"}];
}

/**
 * 原生模板广告点击回调
 */
- (void)nativeExpressAdViewClicked:(GDTNativeExpressAdView *)nativeExpressAdView {
	NSString *adId = nativeExpressAdView.adId;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadNativeExpressAdObserver" object:@{@"code":@1,@"nativeExpressAdType":@"showNativeExpressAd",@"adId":adId,@"eventType":@"adClicked",@"msg":@"广告被点击了"}];
}

/**
 * 原生模板广告被关闭
 */
- (void)nativeExpressAdViewClosed:(GDTNativeExpressAdView *)nativeExpressAdView {
	NSString *adId = nativeExpressAdView.adId;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadNativeExpressAdObserver" object:@{@"code":@1,@"nativeExpressAdType":@"showNativeExpressAd",@"adId":adId,@"eventType":@"adClosed",@"msg":@"广告关闭了"}];
	[self removeNativeExpressAdObserver];
	[_expressView removeFromSuperview];
	_expressView = nil;
}

/**
 * 点击原生模板广告以后即将弹出全屏广告页
 */
- (void)nativeExpressAdViewWillPresentScreen:(GDTNativeExpressAdView *)nativeExpressAdView {
	NSString *adId = nativeExpressAdView.adId;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadNativeExpressAdObserver" object:@{@"code":@1,@"nativeExpressAdType":@"showNativeExpressAd",@"adId":adId,@"eventType":@"adPageWillShow",@"msg":@"广告详情页即将打开"}];
}

/**
 * 点击原生模板广告以后弹出全屏广告页
 */
- (void)nativeExpressAdViewDidPresentScreen:(GDTNativeExpressAdView *)nativeExpressAdView {
	NSString *adId = nativeExpressAdView.adId;
	NSLog(@"mys adId %@",nativeExpressAdView.adId);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadNativeExpressAdObserver" object:@{@"code":@1,@"nativeExpressAdType":@"showNativeExpressAd",@"adId":adId,@"eventType":@"adPageShow",@"msg":@"广告详情页打开"}];
}

/**
 * 全屏广告页将要关闭
 */
- (void)nativeExpressAdViewWillDismissScreen:(GDTNativeExpressAdView *)nativeExpressAdView {
	NSString *adId = nativeExpressAdView.adId;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadNativeExpressAdObserver" object:@{@"code":@1,@"nativeExpressAdType":@"showNativeExpressAd",@"adId":adId,@"eventType":@"adPageWillClose",@"msg":@"广告详情页即将关闭"}];
}

/**
 * 全屏广告页将要关闭
 */
- (void)nativeExpressAdViewDidDismissScreen:(GDTNativeExpressAdView *)nativeExpressAdView {
	NSString *adId = nativeExpressAdView.adId;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadNativeExpressAdObserver" object:@{@"code":@1,@"nativeExpressAdType":@"showNativeExpressAd",@"adId":adId,@"eventType":@"adPageClosed",@"msg":@"广告详情页关闭"}];
}

/**
 * 详解:当点击应用下载或者广告调用系统程序打开时调用
 */
- (void)nativeExpressAdViewApplicationWillEnterBackground:(GDTNativeExpressAdView *)nativeExpressAdView {
	NSString *adId = nativeExpressAdView.adId;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadNativeExpressAdObserver" object:@{@"code":@1,@"nativeExpressAdType":@"showNativeExpressAd",@"adId":adId,@"eventType":@"enterBackground",@"msg":@"广告进入后台"}];
}

/**
 * 原生模板视频广告 player 播放状态更新回调
 */
- (void)nativeExpressAdView:(GDTNativeExpressAdView *)nativeExpressAdView playerStatusChanged:(GDTMediaPlayerStatus)status {
	NSString *adId = nativeExpressAdView.adId;
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

	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadNativeExpressAdObserver" object:@{@"code":@1,@"nativeExpressAdType":@"showNativeExpressAd",@"adId":adId,@"eventType":@"videoStatusChange",@"msg":@"广告 视频广告状态变更",@"status": @(status)}];
}

/**
 * 原生视频模板详情页 WillPresent 回调
 */
- (void)nativeExpressAdViewWillPresentVideoVC:(GDTNativeExpressAdView *)nativeExpressAdView {
	NSString *adId = nativeExpressAdView.adId;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadNativeExpressAdObserver" object:@{@"code":@1,@"nativeExpressAdType":@"showNativeExpressAd",@"adId":adId,@"eventType":@"adVideoPageWillShow",@"msg":@"视频模版详情页即将打开"}];
}

/**
 * 原生视频模板详情页 DidPresent 回调
 */
- (void)nativeExpressAdViewDidPresentVideoVC:(GDTNativeExpressAdView *)nativeExpressAdView {
	NSString *adId = nativeExpressAdView.adId;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadNativeExpressAdObserver" object:@{@"code":@1,@"nativeExpressAdType":@"showNativeExpressAd",@"adId":adId,@"eventType":@"adVideoPageShow",@"msg":@"视频模版详情页打开"}];
}

/**
 * 原生视频模板详情页 WillDismiss 回调
 */
- (void)nativeExpressAdViewWillDismissVideoVC:(GDTNativeExpressAdView *)nativeExpressAdView {
	NSString *adId = nativeExpressAdView.adId;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadNativeExpressAdObserver" object:@{@"code":@1,@"nativeExpressAdType":@"showNativeExpressAd",@"adId":adId,@"eventType":@"adVideoPageWillClose",@"msg":@"视频模版详情页即将关闭"}];
}

/**
 * 原生视频模板详情页 DidDismiss 回调
 */
- (void)nativeExpressAdViewDidDismissVideoVC:(GDTNativeExpressAdView *)nativeExpressAdView {
	NSString *adId = nativeExpressAdView.adId;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"loadNativeExpressAdObserver" object:@{@"code":@1,@"nativeExpressAdType":@"showNativeExpressAd",@"adId":adId,@"eventType":@"adVideoPageClose",@"msg":@"视频模版详情页关闭"}];
}

@end

