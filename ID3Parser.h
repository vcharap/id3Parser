//
//  ID3Parser.h
//  StreamTest
//
//  Created by mac on 7/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


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

@interface ID3Parser : NSObject 
{

}

+ (NSArray *)parseTagWithData:(NSData *)rawData error:(NSError **)error;
@end
