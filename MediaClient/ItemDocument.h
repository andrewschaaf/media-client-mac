
#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVCaptureOutput.h>

@class AVCaptureSession, AVCaptureScreenInput, AVCaptureMovieFileOutput;

@interface ItemDocument : NSDocument <AVCaptureVideoDataOutputSampleBufferDelegate> {
    IBOutlet NSView *captureView;
@private
    
    CGDirectDisplayID           display;
    AVCaptureSession            *captureSession;
    AVCaptureScreenInput        *captureScreenInput;
    AVCaptureVideoDataOutput    *captureVideoDataOutput;
    
    NSTimeInterval initializedAt;
    double numFramesCaptured;
    double numFramesDropped;
    
    NSTask *task;
    NSFileHandle *taskStdin;
}

@property (retain) AVCaptureSession *captureSession;
@property (retain) AVCaptureScreenInput *captureScreenInput;

- (IBAction)start:(id)sender;
- (IBAction)stop:(id)sender;


- (BOOL)createCaptureSession:(NSError **)outError;
- (void)addCaptureVideoPreview;
- (float)maximumScreenInputFramerate;
- (void)setMaximumScreenInputFramerate:(float)maximumFramerate;
- (void)addDisplayInputToCaptureSession:(CGDirectDisplayID)newDisplay cropRect:(CGRect)cropRect;

@end
