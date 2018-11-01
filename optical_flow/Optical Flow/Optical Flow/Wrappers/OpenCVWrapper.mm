//
//  OpenCVWrapper.m
//  Optical Flow
//
//  Created by Németh Bendegúz on 2018. 07. 21..
//  Copyright © 2018. Németh Bendegúz. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import "OpenCVWrapper.h"

@implementation OpenCVWrapper

cv::Mat previousMat;
std::vector<cv::Point2f> previousFeatures;

std::vector<uchar> status;
cv::Mat err;

//cv::Size winSize = cv::Size(31,31);
//cv::TermCriteria termcrit = cv::TermCriteria(cv::TermCriteria::COUNT|cv::TermCriteria::EPS,20,0.03);

- (void) cornerDetector:(CMSampleBufferRef)buf {
    
    previousMat = [self greyscaleMatFromSampleBuffer:buf];
    
    cv::goodFeaturesToTrack(previousMat, previousFeatures, 6, 0.01, 20);
    
}

- (NSMutableArray *) opticalFlowTracker:(CMSampleBufferRef)buf {
    
    cv::Mat mat = [self greyscaleMatFromSampleBuffer:buf];
    
    std::vector<cv::Point2f> features;
    
    //cv::calcOpticalFlowPyrLK(previousMat, mat, previousFeatures, features, status, err, winSize, 3, termcrit, 0, 0.001);
    cv::calcOpticalFlowPyrLK(previousMat, mat, previousFeatures, features, status, err);
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSMutableArray *previousPoints = [[NSMutableArray alloc] init];
    NSMutableArray *currentPoints = [[NSMutableArray alloc] init];
    
    for(unsigned int n = 0; n < previousFeatures.size(); n++) {
        int x = previousFeatures[n].x;
        int y = previousFeatures[n].y;
        [previousPoints addObject:[NSArray arrayWithObjects:@(x), @(y), nil]];
    }
    
    for(unsigned int n = 0; n < features.size(); n++) {
        int x = features[n].x;
        int y = features[n].y;
        [currentPoints addObject:[NSArray arrayWithObjects:@(x), @(y), nil]];
    }
    
    [array addObject:previousPoints];
    [array addObject:currentPoints];
    
    cv::goodFeaturesToTrack(mat, previousFeatures, 6, 0.01, 20);
    previousMat = mat;
    
    return array;
}

- (cv::Mat) greyscaleMatFromSampleBuffer:(CMSampleBufferRef)buf {
    
    CVImageBufferRef imgBuf = CMSampleBufferGetImageBuffer(buf);
    
    // lock the buffer
    CVPixelBufferLockBaseAddress(imgBuf, 0);
    
    // get the address to the image data
    //    void *imgBufAddr = CVPixelBufferGetBaseAddress(imgBuf);   // this is wrong! see http://stackoverflow.com/a/4109153
    void *imgBufAddr = CVPixelBufferGetBaseAddressOfPlane(imgBuf, 0);
    
    // get image properties
    int w = (int)CVPixelBufferGetWidth(imgBuf);
    int h = (int)CVPixelBufferGetHeight(imgBuf);
    
    // create the cv mat
    cv::Mat mat;
    // 8 bit unsigned chars for grayscale data
    mat.create(h, w, CV_8UC1);
    // the first plane contains the grayscale data
    memcpy(mat.data, imgBufAddr, w * h);
    // therefore we use <imgBufAddr> as source
    
    // unlock again
    CVPixelBufferUnlockBaseAddress(imgBuf, 0);
    
    return mat;
}

@end
