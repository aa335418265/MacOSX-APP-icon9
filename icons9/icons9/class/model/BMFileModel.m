//
//  BMFileModel.m
//  icons9
//
//  Created by 冯立海 on 2018/3/5.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#import "BMFileModel.h"

@implementation BMFileModel
+ (instancetype)fileModlWithPath:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path]) {
        return nil;
    }
    BMFileModel *model = [[BMFileModel alloc] init];
    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:path error:nil];
    
    if (fileAttributes != nil) {
        NSNumber *fileSize;
        NSString *fileOwner, *creationDate;
        NSDate *fileModDate;
        //NSString *NSFileCreationDate
        //文件大小
        if ((fileSize = [fileAttributes objectForKey:NSFileSize])) {
            NSLog(@"File size: %qi\n", [fileSize unsignedLongLongValue]);
        }
        //文件创建日期
        if ((creationDate = [fileAttributes objectForKey:NSFileCreationDate])) {
            NSLog(@"File creationDate: %@\n", creationDate);
            //textField.text=NSFileCreationDate;
        }
        //文件所有者
        if ((fileOwner = [fileAttributes objectForKey:NSFileOwnerAccountName])) {
            NSLog(@"Owner: %@\n", fileOwner);
        }
        //文件修改日期
        if ((fileModDate = [fileAttributes objectForKey:NSFileModificationDate])) {
            NSLog(@"Modification date: %@\n", fileModDate);
        }
    }
    
    
    model.fileAttributes = fileAttributes;
    return model;
    
}

@end
