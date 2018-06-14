//
//  BMSQLProjectModel.m
//  icons9
//
//  Created by fenglh on 2018/6/14.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#import "BMSQLProjectModel.h"
#import <SVGKit/SVGKit.h>


@implementation BMSQLProjectModel



- (NSArray <BMIconModel *> *)copyFilesFromPaths:(NSArray <NSString *> *)paths  {
    if (!paths.count) {
        return nil;
    }
    
    NSMutableArray *icons = [NSMutableArray arrayWithCapacity:paths.count];
    NSFileManager *manager = [NSFileManager defaultManager];
    for (NSString *path in paths) {
        BOOL success = [manager copyItemAtPath:path toPath:[self.projectLocalPath stringByAppendingPathComponent:[path lastPathComponent]] error:nil];
        if (success) {
            BMIconModel *model = [BMIconModel modelWithPath:path];
            [icons addObject:model];
        }
    }
    return icons;
}

- (NSArray <BMIconModel *> *)allObjects {
    return [self objectsWithType:BMImageTypeAll];
}


- (NSArray <BMIconModel *> *)objectsWithType:(BMImageType)type {
    
    // 创建文件管理器
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    //遍历文件
    NSArray *contents = [fileMgr contentsOfDirectoryAtPath:self.projectLocalPath error:nil];
    NSMutableArray *images = [NSMutableArray array];
    for (NSString *fileName in contents) {
        if ([BMIconModel getImageType:fileName] & type) {
            NSString *fullPath = [self.projectLocalPath stringByAppendingPathComponent:fileName];
            [images addObject:[BMIconModel modelWithPath:fullPath]];
        }
    }
    return images;
}

@end
