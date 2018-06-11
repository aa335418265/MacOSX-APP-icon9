//
//  BMAPIRequest.h
//  icons9
//
//  Created by fenglh on 2018/6/11.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BMURLResponse.h"


static const BOOL kBMIsTestEnvironment = YES;

typedef void(^BMAPIRequestCallback)(BMURLResponse *response);
@interface BMAPIRequest : NSObject
- (NSNumber *)generateRequestId;
+ (instancetype)sharedInstance;

- (NSInteger)callGETWithParams:(NSDictionary *)params
                       headers:(NSDictionary *)headers
                           url:(NSString *)url
                   queryString:(NSString *)queryString
                       apiName:(NSString *)apiName
                      progress:(void(^)(NSProgress * progress,NSInteger requestId))progress
                       success:(BMAPIRequestCallback)success
                       failure:(BMAPIRequestCallback)failure;

@end
