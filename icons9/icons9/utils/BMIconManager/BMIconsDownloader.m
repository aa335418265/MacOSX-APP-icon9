//
//  BMIconsDownloader.m
//  icons9
//
//  Created by fenglh on 2018/6/25.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#import "BMIconsDownloader.h"
#import <AFNetworking.h>


@interface BMIconsDownloader ()
@property (nonatomic, strong) NSOperationQueue *downQueue; ///< 下载队列
@property (strong, nonatomic) NSMutableDictionary *downloadTaskTable;//task列表，便于之后对task的处理
@end

@implementation BMIconsDownloader

+ (instancetype)sharedInstance {
    static BMIconsDownloader *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[BMIconsDownloader alloc] init];
    });
    return sharedInstance;
}

- (NSOperationQueue *)downQueue {
    if (_downQueue == nil) {
        _downQueue = [[NSOperationQueue alloc] init];
        //设置最大并发操作数，默认-1，表示不进行限制，可进行并发
        _downQueue.maxConcurrentOperationCount = -1;
    }
    return _downQueue;
}

- (void)download:(NSString *)url savePath:(NSString *)path success:(Success)success faild:(Faild)faild {
    if (url == nil || path == nil) {
        NSLog(@"url或者path参数不能为空");
        return;
    }
    NSLog(@"下载url:%@",url);
    NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        //下载文件
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
            NSLog(@"下载进度:%@", downloadProgress.localizedDescription);
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            NSURL *filePath = [NSURL fileURLWithPath:path];
            return filePath;
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            if (!error) {
                NSString *savePath = [NSString stringWithFormat:@"%@",filePath];
                NSLog(@"下载完成，保存路径:%@", savePath);
                [self.downloadTaskTable removeObjectForKey:url];
                success?success():nil;

            }else {
                NSLog(@"下载失败,url=%@",url);
                faild?faild():nil;
            }
        }];
        [task resume];
        self.downloadTaskTable[url] = task;
    }];
    [self.downQueue addOperation:op];
    
    NSLog(@"当前队列操作数：%lu, 操作线程:%@", (unsigned long)[self operationCount],[NSThread currentThread].name);
}


- (NSMutableDictionary *)downloadTaskTable
{
    if (_downloadTaskTable == nil) {
        _downloadTaskTable = [[NSMutableDictionary alloc] init];
    }
    return _downloadTaskTable;
}

//取消下载
- (void)cancelDownloadUrl:(NSString *)url {
    NSURLSessionDataTask *task = self.downloadTaskTable[url];
    if (task) {
        [task cancel];
        [self.downloadTaskTable removeObjectForKey:url];
    }
}

//取消列表下载
- (void)cancelDownloadUrls:(NSArray *)urls
{
    for (NSString *url in urls) {
        [self cancelDownloadUrl:url];
    }
}

//取消所有url下载
- (void)cancelDownloadAll {
    NSArray *allUrls = [self.downloadTaskTable allKeys];
    [self cancelDownloadUrls:allUrls];
}

//当前在队列中的操作数（某个操作执行结束后会自动从这个数组清除）
- (NSArray *)operations{
    return [self.downQueue operations];
}
//当前队列中的操作数
- (NSUInteger)operationCount{
    return [self.downQueue operationCount];
}

@end
