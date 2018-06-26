//
//  BMIconManager.h
//  icons9
//
//  Created by 冯立海 on 2018/3/6.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BMSQLProjectModel.h"


typedef void(^CompledBlock)(BOOL success,NSArray <BMSQLProjectModel *> *projects);
typedef void(^CheckSuccess)(NSArray *list);
typedef void(^CheckFailure)(NSError *error);
@interface BMIconManager : NSObject

+ (instancetype)sharedInstance;

- (NSArray <BMSQLProjectModel *> *)allGroups;
- (BOOL)createGroupWithName:(NSString *)name;



//本地数据校验
- (NSArray *)getLocalIconsMD5ListInProject:(NSString *)projectId;
- (NSString *)caculateLocalUpdateMD5InProject:(NSString *)projectId;

//同步远程数据
- (void)updateProjects:(CompledBlock)complete;
- (void)getIconsUpdateList:(NSString *)projectHash projectId:(NSString *)projectId success:(CheckSuccess )success failure:(CheckFailure)failure;
- (void)updateIcons:(NSArray *)iconHashList  projectName:(NSString *)projectName;


@end
