//
//  SKLManagedDataSource.h
//  Bunyan
//
//  Created by Raheel Ahmad on 3/5/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SKLDataSourceDelegate;
@class SKLManagedObject;

@interface SKLManagedDataSource : NSObject<UITableViewDataSource>

@property (nonatomic) id<SKLDataSourceDelegate> delegate;

- (id)initWithModelClass:(Class)modelClass cellCalss:(Class)cellClass;
- (void)setupTableView:(UITableView *)tableView;

- (SKLManagedObject *)objectAtIndexPath:(NSIndexPath *)indexPath;

@end

@protocol SKLDataSourceDelegate <NSObject>

- (void)configureCell:(UITableViewCell *)cell withObject:(id)object;

@end
