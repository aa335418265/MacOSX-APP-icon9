//
//  BMIconManager.h
//  icons9
//
//  Created by 冯立海 on 2018/3/6.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BMIconGroupModel.h"


typedef void(^CompledBlock)(BOOL success,NSArray <BMIconGroupModel *> *projects);
@interface BMIconManager : NSObject

+ (instancetype)sharedInstance;

- (NSArray <BMIconGroupModel *> *)allGroups;
- (BOOL)createGroupWithName:(NSString *)name;
- (BOOL)checkUpdate;

- (void)updateProjects:(CompledBlock)complete;
- (void)checkProjectIconsUpdate:(NSString *)projectHash projectId:(NSString *)projectId;



@end
