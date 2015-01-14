//
//  HeadTracker.mm
//  CardboardVR-iOS
//
//  Created by Peter Tribe on 2014-08-25.
//  Copyright (c) 2014 Peter Tribe. All rights reserved.
//

#include "HeadTracker.h"

HeadTracker::HeadTracker()
{
    this->referenceTimestamp = 0;
    this->lastGyroEventTimestamp = 0;
    this->manager = nil;
    this->tracker = new OrientationEKF();
    // the inertial reference frame has z up and x forward, while the world has z out and x right
    this->worldToInertialReferenceFrame = this->getRotateEulerMatrix(-90.f, 0.f, 90.f);
    // this assumes the device is landscape with the home button on the right
    this->deviceToDisplay = this->getRotateEulerMatrix(0.f, 0.f, -90.f);
}

HeadTracker::~HeadTracker()
{
    delete this->tracker;
}

GLKMatrix4 HeadTracker::getRotateEulerMatrix(float x, float y, float z)
{
    x *= (float)(M_PI / 180.0f);
    y *= (float)(M_PI / 180.0f);
    z *= (float)(M_PI / 180.0f);
    float cx = (float) cos(x);
    float sx = (float) sin(x);
    float cy = (float) cos(y);
    float sy = (float) sin(y);
    float cz = (float) cos(z);
    float sz = (float) sin(z);
    float cxsy = cx * sy;
    float sxsy = sx * sy;
    GLKMatrix4 matrix;
    matrix.m[0] = cy * cz;
    matrix.m[1] = -cy * sz;
    matrix.m[2] = sy;
    matrix.m[3] = 0.0f;
    matrix.m[4] = cxsy * cz + cx * sz;
    matrix.m[5] = -cxsy * sz + cx * cz;
    matrix.m[6] = -sx * cy;
    matrix.m[7] = 0.0f;
    matrix.m[8] = -sxsy * cz + sx * sz;
    matrix.m[9] = sxsy * sz + sx * cz;
    matrix.m[10] = cx * cy;
    matrix.m[11] = 0.0f;
    matrix.m[12] = 0.0f;
    matrix.m[13] = 0.0f;
    matrix.m[14] = 0.0f;
    matrix.m[15] = 1.0f;
    return matrix;
}

void HeadTracker::startTracking()
{
    if (this->manager != nil) {
        return;
    }
    this->tracker->reset();
    this->manager = [[CMMotionManager alloc] init];
    if ([this->manager isDeviceMotionAvailable])
    {
        [this->manager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical];
//        this->manager.magnetometerUpdateInterval = 1.0f / 100.0f;
//        [this->manager startAccelerometerUpdatesToQueue:
//         [NSOperationQueue currentQueue] withHandler:^
//         (CMAccelerometerData *accelerometerData, NSError *error)
//        {
//            GLKVector3 motionVector = GLKVector3Make(-accelerometerData.acceleration.y,
//                                                     accelerometerData.acceleration.x,
//                                                     accelerometerData.acceleration.z);
//            this->tracker->processAcc(motionVector, accelerometerData.timestamp);
//        }];
//        [this->manager startGyroUpdatesToQueue:
//         [NSOperationQueue currentQueue] withHandler:^
//         (CMGyroData *gyroData, NSError *error)
//        {
//            GLKVector3 motionVector = GLKVector3Make(-gyroData.rotationRate.y,
//                                                     gyroData.rotationRate.x,
//                                                     gyroData.rotationRate.z);
//            if (this->referenceTimestamp == 0)
//            {
//                this->referenceTimestamp =
//                [[NSDate dateWithTimeIntervalSinceNow:-gyroData.timestamp] timeIntervalSinceReferenceDate];
//            }
//            this->lastGyroEventTimestamp = gyroData.timestamp;
//            this->tracker->processAcc(motionVector, gyroData.timestamp);
//        }];
    }
}

void HeadTracker::stopTracking()
{
    if (this->manager == nil) {
        return;
    }
//    [this->manager stopAccelerometerUpdates];
//    [this->manager stopGyroUpdates];
    [this->manager stopDeviceMotionUpdates];
    this->manager = nil;
}

GLKMatrix4 HeadTracker::glMatrixFromRotationMatrix(CMRotationMatrix rotationMatrix)
{
    
    GLKMatrix4 glRotationMatrix;
    
    glRotationMatrix.m00 = rotationMatrix.m11;
    glRotationMatrix.m01 = rotationMatrix.m12;
    glRotationMatrix.m02 = rotationMatrix.m13;
    glRotationMatrix.m03 = 0.0f;
    
    glRotationMatrix.m10 = rotationMatrix.m21;
    glRotationMatrix.m11 = rotationMatrix.m22;
    glRotationMatrix.m12 = rotationMatrix.m23;
    glRotationMatrix.m13 = 0.0f;
    
    glRotationMatrix.m20 = rotationMatrix.m31;
    glRotationMatrix.m21 = rotationMatrix.m32;
    glRotationMatrix.m22 = rotationMatrix.m33;
    glRotationMatrix.m23 = 0.0f;

    glRotationMatrix.m30 = 0.0f;
    glRotationMatrix.m31 = 0.0f;
    glRotationMatrix.m32 = 0.0f;
    glRotationMatrix.m33 = 1.0f;

    return glRotationMatrix;
}

GLKMatrix4 HeadTracker::getLastHeadView()
{
//    if (this->referenceTimestamp == 0)
//    {
//        return GLKMatrix4Identity;
//    }
//    
//    double secondsSinceLastGyroEvent = [[NSDate date] timeIntervalSinceReferenceDate] - this->referenceTimestamp - this->lastGyroEventTimestamp;
//    // NSLog(@"%f", secondsSinceLastGyroEvent);
//    double secondsToPredictForward = secondsSinceLastGyroEvent + 0.03333333333333333;
//    GLKMatrix4 tempHeadView = this->tracker->getPredictedGLMatrix(secondsToPredictForward);
    CMDeviceMotion *motion = this->manager.deviceMotion;
    
    // NSLog(@"%.3f %.3f %.3f", motion.attitude.roll, motion.attitude.pitch, motion.attitude.yaw);
    
    CMRotationMatrix rotationMatrix = motion.attitude.rotationMatrix;
    GLKMatrix4 inertialReferenceFrameToDevice = GLKMatrix4Transpose(this->glMatrixFromRotationMatrix(rotationMatrix)); // note the matrix inversion
    GLKMatrix4 worldToDevice = GLKMatrix4Multiply(inertialReferenceFrameToDevice, worldToInertialReferenceFrame);
    GLKMatrix4 worldToDisplay = GLKMatrix4Multiply(deviceToDisplay, worldToDevice);
    // NSLog(@"%@", NSStringFromGLKMatrix4(outMatrix));
    return worldToDisplay;
}