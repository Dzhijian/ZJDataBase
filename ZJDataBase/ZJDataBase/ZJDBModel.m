//
//  ZJDBModel.m
//  ZJDataBase
//
//  Created by 邓志坚 on 2018/6/12.
//  Copyright © 2018年 邓志坚. All rights reserved.
//  GitHub : https://github.com/Dzhijian/ZJDataBase
//

#import "ZJDBModel.h"
#import "ZJDataBaseTool.h"
#import <objc/runtime.h>

/** SQLite五种数据类型 */
#define SQLTEXT     @"TEXT"
#define SQLINTEGER  @"INTEGER"
#define SQLREAL     @"REAL"
#define SQLBLOB     @"BLOB"
#define SQLNULL     @"NULL"
#define PrimaryKey  @"primary key"
#define primaryId   @"pk"

@implementation ZJDBModel


+(void)initialize{
    if (self != [ZJDBModel self]) {
        [self createTable];
    }
}

-(instancetype)init{
    if (self = [super init]) {
        NSDictionary *dict = [self.class getAllProperties];
        _columeNames = [[NSMutableArray alloc] initWithArray:[dict objectForKey:@"name"]];
        _columeTypes = [[NSMutableArray alloc] initWithArray:[dict objectForKey:@"type"]];
    }
    return self;
}

#pragma mark - 获取该类所有的属性
+(NSDictionary *)getPropertys{
    
    NSMutableArray *proNames = [NSMutableArray array];
    NSMutableArray *proTypes = [NSMutableArray array];
    NSArray *theTransients = [[self class]  transients];
    
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    
    
    for (i = 0; i<outCount; i++) {
        objc_property_t property = properties[i];
        
        // 获取属性名
        NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        if ([theTransients containsObject:propertyName]) {
            continue;
        }
        [proNames addObject:propertyName];
        
        // 获取属性类型参数
        NSString *propertyType = [NSString stringWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
        if ([propertyType hasPrefix:@"T@\"NSString\""]) {
            [proTypes addObject:SQLTEXT];
        } else if ([propertyType hasPrefix:@"T@\"NSData\""]) {
            [proTypes addObject:SQLBLOB];
        } else if ([propertyType hasPrefix:@"Ti"]||[propertyType hasPrefix:@"TI"]||[propertyType hasPrefix:@"Ts"]||[propertyType hasPrefix:@"TS"]||[propertyType hasPrefix:@"TB"]||[propertyType hasPrefix:@"Tq"]||[propertyType hasPrefix:@"TQ"]) {
            [proTypes addObject:SQLINTEGER];
        } else {
            [proTypes addObject:SQLREAL];
        }
        
    }
    // 释放
    free(properties);
    
    return [NSDictionary dictionaryWithObjectsAndKeys:proNames,@"name",proTypes,@"type",nil];
}

#pragma mark - 获取所有属性,包含主键 pk
+(NSDictionary *)getAllProperties{
    
    NSDictionary *dict = [[self class] getPropertys];
    NSMutableArray *proNames = [NSMutableArray array];
    NSMutableArray *proTypes = [NSMutableArray array];
    [proNames  addObject:primaryId];
    [proTypes addObject:[NSString stringWithFormat:@"%@ %@",SQLINTEGER,PrimaryKey]];
    [proNames addObjectsFromArray:[dict objectForKey:@"name"]];
    [proTypes addObjectsFromArray:[dict objectForKey:@"type"]];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:proNames,@"name",proTypes,@"type",nil];
    
}

#pragma mark - 判断是否存在表
+(BOOL)isExistInTable{
    
    __block BOOL res = NO;
    ZJDataBaseTool *zjDB = [ZJDataBaseTool shareInstance];
    [zjDB.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *tableName = NSStringFromClass(self.class);
        res = [db tableExists:tableName];
    }];
    return res;
}

#pragma mark - 获取列名
+(NSArray *)getColumns{
    ZJDataBaseTool *zjDB = [ZJDataBaseTool shareInstance];
    NSMutableArray *columns = [NSMutableArray array];
    [zjDB.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *tableName = NSStringFromClass([self class]);
        FMResultSet *resultSet =[db getTableSchema:tableName];
        while ([resultSet next]) {
            NSString *column = [resultSet stringForColumn:@"name"];
            [columns addObject:column];
        }
        
    }];
    
    return [columns copy];
}

#pragma mark - 创建表,如果已经创建了该表,则返回 YES
+(BOOL)createTable{
    
    __block BOOL res = YES;
    
    ZJDataBaseTool *zjDB = [ZJDataBaseTool shareInstance];
    [zjDB.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSString *tableName = NSStringFromClass(self.class);
        NSString *columeAndType = [self.class getColumeAndTypeString];
        NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(%@);",tableName,columeAndType];
        if (![db executeUpdate:sql]) {
            res = NO;
            *rollback = YES;
            return;
        };
        
        NSMutableArray *columns = [NSMutableArray array];
        FMResultSet *resultSet = [db getTableSchema:tableName];
        while ([resultSet next]) {
            NSString *column = [resultSet stringForColumn:@"name"];
            [columns addObject:column];
        }
        NSDictionary *dict = [self.class getAllProperties];
        NSArray *properties = [dict objectForKey:@"name"];
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"NOT (SELF IN %@)",columns];
        //过滤数组
        NSArray *resultArray = [properties filteredArrayUsingPredicate:filterPredicate];
        for (NSString *column in resultArray) {
            NSUInteger index = [properties indexOfObject:column];
            NSString *proType = [[dict objectForKey:@"type"] objectAtIndex:index];
            NSString *fieldSql = [NSString stringWithFormat:@"%@ %@",column,proType];
            NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ ",NSStringFromClass(self.class),fieldSql];
            if (![db executeUpdate:sql]) {
                res = NO;
                *rollback = YES;
                return ;
            }
        }

    }];
    
    return res;
}

#pragma mark - 保存
-(BOOL)save{
    NSString *tableName = NSStringFromClass(self.class);
    NSMutableString *keyString = [NSMutableString string];
    NSMutableString *valueString = [NSMutableString string];
    NSMutableArray *insertValues = [NSMutableArray array];
    for (int i = 0; i<self.columeNames.count; i++) {
        NSString *proname = [self.columeNames objectAtIndex:i];
        if ([proname isEqualToString:primaryId]) {
            continue;
        }
        
        [keyString appendFormat:@"%@,",proname];
        [valueString appendString:@"?,"];
        
        id value = [self valueForKey:proname];
        if (!value) {
            value = @"";
            
        }
        
        [insertValues addObject:value];
        
    }
    
    // 去掉最后的逗号 ,
    [keyString deleteCharactersInRange:NSMakeRange(keyString.length -1, 1)];
    [valueString deleteCharactersInRange:NSMakeRange(valueString.length -1, 1)];
    
    ZJDataBaseTool *zjDB = [ZJDataBaseTool shareInstance];
    
    __block BOOL res  = NO;
    [zjDB.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@(%@) VALUES (%@);", tableName, keyString, valueString];
        res = [db executeUpdate:sql withArgumentsInArray:insertValues];
        self.pk = res ? [NSNumber numberWithUnsignedLongLong:db.lastInsertRowId].intValue : 0;
        NSLog(res ? @"插入成功" : @"插入失败");
        
    }];
    
    return res;
}




#pragma mark - util method
+ (NSString *)getColumeAndTypeString
{
    NSMutableString* pars = [NSMutableString string];
    NSDictionary *dict = [self.class getAllProperties];
    
    NSMutableArray *proNames = [dict objectForKey:@"name"];
    NSMutableArray *proTypes = [dict objectForKey:@"type"];
    
    for (int i=0; i< proNames.count; i++) {
        [pars appendFormat:@"%@ %@",[proNames objectAtIndex:i],[proTypes objectAtIndex:i]];
        if(i+1 != proNames.count)
        {
            [pars appendString:@","];
        }
    }
    return pars;
}

#pragma mark - 保存或更新
- (BOOL)saveOrUpdate
{
    id primaryValue = [self valueForKey:primaryId];
    if ([primaryValue intValue] <= 0) {
        return [self save];
    }
    
    return [self update];
}

#pragma mark - 根据条件保存或更新
- (BOOL)saveOrUpdateByColumnName:(NSString*)columnName AndColumnValue:(NSString*)columnValue
{
    id record = [self.class findFirstByCriteria:[NSString stringWithFormat:@"where %@ = %@",columnName,columnValue]];
    if (record) {
        id primaryValue = [record valueForKey:primaryId]; //取到了主键PK
        if ([primaryValue intValue] <= 0) {
            return [self save];
        }else{
            self.pk = [primaryValue integerValue];
            return [self update];
        }
    }else{
        return [self save];
    }
}
/** 批量保存用户对象 */
+ (BOOL)saveObjects:(NSArray *)array
{
    //判断是否是JKBaseModel的子类
    for (ZJDBModel *model in array) {
        if (![model isKindOfClass:[ZJDBModel class]]) {
            return NO;
        }
    }
    
    __block BOOL res = YES;
    ZJDataBaseTool *zjDB = [ZJDataBaseTool shareInstance];
    // 如果要支持事务
    [zjDB.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (ZJDBModel *model in array) {
            NSString *tableName = NSStringFromClass(model.class);
            NSMutableString *keyString = [NSMutableString string];
            NSMutableString *valueString = [NSMutableString string];
            NSMutableArray *insertValues = [NSMutableArray  array];
            for (int i = 0; i < model.columeNames.count; i++) {
                NSString *proname = [model.columeNames objectAtIndex:i];
                if ([proname isEqualToString:primaryId]) {
                    continue;
                }
                [keyString appendFormat:@"%@,", proname];
                [valueString appendString:@"?,"];
                id value = [model valueForKey:proname];
                if (!value) {
                    value = @"";
                }
                [insertValues addObject:value];
            }
            [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
            [valueString deleteCharactersInRange:NSMakeRange(valueString.length - 1, 1)];
            
            NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@(%@) VALUES (%@);", tableName, keyString, valueString];
            BOOL flag = [db executeUpdate:sql withArgumentsInArray:insertValues];
            model.pk = flag?[NSNumber numberWithLongLong:db.lastInsertRowId].intValue:0;
            NSLog(flag?@"插入成功":@"插入失败");
            if (!flag) {
                res = NO;
                *rollback = YES;
                return;
            }
        }
    }];
    return res;
}
#pragma mark - 更新单个对象
- (BOOL)update
{
    ZJDataBaseTool *zjDB = [ZJDataBaseTool shareInstance];
    __block BOOL res = NO;
    [zjDB.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        id primaryValue = [self valueForKey:primaryId];
        if (!primaryValue || primaryValue <= 0) {
            return ;
        }
        NSMutableString *keyString = [NSMutableString string];
        NSMutableArray *updateValues = [NSMutableArray  array];
        for (int i = 0; i < self.columeNames.count; i++) {
            NSString *proname = [self.columeNames objectAtIndex:i];
            if ([proname isEqualToString:primaryId]) {
                continue;
            }
            [keyString appendFormat:@" %@=?,", proname];
            id value = [self valueForKey:proname];
            if (!value) {
                value = @"";
            }
            [updateValues addObject:value];
        }
        
        //删除最后那个逗号
        [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
        NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@ = ?;", tableName, keyString, primaryId];
        [updateValues addObject:primaryValue];
        res = [db executeUpdate:sql withArgumentsInArray:updateValues];
        NSLog(res?@"更新成功":@"更新失败");
    }];
    return res;
}


#pragma mark - 批量更新用户对象
+ (BOOL)updateObjects:(NSArray *)array
{
    for (ZJDBModel *model in array) {
        if (![model isKindOfClass:[ZJDBModel class]]) {
            return NO;
        }
    }
    __block BOOL res = YES;
    ZJDataBaseTool *zjDB = [ZJDataBaseTool shareInstance];
    // 如果要支持事务
    [zjDB.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (ZJDBModel *model in array) {
            NSString *tableName = NSStringFromClass(model.class);
            id primaryValue = [model valueForKey:primaryId];
            if (!primaryValue || primaryValue <= 0) {
                res = NO;
                *rollback = YES;
                return;
            }
            
            NSMutableString *keyString = [NSMutableString string];
            NSMutableArray *updateValues = [NSMutableArray  array];
            for (int i = 0; i < model.columeNames.count; i++) {
                NSString *proname = [model.columeNames objectAtIndex:i];
                if ([proname isEqualToString:primaryId]) {
                    continue;
                }
                [keyString appendFormat:@" %@=?,", proname];
                id value = [model valueForKey:proname];
                if (!value) {
                    value = @"";
                }
                [updateValues addObject:value];
            }
            
            //删除最后那个逗号
            [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
            NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@=?;", tableName, keyString, primaryId];
            [updateValues addObject:primaryValue];
            BOOL flag = [db executeUpdate:sql withArgumentsInArray:updateValues];
            NSLog(flag?@"更新成功":@"更新失败");
            if (!flag) {
                res = NO;
                *rollback = YES;
                return;
            }
        }
    }];
    
    return res;
}

#pragma mark - 删除单个对象
- (BOOL)deleteObject
{
    ZJDataBaseTool *zjDB = [ZJDataBaseTool shareInstance];
    __block BOOL res = NO;
    [zjDB.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        id primaryValue = [self valueForKey:primaryId];
        if (!primaryValue || primaryValue <= 0) {
            return ;
        }
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?",tableName,primaryId];
        res = [db executeUpdate:sql withArgumentsInArray:@[primaryValue]];
        NSLog(res?@"删除成功":@"删除失败");
    }];
    return res;
}

#pragma mark - 批量删除用户对象
+ (BOOL)deleteObjects:(NSArray *)array
{
    for (ZJDBModel *model in array) {
        if (![model isKindOfClass:[ZJDBModel class]]) {
            return NO;
        }
    }
    
    __block BOOL res = YES;
    ZJDataBaseTool *zjDB = [ZJDataBaseTool shareInstance];
    // 如果要支持事务
    [zjDB.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (ZJDBModel *model in array) {
            NSString *tableName = NSStringFromClass(model.class);
            id primaryValue = [model valueForKey:primaryId];
            if (!primaryValue || primaryValue <= 0) {
                return ;
            }
            
            NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ = ?",tableName,primaryId];
            BOOL flag = [db executeUpdate:sql withArgumentsInArray:@[primaryValue]];
            NSLog(flag?@"删除成功":@"删除失败");
            if (!flag) {
                res = NO;
                *rollback = YES;
                return;
            }
        }
    }];
    return res;
}

#pragma mark -  通过条件删除数据
+ (BOOL)deleteObjectsByCriteria:(NSString *)criteria
{
    ZJDataBaseTool *zjDB = [ZJDataBaseTool shareInstance];
    __block BOOL res = NO;
    [zjDB.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ %@ ",tableName,criteria];
        res = [db executeUpdate:sql];
        NSLog(res?@"删除成功":@"删除失败");
    }];
    return res;
}

#pragma mark - 通过条件删除 (多参数）--2
+ (BOOL)deleteObjectsWithFormat:(NSString *)format, ...
{
    va_list ap;
    va_start(ap, format);
    NSString *criteria = [[NSString alloc] initWithFormat:format locale:[NSLocale currentLocale] arguments:ap];
    va_end(ap);
    
    return [self deleteObjectsByCriteria:criteria];
}

#pragma mark - 清空表
+ (BOOL)clearTable
{
    ZJDataBaseTool *zjDB = [ZJDataBaseTool shareInstance];
    __block BOOL res = NO;
    [zjDB.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@",tableName];
        res = [db executeUpdate:sql];
        NSLog(res?@"清空成功":@"清空失败");
    }];
    return res;
}

#pragma mark -  查询全部数据
+ (NSArray *)findAll
{
    NSLog(@"zjDB---%s",__func__);
    ZJDataBaseTool *zjDB = [ZJDataBaseTool shareInstance];
    NSMutableArray *users = [NSMutableArray array];
    [zjDB.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@",tableName];
        FMResultSet *resultSet = [db executeQuery:sql];
        while ([resultSet next]) {
            ZJDBModel *model = [[self.class alloc] init];
            for (int i=0; i< model.columeNames.count; i++) {
                NSString *columeName = [model.columeNames objectAtIndex:i];
                NSString *columeType = [model.columeTypes objectAtIndex:i];
                if ([columeType isEqualToString:SQLTEXT]) {
                    [model setValue:[resultSet stringForColumn:columeName] forKey:columeName];
                } else if ([columeType isEqualToString:SQLBLOB]) {
                    [model setValue:[resultSet dataForColumn:columeName] forKey:columeName];
                } else {
                    [model setValue:[NSNumber numberWithLongLong:[resultSet longLongIntForColumn:columeName]] forKey:columeName];
                }
            }
            [users addObject:model];
            FMDBRelease(model);
        }
    }];
    
    return users;
}


#pragma mark - 查找
+ (instancetype)findFirstWithFormat:(NSString *)format, ...
{
    va_list ap;
    va_start(ap, format);
    NSString *criteria = [[NSString alloc] initWithFormat:format locale:[NSLocale currentLocale] arguments:ap];
    va_end(ap);
    
    return [self findFirstByCriteria:criteria];
}

#pragma mark -  查找某条数据
+ (instancetype)findFirstByCriteria:(NSString *)criteria
{
    NSArray *results = [self.class findByCriteria:criteria];
    if (results.count < 1) {
        return nil;
    }
    
    return [results firstObject];
}

#pragma mark - 查找主键
+ (instancetype)findByPK:(int)inPk
{
    NSString *condition = [NSString stringWithFormat:@"WHERE %@=%d",primaryId,inPk];
    return [self findFirstByCriteria:condition];
}

+ (NSArray *)findWithFormat:(NSString *)format, ...
{
    va_list ap;
    va_start(ap, format);
    NSString *criteria = [[NSString alloc] initWithFormat:format locale:[NSLocale currentLocale] arguments:ap];
    va_end(ap);
    
    return [self findByCriteria:criteria];
}

#pragma mark - 通过条件查找数据
+ (NSArray *)findByCriteria:(NSString *)criteria
{
    ZJDataBaseTool *zjDB = [ZJDataBaseTool shareInstance];
    NSMutableArray *users = [NSMutableArray array];
    [zjDB.dbQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = NSStringFromClass(self.class);
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ %@",tableName,criteria];
        FMResultSet *resultSet = [db executeQuery:sql];
        while ([resultSet next]) {
            ZJDBModel *model = [[self.class alloc] init];
            for (int i=0; i< model.columeNames.count; i++) {
                NSString *columeName = [model.columeNames objectAtIndex:i];
                NSString *columeType = [model.columeTypes objectAtIndex:i];
                if ([columeType isEqualToString:SQLTEXT]) {
                    [model setValue:[resultSet stringForColumn:columeName] forKey:columeName];
                } else if ([columeType isEqualToString:SQLBLOB]) {
                    [model setValue:[resultSet dataForColumn:columeName] forKey:columeName];
                } else {
                    [model setValue:[NSNumber numberWithLongLong:[resultSet longLongIntForColumn:columeName]] forKey:columeName];
                }
            }
            [users addObject:model];
            FMDBRelease(model);
        }
    }];
    
    return users;
}

#pragma mark - 打印
- (NSString *)description
{
    NSString *result = @"";
    NSDictionary *dict = [self.class getAllProperties];
    NSMutableArray *proNames = [dict objectForKey:@"name"];
    for (int i = 0; i < proNames.count; i++) {
        NSString *proName = [proNames objectAtIndex:i];
        id  proValue = [self valueForKey:proName];
        result = [result stringByAppendingFormat:@"%@:%@\n",proName,proValue];
    }
    return result;
}



#pragma mark - must be override method
/** 如果子类中有一些property不需要创建数据库字段，那么这个方法必须在子类中重写
 */
+ (NSArray *)transients
{
    return [NSArray array];
}

@end
