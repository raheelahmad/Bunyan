//
//  SKLCollectionDataSource.h
//  Bunyan
//
//  Created by Raheel Ahmad on 4/1/14.
//  Copyright (c) 2014 Sakun Labs. All rights reserved.
//

#import <UIKit/UICollectionView.h>
#import <CoreData/CoreData.h>

@protocol SKLCollectionDataSourceDelegate;

@interface SKLCollectionDataSource : NSObject<UICollectionViewDataSource>

- (id)initWithModelClass:(Class)modelClass cellCalss:(Class)cellClass;
- (void)setupCollectionView:(UICollectionView *)collectionView;

- (id)objectAtIndexPath:(NSIndexPath *)indexPath;

@property (nonatomic, weak) id<SKLCollectionDataSourceDelegate> delegate;
@property (nonatomic, readonly) NSFetchedResultsController *controller;

@end

@protocol SKLCollectionDataSourceDelegate <NSObject>

- (void)configureCell:(UICollectionViewCell *)cell withObject:(id)object;

@end
