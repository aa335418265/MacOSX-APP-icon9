//
//  BMIconModel.m
//  icons9
//
//  Created by 冯立海 on 2018/3/6.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#import "BMIconModel.h"
#import <AppKit/AppKit.h>
@implementation BMIconModel
+ (instancetype)modelWithPath:(NSString *)path {
    


    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path];
    if (!exists) {
        return nil;
    }
    BMIconModel *model = [[BMIconModel alloc] init];
    model.path = path;
    model.image = [[NSImage alloc] initWithContentsOfFile:path] ;
    model.exension = [path pathExtension];
    model.name = [path lastPathComponent];
    return model;
}
@end
