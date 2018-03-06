//
//  BMIconGroupModel.m
//  icons9
//
//  Created by 冯立海 on 2018/3/6.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#import "BMIconGroupModel.h"
#import <AppKit/AppKit.h>

@implementation BMIconGroupModel


- (NSArray <BMIconModel *> *)allObjects {
    // 创建文件管理器
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    
    
    //遍历文件
    NSArray *contents = [fileMgr contentsOfDirectoryAtPath:self.groupPath error:nil];
    NSMutableArray *allImages = [NSMutableArray array];
    
    for (NSString *fileName in contents) {
        if ([[fileName pathExtension] isEqualToString:@"svg"] ||
            [[fileName pathExtension] isEqualToString:@"png"] ||
            [[fileName pathExtension] isEqualToString:@"jpg"]) {
            NSString *fullPath = [self.groupPath stringByAppendingPathComponent:fileName];
            [allImages addObject:[BMIconModel modelWithPath:fullPath]];
        }
    }
    
    return allImages;
}

- (NSArray <BMIconModel *> *)copyFilesFromPaths:(NSArray <NSString *> *)paths  {
    if (!paths.count) {
        return nil;
    }
    
    NSMutableArray *icons = [NSMutableArray arrayWithCapacity:paths.count];
    NSFileManager *manager = [NSFileManager defaultManager];
    for (NSString *path in paths) {
        BOOL success = [manager copyItemAtPath:path toPath:[self.groupPath stringByAppendingPathComponent:[path lastPathComponent]] error:nil];
        if (success) {
            BMIconModel *model = [BMIconModel modelWithPath:path];
            [icons addObject:model];
        }
    }
    return icons;
}

@end
