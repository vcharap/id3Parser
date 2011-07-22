//
//  ID3FrameText.h
//  StreamTest
//
//  Created by mac on 7/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
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
