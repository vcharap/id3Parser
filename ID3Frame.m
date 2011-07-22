//
//  ID3Frame.m
//  StreamTest
//
//  Created by mac on 7/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#import "ID3Frame.h"
#import "ID3FrameText.h"
#import "ID3Parser.h"
#import "zlib.h"

#define AENC @"AENC Audio encryption"
#define APIC @"APIC Attached picture"
#define ASPI @"ASPI Audio seek point index"
#define COMM @"COMM Comments"
#define COMR @"COMR Commercial frame"
#define ENCR @"ENCR Encryption method registration"
#define EQU2 @"EQU2 Equalisation (2)"
#define ETCO @"ETCO Event timing codes"
#define GEOB @"GEOB General encapsulated object"
#define GRID @"GRID Group identification registration"
#define LINK @"LINK Linked information"
#define MCDI @"MCDI Music CD identifier"
#define MLLT @"MLLT MPEG location lookup table"
#define OWNE @"OWNE Ownership frame"
#define PRIV @"PRIV Private frame"
#define PCNT @"PCNT Play counter"
#define POPM @"POPM Popularimeter"
#define POSS @"POSS Position synchronisation frame"
#define RBUF @"RBUF Recommended buffer size"
#define RVA2 @"RVA2 Relative volume adjustment (2)"
#define RVRB @"RVRB Reverb"
#define SEEK @"SEEK Seek frame"
#define SIGN @"SIGN Signature frame"
#define SYLT @"SYLT Synchronised lyric/text"
#define SYTC @"SYTC Synchronised tempo codes"
#define TALB @"TALB Album/Movie/Show title"
#define TBPM @"TBPM BPM (beats per minute)"
#define TCOM @"TCOM Composer"
#define TCON @"TCON Content type"
#define TCOP @"TCOP Copyright message"
#define TDEN @"TDEN Encoding time"
#define TDLY @"TDLY Playlist delay"
#define TDOR @"TDOR Original release time"
#define TDRC @"TDRC Recording time"
#define TDRL @"TDRL Release time"
#define TDTG @"TDTG Tagging time"
#define TENC @"TENC Encoded by"
#define TEXT @"TEXT Lyricist/Text writer"
#define TFLT @"TFLT File type"
#define TIPL @"TIPL Involved people list"
#define TIT1 @"TIT1 Content group description"
#define TIT2 @"TIT2 Title/songname/content description"
#define TIT3 @"TIT3 Subtitle/Description refinement"
#define TKEY @"TKEY Initial key"
#define TLAN @"TLAN Language(s)"
#define TLEN @"TLEN Length"
#define TMCL @"TMCL Musician credits list"
#define TMED @"TMED Media type"
#define TMOO @"TMOO Mood"
#define TOAL @"TOAL Original album/movie/show title"
#define TOFN @"TOFN Original filename"
#define TOLY @"TOLY Original lyricist(s)/text writer(s)"
#define TOPE @"TOPE Original artist(s)/performer(s)"
#define TOWN @"TOWN File owner/licensee"
#define TPE1 @"TPE1 Lead performer(s)/Soloist(s)"
#define TPE2 @"TPE2 Band/orchestra/accompaniment"
#define TPE3 @"TPE3 Conductor/performer refinement"
#define TPE4 @"TPE4 Interpreted, remixed, or otherwise modified by"
#define TPOS @"TPOS Part of a set"
#define TPRO @"TPRO Produced notice"
#define TPUB @"TPUB Publisher"
#define TRCK @"TRCK Track number/Position in set"
#define TRSN @"TRSN Internet radio station name"
#define TRSO @"TRSO Internet radio station owner"
#define TSOA @"TSOA Album sort order"
#define TSOP @"TSOP Performer sort order"
#define TSOT @"TSOT Title sort order"
#define TSRC @"TSRC ISRC (international standard recording code)"
#define TSSE @"TSSE Software/Hardware and settings used for encoding"
#define TSST @"TSST Set subtitle"
#define TXXX @"TXXX User defined text information frame"
#define UFID @"UFID Unique file identifier"
#define USER @"USER Terms of use"
#define USLT @"USLT Unsynchronised lyric/text transcription"
#define WCOM @"WCOM Commercial information"
#define WCOP @"WCOP Copyright/Legal information"
#define WOAF @"WOAF Official audio file webpage"
#define WOAR @"WOAR Official artist/performer webpage"
#define WOAS @"WOAS Official audio source webpage"
#define WORS @"WORS Official Internet radio station homepage"
#define WPAY @"WPAY Payment"
#define WPUB @"WPUB Publishers official webpage"
#define WXXX @"WXXX User defined URL link frame"


//Boilerplate for ID3 FRAME header
#ifndef ID3_FRAMEHDR
#define ID3_FRAMEHDR

#define ID3_FRAMEHDR_LENGTH 10
#define ID3_FRAMEHDR_SIZE_OFFSET 4
#define ID3_FRAMEHDR_FLAGS_OFFSET 8
#define ID3_FRAMEHDR_FLAGS_SIZE 2
#define ID3_FRAMEHDR_ID_SIZE 4
#endif


#define ID3_FRAMEHDR_FLAG_TAGALTER 64
#define ID3_FRAMEHDR_FLAG_FILEALTER 32
#define ID3_FRAMEHDR_FLAG_READONLY 16

#define ID3_FRAMEHDR_FLAG_GROUPIDENT 64
#define ID3_FRAMEHDR_FLAG_COMPRESSION 8
#define ID3_FRAMEHDR_FLAG_ENCRYPTION 4
#define ID3_FRAMEHDR_FLAG_UNSYNC 2
#define ID3_FRAMEHDR_FLAG_DATALEN 1

/*	Frames are grouped by type. For example, all text frames begin with T (as in TPE2) 
 while URL link frames being with W (as in WCOP)
	The values below will be used in a switch statement to determine what type of frame to create
*/

#define ID3_FRAMEHDR_TYPE_T 'T'
#define ID3_FRAMEHDR_TYPE_W 'W'

static NSSet *declaredFrames;

#pragma mark -
#pragma mark Implimentation

/*
 TODO: Consider if its neccessary to reset the parseError and isInParseError with each call to getFrameFrom...
*/

@implementation ID3Frame
@synthesize frameID, frameDescription, flags, size, dataForParsing;
@synthesize tagAlterPreserve, fileAlterPreserve, readOnly, groupingIdentity, compression, encryption, unsynchronisation, dataLengthIndicator;


/*
 Function initializes the Class' variables (note: these are different from an objects instance variables)
*/
+ (void)initialize
{
	if(self == [ID3Frame class]){
		declaredFrames = [NSSet setWithObjects:AENC, APIC, ASPI, COMM, COMR, ENCR, EQU2, ETCO, GEOB, GRID, 
						  LINK, MCDI, MLLT, OWNE, PRIV, PCNT, POPM, POSS, RBUF, RVA2, RVRB, SEEK, SIGN, SYLT, 
						  SYTC, TALB, TBPM, TCOM, TCON, TCOP, TDEN, TDLY, TDOR, TDRC, TDRL, TDTG, TENC, TEXT, 
						  TFLT, TIPL, TIT1, TIT2, TIT3, TKEY, TLAN, TLEN, TMCL, TMED, TMOO, TOAL, TOFN, TOLY, 
						  TOPE, TOWN, TPE1, TPE2, TPE3, TPE4, TPOS, TPRO, TPUB, TRCK, TRSN, TRSO, TSOA, TSOP, 
						  TSOT, TSRC, TSSE, TSST, TXXX, UFID, USER, USLT, WCOM, WCOP, WOAF, WOAR, WOAS, WORS, 
						  WPAY, WPUB, WXXX, nil];
		[declaredFrames retain];

	}
}

/*
 Function removes unsyncronization bytes from a given data object 
 (i.e. all patterns of 0xFF 0x00 are turned into 0xFF)
	- return value is an autoreleased NSData object
*/
+ (NSData *)unsyncData:(NSData *)data
{	
	NSUInteger bufferSize = [data length];
	if(!bufferSize) return nil;
	
	char *buffer = malloc(bufferSize *sizeof(char));
	const char *bytes = (const char*)[data bytes];
	
	NSUInteger index = 0;
	BOOL possibleSync = NO;
	const char* ptr = bytes;
	const char* ptr_end = bytes + bufferSize;
	char FF = 0xFF;
	
	for(; ptr != ptr_end; ptr++){
		char value = *ptr;
		if(possibleSync){
			if(value) possibleSync = NO;
			else{
				possibleSync = NO;
				continue;
			}
		}
		
		if(value == FF){
			possibleSync = YES;
		}
		buffer[index++] = value;
	}
	
	return [NSData dataWithBytes:buffer length:index];
	
}
+ (id)getFrameFromData:(NSData *)data erorr:(NSError **)error
{
	return [ID3Frame getFrameFromBytes:(const void*)[data bytes] error:error];
}

/*
 Function returns a frame for the given bytes.
	- bytes pointer must point to the first byte of a frame.
	- return value is any of the possible sublcasses of ID3Frame, or nil on error.
*/
+ (id)getFrameFromBytes:(const void*)bytes error:(NSError **)error
{
	
	if(bytes == NULL){
		if(error != NULL){
			*error = [ID3Parser errorForCode:ID3_PARSERDOMAIN_EEMPTY underlyingError:nil recoveryObject:nil];
		}
		return nil;
	}

	NSString *ID = [[NSString alloc] initWithBytes:bytes length:ID3_FRAMEHDR_ID_SIZE encoding:NSASCIIStringEncoding];
	
	//Look for frame's ID in the class' set of frames
	NSSet *foundFrames = [declaredFrames objectsPassingTest:^(id string, BOOL *stop){
		NSComparisonResult compareResult = [string compare:ID 
												   options:NSLiteralSearch 
													 range:NSMakeRange(0, ID3_FRAMEHDR_ID_SIZE)];
		if(compareResult == NSOrderedSame){
			*stop = YES;
			return YES;
		}
		else return NO;
	}];

	NSString *foundFrameString = [foundFrames anyObject];
	if(foundFrameString == nil){//Frame ID not found
		NSLog(@"Frame ID: %@ not found\n", ID);
		if(error != NULL){
			*error = [ID3Parser errorForCode:ID3_PARSERDOMAIN_EFRAMEID underlyingError:nil recoveryObject:nil];
		}
		[ID release];	
		return nil;
	}
	
	NSLog(@"Found frame with frame string: %@", foundFrameString);
	//Initialize the ID3Frame object, set its values
	ID3Frame *frame;
	unichar frameType = [foundFrameString characterAtIndex:0];
	switch (frameType) {
		case ID3_FRAMEHDR_TYPE_T:
		{
			frame = [[ID3FrameText alloc] initWithIDString:foundFrameString andBytes:bytes error:error];
			break;
		}
		case ID3_FRAMEHDR_TYPE_W:
		{
			NSLog(@"Type W (URL) frame found. Specifically the frame is: %@\n Frames of type W are currently not supported.", foundFrameString);
			frame = [[ID3Frame alloc] initWithIDString:foundFrameString andBytes:bytes error:error];
			if(error) *error = [ID3Parser errorForCode:ID3_PARSERDOMAIN_EUNKOWN underlyingError:nil recoveryObject:frame];
			[frame release];
			return nil;
		}
		default:
		{
			NSLog(@"Unsupported frame is found. Specifically, the frame is: %@", foundFrameString);
			frame = [[ID3Frame alloc] initWithIDString:foundFrameString andBytes:bytes error:error];
			if(error) *error = [ID3Parser errorForCode:ID3_PARSERDOMAIN_EUNKOWN underlyingError:nil recoveryObject:frame];
			[frame release];
			return nil;
		}
	}

	return [frame autorelease];
	
}

/*
	TODO: MUST CHANGE SIZE VALUE AFTER UNSYNC AND DECOMPRESS!!!!!!!!
			MUST RELEASE SELF IF INITIALIZATION FAILED!!!!!!
*/
- (id)initWithIDString:(NSString *)frameIDString andBytes:(const void*)bytes error:(NSError **)error
{
	self = [super init];
	if(self){
		//Set frame values
		self.frameID = [frameIDString substringWithRange:NSMakeRange(0, ID3_FRAMEHDR_ID_SIZE)];
		self.frameDescription = [frameIDString substringFromIndex:ID3_FRAMEHDR_ID_SIZE + 1];
		
		int syncInteger = *(int *)(bytes + ID3_FRAMEHDR_SIZE_OFFSET);
		self.size = [ID3Parser integerFromSyncsafeInteger:syncInteger];
		
		//Set flag values
		self.flags = [NSData dataWithBytes:bytes + ID3_FRAMEHDR_FLAGS_OFFSET length:ID3_FRAMEHDR_FLAGS_SIZE];
		BOOL value = [self setFlagPropertiesForData:self.flags error:nil];
		
		assert(value);
		if(!value){
		
			return nil;
		}
		
		//Manipulate frame body as required by flags to get raw bytes for parsing
		if(self.encryption){
			if(error){
				*error = [ID3Parser errorForCode:ID3_PARSERDOMAIN_EENCRYP underlyingError:nil recoveryObject:self];
			}
			[self release];
			return nil;
		}
		
		const char* frameBody = (const char*)bytes + ID3_FRAMEHDR_LENGTH;
		self.dataForParsing = [NSData dataWithBytes:frameBody length:self.size];
		if(self.unsynchronisation){
			self.dataForParsing = [ID3Frame unsyncData:self.dataForParsing];
		}
		
		if(self.compression){//Decompression currently not supported, but will be soon!
			if(error){
				*error = [ID3Parser errorForCode:ID3_PARSERDOMAIN_ECOMPR underlyingError:nil recoveryObject:self];
			}
			[self release];
			return nil;
			
			//DO DECOMPRESSION HERE!
			
			/*NOTE THAT unsyncData size must be used!*/
			//self.dataForParsing = nil; //DECOMPRESS
		}		
	}
	return self;
}

/*
 Function sets flags of frame for a given NSData ojbect
	- return value YES if succesful. NO if argument is too small
*/
- (BOOL)setFlagPropertiesForData:(NSData *)data error:(NSError **)error
{
	if([data length] == 2){
		if(![self.flags isEqualToData:data]) self.flags = data;
		
		char byte;
		//1st byte - frame header flags
		[self.flags getBytes:&byte range:NSMakeRange(0, 1)];
		if(byte & ID3_FRAMEHDR_FLAG_TAGALTER)self.tagAlterPreserve = YES;
		if(byte & ID3_FRAMEHDR_FLAG_FILEALTER)self.fileAlterPreserve = YES;
		if(byte & ID3_FRAMEHDR_FLAG_READONLY)self.readOnly = YES;
		
		//2nd byte - frame status flags
		[self.flags getBytes:&byte range:NSMakeRange(1, 1)];
		if(byte & ID3_FRAMEHDR_FLAG_GROUPIDENT)self.groupingIdentity = YES;
		if(byte & ID3_FRAMEHDR_FLAG_COMPRESSION)self.compression = YES;
		if(byte & ID3_FRAMEHDR_FLAG_ENCRYPTION)self.encryption = YES;
		if(byte & ID3_FRAMEHDR_FLAG_UNSYNC)self.unsynchronisation = YES;
		if(byte & ID3_FRAMEHDR_FLAG_DATALEN)self.dataLengthIndicator = YES;
		
		return YES;
		
	}
	else{
		return NO;
	}
}


- (NSDictionary *)descriptionOfFrame
{
	return [NSDictionary dictionaryWithObjectsAndKeys:self.frameID, @"frameID", self.frameDescription, @"frameDescription", nil];
}

@end
