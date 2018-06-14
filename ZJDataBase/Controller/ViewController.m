//
//  ViewController.m
//  ZJDataBase
//
//  Created by 邓志坚 on 2018/6/11.
//  Copyright © 2018年 邓志坚. All rights reserved.
//  https://github.com/Dzhijian/ZJDataBase
//

#import "ViewController.h"
#import "Person.h"
#import "ZJDataBaseTool.h"
#import "ZJDBModel.h"
#import "ZJPersonCell.h"
#import "ZJDBHeadView.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITableView *mainTable;

@property (nonatomic, strong) NSMutableArray *dataSource;

@property (nonatomic, strong) ZJDBHeadView *headView;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"ZJDBTool";
    self.mainTable = [[UITableView alloc]initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64) style:UITableViewStylePlain];
    self.mainTable.delegate = self;
    self.mainTable.dataSource = self;
    self.mainTable.backgroundColor = [UIColor whiteColor];
    [self.mainTable registerNib:[UINib nibWithNibName:@"ZJPersonCell" bundle:nil] forCellReuseIdentifier:@"ZJPersonCell"];
    [self.view addSubview:self.mainTable];
    
    self.mainTable.rowHeight = 130;
//    [self loadData];
    
//    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"刷新" style:(UIBarButtonItemStylePlain) target:self action:@selector(loadData)];
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"添加数据" style:(UIBarButtonItemStylePlain) target:self action:@selector(addData)];
    self.mainTable.tableHeaderView = self.headView;
    [self btnAction];
}


-(void)btnAction{
    
    
    __weak __typeof(self) weakObject = self;
    
    self.headView.selectedBtnBlock = ^(UIButton *sender) {
        [weakObject loadData];
    };
    
    self.headView.addDataBtnBlock = ^(UIButton *sender) {
        [weakObject addData];
    };
    
    self.headView.insertBtnBlock = ^(UIButton *sender) {
        
    };
    
    self.headView.deleteBtnBlock = ^(UIButton *sender) {
        
    };
    
    
}

-(void)addData{
    UIImage *image = [UIImage imageNamed:@"avataricon"];
    NSData *imgDatae = UIImagePNGRepresentation(image);
    
    for (int i = 0;  i < 10; i++) {
        Person *p = [[Person alloc]init];
        
        p.age = 16 + i;
        p.name = [NSString stringWithFormat:@"张三%d",i];
        p.avatarData = imgDatae;
        p.gender = i%2 ? @"男" : @"女";
        [p save];
    }
    
}


-(void)loadData{
    self.dataSource = (NSMutableArray *)[Person findAll];
    [self.mainTable reloadData];
}

#pragma mark - UITableViewDelegate,UITableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataSource.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    ZJPersonCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ZJPersonCell"];
    [cell configWithPerson:self.dataSource[indexPath.row]];
    
    return cell;
}




-(ZJDBHeadView *)headView{
    if (!_headView) {
        _headView = [[ZJDBHeadView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 150)];
        _headView.backgroundColor = [UIColor whiteColor];
    }
    return _headView;
}

-(NSMutableArray *)dataSource{
    if (!_dataSource) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
