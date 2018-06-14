//
//  Person.h
//  ZJDataBase
//
//  Created by 邓志坚 on 2018/6/13.
//  Copyright © 2018年 邓志坚. All rights reserved.
//  https://github.com/Dzhijian/ZJDataBase
//

#import "ZJDBModel.h"

@interface Person : ZJDBModel
// 年龄
@property (nonatomic, assign) int age;
// 姓名
@property (nonatomic, copy) NSString *name;
// 头像
@property (nonatomic, strong) NSData *avatarData;
//性别
@property (nonatomic, copy) NSString *gender;

@end
