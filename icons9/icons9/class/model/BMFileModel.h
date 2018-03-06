//
//  BMFileModel.h
//  icons9
//
//  Created by 冯立海 on 2018/3/5.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BMFileModel : NSObject
+ (instancetype)fileModlWithPath:(NSString *)path;
@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSString *extensionName;

@property (nonatomic, strong) NSDictionary *fileAttributes;

@end
