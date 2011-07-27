//
// ID3Frame.h
//

#import <Cocoa/Cocoa.h>
#import "ID3Parser.h"


//Boilerplate for ID3 FRAME header
#ifndef ID3_FRAMEHDR
#define ID3_FRAMEHDR

/*-------------- Frame Header -----------------*/

//id3v2.4 
#define V4_FRAMEHDR_LENGTH 10
#define V4_FRAMEHDR_SIZE_OFFSET 4
#define V4_FRAMEHDR_FLAGS_OFFSET 8
#define V4_FRAMEHDR_FLAGS_SIZE 2
#define V4_FRAMEHDR_ID_SIZE 4

//id3v2.3
#define V3_FRAMEHDR_LENGTH 10
#define V3_FRAMEHDR_SIZE_OFFSET 4
#define V3_FRAMEHDR_FLAGS_OFFSET 8
#define V3_FRAMEHDR_FLAGS_SIZE 2
#define V3_FRAMEHDR_ID_SIZE 4

//id3v2.2
#define V2_FRAMEHDR_LENGTH 6
#define V2_FRAMEHDR_SIZE_OFFSET 3
#define V2_FRAMEHDR_ID_SIZE 3


/*--------------- Frame Flags -------------------*/

//id3v2.4
#define V4_FRAMEHDR_FLAG_TAGALTER 64
#define V4_FRAMEHDR_FLAG_FILEALTER 32
#define V4_FRAMEHDR_FLAG_READONLY 16

#define V4_FRAMEHDR_FLAG_GROUPIDENT 64
#define V4_FRAMEHDR_FLAG_COMPRESSION 8
#define V4_FRAMEHDR_FLAG_ENCRYPTION 4
#define V4_FRAMEHDR_FLAG_UNSYNC 2
#define V4_FRAMEHDR_FLAG_DATALEN 1


//id3v2.3
#define V3_FRAMEHDR_FLAG_TAGALTER 128
#define V3_FRAMEHDR_FLAG_FILEALTER 64
#define V3_FRAMEHDR_FLAG_READONLY 32

#define V3_FRAMEHDR_FLAG_COMPRESSION 128
#define V3_FRAMEHDR_FLAG_ENCRYPTION 64
#define V3_FRAMEHDR_FLAG_GROUPIDENT 32


#define ID3_FRAMEHDR_TYPE_T 'T'
#define ID3_FRAMEHDR_TYPE_W 'W'

#endif

@interface ID3Frame : NSObject 
{
	NSString *frameID;
	NSString *frameDescription;
	NSUInteger size;
	ID3_VERSION majorVersion;	
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
@property ID3_VERSION majorVersion;
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


+ (id)getFrameFromBytes:(const void*)bytes version:(ID3_VERSION)version error:(NSError **)error; 

/*
+ (id)makeTextFrameWithIDString:(NSString *)frameIDString andBytes:(const void*)bytes;
+ (id)makeURLFrameWithIDString:(NSString *)frameIDString andBytes:(const void*)bytes;
*/

- (id)initWithID:(NSString *)frameIDString description:(NSString *)description version:(ID3_VERSION)version andBytes:(const void*)bytes error:(NSError **)error;
- (BOOL)setFlagPropertiesForData:(NSData *)data error:(NSError **)error;
- (NSDictionary *)descriptionOfFrame;
@end
