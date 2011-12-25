//
//  ChoosePlaneViewController.m
//  EFB
//
//  Created by  on 12/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ChoosePlaneViewController.h"

@interface ChoosePlaneViewController()

- (void)getData;

@end

@implementation ChoosePlaneViewController

@synthesize tableView = _tableView;
@synthesize listData = _listData;
@synthesize delegate = _delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _listData = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self getData];
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return NO;
}

- (void)dealloc {
    [_tableView release];
    [_listData release];
    
    [super dealloc];
}

- (void)getData
{
    [self.listData removeAllObjects];
    [self.listData addObject:@"B3306"];
    [self.listData addObject:@"B3307"];
    [self.listData addObject:@"B3308"];
    [self.listData addObject:@"B3309"];
    [self.listData addObject:@"B3330"];
}

#pragma mark - UITableView delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.listData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell.
    cell.textLabel.text = [self.listData objectAtIndex:indexPath.row];
    return cell;
}

- (IBAction)chooseTapped:(id)sender 
{
    [[NSNotificationCenter defaultCenter] postNotificationName:CLOSE_DIALOG_NOTIFICATION object:self];
}

@end
