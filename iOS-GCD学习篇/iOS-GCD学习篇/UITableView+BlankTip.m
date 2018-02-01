//
//  UITableView+BlankTip.m
//  iOS-GCD学习篇
//
//  Created by zhangzhiliang on 2018/2/1.
//  Copyright © 2018年 zhangzhiliang. All rights reserved.
//

#import "UITableView+BlankTip.h"

@implementation UITableView (BlankTip)

- (BOOL)isExistData {
   __block NSInteger count = 0;
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    if (self.numberOfSections) {
        __weak typeof(self) weakSelf = self;
        dispatch_apply(self.numberOfSections, queue, ^(size_t index) {
            count = count + [weakSelf numberOfRowsInSection:index];
        });
        if (count > 0) {
            return YES;
        } else {
            return NO;
        }
    }
    return NO;
}

@end
