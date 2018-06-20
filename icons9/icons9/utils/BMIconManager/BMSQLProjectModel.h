//
//  BMSQLProjectModel.h
//  icons9
//
//  Created by fenglh on 2018/6/14.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BMIconModel.h"

@interface BMSQLProjectModel : NSObject
@property (nonatomic, strong) NSString *projectId; ///< id
@property (nonatomic, strong) NSString *projectName; ///< 项目名称
@property (nonatomic, strong) NSString *projectHash; ///< 项目哈希
@property (nonatomic, strong) NSString *projectPicUrl; ///< 项目图片url
@property (nonatomic, strong) NSString *projectLocalPath;  //项目本地路径


- (NSArray <BMIconModel *> *)allObjects ;
- (NSArray <BMIconModel *> *)objectsWithType:(BMImageType)type;
- (NSArray <BMIconModel *> *)copyFilesFromPaths:(NSArray <NSString *> *)paths;

@end
