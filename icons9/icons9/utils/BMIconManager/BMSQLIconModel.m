//
//  BMSQLIconModel.m
//  icons9
//
//  Created by fenglh on 2018/6/21.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#import "BMSQLIconModel.h"
#import <MJExtension.h>
@implementation BMSQLIconModel

- (instancetype)init {
    if (self = [super init]) {
        [BMSQLIconModel mj_setupReplacedKeyFromPropertyName:^NSDictionary *{
            return @{
                     @"totalMd5":@"hash",
                     @"iconId":@"id"
                     };
        }];
    }
    return self;
}
@end
