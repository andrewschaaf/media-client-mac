
#import "ItemDocument.h"

#import <AVFoundation/AVFoundation.h>

#define FRAMES_PER_SECOND 4

@implementation ItemDocument

@synthesize captureSession = captureSession, captureScreenInput = captureScreenInput;


- (id)initWithType:(NSString *)typeName error:(NSError **)outError
{
    self = [super initWithType:typeName error:outError];
    
    initializedAt = [[NSDate date] timeIntervalSince1970];
    numFramesCaptured = 0;
    numFramesDropped = 0;
    
    if (self) {
        BOOL success = [self createCaptureSession:outError];
        if ( ! success) {
            [self release];
            return nil;
        }
        
        [NSTimer
             scheduledTimerWithTimeInterval:(500 / 1000.0)
             target:self
             selector:@selector(printStats:)
             userInfo:nil
             repeats:YES];
    }
    
    return self;
}

- (void)printStats:(NSTimer*)timer
{
    if (numFramesCaptured > 5) {
        double elapsed = (double)[[NSDate date] timeIntervalSince1970] - (double)initializedAt;
        double fps = numFramesCaptured / elapsed;
        NSLog(@"%.4f FPS, %lld total, %lld dropped", fps, (long long)numFramesCaptured, (long long)numFramesDropped);
    }
}

- (void)dealloc
{
    [captureSession release];
    [captureScreenInput release];
    [captureVideoDataOutput release];
    [super dealloc];
}

- (IBAction)start:(id)sender
{
    
}

- (IBAction)stop:(id)sender
{
    
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
    
    
    [self setMaximumScreenInputFramerate:[self maximumScreenInputFramerate]];
    
    
    captureVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [captureVideoDataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    if ( ! [[captureVideoDataOutput availableVideoCodecTypes] containsObject:@"avc1"]) {
        NSLog(@"avc1 not supported!");
        return NO;
    }
    
    NSDictionary *settings;
    if (true) {
        settings = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithUnsignedInt:kCVPixelFormatType_24RGB], (NSString*)kCVPixelBufferPixelFormatTypeKey,
            nil];
    }
    else {
        settings = [NSDictionary dictionaryWithObjectsAndKeys:
            @"avc1",                      AVVideoCodecKey,
            [NSNumber numberWithInt:360], AVVideoWidthKey,
            [NSNumber numberWithInt:225], AVVideoHeightKey,
            // AVVideoMaxKeyFrameIntervalKey
            // AVVideoAverageBitRateKey
            // AVVideoCompressionPropertiesKey: ?
            nil];
    }
    [captureVideoDataOutput setVideoSettings:settings];
    if ( ! [captureSession canAddOutput:captureVideoDataOutput]) {
        return NO;
    }
    [captureSession addOutput:captureVideoDataOutput];
    
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
	return FRAMES_PER_SECOND;
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
    }
    [captureScreenInput setCropRect:cropRect];
    [captureSession commitConfiguration];
}


#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate

// video frame was discarded
- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    numFramesDropped += 1;
}

// video frame was written
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sb fromConnection:(AVCaptureConnection *)connection
{
    if ( ! task) {
        task = [[NSTask alloc] init];
        [task setLaunchPath:@"/usr/local/bin/coffee"];
        [task setEnvironment:[NSDictionary dictionaryWithObjectsAndKeys:
                              NSUserName(),                       @"USER",
                              @"/usr/local/bin:/usr/bin:/bin",    @"PATH",
                              nil]];
        [task setArguments:[NSArray arrayWithObjects:
                            [[NSBundle mainBundle] pathForResource:@"upload" ofType:@"coffee"],
                            [NSString stringWithFormat:@"%d", (int)FRAMES_PER_SECOND],
                            nil]];
        [task setStandardInput:[NSPipe pipe]];
        [task launch];
        
        taskStdin = [[task standardInput] fileHandleForWriting];
    }
    
    
    if (numFramesCaptured == 0) {
        initializedAt = [[NSDate date] timeIntervalSince1970];
    }
    numFramesCaptured += 1;
    
    CVImageBufferRef img = CMSampleBufferGetImageBuffer(sb);
    CGSize encodedSize = CVImageBufferGetEncodedSize(img);
    
    CVPixelBufferLockBaseAddress(img, 0);
    
    void *baseAddress = CVPixelBufferGetBaseAddress(img); 
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(img); 
    int width = (int)CVPixelBufferGetWidth(img); 
    int height = (int)CVPixelBufferGetHeight(img); 
    
    [taskStdin writeData:[[NSString stringWithFormat:@"P6\n%d %d\n255\n", (int)width, (int)height]
                                dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSData *pixels = [[NSData alloc] initWithBytesNoCopy:baseAddress length:(bytesPerRow * height) freeWhenDone:NO];
    [taskStdin writeData:pixels];
    
    CVPixelBufferUnlockBaseAddress(img, 0);
    
    //NSLog(@"[SAMPLE] RGB [%d, %d]", (int)encodedSize.width, (int)encodedSize.height);
    
    // NSLog(@"[SAMPLE] typeId=%lu, ns=%ld, %lld, %lld", typeId, numSamples, DecodeTimeStamp, PresentationTimeStamp);
    
    /*
    // If you need to reference the CMSampleBuffer object outside of the scope of this method, you must CFRetain it and then CFRelease it when you are finished with it.
    
    long numSamples = (long)CMSampleBufferGetNumSamples(sb);
    long long DecodeTimeStamp = (long long)CMTimeGetSeconds(CMSampleBufferGetOutputDecodeTimeStamp(sb));
    long long PresentationTimeStamp = (long long)CMTimeGetSeconds(CMSampleBufferGetOutputPresentationTimeStamp(sb));
    unsigned long typeId = 0;// (unsigned long)(CMSampleBufferGetTypeID(sb));
    
    NSLog(@"[SAMPLE] typeId=%lu, ns=%ld, %lld, %lld", typeId, numSamples, DecodeTimeStamp, PresentationTimeStamp);
     
     CMTime CMSampleBufferGetOutputDecodeTimeStamp
     CMSampleBufferGetOutputDuration
     CMSampleBufferGetOutputPresentationTimeStamp
     
     */
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
