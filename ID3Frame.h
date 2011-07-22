//
//  ID3Frame.h
//  StreamTest
//
//  Created by mac on 7/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ID3Frame : NSObject 
{
	NSString *frameID;
	NSString *frameDescription;
	NSUInteger size;
	NSData *flags;
	
	NSData *dataForParsing;
	
	//Frame status flags
	BOOL tagAlterPreserve;
	BOOL fileAlterPreserve;
	BOOL readOnly;
	
	//Frame format flags
	BOOL groupingIdentity;
	BOOL compression;
	BOOL encryption;
	BOOL unsynchronisation;
	BOOL dataLengthIndicator;
}

//Frame Values
@property (copy) NSString *frameID;
@property (copy) NSString *frameDescription;
@property NSUInteger size;
@property (retain) NSData *flags;
@property (retain) NSData *dataForParsing;

//Frame Flags
@property BOOL tagAlterPreserve;
@property BOOL fileAlterPreserve;
@property BOOL readOnly;
@property BOOL groupingIdentity;
@property BOOL compression;
@property BOOL encryption;
@property BOOL unsynchronisation;
@property BOOL dataLengthIndicator;

//+ (id)getFrameFromData:(NSData *)data error:(NSError **)error;
+ (id)getFrameFromBytes:(const void*)bytes error:(NSError **)error; 
+ (NSData *)unsyncData:(NSData *)data;

/*
+ (id)makeTextFrameWithIDString:(NSString *)frameIDString andBytes:(const void*)bytes;
+ (id)makeURLFrameWithIDString:(NSString *)frameIDString andBytes:(const void*)bytes;
*/

- (id)initWithIDString:(NSString *)frameIDString andBytes:(const void*)bytes error:(NSError **)error;
- (BOOL)setFlagPropertiesForData:(NSData *)data error:(NSError **)error;
- (NSDictionary *)descriptionOfFrame;
@end
