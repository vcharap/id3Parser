//
//  ID3Parser.h
//

#import <Cocoa/Cocoa.h>

#ifndef ID3_H
#define ID3_H

#define ID3_HEADER_LENGTH 10
#define ID3_HEADER_FLAGS_OFFSET 5
#define ID3_HEADER_VERSION_OFFSET 3
#define ID3_HEADER_SIZE_OFFSET 6

#define V4_HEADER_FLAG_UNSYNC 128
#define V4_HEADER_FLAG_EXTEND_HDR 64
#define V4_HEADER_FLAG_EXPERIMENTAL 32

#define V2_HEADER_FLAG_UNSYNC 128
#define V2_HEADER_FLAG_COMPRESSION 64

/*--------- Parser Errors ----------*/
#define ID3_PARSERDOMAIN_EFRAME -1
#define ID3_PARSERDOMAIN_EEMPTY 0
#define ID3_PARSERDOMAIN_ENOTFOUND 1
#define ID3_PARSERDOMAIN_EVERSION 2
#define ID3_PARSERDOMAIN_EFRAMEID 3
#define ID3_PARSERDOMAIN_EENCRYP 4
#define ID3_PARSERDOMAIN_ECOMPR 5
#define ID3_PARSERDOMAIN_EENCOD 6
#define ID3_PARSERDOMAIN_EDELIM 7
#define ID3_PARSERDOMAIN_EFORMAT 8
#define ID3_PARSERDOMAIN_EUNKOWN 9


#endif



enum ID3_VERSION{
	ID3_VERSION_2 = 2,
	ID3_VERSION_3,
	ID3_VERSION_4
};
typedef enum ID3_VERSION ID3_VERSION;

@interface ID3Parser : NSObject 
{

}

/*
 Function takes an NSData argument, returns an array representing the id3 tag. 
	
	The array is composed of NSDictionaries, one dictionary per supported frame found in tag.
		Each dictionary contains they keys "frameID", "frameDescription", and a "value".
 
 If there was a parsing error, function retrurns nil and creates an error object with a description of the error. 
	The error argument is not required, but is recomended.
*/
+ (NSArray *)parseTagWithData:(NSData *)rawData error:(NSError **)error;


+ (NSData *)unsyncData:(NSData *)data;
+ (NSError *)errorForCode:(NSInteger)errorCode underlyingError:(NSError *)otherError recoveryObject:(id)recoverObject;
+ (int)integerFromSyncsafeInteger:(int)syncsafeInt;
@end
