//
// ID3Frame.m
//

#import "ID3Frame.h"
#import "ID3Parser.h"
#import "ID3FrameText.h"
#import "frameIDALL.h"


static NSSet *declaredFrames;


@implementation ID3Frame
@synthesize majorVersion, frameID, frameDescription, flags, size, dataForParsing;
@synthesize tagAlterPreserve, fileAlterPreserve, readOnly, groupingIdentity, compression, encryption, unsynchronisation, dataLengthIndicator;


/*
 Function initializes the Class' variables (note: these are different from an objects instance variables)
*/
+ (void)initialize
{
	if(self == [ID3Frame class]){
		declaredFrames = [NSSet setWithObjects:AENC, APIC, ASPI, COMM, COMR, ENCR, EQU2, ETCO, GEOB, GRID, LINK, MCDI, MLLT, OWNE, 
						  PRIV, PCNT, POPM, POSS, RBUF, RVA2, RVRB, SEEK, SIGN, SYLT, SYTC, TALB, TBPM, TCOM, TCON, TCOP, TDEN, 
						  TDLY, TDOR, TDRC, TDRL, TDTG, TENC, TEXT, TFLT, TIPL, TIT1, TIT2, TIT3, TKEY, TLAN, TLEN, TMCL, TMED, 
						  TMOO, TOAL, TOFN, TOLY, TOPE, TOWN, TPE1, TPE2, TPE3, TPE4, TPOS, TPRO, TPUB, TRCK, TRSN, TRSO, TSOA, 
						  TSOP, TSOT, TSRC, TSSE, TSST, TXXX, UFID, USER, USLT, WCOM, WCOP, WOAF, WOAR, WOAS, WORS, WPAY, WPUB, 
						  WXXX, CRM, EQU, RVA, SLT, STC, TDA, TIM, TOR, TP1, TRD, TSI, TYE, ULT, nil];
		[declaredFrames retain];

	}
}

/*
 Function returns a frame for the given bytes. Returns any of the possible sublcasses of ID3Frame, or nil on error. If nil, check NSError.
	- bytes pointer must point to the first byte of a frame.
*/
+ (id)getFrameFromBytes:(const void*)bytes version:(ID3_VERSION)version error:(NSError **)error
{
	
	if(bytes == NULL){
		if(error) *error = [ID3Parser errorForCode:ID3_PARSERDOMAIN_EEMPTY underlyingError:NULL recoveryObject:nil];
		return nil;
	}

	NSUInteger idSize;
	if(version == ID3_VERSION_2) idSize = V2_FRAMEHDR_ID_SIZE;
	else idSize = V4_FRAMEHDR_ID_SIZE;
	
	NSString *anID = [[NSString alloc] initWithBytes:bytes length:idSize encoding:NSASCIIStringEncoding];
	
	//Look for frame's ID in the class' set of frames
	NSSet *foundFrames = [declaredFrames objectsPassingTest:^(id aString, BOOL *stop){
		
		NSRange idRange = [aString rangeOfString:@" "];
		if(idRange.location == NSNotFound) return NO;
		NSString *idString = [aString substringToIndex:idRange.location];
		
		NSUInteger length = [idString length];
		if(version == ID3_VERSION_2){
			if(length == 4) return NO;
			if(length == 8) idString = [idString substringFromIndex:5];
			
		}
		else{
			if(length == 3) return NO;
			if(length  == 8) idString = [idString substringToIndex:4];
		}

		NSComparisonResult compareResult = [idString compare:anID options:NSLiteralSearch];
		if(compareResult == NSOrderedSame){
			*stop = YES;
			return YES;
		}
		else return NO;
	}];

	NSString *foundFrameString = [foundFrames anyObject];
	if(foundFrameString == nil){//Frame ID not found
		NSLog(@"Frame ID: %@ not found\n", anID);
		if(error != NULL){
			*error = [ID3Parser errorForCode:ID3_PARSERDOMAIN_EFRAMEID underlyingError:nil recoveryObject:nil];
		}
		[anID release];	
		return nil;
	}
	
	NSLog(@"Found frame with frame string: %@", foundFrameString);
	
	NSRange space = [foundFrameString rangeOfString:@" "];
	assert(space.location != NSNotFound);
	
	NSString *description = [foundFrameString substringFromIndex:space.location + 1];
	
	//Initialize the ID3Frame object, set its values
	ID3Frame *frame;
	unichar frameType = [foundFrameString characterAtIndex:0];
	switch (frameType) {
		case ID3_FRAMEHDR_TYPE_T:
		{
			frame = [[ID3FrameText alloc] initWithID:anID description:description version:version andBytes:bytes error:error];
			break;
		}
		case ID3_FRAMEHDR_TYPE_W:
		{
			NSLog(@"Type W (URL) frame found. Specifically the frame is: %@\n Frames of type W are currently not supported.", foundFrameString);
			frame = [[ID3Frame alloc] initWithID:anID description:description version:version andBytes:bytes error:error];
			if(error) *error = [ID3Parser errorForCode:ID3_PARSERDOMAIN_EUNKOWN underlyingError:nil recoveryObject:frame];
			[frame release];
			[anID release];
			return nil;
		}
		default:
		{
			NSLog(@"Unsupported frame is found. Specifically, the frame is: %@", foundFrameString);
			frame = [[ID3Frame alloc] initWithID:anID description:description version:version andBytes:bytes error:error];
			if(error) *error = [ID3Parser errorForCode:ID3_PARSERDOMAIN_EUNKOWN underlyingError:nil recoveryObject:frame];
			[frame release];
			[anID release];
			return nil;
		}
	}

	[anID release];
	return [frame autorelease];
	
}

/*
 Function initializes a frame instance. Returns the initialized frame, or nil on error. If nil, check NSError.
	- frameIDString is the 3 or 4 letter frame ID
	- description is the string description of the frame ID
	- bytes is a pointer to beginning of frame header, can't be null.
*/
- (id)initWithID:(NSString*)frameIDString description:(NSString*)idDescription version:(ID3_VERSION)version andBytes:(const void*)bytes error:(NSError **)error
{
	if(bytes == NULL){
		if(error) *error = [ID3Parser errorForCode:ID3_PARSERDOMAIN_EEMPTY underlyingError:NULL recoveryObject:nil];
		return nil;
	}
	
	self = [super init];
	if(self){
		//set frame values
		majorVersion = version;
		self.frameID = frameIDString;
		self.frameDescription = idDescription;
		
		//set size
		if(majorVersion == ID3_VERSION_2){
			char num[4];
			num[0] = 0;
			const char* ptr = (const char*)bytes + V2_FRAMEHDR_SIZE_OFFSET;
			memcpy(num + 1, ptr, 3);
			self.size = CFSwapInt32BigToHost(*(uint32_t*)num);
		}
		else if(majorVersion == ID3_VERSION_3){
			const int *sizePtr = (const int*)((const char*)bytes + V4_FRAMEHDR_SIZE_OFFSET);
			self.size = CFSwapInt32BigToHost(*sizePtr);
		}
		else if(majorVersion == ID3_VERSION_4){
			int syncInteger = *(int *)(bytes + V4_FRAMEHDR_SIZE_OFFSET);
			self.size = [ID3Parser integerFromSyncsafeInteger:syncInteger];
		}

		
		//set flag values
		if(majorVersion == ID3_VERSION_4 || majorVersion == ID3_VERSION_3){
			self.flags = [NSData dataWithBytes:bytes + V4_FRAMEHDR_FLAGS_OFFSET length:V4_FRAMEHDR_FLAGS_SIZE];
			BOOL value = [self setFlagPropertiesForData:self.flags error:nil];
			assert(value);
		}
		
		
		if(self.encryption){
			if(error){
				*error = [ID3Parser errorForCode:ID3_PARSERDOMAIN_EENCRYP underlyingError:nil recoveryObject:self];
			}
			[self release];
			return nil;
		}
		
		//get frame body
		NSUInteger frameHeaderLength;
		if(majorVersion == ID3_VERSION_2) frameHeaderLength = V2_FRAMEHDR_LENGTH;
		else frameHeaderLength = V4_FRAMEHDR_LENGTH;
		
		const char* frameBody = (const char*)bytes + frameHeaderLength;
		self.dataForParsing = [NSData dataWithBytes:frameBody length:self.size];
		
		if(self.unsynchronisation){
			self.dataForParsing = [ID3Parser unsyncData:self.dataForParsing];
		}
		
		if(self.compression){//Decompression currently not supported - reports an error
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
	- return value YES if succesful. NO if argument is too small.
 
	TODO: Add error reporting
*/
- (BOOL)setFlagPropertiesForData:(NSData *)data error:(NSError **)error
{
	if(self.majorVersion == ID3_VERSION_2)return NO;
	
	if([data length] == 2){
		if(![self.flags isEqualToData:data]) self.flags = data;
		
		char byte;
		//1st byte - frame header flags
		[self.flags getBytes:&byte range:NSMakeRange(0, 1)];
		if(self.majorVersion == ID3_VERSION_4){

			if(byte & V4_FRAMEHDR_FLAG_TAGALTER)self.tagAlterPreserve = YES;
			if(byte & V4_FRAMEHDR_FLAG_FILEALTER)self.fileAlterPreserve = YES;
			if(byte & V4_FRAMEHDR_FLAG_READONLY)self.readOnly = YES;
		}
		else if(self.majorVersion == ID3_VERSION_3){
			if(byte & V3_FRAMEHDR_FLAG_TAGALTER)self.tagAlterPreserve = YES;
			if(byte & V3_FRAMEHDR_FLAG_FILEALTER)self.fileAlterPreserve = YES;
			if(byte & V3_FRAMEHDR_FLAG_READONLY)self.readOnly = YES;		
		}
		
		//2nd byte - frame status flags
		[self.flags getBytes:&byte range:NSMakeRange(1, 1)];
		if(self.majorVersion == ID3_VERSION_4){

			if(byte & V4_FRAMEHDR_FLAG_COMPRESSION)self.compression = YES;
			if(byte & V4_FRAMEHDR_FLAG_ENCRYPTION)self.encryption = YES;
			if(byte & V4_FRAMEHDR_FLAG_UNSYNC)self.unsynchronisation = YES;
			if(byte & V4_FRAMEHDR_FLAG_DATALEN)self.dataLengthIndicator = YES;

		}
		else if(self.majorVersion == ID3_VERSION_3){
			if(byte & V3_FRAMEHDR_FLAG_COMPRESSION)self.compression = YES;
			if(byte & V3_FRAMEHDR_FLAG_ENCRYPTION)self.encryption = YES;
			if(byte & V3_FRAMEHDR_FLAG_GROUPIDENT)self.groupingIdentity = YES;

		}
		
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

- (void)dealloc
{
	[frameID release];
	[frameDescription release];
	[flags release];
	[dataForParsing release];
	
	[super dealloc];
}
@end
