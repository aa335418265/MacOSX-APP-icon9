//
//  BMIconManager.m
//  icons9
//
//  Created by 冯立海 on 2018/3/6.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#import "BMIconManager.h"
#import <AppKit/AppKit.h>
#import "BMAPIRequest.h"
#import "BMAPIRequestURL.h"
#import <sqlite3.h>
#import "BMSQLProjectModel.h"
#define TABLE_PROJECTS @"projects"

@interface BMIconManager ()
{
    sqlite3 *database;
}
@property (nonatomic, strong) NSString *homePath;
@property (nonatomic, strong) NSString *sqliteFile;
@property (nonatomic, strong) NSString *baseUrl;


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


- (instancetype)init {
    self = [super init];
    if (self) {
        NSFileManager *fileMgr = [NSFileManager defaultManager];
        NSArray * searchResult =  [fileMgr URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
        NSURL * appSupportPath = [searchResult firstObject];
        self.homePath = [appSupportPath.path stringByAppendingPathComponent:@"icon9"];
        if ([fileMgr fileExistsAtPath:self.homePath] == false) {
            [fileMgr createDirectoryAtPath:self.homePath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        self.sqliteFile = [NSString stringWithFormat:@"%@/projects.db",self.homePath];
        //创建数据库
        [self openDatabase];
        [self createTable];
    }
    return self;
}


- (void)openDatabase {
    int databaseResult = sqlite3_open([self.sqliteFile UTF8String], &database);
    if (databaseResult == SQLITE_OK) {
        NSLog(@"打开数据库成功");
    }else{
        NSLog(@"创建／打开数据库失败,%d",databaseResult);
    }
}

- (void)createTable {
    char *error;
    NSString *sqlString = [NSString stringWithFormat:@"create table if not exists %@(id integer primary key autoincrement,projectid char unique, name char unique ,hash char unique, projectpath char)", TABLE_PROJECTS];
    const char *sql = [sqlString cStringUsingEncoding:NSUTF8StringEncoding];
    int tableResult = sqlite3_exec(database, sql, NULL, NULL, &error);
    if (tableResult == SQLITE_OK) {
        NSLog(@"创建表成功");
    }else{
        NSLog(@"创建表失败:%s",error);
    }
}

- (void)insert:(NSArray <NSDictionary *> *)list {
    
    for (NSDictionary *param in list) {
        NSString *projectId = [param objectForKey:@"id"];
        NSString *name = [param objectForKey:@"name"];
        NSString *hash = [param objectForKey:@"hash"];
        NSString *projectPath=[self.homePath stringByAppendingPathComponent:name];
        if (name == nil || hash == nil ) {
            continue;
        }
        NSString *sqlString = [NSString stringWithFormat:@"INSERT INTO %@(projectid,name,hash, projectpath) VALUES ('%@','%@','%@', '%@');",TABLE_PROJECTS, projectId,name, hash,projectPath];
        char *error;
        const char * sql = [sqlString cStringUsingEncoding:(NSUTF8StringEncoding)];
        int ret = sqlite3_exec(database, sql, NULL, NULL, &error);
        if (ret==SQLITE_OK) {
            NSLog(@"插入成功");
        }else{
            NSLog(@"插入失败:%s", error);
        }
    }

}

- (NSArray *)queryProjects
{
    sqlite3_stmt *statement = nil;
    NSString *sqlString = [NSString stringWithFormat:@"select * from %@;", TABLE_PROJECTS];
    int resutl = sqlite3_prepare_v2(database, sqlString.UTF8String, -1, &statement, NULL);
    NSMutableArray *results = [NSMutableArray array];
    if (resutl == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            BMSQLProjectModel *model = [[BMSQLProjectModel alloc] init];

            int projectId =sqlite3_column_int(statement, 1);
            const char *name = (const char *)sqlite3_column_text(statement, 2);
            const char *hash = (const char *)sqlite3_column_text(statement, 3);
            const char *path = (const char *)sqlite3_column_text(statement, 4);
            model.projectId = projectId;
            model.projectName = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
            model.projectHash = [NSString stringWithCString:hash encoding:NSUTF8StringEncoding];
            model.projectLocalPath = [NSString stringWithCString:path encoding:NSUTF8StringEncoding];

            [results addObject:model];
        }
    }else{
        NSLog(@"查询数据库失败");
    }
    return results;
}

- (BOOL)createGroupWithName:(NSString *)name {

    return NO;
}

- (BOOL)checkUpdate {
    
    return YES;
}

- (void)updateProjects:(CompledBlock)complete {
    
    dispatch_queue_t queue = dispatch_queue_create(0, DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        NSString *url = [NSString stringWithFormat:@"%@%@", self.baseUrl, URI_PROJECTS];
        NSUInteger requestId = [[BMAPIRequest sharedInstance] callGETWithParams:params headers:nil url:url queryString:nil apiName:NSStringFromSelector(_cmd)  progress:nil success:^(BMURLResponse *response) {
            id data = [response.content objectForKey:@"data"];
            [self insert:data];
            complete(YES,[self allGroups]);
        } failure:^(BMURLResponse *response) {
            complete(NO,[self allGroups]);
            NSLog(@"请求失败");
        }];
    });
}

- (void)checkProjectIconsUpdate:(NSString *)projectHash projectId:(NSString *)projectId{
    dispatch_queue_t queue = dispatch_queue_create(0, DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        [params setObject:projectHash forKey:@"hash"];
        [params setObject:projectId forKey:@"projectId"];
        NSString *url = [NSString stringWithFormat:@"%@%@", self.baseUrl, URI_CHECK_UPDATE];
        NSUInteger requestId = [[BMAPIRequest sharedInstance] callGETWithParams:params headers:nil url:url queryString:nil apiName:NSStringFromSelector(_cmd)  progress:nil success:^(BMURLResponse *response) {
            id data = [response.content objectForKey:@"data"];
            NSLog(@"data=%@",data);


        } failure:^(BMURLResponse *response) {
            NSLog(@"请求失败");
        }];
    });
}




- (NSArray <BMSQLProjectModel *> *)allGroups {
    NSArray *projects = [self queryProjects];
    return projects;
}




#pragma mark - Getter and Setter

- (NSString *)baseUrl {
    return kBMIsTestEnvironment ? BASE_URL_TEST : BASE_URL;
}



@end
