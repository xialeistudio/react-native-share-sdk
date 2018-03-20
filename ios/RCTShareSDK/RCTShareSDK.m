//
// Created by 夏磊 on 2018/3/19.
// Copyright (c) 2018 Groupfriend Information Technology Co,.Ltd. All rights reserved.
//

#import "RCTShareSDK.h"
#import <ShareSDK/ShareSDK.h>
#import <ShareSDKConnector/ShareSDKConnector.h>
#import <ShareSDKUI/ShareSDKUI.h>
#import <ShareSDKExtension/ShareSDK+Extension.h>
//QQ SDK header file
#import <TencentOpenAPI/TencentOAuth.h>
#import <TencentOpenAPI/QQApiInterface.h>
//Wechat SDK header file
#import "WXApi.h"
//SinaWeibo SDK header file
#import "WeiboSDK.h"

// ShareSDK配置KEY
NSString *const kSinaAppId = @"SinaAppId";
NSString *const kSinaAppSecret = @"SinaAppSecret";
NSString *const kWechatAppId = @"WechatAppId";
NSString *const kWechatAppSecret = @"WechatAppSecret";
NSString *const kQQAppId = @"QQAppId";
NSString *const kQQAppSecret = @"QQAppSecret";
// 错误代码定义
NSString *const kErrWechatNotInstalled = @"kErrWechatNotInstalled";
NSString *const kErrWechatLogin = @"kErrWechatLogin";

@implementation RCTShareSDK
{

}

RCT_EXPORT_MODULE()

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self bootstrap];
    }

    return self;
}

- (void)bootstrap
{
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSArray *platforms = @[
        @(SSDKPlatformTypeSinaWeibo),
        @(SSDKPlatformTypeMail),
        @(SSDKPlatformTypeSMS),
        @(SSDKPlatformTypeWechat),
        @(SSDKPlatformTypeQQ)];
    void(^onImport)(SSDKPlatformType)=^(SSDKPlatformType platformType)
    {
        switch (platformType)
        {
            case SSDKPlatformTypeWechat:[ShareSDKConnector connectWeChat:[WXApi class]];
                break;
            case SSDKPlatformTypeQQ:[ShareSDKConnector connectQQ:[QQApiInterface class] tencentOAuthClass:[TencentOAuth class]];
                break;
            case SSDKPlatformTypeSinaWeibo:[ShareSDKConnector connectWeibo:[WeiboSDK class]];
                break;
            default:break;
        }
    };
    void(^onConfiguration)(SSDKPlatformType, NSMutableDictionary *)=^(SSDKPlatformType platformType,
                                                                  NSMutableDictionary *appInfo)
    {
        switch (platformType)
        {
            case SSDKPlatformTypeSinaWeibo:
                [appInfo SSDKSetupSinaWeiboByAppKey:info[kSinaAppId]
                                          appSecret:info[kSinaAppSecret]
                                        redirectUri:@"http://www.sharesdk.cn"
                                           authType:SSDKAuthTypeBoth];
                break;
            case SSDKPlatformTypeWechat:
                [appInfo SSDKSetupWeChatByAppId:info[kWechatAppId]
                                      appSecret:info[kWechatAppSecret]];
                break;
            case SSDKPlatformTypeQQ:
                [appInfo SSDKSetupQQByAppId:info[kQQAppId]
                                     appKey:info[kQQAppSecret]
                                   authType:SSDKAuthTypeBoth];
                break;
            default:break;
        }
    };
    [ShareSDK registerActivePlatforms:platforms
                             onImport:onImport
                      onConfiguration:onConfiguration];
}

# pragma 检测微信是否安装
RCT_EXPORT_METHOD(isWechatInstalled:(RCTPromiseResolveBlock) resolve
                  reject:(RCTPromiseRejectBlock) reject)
{
    resolve(@([ShareSDK isClientInstalled:SSDKPlatformTypeWechat]));
}
# pragma 分享
RCT_EXPORT_METHOD(share:(NSString *) title
                  desc:(NSString *) desc
                  imgUrl:(NSString *) imgUrl
                  url:(NSString *) url
                  resolve:(RCTPromiseResolveBlock) resolve
                  reject:(RCTPromiseRejectBlock) reject)
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params SSDKSetupShareParamsByText:desc
                                images:@[imgUrl]
                                   url:[[NSURL alloc] initWithString:url]
                                 title:title
                                  type:SSDKContentTypeAuto];
    [ShareSDK showShareActionSheet:nil items:nil shareParams:params onShareStateChanged:^(SSDKResponseState state,
                                                                                          SSDKPlatformType platformType,
                                                                                          NSDictionary *userData,
                                                                                          SSDKContentEntity *contentEntity,
                                                                                          NSError *error,
                                                                                          BOOL end)
    {
        switch (state)
        {
            case SSDKResponseStateSuccess:resolve(@(YES));
                break;
            case SSDKResponseStateFail:
            case SSDKResponseStateCancel:resolve(@(NO));
                break;
            default:break;
        }
    }];
}
# pragma 微信登录
RCT_EXPORT_METHOD(loginByWechat:(RCTPromiseResolveBlock) resolve
                  reject:(RCTPromiseRejectBlock) reject)
{
    if (![ShareSDK isClientInstalled:SSDKPlatformTypeWechat])
    {
        reject(kErrWechatNotInstalled, @"您未安装微信APP", nil);
        return;
    }
    [ShareSDK getUserInfo:SSDKPlatformTypeWechat onStateChanged:^(SSDKResponseState state,
                                                                  SSDKUser *user,
                                                                  NSError *error)
    {
        if (state != SSDKResponseStateSuccess)
        {
            reject(kErrWechatLogin, @"微信登录失败", error);
            return;
        }
        NSDictionary *data = @{@"access_token": [[user credential] token], @"openid": [[user credential] uid]};
        resolve(data);
    }];
}
@end
