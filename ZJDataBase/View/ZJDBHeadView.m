//
//  ZJDBHeadView.m
//  ZJDataBase
//
//  Created by 邓志坚 on 2018/6/14.
//  Copyright © 2018年 邓志坚. All rights reserved.
//

#import "ZJDBHeadView.h"

@interface ZJDBHeadView ()

@property (nonatomic, strong) UIButton *selectedAllBtn;

@property (nonatomic, strong) UIButton *addDataBtn;

@property (nonatomic, strong) UIButton *insertBtn;

@property (nonatomic, strong) UIButton *deleteBtn;

@end

@implementation ZJDBHeadView



-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        
        [self addSubview:self.selectedAllBtn];
        [self addSubview:self.addDataBtn];
        [self addSubview:self.insertBtn];
        [self addSubview:self.deleteBtn];
        
        
        [self.selectedAllBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(15);
            make.left.mas_equalTo(15);
            make.width.mas_equalTo(130);
            make.height.mas_equalTo(35);
        }];
        
        [self.addDataBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(15);
            make.right.mas_equalTo(-15);
            make.width.mas_equalTo(130);
            make.height.mas_equalTo(35);
        }];
        
        [self.insertBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.selectedAllBtn.mas_bottom).offset(15);
            make.left.mas_equalTo(15);
            make.width.mas_equalTo(130);
            make.height.mas_equalTo(35);
        }];
        
        [self.deleteBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.addDataBtn.mas_bottom).offset(15);
            make.right.mas_equalTo(-15);
            make.width.mas_equalTo(130);
            make.height.mas_equalTo(35);
        }];
        
        
    }
    return self;
}

-(void)btnAction:(UIButton *)sender{
    if (sender == self.selectedAllBtn) {
        
        if (self.selectedBtnBlock) {
            self.selectedBtnBlock(sender);
        }
        
    }else if (sender == self.addDataBtn){
        if (self.addDataBtnBlock) {
            self.addDataBtnBlock(sender);
        }
    }else if (sender == self.insertBtn){
        if (self.insertBtnBlock) {
            self.insertBtnBlock(sender);
        }
    }else if (sender == self.deleteBtn){
        if (self.deleteBtnBlock) {
            self.deleteBtnBlock(sender);
        }
    }
}


-(UIButton *)selectedAllBtn{
    if (!_selectedAllBtn) {
        _selectedAllBtn = [[UIButton alloc]init];
        [_selectedAllBtn setTitle:@"查询全部数据" forState:(UIControlStateNormal)];
        [_selectedAllBtn setTitleColor:[UIColor blueColor] forState:(UIControlStateNormal)];
        [_selectedAllBtn addTarget:self action:@selector(btnAction:) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _selectedAllBtn;
}

-(UIButton *)addDataBtn{
    if (!_addDataBtn) {
        _addDataBtn = [[UIButton alloc]init];
        [_addDataBtn setTitle:@"添加数据" forState:(UIControlStateNormal)];
        [_addDataBtn setTitleColor:[UIColor blueColor] forState:(UIControlStateNormal)];
        [_addDataBtn addTarget:self action:@selector(btnAction:) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _addDataBtn;
}

-(UIButton *)insertBtn{
    if (!_insertBtn) {
        _insertBtn = [[UIButton alloc]init];
        [_insertBtn setTitle:@"插入数据" forState:(UIControlStateNormal)];
        [_insertBtn setTitleColor:[UIColor blueColor] forState:(UIControlStateNormal)];
        [_insertBtn addTarget:self action:@selector(btnAction:) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _insertBtn;
}

-(UIButton *)deleteBtn{
    if (!_deleteBtn) {
        _deleteBtn = [[UIButton alloc]init];
        [_deleteBtn setTitle:@"删除全部数据" forState:(UIControlStateNormal)];
        [_deleteBtn setTitleColor:[UIColor blueColor] forState:(UIControlStateNormal)];
        [_deleteBtn addTarget:self action:@selector(btnAction:) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _deleteBtn;
}


@end
