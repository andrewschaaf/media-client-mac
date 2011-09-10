
#import "ItemDocument.h"

#import <AVFoundation/AVFoundation.h>

@implementation ItemDocument

@synthesize captureSession = captureSession, captureScreenInput = captureScreenInput;


- (id)initWithType:(NSString *)typeName error:(NSError **)outError
{
    self = [super initWithType:typeName error:outError];
    
    if (self) 
    {        
        BOOL success = [self createCaptureSession:outError];
        if (!success) 
        {
            [self release];
            return nil;
        }
    }
    
    return self;
}

- (void)dealloc
{
    [captureSession release];
    [captureScreenInput release];
    [captureMovieFileOutput release];
    [super dealloc];
}

- (IBAction)start:(id)sender
{
    NSString *desktop = [@"~/Desktop" stringByStandardizingPath];
    long long ms = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
    NSString *path = [NSString stringWithFormat:@"%@/MediaClient_%lld.mov", desktop, ms];
    [captureMovieFileOutput
            startRecordingToOutputFileURL:[NSURL fileURLWithPath:path]
                        recordingDelegate:self];
}

- (IBAction)stop:(id)sender
{
    [captureMovieFileOutput stopRecording];
}

#pragma mark Capture

- (BOOL)createCaptureSession:(NSError **)outError
{
    captureSession = [[AVCaptureSession alloc] init];
	if ( ! [captureSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        return NO;
    }
    [captureSession setSessionPreset:AVCaptureSessionPresetHigh];
    
    display = CGMainDisplayID();
    
    captureScreenInput = [[AVCaptureScreenInput alloc] initWithDisplayID:display];
    if ( ! [captureSession canAddInput:captureScreenInput]) {
        return NO;
    }
    [captureSession addInput:captureScreenInput];
    
    captureMovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    [captureMovieFileOutput setDelegate:self];
    if ( ! [captureSession canAddOutput:captureMovieFileOutput]) {
        return NO;
    }
    [captureSession addOutput:captureMovieFileOutput];
    
    return YES;
}

- (void)addCaptureVideoPreview
{
	AVCaptureVideoPreviewLayer *videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
	[videoPreviewLayer setFrame:[[captureView layer] bounds]];
	[videoPreviewLayer setAutoresizingMask:kCALayerWidthSizable|kCALayerHeightSizable];
    [[captureView layer] addSublayer:videoPreviewLayer];
	[[captureView layer] setBackgroundColor:CGColorGetConstantColor(kCGColorBlack)];
    [videoPreviewLayer release];
}

- (float)maximumScreenInputFramerate
{
	return 30.0;
}

- (void)setMaximumScreenInputFramerate:(float)maximumFramerate
{
	CMTime minimumFrameDuration = CMTimeMake(1, (int32_t)maximumFramerate);
	[captureScreenInput setMinFrameDuration:minimumFrameDuration];
}

- (void)addDisplayInputToCaptureSession:(CGDirectDisplayID)newDisplay cropRect:(CGRect)cropRect
{
    [captureSession beginConfiguration];
    if (newDisplay != display) {
        [captureSession removeInput:captureScreenInput];
        AVCaptureScreenInput *newScreenInput = [[AVCaptureScreenInput alloc] initWithDisplayID:newDisplay];
        [captureScreenInput release];
        captureScreenInput = newScreenInput;
        if ([captureSession canAddInput:captureScreenInput]) {
            [captureSession addInput:captureScreenInput];
        }
        [self setMaximumScreenInputFramerate:[self maximumScreenInputFramerate]];
    }
    [captureScreenInput setCropRect:cropRect];
    [captureSession commitConfiguration];
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    if (error) {
        [self presentError:error];
		return;
    }
    
    [[NSWorkspace sharedWorkspace] openURL:outputFileURL];
}

#pragma mark Document Stuff

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"ItemDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    [self addCaptureVideoPreview];
    [captureSession startRunning];
}

- (void)close
{
    [captureSession stopRunning];
    [super close];
}

-(BOOL)isDocumentEdited
{
    return NO;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    /*
     Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    */
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    /*
    Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    */
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    return YES;
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

@end
