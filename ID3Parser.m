//
//  ID3Parser.m
//

#import "ID3Parser.h"
#import "ID3Frame.h"

static NSString * const ID3ParserDomain = @"ID3ParserDomain";

//Private Class interface
@interface ID3Parser ()

+ (NSArray *)descriptionsForFramesArray:(NSArray *)tagsArray;
@end


@implementation ID3Parser

+ (NSArray *)parseTagWithData:(NSData *)data error:(NSError **)error
{
	//NSDictionary *tagDictionary = nil;
	NSUInteger length = [data length];
	
	if(!length){
		if(error) *error = [ID3Parser errorForCode:ID3_PARSERDOMAIN_EEMPTY
								   underlyingError:NULL 
									recoveryObject:nil];
		return nil;
	}

	[data retain]; 		
	
	//find start of tag, end of tag
	NSRange id3Header = [data rangeOfData:[NSData dataWithBytes:"ID3" length:3] options:0 range:NSMakeRange(0, length)]; 
	if(id3Header.location == NSNotFound){
		if(error) *error = [ID3Parser errorForCode:ID3_PARSERDOMAIN_ENOTFOUND 
										   underlyingError:NULL 
											recoveryObject:nil];
		[data release];
		return nil;
	}
	
	const char *id3HeaderBegin = (const char*)[data bytes] + id3Header.location;
	char version = *(id3HeaderBegin + ID3_HEADER_VERSION_OFFSET);
	int tagSize;
	ID3_VERSION majorVersion;
	switch (version){
		case 2:
		{	
			char num[4];
			num[0] = 0;
			const char* ptr = id3HeaderBegin + ID3_HEADER_SIZE_OFFSET;
			memcpy(num + 1, ptr, 3);
			tagSize = CFSwapInt32BigToHost(*(uint32_t*)num);
			majorVersion = ID3_VERSION_2;
			break;
		}
		case 3:
		{
			const int *sizePtr = (const int*)(id3HeaderBegin + ID3_HEADER_SIZE_OFFSET);
			tagSize = CFSwapInt32BigToHost(*sizePtr);
			majorVersion = ID3_VERSION_3;
			break;
		}
		case 4:
		{	
			majorVersion = ID3_VERSION_4;
			int syncInt = *(int *)(id3HeaderBegin + ID3_HEADER_SIZE_OFFSET);
			tagSize = [ID3Parser integerFromSyncsafeInteger:syncInt];
			assert(tagSize <= 0xFFFFFFF);
			break;
		}
		default:
		{
			if(error) *error = [ID3Parser errorForCode:ID3_PARSERDOMAIN_EVERSION 
									   underlyingError:NULL 
										recoveryObject:nil];
			[data release];
			return nil;
		}
	}

	NSLog(@"\n\nMAJOR VERSION IS: %d\n", majorVersion);
	NSLog(@"Tag size is: %d\n", tagSize);
	
	
	char flags = *(id3HeaderBegin + ID3_HEADER_FLAGS_OFFSET);
	
	if(majorVersion == ID3_VERSION_2 && (flags & V2_HEADER_FLAG_COMPRESSION)){
		if(error) *error = [ID3Parser errorForCode:ID3_PARSERDOMAIN_ECOMPR underlyingError:NULL recoveryObject:nil];
		[data release];
		return nil;
	}
	   
	   
	//check for unsynchronisation
	const char* id3BodyBegin = id3HeaderBegin + ID3_HEADER_LENGTH;
	
	if((char)V4_HEADER_FLAG_UNSYNC & flags){
		if(majorVersion == ID3_VERSION_3 || majorVersion == ID3_VERSION_2){
			NSLog(@"Tag has been unsynchronised\n");
			NSData *tagBody = [ID3Parser unsyncData:[NSData dataWithBytes:id3HeaderBegin + ID3_HEADER_LENGTH length:tagSize]];
			tagSize = [tagBody length];
			id3BodyBegin = (const char*)[tagBody bytes];
			[tagBody retain];
			[data release];
		}
	}
	
	   
	//check for extended header
	int extendedHeaderSize = 0;
	if(majorVersion == ID3_VERSION_3 || majorVersion == ID3_VERSION_4){//extended header only in v2.3 and younger
		
		if((char)V4_HEADER_FLAG_EXTEND_HDR & flags){
			NSLog(@"Extended header is present in mask\n");
			int syncInt = *(int *)(id3BodyBegin);
			if(majorVersion == ID3_VERSION_4){
				extendedHeaderSize = [ID3Parser integerFromSyncsafeInteger:syncInt];
				assert(extendedHeaderSize <=0xFFFFFFF);
			}
			else{
				extendedHeaderSize = CFSwapInt32BigToHost(syncInt);
			}
		}
	}
	
	//Begin parsing frames
	NSUInteger frameHeaderLength;
	if(majorVersion == ID3_VERSION_2){ frameHeaderLength = V2_FRAMEHDR_LENGTH;}
	else {frameHeaderLength = V4_FRAMEHDR_LENGTH;}

	NSMutableArray *framesArray = [[NSMutableArray alloc] init];
	const char* framePointer = (const char*)(id3BodyBegin + extendedHeaderSize);
	const char *headerEnd = framePointer + tagSize;
	
	while(framePointer != headerEnd && *framePointer != 0){
		
		NSError *frameError = nil;
		ID3Frame *frame = [ID3Frame getFrameFromBytes:framePointer version:majorVersion error:&frameError];
		
		if(frame == nil){
			NSLog(@"Error parsing frame. error is: %@\n", frameError);
			NSUInteger errorCode = [frameError code];
			
			if(errorCode == ID3_PARSERDOMAIN_EEMPTY || errorCode == ID3_PARSERDOMAIN_EFRAMEID){//Stop parsing: no useful information gathered
				NSLog(@"Stopping parser due to unrecoverable frame parsing error.\n");
				if(error) *error = [ID3Parser errorForCode:ID3_PARSERDOMAIN_EFRAME 
											underlyingError:frameError 
											 recoveryObject:nil];
				[framesArray release];
				[data release];
				return nil;
			}
			else{//Continue parsing: location of next frame can be found.
				ID3Frame *recoveredFrame = [frameError recoveryAttempter];
				NSLog(@"Ignoring frame with frame ID: %@ and ID description: %@\n\n\n", recoveredFrame.frameID, recoveredFrame.frameDescription);
				framePointer = framePointer + frameHeaderLength + recoveredFrame.size;
				continue;
			}
		}
		
		framePointer = framePointer + frameHeaderLength + frame.size;
		[framesArray addObject:frame];			
	}

	NSArray *frameDictionaries = [ID3Parser descriptionsForFramesArray:framesArray];
	[framesArray release];
	return frameDictionaries;
	
}

+ (NSError *)errorForCode:(NSInteger)errorCode underlyingError:(NSError *)otherError recoveryObject:(id)recoverObject
{
	NSString *description;
	NSString *reason;
	NSMutableDictionary *userInfo;
	NSError *error = nil;
	switch (errorCode) {
		case ID3_PARSERDOMAIN_EEMPTY:
		{
			description = @"Error: Unable to parse. Can't parse empty data";
			reason = @"Argument is nil or empty";
			break;
		}
		case ID3_PARSERDOMAIN_ENOTFOUND:
		{	
			description = @"Error: Unable to parse tag. Start of ID3 tag not found.";
			reason = @"Start of ID3 tag not found in data.";
			break;
		}
		case ID3_PARSERDOMAIN_EVERSION:
		{
			description = @"Error: Can't parse ID3 tag of unsupported version.";
			reason = @"ID3 version of tag currently not supported.";
			break;
		}
		case ID3_PARSERDOMAIN_EFRAMEID:
		{
			description = @"Error: Unable to parse frame. Frame ID unknown";
			reason = @"Frame ID unknown"; 
			break;
		}
		case ID3_PARSERDOMAIN_EENCRYP:
		{
			description = @"Error: Unable to parse frame, parsing of encrypted frames is not supported.";
			reason = @"Frame is encrypted";
			break;
		}
		case ID3_PARSERDOMAIN_ECOMPR:
		{
			description = @"Error: Unable to parse the tag, parsing of compressed data is not supported.";
			reason = @"Data is compressed.";
			break;
		}
		case ID3_PARSERDOMAIN_EENCOD:
		{
			description = @"Error: unable to parse frame. Could not determine text encoding.";
			reason = @"Text encoding undetermined.";
			break;
		}
		case ID3_PARSERDOMAIN_EDELIM:
		{
			description = @"Error: unable to parse frame. Could not find delimiter character";
			reason = @"Delimiter character not found.";
			break;
		}
		case ID3_PARSERDOMAIN_EFRAME:
		{
			description = @"Unable to parse tag. There was frame parsing error. Check the underlying error.";
			reason = @"Unable to parse frame.";
			break;
		}
		case ID3_PARSERDOMAIN_EFORMAT:
		{
			description = @"Unable to parse frame body. Frame body format is incorrect.";
			reason = @"Unexpected frame body format";
			break;
		}
		case ID3_PARSERDOMAIN_EUNKOWN:
		{
			description = @"Did not finish parsing frame. This frame is not currently supported. Check recovery object for frame header info.";
			reason = @"Frame is not supported at this time.";
			break;
		}
		default:
			return nil;
			break;
	}
	userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				description, NSLocalizedDescriptionKey, reason, NSLocalizedFailureReasonErrorKey, nil];
   
	if(otherError != nil) [userInfo setObject:otherError forKey:NSUnderlyingErrorKey];
	if(recoverObject != nil) [userInfo setObject:recoverObject forKey:NSRecoveryAttempterErrorKey];
	error = [[NSError alloc] initWithDomain:ID3ParserDomain code:errorCode userInfo:userInfo];
	return [error autorelease];
}
		 
/*
 Function takes a 4 byte syncsafe integer in big endian notation!!!!!. 
 Returns a uint32_t with the sync bits removed AND in LITTLE ENDIAN notation.
*/
+ (int)integerFromSyncsafeInteger:(int)syncsafeInt
{
	int tagSize = 0;
	char* tagPtr = (char*)(&tagSize);
	char* sizePtr = (char *)(&syncsafeInt);
	int i = 0;
	for(; i<3; i++){
		*tagPtr = *tagPtr | (*(sizePtr + i));
		tagSize = tagSize<<7;
	}

	*tagPtr = *tagPtr | *(sizePtr + i);
	return tagSize;
}

+ (NSArray *)descriptionsForFramesArray:(NSArray *)tagsArray 
{
	NSMutableArray *descriptions = [[[NSMutableArray alloc] init] autorelease];
	for(id frame in tagsArray){
		[descriptions addObject:[frame descriptionOfFrame]];
	}
	return [NSArray arrayWithArray:descriptions];
}

/*
 Function takes some data as argument. Returns an NSData object with the unsynchronisation scheme reversed
 (ie all byte patterns 0xFF 00 -> 0xFF)
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
	
	NSData *finalData = [NSData dataWithBytes:buffer length:index];
	free(buffer);
	return finalData;
	
}
@end
