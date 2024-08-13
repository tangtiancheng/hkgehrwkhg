//
//  XMGDownLoader.m
//  XMGDownLoader
//
//  Created by 小码哥 on 2017/1/8.
//  Copyright © 2017年 xmg. All rights reserved.
//

#import "XMGDownLoader.h"
#import "XMGFileTool.h"

#define kTmpPath NSTemporaryDirectory()


@interface XMGDownLoader () <NSURLSessionDataDelegate>

{
    long long _tmpSize;
    long long _totalSize;
}

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;

@property (nonatomic, copy) NSString *downLoadingPath;
//这个是写数据拼数据用的
@property (nonatomic, strong) NSOutputStream *outputStream;

//是否开始有拉取到第一段数据了
@property (nonatomic, assign) BOOL isStarDownloadData;

@end


@implementation XMGDownLoader


- (instancetype)init {
    if(self = [super init]) {
    }
    return self;
}
    
- (NSURLSession *)session {
    if (!_session) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _session;
}
    
    
- (void)downLoader:(NSURL *)url {
    self.isStarDownloadData = NO;
    NSString *fileName = url.lastPathComponent;
    self.downLoadingPath = [kTmpPath stringByAppendingPathComponent:fileName];
    //这里为了方便测试,再次点击下载,如果发现downLoadingPath存在,那就删除掉
    if ([XMGFileTool fileExists:self.downLoadingPath]) {
        //全部复原清空
        [self.dataTask cancel];
        self.dataTask = nil;
        [self.outputStream close];
        self.outputStream = nil;
        [XMGFileTool removeFile:self.downLoadingPath];
        _tmpSize = 0;
        _totalSize = 0;
        [_session finishTasksAndInvalidate];
    }
    
    
    // 从0字节开始请求资源
    [self downLoadWithURL:url offset:0];
    
}

#pragma mark - 协议方法

// 第一次接受到相应的时候调用(响应头, 并没有具体的资源内容)
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {

    // 取资源总大小
    // 1. 从  Content-Length 取出来
    // 2. 如果 Content-Range 有, 应该从Content-Range里面获取
    
    _totalSize = [response.allHeaderFields[@"Content-Length"] longLongValue];
    NSString *contentRangeStr = response.allHeaderFields[@"Content-Range"];
    if (contentRangeStr.length != 0) {
        _totalSize = [[contentRangeStr componentsSeparatedByString:@"/"].lastObject longLongValue];
    }
    
    
    // 继续接受数据
    // 确定开始下载数据
    self.outputStream = [NSOutputStream outputStreamToFileAtPath:self.downLoadingPath append:YES];
    [self.outputStream open];
    completionHandler(NSURLSessionResponseAllow);
    
}
static NSInteger i = 0;

//下载到资源了,多次调用,直到下载完毕
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    
    //下载数据写进downLoadingPath
    [self.outputStream write:data.bytes maxLength:data.length];
    
    _tmpSize = [XMGFileTool fileSize:self.downLoadingPath];
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(downloadData:)]) {
        //下载大于等于400K的时候 或者 短音频低于400M的等下载完 再去播
        if(self.isStarDownloadData == NO && (_tmpSize > 400 * 1024 || _tmpSize >= _totalSize)) {
            self.isStarDownloadData = YES;
            //这里我也不知道为啥调用一次,就能把那么长一首歌全播下来,按理来说,这里会多次收到下载数据,应该是一小段一小段数据下载下来的.理论上应该一开始只播放几秒. 所以猜测可能和NSOutputStream这种流的方式写入文件有关系.   如果用[data WriteToFile]这种就不行
            [self.delegate downloadData:self.downLoadingPath];
        }
    }
    
    NSLog(@"在接受后续数据%ld",data.length);
//    NSLog(@"%lld", [XMGFileTool fileSize:self.downLoadingPath]);
  
}

// 请求完成的时候调用( != 请求成功/失败)
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    NSLog(@"请求完成");
    
    if (error == nil) {
        // 不一定是成功
        // 数据是肯定可以请求完毕
        // 判断, 本地缓存 == 文件总大小 {filename: filesize: md5:xxx}
        // 如果等于 => 验证, 是否文件完整(file md5 )
        
        if(self.delegate && [self.delegate respondsToSelector:@selector(downloadData:)]) {
            
            if(self.isStarDownloadData == NO ) {
                self.isStarDownloadData = YES;
                [self.delegate downloadData:self.downLoadingPath];
            }
        }
        
        
    } else {
        NSLog(@"取消下载了");
    }
    
    [self.outputStream close];
    
    
    
}


#pragma mark - 私有方法

/**
 根据开始字节, 请求资源
 
 @param url url
 @param offset 开始字节
 */
- (void)downLoadWithURL:(NSURL *)url offset:(long long)offset {
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:0];
    [request setValue:[NSString stringWithFormat:@"bytes=%lld-", offset] forHTTPHeaderField:@"Range"];
    // session 分配的task, 默认情况, 挂起状态
    self.dataTask = [self.session dataTaskWithRequest:request];
    
    [self.dataTask resume];
    
    
    
}







@end
