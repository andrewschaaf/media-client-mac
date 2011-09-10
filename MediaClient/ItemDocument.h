
#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVCaptureOutput.h>

@class AVCaptureSession, AVCaptureScreenInput, AVCaptureMovieFileOutput;

@interface ItemDocument : NSDocument <AVCaptureFileOutputDelegate,AVCaptureFileOutputRecordingDelegate> {
    IBOutlet NSView *captureView;
@private
    CGDirectDisplayID           display;
    AVCaptureSession            *captureSession;
    AVCaptureScreenInput        *captureScreenInput;
    AVCaptureMovieFileOutput    *captureMovieFileOutput;
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
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error;

@end
