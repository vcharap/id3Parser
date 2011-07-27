//
//  ID3FrameText.m
//

#import "ID3FrameText.h"
#import "ID3Parser.h"

#define ID3_TXTFRAME_ENCODING_SIZE 1

#define ID3_TXTFRAME_ENCODING_ISO 0x00
#define ID3_TXTFRAME_ENCODING_UTF16 0x01
#define ID3_TXTFRAME_ENCODING_UTF16BE 0x02
#define ID3_TXTFRAME_ENCODING_UTF8 0x03


@implementation ID3FrameText
@synthesize textEncoding, textStrings, description;

/*
 Function initializes a text frame instance. Returns the initialized frame, or nil on error. If nil, check NSError.
 - frameIDString is the 3 or 4 letter frame ID
 - description is the string description of the frame ID
 - bytes is a pointer to beginning of frame header, can't be null.
  - error argument can be ommited, but its not recommended

 */
- (id)initWithID:(NSString *)frameIDString description:(NSString*)aDescription version:(ID3_VERSION)version andBytes:(const void *)bytes error:(NSError **)error
{
	self = [super initWithID:frameIDString description:aDescription version:version andBytes:bytes error:error];
	if(self){
		
		self.textStrings = [[NSMutableArray alloc] init];
		
		//Get the text encoding of the tag.
		char* encodingPtr = (char*)[self.dataForParsing bytes];
		if(encodingPtr == NULL){//No data to parse
			if(error) *error = [ID3Parser errorForCode:ID3_PARSERDOMAIN_EEMPTY underlyingError:nil recoveryObject:self];
			[self release];
			return nil;
		}
	
		NSData *nullChar;
		short nullVal = 0;
		switch (*encodingPtr) {
			case ID3_TXTFRAME_ENCODING_ISO:
			{
				self.textEncoding = NSISOLatin1StringEncoding;
				nullChar = [NSData dataWithBytes:&nullVal length:1];
				break;
			}
			case ID3_TXTFRAME_ENCODING_UTF16:
			{
				self.textEncoding = NSUTF16StringEncoding;
				nullChar = [NSData dataWithBytes:&nullVal length:2];
				break;
			}
			case ID3_TXTFRAME_ENCODING_UTF16BE:
			{
				self.textEncoding = NSUTF16BigEndianStringEncoding;
				nullChar = [NSData dataWithBytes:&nullVal length:2];
				break;
			}
			case ID3_TXTFRAME_ENCODING_UTF8:
			{
				self.textEncoding = NSUTF8StringEncoding;
				nullChar = [NSData dataWithBytes:&nullVal length:1];
				break;
			}
			default:
			{
				if(error){
					*error = [ID3Parser errorForCode:ID3_PARSERDOMAIN_EENCOD underlyingError:nil recoveryObject:self];
				}
				[self release];
				return nil;
			}
		}
		
		
		//Parse the text
		NSUInteger length = [self.dataForParsing length];
		NSUInteger index = 1;
		NSRange dataRange;
		NSString *frameString;
		
		NSString *userFrameID;
		if(self.majorVersion == ID3_VERSION_2) userFrameID = @"TXX";
		else userFrameID = @"TXXX";
		
		while(index < length){
			NSRange nullDelimeter = [self.dataForParsing rangeOfData:nullChar options:0 range:NSMakeRange(index, length - index)];
			
			if([self.frameID isEqualToString:userFrameID] && self.description == nil){//TXX(X) frame
				if(nullDelimeter.location == NSNotFound){
					/*FRAME FORMATTING IS WRONG  - expecting at least 1 null delimeter*/
					if(error) *error = [ID3Parser errorForCode:ID3_PARSERDOMAIN_EFORMAT underlyingError:nil recoveryObject:self];
					[self release];
					return nil;
				}
				
				//set description string
				dataRange = NSMakeRange(index, nullDelimeter.location - index);
				frameString = [[NSString alloc] initWithData:[self.dataForParsing subdataWithRange:dataRange] 
															  encoding:self.textEncoding];
				index = nullDelimeter.location + nullDelimeter.length;
				self.description = frameString;
				[frameString release];
				continue;
			}
			
			if(nullDelimeter.location == NSNotFound){//no more null delimeters
				//put remainig data into a string
				dataRange = NSMakeRange(index, length - index);
				frameString = [[NSString alloc] initWithData:[self.dataForParsing subdataWithRange:dataRange] encoding:self.textEncoding];
				[self.textStrings addObject:frameString];
				[frameString release];
				break;
			}
			
			//put data up to current delimeter into a string.
			dataRange = NSMakeRange(index, nullDelimeter.location - index);
			frameString = [[NSString alloc] initWithData:[self.dataForParsing subdataWithRange:dataRange] encoding:self.textEncoding];
			[self.textStrings addObject:frameString];
			[frameString release];
			index = nullDelimeter.location + nullDelimeter.length;
			
			if(self.majorVersion == ID3_VERSION_2 || self.majorVersion == ID3_VERSION_3) break; //in v3 and older, data beyond null char is ignored

		}
		   
	}
	return self;
}

/*
 Function returns a NSDictionary describing the frame
	- all frames have keys "frameID" "frameDescription" and "value"
*/
- (NSDictionary*)descriptionOfFrame
{
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	[dictionary setValue:self.frameID forKey:@"frameID"];
	[dictionary setValue:self.frameDescription forKey:@"frameDescription"];
									   
	[dictionary setValue:self.description forKey:@"description"];
	
	//concatenate strings from array...i guess
	NSMutableString *value = [[NSMutableString alloc] init];
	for(NSString *string in self.textStrings){
		[value appendString:[NSString stringWithFormat:@"%@ ", string]];
	}
	
	[dictionary setValue:value forKey:@"value"];
	[value release];
	return [NSDictionary dictionaryWithDictionary:dictionary];
}

- (void)dealloc
{
	[textEncoding release];
	[description release];
	[textStrings release];
	[super dealloc];
}
@end
