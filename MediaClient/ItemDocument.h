
#import <Cocoa/Cocoa.h>

@interface ItemDocument : NSDocument {
    IBOutlet NSView *captureView;
}


- (IBAction)start:(id)sender;
- (IBAction)stop:(id)sender;

@end
