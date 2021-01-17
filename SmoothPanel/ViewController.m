//
//  ViewController.m
//  SmoothPanel
//
//  Created by Sharker on 2021/1/15.
//

#import "ViewController.h"
#import "SmoothPanel.h"

@interface ViewController ()<PanelPanDelegate, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, strong) SmoothPanel *panel;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray *array;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIView *redView = [[UIView alloc] initWithFrame:CGRectMake(20, 20, 100, 100)];
    redView.backgroundColor = [UIColor redColor];
    
    self.panel = [[SmoothPanel alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 200, self.view.frame.size.width, self.view.frame.size.height)];
    self.panel.delegate = self;
    self.panel.backgroundColor = [UIColor cyanColor];
    [self.view addSubview:self.panel];
    self.panel.layer.cornerRadius = 5.f;
    self.panel.layer.masksToBounds = YES;
//    [self.panel addSubview:redView];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.height - 180) style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor redColor];
    self.panel.normalY = self.view.frame.size.height - 200;
    PanelPanGestureRecognizer *panGesture = [[PanelPanGestureRecognizer alloc] init];
    panGesture.minimumNumberOfTouches = 1;
    panGesture.delegate = self;
    [self.tableView addGestureRecognizer:panGesture];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    // mock
    NSArray *arr = @[@{@"title":@"title1",@"subTitle":@"subTitle1"},
                     @{@"title":@"title2",@"subTitle":@"subTitle2"},
                     @{@"title":@"title3",@"subTitle":@"subTitle3"},
                     @{@"title":@"title4",@"subTitle":@"subTitle4"},
                     @{@"title":@"title5",@"subTitle":@"subTitle5"},
                     @{@"title":@"title6",@"subTitle":@"subTitle6"},
                     @{@"title":@"title7",@"subTitle":@"subTitle7"},
                     @{@"title":@"title8",@"subTitle":@"subTitle8"},
                     @{@"title":@"title9",@"subTitle":@"subTitle9"},
                     @{@"title":@"title10",@"subTitle":@"subTitle10"},
                     @{@"title":@"title11",@"subTitle":@"subTitle11"},
                     @{@"title":@"title12",@"subTitle":@"subTitle12"},
                     @{@"title":@"title13",@"subTitle":@"subTitle13"},
                     @{@"title":@"title14",@"subTitle":@"subTitle14"},
                     @{@"title":@"title15",@"subTitle":@"subTitle15"},
                     @{@"title":@"title16",@"subTitle":@"subTitle16"},
                     @{@"title":@"title17",@"subTitle":@"subTitle17"},
                     @{@"title":@"title18",@"subTitle":@"subTitle18"},
                     @{@"title":@"title19",@"subTitle":@"subTitle19"}];
    self.array = arr;
    
    [self.panel addSubview:self.tableView];

}

#pragma mark delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellId = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];

    }
    cell.textLabel.text = self.array[indexPath.row][@"title"];
    cell.detailTextLabel.text = self.array[indexPath.row][@"subTitle"];
    
    return cell;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.array.count;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0f;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)panelMoveDistance:(CGFloat)distance distanceToMax:(CGFloat)distanceToMax ratio:(CGFloat)ratio {
    
}

#pragma mark setter
- (NSArray *)array {
    if (!_array) {
        _array = [[NSArray alloc] init];
    }
    return _array;
}


@end
