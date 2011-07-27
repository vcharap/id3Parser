//
//  ID3FrameText.h
//

#import <Cocoa/Cocoa.h>
#import "ID3Frame.h"


@interface ID3FrameText : ID3Frame 
{
	NSStringEncoding textEncoding;
	NSString *description; //description is not nil if and only if the frame is 'TXXX'
	NSMutableArray *textStrings;
}

@property NSStringEncoding textEncoding;
@property (retain) NSMutableArray *textStrings;
@property (retain) NSString *description;
@end
