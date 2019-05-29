//
//  KaiserSDK.m
//  Unity-iPhone
//
//  Created by kaiser on 2017/4/18.
//
//

#import "KaiserSDK.h"
#import <KSProxy/KSProxy.h>
#import <KSProxy/KSPay.h>
#import <KSProxy/KSCustomerInfo.h>
#import <Bugly/Bugly.h>
#import <KSProxy/KSVoice.h>

#import <KSProxy/KSShare.h>
#import <KSProxy/KSBIStatistic.h>//可选项，业务数据上报接口

#import "UnityAppController.h"

#define kCallBack       "KaiserCallBack"

#if defined(__cplusplus)
extern "C"{
#endif
    extern void UnitySendMessage(const char *, const char *, const char *);
    extern NSString* _CreateNSString (const char* string);
#if defined(__cplusplus)
}
#endif

@interface KaiserSDK ()

@property (nonatomic, strong) KSShare *share;

@end

@implementation KaiserSDK

- (instancetype)init
{
    if (self = [super init]) {
        
    }
    return self;
}

- (KSShare *)dupa
{
    if (!_share) {
        _share = [[KSShare alloc] init];
    }
    return _share;
}

//- (NSString *)jsonStr:(id)source
//{
//    NSData *data = [NSJSONSerialization dataWithJSONObject:source options:NSJSONWritingPrettyPrinted error:nil];
//    NSString *jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    return jsonStr;
//}

#if defined(__cplusplus)
extern "C"{
#endif
    
    KSShare *shareInit;
    //供u3d调用的c函数
    
    void _PlatformInit(char *appid,char *appkey)
    {
        [[KSProxy shareInstance] initWithConfig:[NSString stringWithUTF8String:appid] appkey:[NSString stringWithUTF8String:appkey] complete:^{
            NSLog(@"初始化完成");
            NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:@0,@"callBackEvent", nil];
            NSString *json = jsonStr(dic);
            UnitySendMessage(kCallBack, kCallBack, [json UTF8String]);
        }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:KSLoginNotif object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
            NSLog(@"note = %@",note.userInfo);
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            [dic addEntriesFromDictionary:note.userInfo];
            [dic setObject:@1 forKey:@"callBackEvent"];
            NSString *json = jsonStr(dic);
            UnitySendMessage(kCallBack, kCallBack, [json UTF8String]);
        }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:KSLogoutNotif object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
            NSLog(@"note = %@",note.userInfo);
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            [dic addEntriesFromDictionary:note.userInfo];
            [dic setObject:@2 forKey:@"callBackEvent"];
            NSString *json = jsonStr(dic);
            UnitySendMessage(kCallBack, kCallBack, [json UTF8String]);
        }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:KSPaymentNotif object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
            NSLog(@"note = %@",note.userInfo);
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            [dic addEntriesFromDictionary:note.userInfo];
            [dic setObject:@3 forKey:@"callBackEvent"];
            NSString *json = jsonStr(dic);
            UnitySendMessage(kCallBack, kCallBack, [json UTF8String]);
        }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:@"UploadFileNotif" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
            NSLog(@"note = %@",note.userInfo);
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            [dic addEntriesFromDictionary:note.userInfo];
            [dic setObject:@5 forKey:@"callBackEvent"];
            NSString *json = jsonStr(dic);
            UnitySendMessage(kCallBack, kCallBack, [json UTF8String]);
        }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:@"SpeechToTextNotif" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
            NSLog(@"note = %@",note.userInfo);
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            [dic addEntriesFromDictionary:note.userInfo];
            [dic setObject:@6 forKey:@"callBackEvent"];
            NSString *json = jsonStr(dic);
            UnitySendMessage(kCallBack, kCallBack, [json UTF8String]);
        }];
        
    }
    
    void _PlatformSetRootView()
    {
        [[KSProxy shareInstance] setRootViewController:UnityGetGLViewController()];
    }
    
    void _PlatformInitBugly(char *appid)
    {
        //初始化bugly，填写游戏自己的参数
        [Bugly startWithAppId:[NSString stringWithUTF8String:appid]];
    }
    
    void _PlatformInitReyun(char *appkey)
    {
        //初始化热云广告，填写游戏自己的参数
        [[KSProxy shareInstance] registADkey:[NSString stringWithUTF8String:appkey]];
    }
    
    void _PlatformInitPush(char *appkey)
    {
        //初始化消息推送，填写游戏自己的参数
        [[KSProxy shareInstance] registPushAppkey:[NSString stringWithUTF8String:appkey]];
    }
    
    void _PlatformLogin()
    {
        [[KSProxy shareInstance] login];
        
    }
    
    void _PlatformLogout()
    {
        [[KSProxy shareInstance] logout];
        
    }
    
    void _PlatformChangeout()
    {
        [[KSProxy shareInstance] changeAccount];
        
    }
    
    void _PlatformPay(char *string)
    {
        NSString *str = [NSString stringWithUTF8String:string];
        str = checkJsonStr(str);
        NSData *strData = [str dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:strData options:NSJSONReadingMutableContainers error:nil];
        
        KSPay *pay = [[KSPay alloc] init];
        pay.cp_orderno = dic[@"cp_orderno"];
        pay.ext_info = dic[@"ext_info"];
        pay.level = dic[@"level"];
        pay.price = dic[@"price"];
        pay.project = dic[@"project"];
        pay.uid = dic[@"uid"];
        pay.product_id = dic[@"product_id"];
        pay.serverId = dic[@"serverId"];
        pay.rid = dic[@"rid"];
        pay.desc = dic[@"desc"];
        
        [[KSProxy shareInstance] pay:pay];
    }
    
    void _PlatformInituserCenter()
    {
        [[KSProxy shareInstance] initUserCenter:^{
            NSDictionary *dic = [[NSDictionary alloc] initWithObjectsAndKeys:@4,@"callBackEvent", nil];
            NSString *json = jsonStr(dic);
            UnitySendMessage("KaiserCallBack", "KaiserCallBack", [json UTF8String]);
        }];
    }
    
    void _PlatformShowCustomService(char *string)
    {
        NSString *str = [NSString stringWithUTF8String:string];
        str = checkJsonStr(str);
        NSData *strData = [str dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:strData options:NSJSONReadingMutableContainers error:nil];
        
        KSCustomerInfo *info = [[KSCustomerInfo alloc] init];
        info.serverId = dic[@"serverId"];
        info.serverName = dic[@"serverName"];
        info.roleId = dic[@"roleId"];
        info.roleName = dic[@"roleName"];
        
        [[KSProxy shareInstance] initCustomServiceViewWithConfigInfo:info];
    }
    
    void _PlatformInitVoice(char *appid,char *appkey,char *string)
    {
        //实时语音sdk 第一步：注册
        [[KSVoice shareInstance] setAppID:[NSString stringWithUTF8String:appid] appKey:[NSString stringWithUTF8String:appkey] playerid:[NSString stringWithUTF8String:string]];
    }
    
    void _PlatformJoinTeamRoom(char *string)
    {
        //实时语音sdk 第二步：加入房间（有两种房间，小队房间和全服房间。如果一个房间内同时聊天的玩家小于20人，则使用小队语音模式，这时玩家可以自由发言。当一个房间内语音聊天的玩家大于20人时，则使用全服语音，同时说话人数上限为5人（该模式常用于主播，解说，指挥等）
        int ret = [[KSVoice shareInstance] joinTeamRoomWithName:[NSString stringWithUTF8String:string] msTimeout:5000];
        if (ret == 0) {
            NSLog(@"加入房间成功");
        }
    }
    
    void _PlatformJoinNationalRoom(char *string,int role)
    {
        //实时语音sdk 第二步：加入房间（有两种房间，小队房间和全服房间。如果一个房间内同时聊天的玩家小于20人，则使用小队语音模式，这时玩家可以自由发言。当一个房间内语音聊天的玩家大于20人时，则使用全服语音，同时说话人数上限为5人（该模式常用于主播，解说，指挥等）
        
        int ret = [[KSVoice shareInstance] joinNationalRoomWithNameAndRole:[NSString stringWithUTF8String:string] role:role msTimeout:5000];
        if (ret == 0) {
            NSLog(@"加入房间成功");
        }
    }
    
    void _PlatformQuitTeamRoom(char *string)
    {
        //实时语音sdk 退出房间
        [[KSVoice shareInstance] quitRoomWithName:[NSString stringWithUTF8String:string] msTimeout:5000];
    }
    
    void _PlatformOpenSpeaker(bool on)
    {
        //实时语音sdk 第三步：设置硬件开关，两台设备间的测试距离最好大于100米
        [[KSVoice shareInstance] setSpeakerOpen:on];
    }
    
    void _PlatformOpenMIC(bool on)
    {
        //实时语音sdk 第三步：设置硬件开关，两台设备间的测试距离最好大于100米
        [[KSVoice shareInstance] setMICOpen:on];
    }
    
    // 分享平台初始化
    void _PlatformInitWechat(char * string)
    {
        //初始化微信分享,测试包名: com.tencent.wc.xin.SDKSample 测试appid: wxd930ea5d5a258f4f
        KSShare *share = shareInstance();
        [share initializeWechatWithAppId:[NSString stringWithUTF8String:string] appSecret:nil];
        
    }
    
    void _PlatformInitQQ(char * QQId)
    {
        KSShare *share = shareInstance();
        [share initializeQQWithAppId:[NSString stringWithUTF8String:QQId] appSecret:nil];
    }
    
    void _PlatformInitWeibo(char * weiboId, char * redirectUrl)
    {
        KSShare *share = shareInstance();
        [share initializeSinaWeiboWithAppId:[NSString stringWithUTF8String:weiboId] appSecret:nil redirectUri:[NSString stringWithUTF8String:redirectUrl]];
    }
    
    // 三方平台分享
    // 微信
    void _PlatformShareMessage(char * content,char * title,char * url,char * imageName)
    {
        KSShare *share = shareInstance();

        if ([KSShare isWeChatInstalled]) {
            NSString *image = imageName!=nil?[NSString stringWithUTF8String:imageName]:nil;
            [share sendWechatMessage:[NSString stringWithUTF8String:content] title:[NSString stringWithUTF8String:title] url:[NSString stringWithUTF8String:url] image:[UIImage imageNamed:image]];
        }
        else
        {
            NSLog(@"请安装微信或配置LSApplicationQueriesSchemes");
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"请先安装微信" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert show];
        }
    }
    
    // 微信朋友圈
    void _PlatformShareFriends(char * content,char * title,char * url,char * imageName)
    {
        KSShare *share = shareInstance();

        if ([KSShare isWeChatInstalled]) {
            NSString *image = imageName!=nil?[NSString stringWithUTF8String:imageName]:nil;
            [share sendWechatFriends:[NSString stringWithUTF8String:content] title:[NSString stringWithUTF8String:title] url:[NSString stringWithUTF8String:url] image:[UIImage imageNamed:image]];
        }
        else
        {
            NSLog(@"请安装微信或配置LSApplicationQueriesSchemes");
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"请先安装微信" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert show];
        }
    }
    
    // 微博
    void _PlatformShareWeibo(char * content,char * title,char * url,char * imageName)
    {
        KSShare *share = shareInstance();
        if ([KSShare isWeiboInstalled]) {
            NSString *image = imageName!=nil?[NSString stringWithUTF8String:imageName]:nil;
            [share sendSinaWeibo:[NSString stringWithUTF8String:content] title:[NSString stringWithUTF8String:title] url:[NSString stringWithUTF8String:url] image:[UIImage imageNamed:image]];
        } else {
            NSLog(@"请安装微博或配置LSApplicationQueriesSchemes");
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"请先安装微博" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert show];
        }
    }
    
    // QQ空间
    void _PlatformShareQQSpace(char * content,char * title,char * url,char * imageName)
    {
        KSShare *share = shareInstance();
        if ([KSShare isQQInstalled]) {
            NSString *image = imageName!=nil?[NSString stringWithUTF8String:imageName]:nil;
            [share sendQQZone:[NSString stringWithUTF8String:content] title:[NSString stringWithUTF8String:title] url:[NSString stringWithUTF8String:url] image:[UIImage imageNamed:image]];
        } else {
            NSLog(@"请安装QQ或配置LSApplicationQueriesSchemes");
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"请先安装QQ" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert show];
        }
    }
    
    // QQ
    void _PlatformShareQQ(char * content,char * title,char * url,char * imageName)
    {
        KSShare *share = shareInstance();
        if ([KSShare isQQInstalled]) {
            NSString *image = imageName!=nil?[NSString stringWithUTF8String:imageName]:nil;
            [share sendQQ:[NSString stringWithUTF8String:content] title:[NSString stringWithUTF8String:title] url:[NSString stringWithUTF8String:url] image:[UIImage imageNamed:image]];
        } else {
            NSLog(@"请安装QQ或配置LSApplicationQueriesSchemes");
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"请先安装QQ" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert show];
        }
    }

    void _PlatformStartRecording()
    {
        [[KSVoice shareInstance] StartRecording];
    }
    void _PlatformStopRecording()
    {
        [[KSVoice shareInstance] StopRecording];
    }
    void _PlatformPlayRecordedFile(char * _fileID)
    {
        NSString * _fileIDs = [NSString stringWithUTF8String:_fileID];
        if (_fileIDs&&![_fileIDs isEqualToString:@""]) {
            [[KSVoice shareInstance] PlayRecordedFile:[_fileIDs copy]];
        }
    }
    void _PlatformStopPlayFile()
    {
        [[KSVoice shareInstance] StopPlayFile];
    }
    
    void _PlatforminitSpeechToText()
    {
        //进行语音翻译前，需要先切换后，再重新录制。才能翻译
        [[KSVoice shareInstance] initSpeechToText];
    }
    void _PlatformStartSpeech()
    {
        //进行语音翻译前，需要先切换后，再重新录制。才能翻译
        [[KSVoice shareInstance] StartSpeech];
    }
    void _PlatformSpeechToText(char * _fileID)
    {
        NSString * _fileIDs = [NSString stringWithUTF8String:_fileID];
        if (_fileIDs&&![_fileIDs isEqualToString:@""]) {
            [[KSVoice shareInstance] SpeechToText:[_fileIDs copy]];
        }
    }
    
    KSShare *shareInstance()
    {
        if (!shareInit) {
            shareInit = [[KSShare alloc] init];
        }
        return shareInit;
    }
    
    NSString * jsonStr(id source)
    {
        NSData *data = [NSJSONSerialization dataWithJSONObject:source options:NSJSONWritingPrettyPrinted error:nil];
        NSString *jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        
        NSString *mutStr = checkJsonStr(jsonStr);
        return mutStr;
    }
    
    // 去掉jsonString中的空格与回车
    NSString * checkJsonStr(NSString *source)
    {
        NSMutableString *mutStr = [NSMutableString stringWithString:source];
        NSRange range = {0,source.length};
        [mutStr replaceOccurrencesOfString:@" "withString:@""options:NSLiteralSearch range:range];
        NSRange range2 = {0,mutStr.length};
        [mutStr replaceOccurrencesOfString:@"\n"withString:@""options:NSLiteralSearch range:range2];
        return mutStr;
    }
    
    - (void)dealloc
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:KSLoginNotif object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:KSLogoutNotif object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:KSPaymentNotif object:nil];
    }
    
#if defined(__cplusplus)
    
}
#endif

@end
