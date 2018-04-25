//
//  HttpDownloadUnit.h
//  RunTimeTest
//
//  Created by 志方 on 2018/4/24.
//  Copyright © 2018年 志方. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum enWordResType{
    RES_TYPE_JPG,
    RES_TYPE_MP3,
    RES_TYPE_FLV,
    RES_TYPE_UNKONW,
}enWordResType;

///http下载任务委托
@class HttpDownloadUnit;
@protocol HttpDownloadUnitDelegate <NSObject>

-(void) HttpDownloadUnitProgress:(HttpDownloadUnit *) object percent:(int)nPercent;
-(void) HttpDownLoadUnitCompleted:(HttpDownloadUnit *) object data:(NSData *) data;
-(void) HttpDownloadUnitError:(HttpDownloadUnit *) object error:(NSError *) error;

@end

@interface HttpDownloadUnit : NSObject<NSURLConnectionDelegate,NSURLConnectionDataDelegate>
{
    NSURLConnection *_conn;
    NSMutableData *_buffer;
    int64_t _byteTotal;
}

@property (nonatomic, copy) NSString *url;
@property (nonatomic, strong) id<HttpDownloadUnitDelegate> delegate;

///方法定义
///根据一个完整url返回一个不包含xxx.xxx.com的相对路径
+(NSString *) relativePath : (NSString *) strUrl;
///根据文件名创建对应的本地路径
+(void) createFolderByPath :(NSString *) strFileName;
///取消
-(void) cancel;
-(void) startCache:(NSString *) strUrl;
-(id) initWithURL: (NSString *) url;

@end
