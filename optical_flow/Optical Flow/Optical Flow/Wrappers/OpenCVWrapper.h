//
//  OpenCVWrapper.h
//  Optical Flow
//
//  Created by Németh Bendegúz on 2018. 07. 21..
//  Copyright © 2018. Németh Bendegúz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface OpenCVWrapper : NSObject

- (void) cornerDetector:(CMSampleBufferRef)buf;
- (NSMutableArray *) opticalFlowTracker:(CMSampleBufferRef)buf;

@end
