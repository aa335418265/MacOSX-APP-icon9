//
//  BMIconsDownloader.h
//  icons9
//
//  Created by fenglh on 2018/6/25.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^DownloadSuccess) (void);
typedef void (^DownloadFaild) (void);
@interface BMIconsDownloader : NSObject
+ (instancetype)sharedInstance;


//下载
- (void)download:(NSString *)url savePath:(NSString *)path success:(DownloadSuccess)success faild:(DownloadFaild)faild;

//取消下载
- (void)cancelDownloadUrl:(NSString *)url;

//取消列表下载
- (void)cancelDownloadUrls:(NSArray *)urls;

//取消所有url下载
- (void)cancelDownloadAll;

//当前在队列中的操作数（某个操作执行结束后会自动从这个数组清除）
- (NSArray *)operations;


//当前队列中的操作数
- (NSUInteger)operationCount;
@end
