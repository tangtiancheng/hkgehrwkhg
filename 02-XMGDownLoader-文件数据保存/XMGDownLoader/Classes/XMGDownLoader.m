//
//  XMGDownLoader.m
//  XMGDownLoader
//
//  Created by 小码哥 on 2017/1/8.
//  Copyright © 2017年 xmg. All rights reserved.
//

#import "XMGDownLoader.h"
#import "XMGFileTool.h"

#define kCachePath NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject
#define kTmpPath NSTemporaryDirectory()


@interface XMGDownLoader () <NSURLSessionDataDelegate>
{
    long long _tmpSize;
    long long _totalSize;
}
@property (nonatomic, strong) NSURLSession *session;
    
    @property (nonatomic, copy) NSString *downLoadedPath;
    @property (nonatomic, copy) NSString *downLoadingPath;
    @property (nonatomic, strong) NSOutputStream *outputStream;
    
@end

@implementation XMGDownLoader

    
    - (NSURLSession *)session {
        if (!_session) {
             NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
            _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        }
        return _session;
    }
    
    
- (void)downLoader:(NSURL *)url {
    
    // 图片
    // 让用户, 拿着杯子喝水(瓶口, 用户)
    // 用户, 从杯底 喝水, 从杯子中间喝水
    
    
    // 1. 文件的存放
    // 下载ing => temp + 名称
    // MD5 + URL 防止重复资源
    // a/1.png md5 -
    // b/1.png
    // 下载完成 => cache + 名称
    NSString *fileName = url.lastPathComponent;
    
    self.downLoadedPath = [kCachePath stringByAppendingPathComponent:fileName];
    self.downLoadingPath = [kTmpPath stringByAppendingPathComponent:fileName];
    
    
    
    // 1. 判断, url地址, 对应的资源, 是下载完毕,(下载完成的目录里面,存在这个文件)
    // 1.1 告诉外界, 下载完毕, 并且传递相关信息(本地的路径, 文件的大小)
    //     return
    if ([XMGFileTool fileExists:self.downLoadedPath]) {
        // UNDO: 告诉外界, 已经下载完成;
        NSLog(@"已经下载完成");
        
        return;
    }
    
    
    
    
    // 2. 检测, 临时文件是否存在
    // 2.2 不存在: 从0字节开始请求资源
    //     return
    if (![XMGFileTool fileExists:self.downLoadingPath]) {
        // 从0字节开始请求资源
        [self downLoadWithURL:url offset:0];
        return;
    }
    
    
    // 2.1 存在, : 直接, 以当前的存在文件大小, 作为开始字节, 去网络请求资源
    //     HTTP: rang: 开始字节-
    //    正确的大小 1000   1001
    
    //   本地大小 == 总大小  ==> 移动到下载完成的路径中
    //    本地大小 > 总大小  ==> 删除本地临时缓存, 从0开始下载
    //    本地大小 < 总大小 => 从本地大小开始下载
    
    // 获取本地大小
    _tmpSize = [XMGFileTool fileSize:self.downLoadingPath];
    
    [self downLoadWithURL:url offset:_tmpSize];
    
    
    // 文件的总大小获取
    // 发送网络请求
    // 同步 / 异步
    
    //        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    //        request.HTTPMethod = @"HEAD";
    //        NSHTTPURLResponse *response = nil;
    //        NSError *error = nil;
    //        [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    //        // 资源已经下载完毕了❌
    //        // 我们需要的是响应头
    //        if (error == nil) {
    //
    //            NSLog(@"%@", response.allHeaderFields[@"Content-Length"]);
    //        }
    
}


#pragma mark - 协议方法
    
    // 第一次接受到相应的时候调用(响应头, 并没有具体的资源内容)
    // 通过这个方法, 里面, 系统提供的回调代码块, 可以控制, 是继续请求, 还是取消本次请求
    -(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
        
        // Content-Length 请求的大小 != 资源大小
//        100 -
        // 总大小 19061805
//        19061705
        // 本地缓存大小
        
        // 取资源总大小
        // 1. 从  Content-Length 取出来
        // 2. 如果 Content-Range 有, 应该从Content-Range里面获取
        
        _totalSize = [response.allHeaderFields[@"Content-Length"] longLongValue];
        NSString *contentRangeStr = response.allHeaderFields[@"Content-Range"];
        if (contentRangeStr.length != 0) {
            _totalSize = [[contentRangeStr componentsSeparatedByString:@"/"].lastObject longLongValue];
        }
        
        
        // 比对本地大小, 和 总大小
        if (_tmpSize == _totalSize) {
            
            // 1. 移动到下载完成文件夹
            NSLog(@"移动文件到下载完成");
            [XMGFileTool moveFile:self.downLoadingPath toPath:self.downLoadedPath];
            
            // 2. 取消本次请求
            completionHandler(NSURLSessionResponseCancel);
            return;
        }
        
 
        if (_tmpSize > _totalSize) {
            
            // 1. 删除临时缓存
            NSLog(@"删除临时缓存");
            [XMGFileTool removeFile:self.downLoadingPath];
            // 2. 从0 开始下载
            NSLog(@"重新开始下载");
            [self downLoader:response.URL];
//             [self downLoadWithURL:response.URL offset:0];
            // 3. 取消请求
            completionHandler(NSURLSessionResponseCancel);
            
            return;
            
        }
        
        
        // 继续接受数据
        // 确定开始下载数据
        self.outputStream = [NSOutputStream outputStreamToFileAtPath:self.downLoadingPath append:YES];
        [self.outputStream open];
        completionHandler(NSURLSessionResponseAllow);
        
    }
    
    
    // 当用户确定, 继续接受数据的时候调用
    - (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
    {

        [self.outputStream write:data.bytes maxLength:data.length];
        
        NSLog(@"在接受后续数据");
    }
    
    // 请求完成的时候调用( != 请求成功/失败)
    - (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
        
        NSLog(@"请求完成");
        
        if (error == nil) {
            
            // 不一定是成功
            // 数据是肯定可以请求完毕
            // 判断, 本地缓存 == 文件总大小 {filename: filesize: md5:xxx}
            // 如果等于 => 验证, 是否文件完整(file md5 )
            
            //
            
            
            
        }else {
            NSLog(@"有问题");
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
       NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:request];
       
       [dataTask resume];
       
        
        
    }
    
    
    
    
    
    
    
@end
