//
//  BMSQLProjectModel.h
//  icons9
//
//  Created by fenglh on 2018/6/14.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BMSQLProjectModel : NSObject
@property (nonatomic, assign) NSInteger projectId; ///< id
@property (nonatomic, strong) NSString *projectName; ///< 项目名称
@property (nonatomic, strong) NSString *projectHash; ///< 项目哈希
@property (nonatomic, strong) NSString *projectLocalPath;  //项目本地路径
@end
