//
//  HPMyThreadViewController.m
//  HiPDA
//
//  Created by wujichao on 13-11-22.
//  Copyright (c) 2013年 wujichao. All rights reserved.
//

#import "HPMyThreadViewController.h"
#import "HPThread.h"
#import "HPUser.h"
#import "HPMyThread.h"
#import "HPPostViewController.h"
#import "HPIndecator.h"

#import "UIAlertView+Blocks.h"
#import <SVProgressHUD.h>

#import "SWRevealViewController.h"
#import "UITableView+ScrollToTop.h"

@interface HPMyThreadViewController ()

@property NSInteger current_page;

@end

@implementation HPMyThreadViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"我的帖子";
    
    [self addPageControlBtn];
    [self addRevealActionBI];
    
    [self addRefreshControl];
    
    
    //[self load];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [self addGuesture];
    [super viewWillAppear:animated];
}
- (void)viewWillDisappear:(BOOL)animated {
    
    [self removeGuesture];
    [super viewWillDisappear:animated];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -

- (void)load {
    _current_page = 1;
    [self.refreshControl beginRefreshing];
    [self ayscn:nil];
}

- (void)refresh:(id)sender {
    
    if ([self.refreshControl isRefreshing]) {
        //return;
    }
    
    _current_page = 1;
    
    if ([sender isKindOfClass:[UIRefreshControl class]]) {
        ;
    } else {
        //[HPIndecator show];
        [self showRefreshControl];
    }
    
    [self ayscn:nil];
}


- (void)refresh {
    _current_page = 1;
    [self.refreshControl beginRefreshing];
    [self ayscn:nil];
}

- (void)setup {
    _myThreads = [[HPMyThread sharedMyThread] myThreads];
    NSLog(@"_myThreads %@",_myThreads);
    
    _current_page = 1;
}

- (void)ayscn:(id)sender {
    
    if ([sender isKindOfClass:[NSString class]]) {
        [SVProgressHUD showWithStatus:sender];
    } else {
        ;//[SVProgressHUD showWithStatus:@"同步中..."];
    }
    
    __weak typeof(self) weakSelf = self;
    [HPMyThread ayscnMyThreadWithBlock:^(NSArray *threads, NSError *error) {
        
        if (error) {
            [SVProgressHUD dismiss];
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:[error localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
            
        } else if ([threads count]){
            [SVProgressHUD dismiss];
            if (_current_page == 1) {
                [[HPMyThread sharedMyThread] cacheMyThreads:threads];
            }
            _myThreads = threads;
            [weakSelf.tableView reloadData];
            
            if (![weakSelf.refreshControl isRefreshing]) {
                [weakSelf.tableView hp_scrollToTop];
                [weakSelf.tableView flashScrollIndicators];
            }
            
        } else {
            [SVProgressHUD showErrorWithStatus:@"您没有主题帖子"];
        }
        
        [weakSelf.refreshControl endRefreshing];
        [HPIndecator dismiss];
        
    } page:_current_page];
}

- (void)prevPage:(id)sender {
    
    if (_current_page > 1) {
        _current_page--;
        [self ayscn:@"加载上一页..."];
    } else {
        [SVProgressHUD showErrorWithStatus:@"已经是第一页"];
    }
    
}

- (void)nextPage:(id)sender {
    NSLog(@"_myThreads _myThreads %ld", _myThreads.count);
    if (_myThreads.count >= 44) {
        _current_page++;
        [self ayscn:@"加载下一页..."];
    } else {
        [SVProgressHUD showErrorWithStatus:@"已经是最后一页"];
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [_myThreads count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"HPMyThreadCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    HPThread *thread = [_myThreads objectAtIndex:indexPath.row];
    cell.textLabel.text = thread.title;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"最后回复: %@ - %@",
                                 thread.threadLastReplyUsername, thread.threadLastReplyDateString];
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    HPThread *thread = [_myThreads objectAtIndex:indexPath.row];
    UIViewController *rvc = [[PostViewControllerClass() alloc] initWithThread:thread];

    [self.navigationController pushViewController:rvc animated:YES];
}


@end
