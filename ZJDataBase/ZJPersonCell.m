//
//  ZJPersonCell.m
//  ZJDataBase
//
//  Created by 邓志坚 on 2018/6/13.
//  Copyright © 2018年 邓志坚. All rights reserved.
//  https://github.com/Dzhijian/ZJDataBase
//

#import "ZJPersonCell.h"
@interface ZJPersonCell ()
@property (weak, nonatomic) IBOutlet UILabel *nameLab;
@property (weak, nonatomic) IBOutlet UILabel *ageLab;
@property (weak, nonatomic) IBOutlet UILabel *genderLab;
@property (weak, nonatomic) IBOutlet UIImageView *avatar;

@end
@implementation ZJPersonCell
-(void)configWithPerson:(Person *)person{
    self.avatar.image = [UIImage imageWithData:person.avatarData];
    self.ageLab.text =[NSString stringWithFormat:@"%d",person.age];
    self.nameLab.text = person.name;
    self.genderLab.text = person.gender;
}
- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
