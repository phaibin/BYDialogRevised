//
//  BYDialogRevisedViewController.m
//  BYDialogRevised
//
//  Created by  on 12/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BYDialogRevisedViewController.h"
#import "ChoosePlaneViewController.h"
#import "BYDialog.h"

@implementation BYDialogRevisedViewController

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

- (IBAction)popupTapped:(id)sender {
    ChoosePlaneViewController *choosePlaneViewController = [[ChoosePlaneViewController alloc] initWithNibName:@"ChoosePlaneViewController" bundle:nil];
    BYDialog *dialog = [[BYDialog alloc] initWithFrame:CGRectZero];
    dialog.contentView = choosePlaneViewController.view;
    [dialog show];
    [dialog release];
}

@end
