//
//  BMIconGroupModel.h
//  icons9
//
//  Created by 冯立海 on 2018/3/6.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BMIconModel.h"


typedef NS_ENUM(NSUInteger, BMImageType) {
    BMImageTypeNone = 0,
    BMImageTypeSVG = 1 << 0,
    BMImageTypePNG = 1 << 1,
    BMImageTypeJPG = 1 << 2,
    BMImageTypeAll = BMImageTypeSVG | BMImageTypePNG | BMImageTypeJPG,
};


@interface BMIconGroupModel : NSObject


@property (nonatomic, strong) NSString *groupName;  //组名
@property (nonatomic, strong) NSString *groupPath;  //组路径

- (NSArray <BMIconModel *> *)allObjects ;
- (NSArray <BMIconModel *> *)objectsWithType:(BMImageType)type;

- (NSArray <BMIconModel *> *)copyFilesFromPaths:(NSArray <NSString *> *)paths;

@end
