//
//  HPMyNoticeViewController.m
//  HiPDA
//
//  Created by wujichao on 13-11-25.
//  Copyright (c) 2013年 wujichao. All rights reserved.
//

#import "HPMyNoticeViewController.h"
#import "HPThread.h"
#import "HPUser.h"
#import "HPNotice.h"
#import "HPPostViewController.h"
#import "HPIndecator.h"
#import "HPSetting.h"
#import "HPCache.h"
#import "HPTheme.h"

#import "UIAlertView+Blocks.h"
#import "NSString+Additions.h"
#import <SVProgressHUD.h>

#import "SWRevealViewController.h"
#import "HPRearViewController.h"
#import "UITableView+ScrollToTop.h"



#define FONT_SIZE 15.0f
#define CELL_CONTENT_WIDTH 320.0f
#define CELL_CONTENT_MARGIN 10.0f

@interface HPMyNoticeViewController ()

@property NSInteger current_page;

@end

@implementation HPMyNoticeViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"帖子消息";
    
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


- (void)setup {
    _myNotices = [[HPNotice sharedNotice] myNotices];
    NSLog(@"_myNotices %@ %ld",_myNotices, _myNotices.count);
    _current_page = 1;
}


- (void)ayscn:(id)sender {
    
    if ([sender isKindOfClass:[NSString class]]) {
        [SVProgressHUD showWithStatus:sender];
    } else {
        ;//[SVProgressHUD showWithStatus:@"同步中..."];
    }
    
    __weak typeof(self) weakSelf = self;
    [HPNotice ayscnMyNoticesWithBlock:^(NSArray *threads, NSError *error) {
        
        if (error) {
            [SVProgressHUD dismiss];
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:[error localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
            
        } else if ([threads count]){
            [SVProgressHUD dismiss];
            
            if (_current_page == 1) {
                [[HPNotice sharedNotice] cacheMyNotices:threads];
            }
            _myNotices = threads;
            [weakSelf.tableView reloadData];
            
            if (![weakSelf.refreshControl isRefreshing]) {
                [weakSelf.tableView hp_scrollToTop];
                [weakSelf.tableView flashScrollIndicators];
            }
            
            [Setting saveInteger:0 forKey:HPNoticeCount];
            [[HPRearViewController sharedRearVC] updateBadgeNumber];
            
        } else {
            [SVProgressHUD showErrorWithStatus:@"您没有提醒消息"];
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
    NSLog(@"_myNotices _myNotices.count %ld", _myNotices.count);
    if (_myNotices.count >= 44) {
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
    return [_myNotices count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"HPMyNoticeCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        [cell.detailTextLabel setLineBreakMode:NSLineBreakByWordWrapping];
        [cell.detailTextLabel setMinimumScaleFactor:FONT_SIZE];
        [cell.detailTextLabel setNumberOfLines:0];
        [cell.detailTextLabel setFont:[UIFont systemFontOfSize:FONT_SIZE]];
        [cell.detailTextLabel setTag:1];
    }
    
    HPThread *thread = [_myNotices objectAtIndex:indexPath.row];
   
    CGFloat width = CELL_CONTENT_WIDTH - (CELL_CONTENT_MARGIN * 2);
    CGFloat height = [thread.replyDetail
                      heightOfContentWithFont:[UIFont systemFontOfSize:FONT_SIZE]
                                        width:width];
    
    CGSize size = CGSizeMake(width, height);
    
    // title
    //
    NSString *title = thread.title;
    NSMutableAttributedString *attrString =
    [[NSMutableAttributedString alloc] initWithString:title];
    
    // isRead && thread color
    if ([[HPCache sharedCache] isReadThread:thread.tid pid:thread.pid]) {
        [attrString addAttribute:NSForegroundColorAttributeName value:[HPTheme readColor] range:NSMakeRange(0, [title length])];
        
    } else {
        // thread color
        [attrString addAttribute:NSForegroundColorAttributeName value:[HPTheme textColor] range:NSMakeRange(0, [title length])];
    }
    
    cell.textLabel.attributedText = attrString;
    cell.detailTextLabel.text = thread.replyDetail;
    
    [cell.detailTextLabel setFrame:CGRectMake(CELL_CONTENT_MARGIN, CELL_CONTENT_MARGIN, CELL_CONTENT_WIDTH - (CELL_CONTENT_MARGIN * 2), MAX(size.height, 44.0f) + 25)];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    HPThread *thread = [_myNotices objectAtIndex:indexPath.row];
    
    CGFloat width = CELL_CONTENT_WIDTH - (CELL_CONTENT_MARGIN * 2);
    CGFloat height = MAX([thread.replyDetail
                      heightOfContentWithFont:[UIFont systemFontOfSize:FONT_SIZE]
                      width:width]
                    ,44.f);
   
    return height + (CELL_CONTENT_MARGIN * 2) + 25;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    HPThread *thread = [_myNotices objectAtIndex:indexPath.row];
    
    // mark read
    UITableViewCell *cell = (UITableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    [cell.textLabel setTextColor:[HPTheme readColor]];
    [[HPCache sharedCache] readThread:thread.tid pid:thread.pid];
    
    UIViewController *rvc  = nil;
    
    if (thread.pid) {
        
        // 回复 & 引用 & 回复了你的主题
        /*
         thread.tid, thread.title, thread.fid,
         
         thread.pid
         thread.replyDetail
         */
        
        rvc = [[PostViewControllerClass() alloc] initWithThread:thread
                                                  find_pid:thread.pid];
        
        NSLog(@"redirectFromPid %d", [thread pid]);
    } else {
        
        // TODO: remove
        /*
         thread.tid, thread.title = title, thread.replyDetail
         */
        
        rvc = [[PostViewControllerClass() alloc] initWithThread:thread
                                                      page:1
                                             forceFullPage:YES];
        
    }
    
    [self.navigationController pushViewController:rvc animated:YES];
}


@end
