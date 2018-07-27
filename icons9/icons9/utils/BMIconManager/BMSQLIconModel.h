//
//  BMSQLIconModel.h
//  icons9
//
//  Created by fenglh on 2018/6/21.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BMSQLIconModel : NSObject

@property (nonatomic, strong) NSString *iconId; ///< 素材id
@property (nonatomic, strong) NSString *iconName; ///< 素材名字
@property (nonatomic, strong) NSString *projectIds; ///< 项目id
//@property (nonatomic, strong) NSString *projectName; ///< 项目名字

@property (nonatomic, strong) NSString *svgUrl; ///< 素材 svg url
@property (nonatomic, strong) NSString *pngExtraUrl; ///< 素材 png url
@property (nonatomic, strong) NSString *pngDoubleUrl; ///< 素材 png2x url
@property (nonatomic, strong) NSString *pngTripleUrl; ///< 素材 png3x url



@property (nonatomic, strong) NSString *svgLocalPath; ///< 素材 本地路径
@property (nonatomic, strong) NSString *pngExtraLocalPath; ///< 素材 本地路径
@property (nonatomic, strong) NSString *pngDoubleLocalPath; ///< 素材 本地路径
@property (nonatomic, strong) NSString *pngTripleLocalPath; ///< 素材 本地路径


@property (nonatomic, strong) NSString *pngExtraSize; ///< 大小
@property (nonatomic, strong) NSString *pngDoubleSize; ///< 大小
@property (nonatomic, strong) NSString *pngTripleSize; ///< 大小




@property (nonatomic, strong) NSString *svgFileMd5; ///< 素材文件的md5
@property (nonatomic, strong) NSString *pngExtraFileMd5; ///< 素材文件的md5
@property (nonatomic, strong) NSString *pngDoubleFileMd5; ///< 素材文件的md5
@property (nonatomic, strong) NSString *pngTripleFileMd5; ///< 素材文件的md5

@property (nonatomic, strong) NSString *createName; ///< 创建者
@property (nonatomic, strong) NSString *lastUpdateName; ///< 最后修改者
@property (nonatomic, strong) NSString *remark; ///< 备注
@property (nonatomic, assign) NSTimeInterval lastUpdateTime; ///< 最后创建时间
@property (nonatomic, assign) NSTimeInterval createTime; ///< 创建时间


@property (nonatomic, strong) NSString *totalMd5; ///< 总md5


@end
