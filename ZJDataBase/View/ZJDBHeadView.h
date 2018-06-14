//
//  ZJDBHeadView.h
//  ZJDataBase
//
//  Created by 邓志坚 on 2018/6/14.
//  Copyright © 2018年 邓志坚. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef void(^SelectedBtnAction)(UIButton *sender);
typedef void(^AddDataBtnAction)(UIButton *sender);
typedef void(^InsertBtnAction)(UIButton *sender);
typedef void(^DeleteBtnAction)(UIButton *sender);


@interface ZJDBHeadView : UIView



@property (nonatomic, copy) SelectedBtnAction selectedBtnBlock;
@property (nonatomic, copy) AddDataBtnAction  addDataBtnBlock;
@property (nonatomic, copy) InsertBtnAction   insertBtnBlock;
@property (nonatomic, copy) DeleteBtnAction   deleteBtnBlock;


@end
