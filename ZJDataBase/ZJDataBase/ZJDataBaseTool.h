//
//  ZJDataBaseTool.h
//  ZJDataBase
//
//  Created by 邓志坚 on 2018/6/11.
//  Copyright © 2018年 邓志坚. All rights reserved.
//

#import <Foundation/Foundation.h>
@class FMDatabaseQueue;
@interface ZJDataBaseTool : NSObject

@property (nonatomic, retain, readonly) FMDatabaseQueue *dbQueue;

+(instancetype)shareInstance;

+ (NSString *)dbPath;

- (BOOL)changeDBWithDirectoryName:(NSString *)directoryName;

@end
