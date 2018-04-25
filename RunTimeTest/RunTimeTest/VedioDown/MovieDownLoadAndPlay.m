//
//  MovieDownLoadAndPlay.m
//  RunTimeTest
//
//  Created by 志方 on 2018/4/24.
//  Copyright © 2018年 志方. All rights reserved.
//

#import "MovieDownLoadAndPlay.h"
#import <AVFoundation/AVFoundation.h>
#import "UIButton+EnlargeTouchAre.h"

@interface MovieDownLoadAndPlay ()<NSURLSessionDownloadDelegate>
{
    CGFloat screenWidth;
}

///视频下载
@property (nonatomic, strong) NSURLSessionDownloadTask *downTask;
///下载进度
@property (nonatomic, strong) UIProgressView *progress;
@property (nonatomic, strong) AVPlayer *player;

@end

@implementation MovieDownLoadAndPlay

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    screenWidth = [UIScreen mainScreen].bounds.size.width;
    [self setButton:CGRectMake(screenWidth/2 - 25, 100, 100, 40) title:@"下载小电影" action:@selector(movieAction)];
    self.progress = [[UIProgressView alloc] initWithFrame:CGRectMake(50, 160, screenWidth-100, 30)];
    [self.view addSubview:_progress];
    
    [self setButton:CGRectMake(screenWidth/2 - 25, 200, 100, 40) title:@"暂停下载" action:@selector(pauseDownload)];
    [self setButton:CGRectMake(screenWidth/2 - 25, 250, 100, 40) title:@"继续下载" action:@selector(continueDownload)];
}

-(void) movieAction {
    NSURL *url = [NSURL URLWithString:@"http://hc25.aipai.com/user/656/20448656/6167672/card/25033081/card.mp4?l=a"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    // 参数1: 默认配置
    // 参数2: 代理人 //协议 <NSURLSessionDownloadDelegate>
    // 参数3: 再哪个线程内执行(当前选择主线程)
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    self.downTask = [session downloadTaskWithRequest:request];
    ///开始下载
    [self.downTask resume];
}

///播放
-(void) playWithFilePath : (NSString *) filePath {
    NSURL *url = [NSURL fileURLWithPath:filePath];
    self.player = [AVPlayer playerWithURL:url];
    ///显示视频
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    playerLayer.frame = CGRectMake(50, 360, screenWidth -100,300);
    [self.view.layer addSublayer:playerLayer];
    
    ///播放
    [self.player play];
}

#pragma mark 视频下载delegate
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    NSLog(@"下载过程中多次调用，每次下载不一定多大的数据");
    NSLog(@"本次下载大小%.2fKB 已经下载大小 %.2fKB  总大小%.2fKB",bytesWritten/1024.0,totalBytesWritten/1024.0,totalBytesExpectedToWrite/1024.0);
    self.progress.progress = (CGFloat)totalBytesWritten/totalBytesExpectedToWrite;
}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSLog(@"下载结束");
    ///获取本地对应位置的路径
    NSString *cach = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    ///拼接文件的名字(系统默认)
    NSString *file = [cach stringByAppendingPathComponent:downloadTask.response.suggestedFilename];
    NSFileManager *fileMan = [NSFileManager defaultManager];
    ///将下载的数据临时文件移到本地路径
    [fileMan moveItemAtPath:location.path toPath:file error:nil];
    ///调用视频处理方法播放视频
    [self playWithFilePath:file];
}

-(void) pauseDownload {
    if (NSURLSessionTaskStateRunning == self.downTask.state) {
        [self.downTask suspend];
    }
}

-(void) continueDownload {
    if (NSURLSessionTaskStateSuspended == self.downTask.state) {
        [self.downTask resume];
    }
}

-(void) setButton: (CGRect) rect title: (NSString *) title action:(SEL) action {
    UIButton *push = [UIButton buttonWithType:UIButtonTypeSystem];
    [push setTitle:title forState:UIControlStateNormal];
    push.frame = rect;
    push.backgroundColor = [UIColor orangeColor];
//    [push setEnlargeEdgeWithTop:30 right:30 bottom:30 left:30];
    
    [push addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:push];
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
