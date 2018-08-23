//
//  BMIconManager.h
//  icons9
//
//  Created by 冯立海 on 2018/3/6.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BMSQLProjectModel.h"
#import "BMSQLIconModel.h"


typedef void(^CompledBlock)(BOOL success,NSArray <BMSQLProjectModel *> *projects);
typedef void(^CheckSuccess)(NSArray *list);
typedef void(^CheckFailure)(NSError *error);
typedef void(^Success)(NSString *filePath);
typedef void(^Fail)(void);
@interface BMIconManager : NSObject

+ (instancetype)sharedInstance;

- (NSArray <BMSQLProjectModel *>*)queryProjects;
- (NSArray <BMSQLIconModel *>*)querySqlIconsWithProjectId:(NSString *)projectId;
- (NSArray <BMIconModel *>*)allIcons:(NSString *)projectId imageType:(BMImageType)imageType;







- (BOOL)createGroupWithName:(NSString *)name;



//本地数据校验
- (NSArray *)getProjectHashList:(NSString *)projectId;
- (NSString *)caculateLocalUpdateMD5InProject:(NSString *)projectId;

//同步远程数据
- (void)updateProjects:(CompledBlock)complete;
- (void)getIconsUpdateList:(NSString *)projectHash projectId:(NSString *)projectId success:(CheckSuccess )success failure:(CheckFailure)failure;
- (void)updateIcons:(NSArray *)iconHashList  projectName:(NSString *)projectName success:(Success)success fail:(Fail)fail;



@end
