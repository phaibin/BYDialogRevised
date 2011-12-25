//
//  BYDialog.h
//  BYDialog
//
//  Created by Near Xu on 10-11-10.
//  Copyright 2010 xubenyang.me
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <UIKit/UIKit.h>

@interface BYDialog : UIView {
  
 @protected 
  UIView *_contentView;
  UIDeviceOrientation _orientation;
  BOOL _showing;
  BOOL _presented;
}
@property (nonatomic, readonly) BOOL visible;
@property (nonatomic, readwrite, retain) IBOutlet UIView *contentView;

- (void)show;
- (void)dismissAnimated:(BOOL)animated;

// Default to do nothing.
- (void)willPresentDialog;
- (void)didPresentDialog;
- (void)willDismissDialog;
- (void)didDismissDialog;

@end
