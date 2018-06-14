//
//  ZJDataBaseTool.m
//  ZJDataBase
//
//  Created by 邓志坚 on 2018/6/11.
//  Copyright © 2018年 邓志坚. All rights reserved.
//  GitHub : https://github.com/Dzhijian/ZJDataBase
//

#import "ZJDataBaseTool.h"
#import "ZJDBModel.h"
#import <objc/runtime.h>


@interface ZJDataBaseTool ()

@property (nonatomic, retain) FMDatabaseQueue *dbQueue;

@end

@implementation ZJDataBaseTool

static ZJDataBaseTool *_instance = nil;
+(instancetype)shareInstance{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[super allocWithZone:NULL]init];
    });
    return _instance;
}
+ (id)allocWithZone:(struct _NSZone *)zone
{
    return [ZJDataBaseTool shareInstance];
}

- (id)copyWithZone:(struct _NSZone *)zone
{
    return [ZJDataBaseTool shareInstance];
}

- (FMDatabaseQueue *)dbQueue
{
    if (!_dbQueue) {
        _dbQueue = [[FMDatabaseQueue alloc] initWithPath:[self.class dbPath]];
    }
    return _dbQueue;
}



+ (NSString *)dbPath
{
    return [self dbPathWithDirectoryName:nil];
}

+ (NSString *)dbPathWithDirectoryName:(NSString *)directoryName
{
    NSString *docsdir = [NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSFileManager *filemanage = [NSFileManager defaultManager];
    if (directoryName == nil || directoryName.length == 0) {
        docsdir = [docsdir stringByAppendingPathComponent:@"ZJDB"];
    } else {
        docsdir = [docsdir stringByAppendingPathComponent:directoryName];
    }
    BOOL isDir;
    BOOL exit =[filemanage fileExistsAtPath:docsdir isDirectory:&isDir];
    if (!exit || !isDir) {
        [filemanage createDirectoryAtPath:docsdir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *dbpath = [docsdir stringByAppendingPathComponent:@"zjdb.sqlite"];
    return dbpath;
}

- (BOOL)changeDBWithDirectoryName:(NSString *)directoryName
{
    if (_instance.dbQueue) {
        _instance.dbQueue = nil;
    }
    _instance.dbQueue = [[FMDatabaseQueue alloc] initWithPath:[ZJDataBaseTool dbPathWithDirectoryName:directoryName]];
    
    int numClasses;
    Class *classes = NULL;
    numClasses = objc_getClassList(NULL,0);
    
    if (numClasses >0 )
    {
        classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
        numClasses = objc_getClassList(classes, numClasses);
        for (int i = 0; i < numClasses; i++) {
            if (class_getSuperclass(classes[i]) == [ZJDBModel class]){
                id class = classes[i];
                [class performSelector:@selector(createTable) withObject:nil];
            }
        }
        free(classes);
    }
    
    return YES;
}
@end
