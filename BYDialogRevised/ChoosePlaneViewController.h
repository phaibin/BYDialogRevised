//
//  ChoosePlaneViewController.h
//  EFB
//
//  Created by  on 12/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ChoosePlaneDelegate <NSObject>

- (void)choosePlane;

@end

@interface ChoosePlaneViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>

@property (retain, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, retain) NSMutableArray *listData;
@property (nonatomic, assign) id<ChoosePlaneDelegate> delegate;

- (IBAction)chooseTapped:(id)sender;

@end
