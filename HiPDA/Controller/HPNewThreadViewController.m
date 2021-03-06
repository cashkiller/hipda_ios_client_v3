//
//  HPNewThreadViewController.m
//  HiPDA
//
//  Created by wujichao on 14-3-27.
//  Copyright (c) 2014年 wujichao. All rights reserved.
//

#import "HPNewThreadViewController.h"
#import "UIAlertView+Blocks.h"
#import "HPForum.h"
#import <SVProgressHUD.h>
#import "HPTheme.h"
#import "HPSetting.h"

@interface HPNewThreadViewController()<UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, assign)NSInteger fid;
@property (nonatomic, strong)NSString *formhash;
@property (nonatomic, assign)BOOL waitingForToken;

@property (nonatomic, strong)NSArray *types;
@property (nonatomic, assign)NSInteger current_type;

@property (nonatomic, strong)UITextField *titleField;
@property (nonatomic, strong)UIButton *selectTypeBtn;
@property (nonatomic, strong)UIPickerView *typePickerView;

@end

@implementation HPNewThreadViewController


- (id)initWithFourm:(NSInteger)fid delegate:(id<HPCompositionDoneDelegate>)delegate {
    
    self = [super init];
    if (self) {
        _fid = fid;
        self.actionType = ActionTypeNewThread;
        [self setDelegate:delegate];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // data
    //
    NSDictionary *d = [HPForum forumsDict];
    [d enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        if ([obj integerValue] == _fid) {
            self.title = S(@"%@ 发表新帖",key);
            *stop = YES;
        }
    }];
    
    _types = [HPForum forumTypeWithFid:_fid];
    _current_type = 0;
    
    // ui
    //
    if (IOS7_OR_LATER) self.edgesForExtendedLayout = UIRectEdgeNone;
    
    UIColor *backgroudColor = [HPTheme backgroundColor];
    _titleField = [UITextField new];
    _titleField.font = [UIFont systemFontOfSize:20.0f];
    _titleField.placeholder = @"title here...";
    dispatch_async(dispatch_get_main_queue(), ^{
        [_titleField becomeFirstResponder];
    });
    _titleField.backgroundColor = backgroudColor;
    _titleField.keyboardAppearance = [HPTheme keyboardAppearance];
    if (![Setting boolForKey:HPSettingNightMode]) {
        _titleField.textColor = [UIColor blackColor];
    } else {
        _titleField.textColor = [UIColor colorWithRed:109.f/255.f green:109.f/255.f blue:109.f/255.f alpha:1.f];
    }

    _selectTypeBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _selectTypeBtn.backgroundColor = backgroudColor;
    [_selectTypeBtn setTitle:@"默认分类" forState:UIControlStateNormal];
    [_selectTypeBtn addTarget:self action:@selector(selectType:) forControlEvents:UIControlEventTouchUpInside];
    _selectTypeBtn.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    _selectTypeBtn.titleLabel.font = [UIFont systemFontOfSize:16.f];
    
    CGFloat originY = 20;
    _selectTypeBtn.frame = CGRectMake(5.f,
                                      originY,
                                      70.f,
                                      24.f);
    
    CGFloat originX = 5.f + (_types?70.f:0.f) + 5.f;
    _titleField.frame = CGRectMake(originX,
                                   originY,
                                   self.view.bounds.size.width - originX - 5.f,
                                   24.f);
    
    [self.view addSubview:_titleField];
    if (_types) [self.view addSubview:_selectTypeBtn];
    


    UIView *line1 = [UIView new];
    line1.backgroundColor = rgb(205.f, 205.f, 205.f);
    line1.frame = CGRectMake(7, originY + 27, HP_SCREEN_WIDTH-14, .5);
    
    UIView *line2 = [UIView new];
    line2.backgroundColor = rgb(205.f, 205.f, 205.f);
    line2.frame = CGRectMake(72.f, originY + 2, .5, 22);
    
    [self.view addSubview:line1];
    if (_types) [self.view addSubview:line2];
    
    CGRect f = self.contentTextFiled.frame;
    f.origin.y = _titleField.frame.origin.y + _titleField.frame.size.height + 5.f;
    f.origin.x = 5.f;
    f.size.width = self.view.bounds.size.width - 10.f;
    self.contentTextFiled.frame = f;
    
    _typePickerView = [[UIPickerView alloc] initWithFrame:CGRectZero];
    _typePickerView.delegate = self;
    _typePickerView.showsSelectionIndicator = YES;
    
    [self loadFormhash];
}

- (void)loadFormhash {
    
    [self.indicator startAnimating];
    
    __weak typeof(self) weakSelf = self;
    
    [HPSendPost loadFormHashWithBlock:^(NSString *formhash, NSError *error) {

        [weakSelf.indicator stopAnimating];
        if (error) {
            if ([error isNeedBindError]) {
                [weakSelf close];
                return;
            }
            [UIAlertView showConfirmationDialogWithTitle:@"出错啦"
                                                 message:[NSString stringWithFormat:@"加载失败(%@), 是否重试?", [error localizedDescription]]
                                                 handler:^(UIAlertView *alertView, NSInteger buttonIndex)
             {
                 if (buttonIndex == [alertView cancelButtonIndex]) {
                     ;
                 } else {
                     [weakSelf loadFormhash];
                 }
             }];
            return;
        }

        _formhash = formhash;
        if (_waitingForToken) {
            _waitingForToken = NO;
            [weakSelf send:nil];
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)send:(id)sender {
    
    
    if (!_formhash) {
        [self.view endEditing:YES];
        [SVProgressHUD showWithStatus:@"正在获取回复token, 马上好" maskType:SVProgressHUDMaskTypeBlack];
        _waitingForToken = YES;
        return;
    }
    
    // check
    if ([self.titleField.text isEqualToString:@""] ||
        [self.titleField.text isEqualToString:@"title here..."]) {
        [SVProgressHUD showErrorWithStatus:@"请输入标题"];
        return;
    }
    if ([self.contentTextFiled.text isEqualToString:@""] ||
        [self.contentTextFiled.text isEqualToString:@"content here..."]) {
        [SVProgressHUD showErrorWithStatus:@"请输入内容"];
        return;
    }
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [self.view endEditing:YES];
    [SVProgressHUD showWithStatus:@"发送中..." maskType:SVProgressHUDMaskTypeBlack];
    
    
    __weak typeof(self) weakSelf = self;
    [HPSendPost sendThreadWithFid:_fid
                             type:_current_type
                          subject:_titleField.text
                          message:weakSelf.contentTextFiled.text
                           images:weakSelf.imagesString
                         formhash:_formhash
                            block:^(NSString *msg, NSError *error)
     {
         weakSelf.navigationItem.rightBarButtonItem.enabled = YES;
         if (error) {
             
              [SVProgressHUD showErrorWithStatus:[error localizedDescription]];
             
         } else {
             
             [SVProgressHUD showSuccessWithStatus:@"发送成功"];
             [weakSelf doneWithError:nil];
         }
     }];
}


#pragma mark - select type

- (void)selectType:(id)sender {
    
    [self.view endEditing:YES];
    // pick forum
    
    CGFloat height = 260;
    _typePickerView.frame = CGRectMake(0, [self.view bounds].size.height - height, [self.view bounds].size.width, height);
    [self.view addSubview:_typePickerView];
}

#pragma mark UIPickerViewDelegate
- (void)pickerView:(UIPickerView *)pickerView didSelectRow: (NSInteger)row inComponent:(NSInteger)component {
    
    [_selectTypeBtn setTitle:[[_types objectAtIndex:row] objectForKey:@"key"] forState:UIControlStateNormal];
    
    _current_type = [[[_types objectAtIndex:row] objectForKey:@"value"] integerValue];
    
    [_titleField becomeFirstResponder];
    [_typePickerView removeFromSuperview];
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    
    return [_types count];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

/*
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    
    return [[_types objectAtIndex:row] objectForKey:@"key"];
}
*/
- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *title = [[_types objectAtIndex:row] objectForKey:@"key"];
    NSAttributedString *attString = [[NSAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName:[HPTheme textColor]}];
    
    if (!IOS7_OR_LATER) {
        attString = [[NSAttributedString alloc] initWithString:title];
    }
    
    return attString;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    
    int sectionWidth = 300;
    return sectionWidth;
}

@end
