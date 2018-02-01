//
//  UITableView+BlankTip.h
//  iOS-GCD学习篇
//
//  Created by zhangzhiliang on 2018/2/1.
//  Copyright © 2018年 zhangzhiliang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITableView (BlankTip)

/**
 用来判断当前tableview是否存在数据，如果不存在可以显示相关的logo、tip
 */
- (BOOL)isExistData;

@end
