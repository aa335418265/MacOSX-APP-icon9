//
//  BMIconModel.h
//  icons9
//
//  Created by 冯立海 on 2018/3/6.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BMIconModel : NSObject
@property (nonatomic, strong) NSString *name;       //文件名
@property (nonatomic, strong) NSImage *image;       //图片
@property (nonatomic, strong) NSString *path;     //路径
@property (nonatomic, strong) NSString *exension; //扩展名呢

+ (instancetype)modelWithPath:(NSString *)path;
@end
