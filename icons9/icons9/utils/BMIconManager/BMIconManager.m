//
//  BMIconManager.m
//  icons9
//
//  Created by 冯立海 on 2018/3/6.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#import "BMIconManager.h"
#import <AppKit/AppKit.h>

@interface BMIconManager ()
@property (nonatomic, strong) NSString *homePath;

@end
@implementation BMIconManager

+ (instancetype)sharedInstance {
    static BMIconManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[BMIconManager alloc] init];
    });
    return sharedInstance;
}

- (BOOL)createGroupWithName:(NSString *)name {
    return FALSE;
}

- (NSArray <BMIconGroupModel *> *)allGroups {

    
    NSFileManager *manager=[NSFileManager defaultManager];
    
    NSArray *dirs =  [manager contentsOfDirectoryAtPath:self.homePath error:nil];
    NSMutableArray *groupDirs = [NSMutableArray array];
    if (dirs == nil) {
        return groupDirs;
    }
    [groupDirs addObjectsFromArray:dirs];
    [groupDirs removeObject:@".DS_Store"];
    
    
    NSMutableArray *allGroups = [NSMutableArray arrayWithCapacity:dirs.count];
    
    for (NSString *group in groupDirs) {
        BMIconGroupModel *model = [[BMIconGroupModel alloc] init];
        model.groupPath = [self.homePath stringByAppendingPathComponent:group];
        model.groupName = group;
        [allGroups addObject:model];
    }

    return allGroups;
}



#pragma mark - Getter and Setter

- (NSString *)homePath {
    if (_homePath == nil) {
        NSFileManager *fileMgr = [NSFileManager defaultManager];
        NSArray * searchResult =  [fileMgr URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
        NSURL * appSupportPath = [searchResult firstObject];
        _homePath = [appSupportPath.path stringByAppendingPathComponent:@"icon9"];
        if ([fileMgr fileExistsAtPath:_homePath] == false) {
            [fileMgr createDirectoryAtPath:_homePath withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    return _homePath;
}
@end
