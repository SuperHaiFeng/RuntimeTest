//
//  ViewController2.m
//  RunTimeTest
//
//  Created by 志方 on 2018/3/22.
//  Copyright © 2018年 志方. All rights reserved.
//

#import "ViewController2.h"
#import <Vision/Vision.h>
#import <DeviceCheck/DeviceCheck.h>
#import <PDFKit/PDFKit.h>
#import <AVFoundation/AVFoundation.h>

static id invokeBlock(id block, NSArray *arguments) {
    if (block == nil) {
        return nil;
    }
    
    id target = [block copy];
    const char *_Block_signature(void *);
    const char *signature = _Block_signature((__bridge void *)target);
    
    NSMethodSignature *methodSignature = [NSMethodSignature signatureWithObjCTypes:signature];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    ///invocation有1个隐藏参数，所以argument从1开始
    if ([arguments isKindOfClass:[NSArray class]]) {
        NSInteger count = MIN(arguments.count, methodSignature.numberOfArguments - 1);
        for (int i = 0; i < count; i++) {
            const char *type = [methodSignature getArgumentTypeAtIndex:1 + i];
            NSString *typeStr = [NSString stringWithUTF8String:type];
            if ([typeStr containsString:@"\""]) {
                type = [typeStr substringToIndex:1].UTF8String;
            }
            
            ///需要做参数类型判断然后解析成对应类型，这里默认所有参数均为oc对象
            if (strcmp(type, "@") == 0) {
                id argument = arguments[i];
                [invocation setArgument:&argument atIndex:1 + i];
            }
        }
    }
    
    [invocation invoke];
    
    id retureVal;
    const char *type = methodSignature.methodReturnType;
    NSString *returnType = [NSString stringWithUTF8String:type];
    if ([returnType containsString:@"\""]) {
        type = [returnType substringToIndex:1].UTF8String;
    }
    if (strcmp(type, "@") == 0) {
        [invocation getReturnValue:&retureVal];
    }
    ///需要做返回类型判断，比如返回值为常量需要包装成对象，这里仅以最简单的‘@’为例
    return retureVal;
}

@interface ViewController2 ()<PDFViewDelegate,AVAudioRecorderDelegate>

@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) AVAudioPlayer *player;///只能播放本地文件
@property (nonatomic, strong) NSTimer *timer;
@property (weak, nonatomic) IBOutlet UIProgressView *progress;

@end

@implementation ViewController2

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    ///获取本机token
    DCDevice *device = [DCDevice currentDevice];
    [device generateTokenWithCompletionHandler:^(NSData * _Nullable token, NSError * _Nullable error) {
        NSLog(@"======%@",token);
    }];
//    [self loadPDFFile];
    
    id returnVal = invokeBlock((id)^(NSString *a, NSString *b) {
        return [NSString stringWithFormat:@"%@   %@",a,b];
    }, @[@"01",@"jackl"]);
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(audioPowerChange) userInfo:nil repeats:YES];
    self.timer.fireDate = [NSDate distantFuture];///暂停定时器
    [self setAVAudioSession];
    [self initAudioRecorder];
}

#pragma mark - 使用AVAudioRecord录音与播放
///获取录音存放路径
-(NSString *) getSaveFilePath {
    NSString *urlStr = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    urlStr = [urlStr stringByAppendingPathComponent:@"recorder.caf"];
    return urlStr;
}
///初始化音视频
-(void) setAVAudioSession {
    ///获取音频会话
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    ///设置为播放和录音状态，以便可以在录制完之后播放录音
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:NULL];
    ///激活修改
    [audioSession setActive:YES error:NULL];
}
///初始化音频播放器
-(void) initAudioPlayer {
    NSString *filePath = [self getSaveFilePath];
    NSURL *url = [NSURL fileURLWithPath:filePath];
    NSError *error = nil;
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    if (error) {
        return;
    }
    player.numberOfLoops = 0;
    [player prepareToPlay];
    self.player = player;
    
}
///初始化录音器
-(void) initAudioRecorder {
    NSString *filePath = [self getSaveFilePath];
    NSURL *url = [NSURL fileURLWithPath:filePath];
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    //设置录音格式
    [settings setObject:@(kAudioFormatLinearPCM) forKey:AVFormatIDKey];
    //设置录音采样率，8000是电话采样率，对于一般录音已经够了
    [settings setObject:@(8000) forKey:AVSampleRateKey];
    //设置通道,这里采用单声道
    [settings setObject:@(1) forKey:AVNumberOfChannelsKey];
    //每个采样点位数,分为8、16、24、32
    [settings setObject:@(8) forKey:AVLinearPCMBitDepthKey];
    //是否使用浮点数采样
    [settings setObject:@(YES) forKey:AVLinearPCMIsFloatKey];
    
    NSError *error = nil;
    AVAudioRecorder *record = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
    if (error) {
        return;
    }
    record.delegate = self;
    record.meteringEnabled = YES; //如果要监控声波，必须设为YES
    [record prepareToRecord];
    self.recorder = record;
}
///进度条模拟声波状态
-(void) audioPowerChange {
    [self.recorder updateMeters];
    ///去的第一个通道的音频，注意音频强度范围是-160.0到0
    float power = [self.recorder averagePowerForChannel:0];
    CGFloat progress = (1.0/160.0)*(power+160.0);
    self.progress.progress = progress;
}
///开始录音(接着录音)
- (IBAction)record:(id)sender {
    if (![self.recorder isRecording]) {
        [self.recorder record];
        self.timer.fireDate = [NSDate distantPast];///灰度定时器
    }
}
///暂停录音
- (IBAction)pauseRecord:(id)sender {
    if (![self.recorder isRecording]) {
        [self.recorder pause];
        self.timer.fireDate = [NSDate distantFuture];
    }
}
///结束录音
- (IBAction)stopRecord:(id)sender {
    [self.recorder stop];
    self.timer.fireDate = [NSDate distantFuture];
    self.progress.progress = 0.0;
}
-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    [self initAudioPlayer];
    [self.player play];
}

///加载pdf文件
-(void) loadPDFFile{
    ///加载pdf文件
    PDFView *pdf = [[PDFView alloc] initWithFrame:self.view.frame];
    pdf.delegate = self;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"toefl_student_test_prep_planner" ofType:@"pdf"];
    PDFDocument *document = [[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath:path]];
    pdf.document = document;
    
    [pdf setMaxScaleFactor:1];
    [pdf setMinScaleFactor:1];
    [pdf setContentMode:UIViewContentModeScaleAspectFit];
    [self.view addSubview:pdf];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
