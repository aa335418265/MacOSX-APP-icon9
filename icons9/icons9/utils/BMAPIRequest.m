//
//  BMAPIRequest.m
//  icons9
//
//  Created by fenglh on 2018/6/11.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#import "BMAPIRequest.h"
#import <AFNetworking.h>
#import "AFHTTPRequestSerializer+addHeaders.h"
#import "BMLoger.h"
#import "NSDictionary+AXNetworkingMethods.h"
#import "NSURLRequest+AIFNetworkingMethods.h"

#define callHttpRequest(MANAGER,REQUEST_METHOD, REQUEST_URL, REQUEST_PARAMS, PROGRESS_CALLBACK, SUCCESS_CALLBACK, FAILURE_CALLBACK)\
{\
NSNumber *requestId = [self generateRequestId];\
@weakify(self);\
NSURLSessionTask *task = [MANAGER REQUEST_METHOD:REQUEST_URL parameters:REQUEST_PARAMS progress:^(NSProgress * _Nonnull uploadProgress) {\
@strongify(self);\
[self callAPIPogress:uploadProgress requestId:[requestId integerValue] progressCallback:progress];\
} success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {\
@strongify(self);\
[self callAPISuccess:task responseObject:responseObject requestId:requestId successCallback:SUCCESS_CALLBACK];\
} failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {\
@strongify(self);\
[self callAPIFailure:task error:error requestId:requestId failureCallback:FAILURE_CALLBACK];\
}];\
task.originalRequest.requestParams = REQUEST_PARAMS;\
self.httpRequestTaskTable[requestId] = task;\
return [requestId integerValue];\
}



@interface BMAPIRequest ()

@property (strong, nonatomic) NSNumber *recordRequestId;

@property (strong, nonatomic) NSMutableDictionary *httpRequestTaskTable;//保存httpRequestTaskTable 的返回值，便于之后对task的处理

@end;
@implementation BMAPIRequest

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceTocke;
    static BMAPIRequest *sharedInstance = nil;
    dispatch_once(&onceTocke, ^{
        sharedInstance = [[BMAPIRequest alloc] init];
    });
    return sharedInstance;
}


//#warning get
- (NSInteger)callGETWithParams:(NSDictionary *)params
                       headers:(NSDictionary *)headers
                           url:(NSString *)url
                   queryString:(NSString *)queryString
                       apiName:(NSString *)apiName
                      progress:(void(^)(NSProgress * progress,NSInteger requestId))progress
                       success:(BMAPIRequestCallback)success
                       failure:(BMAPIRequestCallback)failure
{
    
    NSString *urlString = [self urlString:url queryString:queryString];
    AFHTTPSessionManager *manager = [self sharedSessionManager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html",@"application/json", @"text/json" ,@"text/javascript",@"video/mp4", nil]; // 设置相应的 http header Content-Type
    [manager.requestSerializer addHeaders:headers];
    
    NSMutableURLRequest *request = [manager.requestSerializer requestWithMethod:@"GET" URLString:urlString parameters:params error:NULL];
    [BMLoger logDebugInfoWithRequest:request apiName:apiName url:url requestParams:params httpMethod:@"GET"];
    callHttpRequest(manager, GET, urlString, params, progress, success, failure);

    
}


#pragma mark - 私有方法

- (NSString *)urlString:(NSString *)url queryString:(NSString *)queryString {
    if (queryString && ![queryString isEqualToString:@""]) {
        return [NSString stringWithFormat:@"%@?%@",url,queryString];
    }else {
        return url;
    }
}

/**
 * 生成requestId
 */
- (NSNumber *)generateRequestId
{
    if (_recordRequestId == nil) {
        _recordRequestId = @(1);
    }else if([_recordRequestId integerValue] == NSIntegerMax){
        _recordRequestId = @(1);
    }else{
        _recordRequestId = @([_recordRequestId integerValue] + 1);
    }
    
    return _recordRequestId;
}

/**
 * 调用进度
 */
- (void)callAPIPogress:(NSProgress *)progress requestId:(NSInteger)requestId progressCallback:(void(^)(NSProgress *progress, NSInteger requestId))progressCallback
{
    dispatch_async(dispatch_get_main_queue(), ^{
        progressCallback?progressCallback(progress,requestId):nil;
    });
}

/**
 * API 调用失败
 */
- (void)callAPIFailure:(NSURLSessionTask *)task error:(NSError *)error requestId:(NSNumber *)requestId failureCallback:(BMAPIRequestCallback)failureCallback
{

    NSURLSessionTask *storedTask = self.httpRequestTaskTable[requestId];
    if (storedTask == nil) {
        NSLog(@"接口请求失败！但在接口请求过程中接口被取消掉了，所以忽略该请求!");
    }else{
        [self.httpRequestTaskTable removeObjectForKey:requestId];
    }
    [BMLoger logDebugInfoWithResponse:nil resposeString:nil request:task.originalRequest error:error];
    BMURLResponse *response = [[BMURLResponse alloc] initWithResponseString:nil requestId:requestId request:task.originalRequest response:(NSHTTPURLResponse *)task.response responseData:nil error:error];
    failureCallback?failureCallback(response):nil;
}

/**
 * API 调用成功
 */
- (void)callAPISuccess:(NSURLSessionTask *)task responseObject:(id)responseObject requestId:(NSNumber *)requestId successCallback:(BMAPIRequestCallback)successCallback
{
    NSURLSessionTask *storedTask = self.httpRequestTaskTable[requestId];
    if (storedTask == nil) {
        NSLog(@"接口请求成功！但在接口请求过程中接口被取消掉了，所以忽略该请求!");
        return;
    }else{
        [self.httpRequestTaskTable removeObjectForKey:requestId];
    }
    
    NSString *contentString;
    NSData *responseData;
    
    if ([NSJSONSerialization isValidJSONObject:responseObject]) {
        responseData = [NSJSONSerialization dataWithJSONObject:responseObject options:NSJSONWritingPrettyPrinted error:nil];\
        NSDictionary *responseDictionary = (NSDictionary *)responseObject;
        contentString = responseDictionary.jsonStringEncoded;
    }else{
        contentString = @"(responseObject 不是有效的JSON对象(例如：文件、视频等)，此类型数据不作日志打印输出！)";
        responseData = responseObject;
    }
    
    [BMLoger logDebugInfoWithResponse:(NSHTTPURLResponse *)task.response resposeString:contentString request:task.originalRequest error:NULL];
    BMURLResponse *response = [[BMURLResponse alloc] initWithResponseString:contentString requestId:requestId request:task.originalRequest response:(NSHTTPURLResponse *)task.response responseData:responseData status:BMURLResponseStatusSuccess];
    successCallback?successCallback(response):nil;
    
}

//取消单个请求
- (void)cancelRequestWithRequestId:(NSNumber *)requestID
{
    NSURLSessionDataTask *task = self.httpRequestTaskTable[requestID];
    [task cancel];
    [self.httpRequestTaskTable removeObjectForKey:requestID];
}

//取消所有请求
- (void)cancelRequestWithRequestIdList:(NSArray *)requestIDList
{
    for (NSNumber *requestId in requestIDList) {
        [self cancelRequestWithRequestId:requestId];
    }
}

#pragma mark -  gettters and setters 

- (AFHTTPSessionManager *)sharedSessionManager {
    
    static AFHTTPSessionManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [AFHTTPSessionManager manager];
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
        manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        manager.requestSerializer.timeoutInterval = 20;
    });
    return manager;
    
}

@end
