//
//  NSString+Hash.m
//  Orbitink
//
//  Created by mmackh on 5/3/13.
//  Copyright (c) 2013 Professional Consulting & Trading GmbH. All rights reserved.
//

#import "NSString+Additions.h"
#import <CommonCrypto/CommonDigest.h>
#import <JavaScriptCore/JavaScriptCore.h>

static const char _base64EncodingTable[64] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static const short _base64DecodingTable[256] = {
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -1, -1, -2, -1, -1, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
    -1, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 62, -2, -2, -2, 63,
    52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -2, -2, -2, -2, -2, -2,
    -2,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
    15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -2, -2, -2, -2, -2,
    -2, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
    41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -2, -2, -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2
};

@implementation NSString (Additions)

- (NSString *)urlFriendlyFileNameWithExtension:(NSString *)extension prefixID:(int)prefixID
{
    if (self.length == 0) return @"";
    
    NSString *umlaut = [self stringByReplacingOccurrencesOfString:@"ß" withString:@"ss"];
    umlaut = [umlaut stringByReplacingOccurrencesOfString:@"ä" withString:@"ae"];
    umlaut = [umlaut stringByReplacingOccurrencesOfString:@"ö" withString:@"oe"];
    umlaut = [umlaut stringByReplacingOccurrencesOfString:@"ü" withString:@"ue"];
    umlaut = [umlaut stringByReplacingOccurrencesOfString:@"Ä" withString:@"Ae"];
    umlaut = [umlaut stringByReplacingOccurrencesOfString:@"Ö" withString:@"Oe"];
    umlaut = [umlaut stringByReplacingOccurrencesOfString:@"Ü" withString:@"Ue"];
    
    NSMutableCharacterSet *charactersToRemove = [[[ NSCharacterSet alphanumericCharacterSet ] invertedSet ] mutableCopy];
    [charactersToRemove removeCharactersInString:@"-+"];
    NSString *cleanTitle = [[umlaut componentsSeparatedByCharactersInSet:charactersToRemove] componentsJoinedByString:@"_"];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"__+" options:NSRegularExpressionCaseInsensitive error:nil];
    cleanTitle = [regex stringByReplacingMatchesInString:cleanTitle options:0 range:NSMakeRange(0, [cleanTitle length]) withTemplate:@"_"];
    
    if ([[cleanTitle substringWithRange:NSMakeRange([cleanTitle length]-1, 1)] isEqualToString:@"_"])
    {
        cleanTitle = [cleanTitle substringWithRange:NSMakeRange(0, [cleanTitle length]-1)];
    }
    
    if (!prefixID)
    {
        return [cleanTitle stringByAppendingPathExtension:extension];
    }
    
    return [[[NSString stringWithFormat:@"%i-%@",prefixID, cleanTitle] lowercaseString] stringByAppendingPathExtension:extension];
}

- (NSString *)urlFriendlyFileName
{
    NSString *fileExtension = [self pathExtension];
    return [[self stringByReplacingOccurrencesOfString:fileExtension withString:@""] urlFriendlyFileNameWithExtension:fileExtension prefixID:0];
}

- (NSString *)stringByAppendingURLPathComponent:(NSString *)pathComponent
{
    NSString *protocol = ([self hasPrefix:@"https://"]) ? @"https://" : @"http://";
    NSString *cleanedStr = [self stringByReplacingOccurrencesOfString:protocol withString:@""];
    return [NSString stringWithFormat:@"%@%@",protocol, [cleanedStr stringByAppendingPathComponent:pathComponent]];
}

- (NSString *)stringByDeletingLastURLPathComponent
{
    NSString *protocol = ([self hasPrefix:@"https://"]) ? @"https://" : @"http://";
    NSString *cleanedStr = [self stringByReplacingOccurrencesOfString:protocol withString:@""];
    return [NSString stringWithFormat:@"%@%@",protocol, [cleanedStr stringByDeletingLastPathComponent]];
}

- (NSString *)sha512
{
    const char *cstr = [self cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:self.length];
    uint8_t digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (int)data.length, digest);
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++)
    {
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}

- (NSString *)base64Encode
{
    NSData *objData = [self dataUsingEncoding:NSUTF8StringEncoding];
    const unsigned char * objRawData = [objData bytes];
    char * objPointer;
    char * strResult;
    
    // Get the Raw Data length and ensure we actually have data
    int intLength = (int)[objData length];
    if (intLength == 0) return nil;
    
    // Setup the String-based Result placeholder and pointer within that placeholder
    strResult = (char *)calloc((((intLength + 2) / 3) * 4) + 1, sizeof(char));
    objPointer = strResult;
    
    // Iterate through everything
    while (intLength > 2) { // keep going until we have less than 24 bits
        *objPointer++ = _base64EncodingTable[objRawData[0] >> 2];
        *objPointer++ = _base64EncodingTable[((objRawData[0] & 0x03) << 4) + (objRawData[1] >> 4)];
        *objPointer++ = _base64EncodingTable[((objRawData[1] & 0x0f) << 2) + (objRawData[2] >> 6)];
        *objPointer++ = _base64EncodingTable[objRawData[2] & 0x3f];
        
        // we just handled 3 octets (24 bits) of data
        objRawData += 3;
        intLength -= 3;
    }
    
    // now deal with the tail end of things
    if (intLength != 0) {
        *objPointer++ = _base64EncodingTable[objRawData[0] >> 2];
        if (intLength > 1) {
            *objPointer++ = _base64EncodingTable[((objRawData[0] & 0x03) << 4) + (objRawData[1] >> 4)];
            *objPointer++ = _base64EncodingTable[(objRawData[1] & 0x0f) << 2];
            *objPointer++ = '=';
        } else {
            *objPointer++ = _base64EncodingTable[(objRawData[0] & 0x03) << 4];
            *objPointer++ = '=';
            *objPointer++ = '=';
        }
    }
    
    // Terminate the string-based result
    *objPointer = '\0';
    
    // Create result NSString object
    NSString *base64String = [NSString stringWithCString:strResult encoding:NSASCIIStringEncoding];
    
    // Free memory
    free(strResult);
    
    return base64String;
}

- (NSString *)base64Decode
{
    const char *objPointer = [self cStringUsingEncoding:NSASCIIStringEncoding];
    size_t intLength = strlen(objPointer);
    int intCurrent;
    int i = 0, j = 0, k;
    
    unsigned char *objResult = calloc(intLength, sizeof(unsigned char));
    
    // Run through the whole string, converting as we go
    while ( ((intCurrent = *objPointer++) != '\0') && (intLength-- > 0) ) {
        if (intCurrent == '=') {
            if (*objPointer != '=' && ((i % 4) == 1)) {// || (intLength > 0)) {
                // the padding character is invalid at this point -- so this entire string is invalid
                free(objResult);
                return nil;
            }
            continue;
        }
        
        intCurrent = _base64DecodingTable[intCurrent];
        if (intCurrent == -1) {
            // we're at a whitespace -- simply skip over
            continue;
        } else if (intCurrent == -2) {
            // we're at an invalid character
            free(objResult);
            return nil;
        }
        
        switch (i % 4) {
            case 0:
                objResult[j] = intCurrent << 2;
                break;
                
            case 1:
                objResult[j++] |= intCurrent >> 4;
                objResult[j] = (intCurrent & 0x0f) << 4;
                break;
                
            case 2:
                objResult[j++] |= intCurrent >>2;
                objResult[j] = (intCurrent & 0x03) << 6;
                break;
                
            case 3:
                objResult[j++] |= intCurrent;
                break;
        }
        i++;
    }
    k = j;
    if (intCurrent == '=') {
        switch (i % 4) {
            case 1:
                // Invalid state
                free(objResult);
                return nil;
                
            case 2:
                k++;
                // flow through
            case 3:
                objResult[k] = 0;
        }
    }
    
    // Cleanup and setup the return NSData
    NSData * objData = [[NSData alloc] initWithBytes:objResult length:j];
    free(objResult);
    return [[NSString alloc] initWithData:objData encoding:NSUTF8StringEncoding];
}

- (NSString*)stringBetweenString:(NSString *)start andString:(NSString *)end {
    NSRange startRange = [self rangeOfString:start];
    if (startRange.location != NSNotFound) {
        NSRange targetRange;
        targetRange.location = startRange.location + startRange.length;
        targetRange.length = [self length] - targetRange.location;
        NSRange endRange = [self rangeOfString:end options:0 range:targetRange];
        if (endRange.location != NSNotFound) {
            targetRange.length = endRange.location - targetRange.location;
            return [self substringWithRange:targetRange];
        }
    }
    return nil;
}

- (NSString *)stringByStrippingHTML
{
    NSRange r;
    NSString *s = [self copy];
    while ((r = [s rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
        s = [s stringByReplacingCharactersInRange:r withString:@""];
    return s;
}

- (NSString *)localCachePath
{
    NSString *filename = [self sha512];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [NSString stringWithFormat:@"%@/%@.%@",[paths objectAtIndex:0],filename,self.pathExtension];
}

- (NSString *)trim
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (BOOL)isNumeric
{
    NSScanner* scan = [NSScanner scannerWithString:self];
    int val;
    return [scan scanInt:&val] && [scan isAtEnd];
}

- (BOOL)containsString:(NSString *)needle
{
    if (!self.length) return NO;
    return ([self rangeOfString:needle].location == NSNotFound) ? NO : YES;
}

__attribute__((overloadable))
NSString *substr(NSString *str, int start)
{
    return substr(str, start, 0);
}

__attribute__((overloadable))
NSString *substr(NSString *str, int start, int length)
{
    NSInteger str_len = str.length;
    if (!str_len) return @"";
    if (str_len < length) return str;
    if (start < 0 && length == 0)
    {
        return [str substringFromIndex:str_len+start];
    }
    if (start == 0 && length > 0)
    {
        return [str substringToIndex:length];
    }
    if (start < 0 && length > 0)
    {
        return [[str substringFromIndex:str_len+start] substringToIndex:length];
    }
    if (start > 0 && length > 0)
    {
        return [[str substringFromIndex:start] substringToIndex:length];
    }
    if (start > 0 && length == 0)
    {
        return [str substringFromIndex:start];
    }
    if (length < 0)
    {
        NSString *tmp_str;
        if (start < 0)
        {
            tmp_str = [str substringFromIndex:str_len+start];
        }
        else
        {
            tmp_str = [str substringFromIndex:start];
        }
        NSInteger tmp_str_len = tmp_str.length;
        if (tmp_str_len + length <= 0) return @"";
        return [tmp_str substringToIndex:tmp_str_len+length];
    }
    
    return str;
}


- (NSString *)replaceWithPattern:(NSString *)pattern template:(NSString *)template isdot:(BOOL)isdot {
    
    NSRegularExpression *regex;
    if (!isdot) {
        regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    } else {
        regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators error:nil];
    }
    
    return [regex stringByReplacingMatchesInString:self options:0 range:NSMakeRange(0, [self length]) withTemplate:template];
}

- (NSArray *)matchesWithPattern:(NSString *)pattern isdot:(BOOL)isdot {
    
    NSRegularExpression *regex;
    if (!isdot) {
        regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    } else {
        regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive|NSRegularExpressionDotMatchesLineSeparators error:nil];
    }
    
    NSArray *matches = [regex matchesInString:self
                                      options:0
                                        range:NSMakeRange(0, [self length])];
    
    NSMutableArray *strings = [NSMutableArray arrayWithCapacity:[matches count]];
    
    //NSLog(@"matches count %d", [matches count]);
    
    for (NSTextCheckingResult *result in matches) {
        //NSLog(@"[result numberOfRanges]%d",[result numberOfRanges]);
        if ([result numberOfRanges] > 2) {
            NSMutableArray *items = [NSMutableArray arrayWithCapacity:[result numberOfRanges]];
            for (NSUInteger i=0; i < [result numberOfRanges]; i++) {
                [items addObject:[self substringWithRange:[result rangeAtIndex:i]]];
            }
            [strings addObject:items];
        } else if ([result numberOfRanges] == 2) {
            [strings addObject:[self substringWithRange:[result rangeAtIndex:1]]];
        } else {
            [strings addObject:[self substringWithRange:[result rangeAtIndex:0]]];
        }
    }
    
    return strings;
}

 
- (int) indexOf:(NSString *)text {
    NSRange range = [self rangeOfString:text];
    if ( range.length > 0 ) {
        return range.location;
    } else {
        return -1;
    }
}

/*
 * copy from hacker news
 */
- (UIColor *)colorFromHexString
{
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:self];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

- (NSString*)stringFromString:(NSString *)start {
    NSRange startRange = [self rangeOfString:start];
    if (startRange.location != NSNotFound) {
        
        startRange.length = [self length] - startRange.location;
        
        return [self substringWithRange:startRange];
    }
    return nil;
}

/*
 *
 */
- (CGFloat)heightOfContentWithFont:(UIFont *)font width:(CGFloat)width {
    
    CGSize constraint = CGSizeMake(width, 20000.0f);
    
    NSAttributedString *attributedText = [[NSAttributedString alloc]initWithString:self attributes:@{NSFontAttributeName:font}];
    
    CGRect rect = [attributedText boundingRectWithSize:constraint
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                               context:nil];
    CGSize size = rect.size;
    return size.height;
}


- (NSString *)URLEncode {
    return [self URLEncodeUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)js_encodeURI
{
    JSContext *context = [[JSContext alloc] init];
    JSValue *value = [context evaluateScript:[NSString stringWithFormat:@"encodeURI('%@');", self]];
    return [value toString];
}

- (NSString *)URLEncodeUsingEncoding:(NSStringEncoding)encoding {
    return (__bridge_transfer NSString *)
    CFURLCreateStringByAddingPercentEscapes(NULL,
                                            (__bridge CFStringRef)self,
                                            NULL,
                                            (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                            CFStringConvertNSStringEncodingToEncoding(encoding));
}

- (NSString *)URLDecode {
    return [self URLDecodeUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)URLDecodeUsingEncoding:(NSStringEncoding)encoding {
    return (__bridge_transfer NSString *)
    CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL,
                                                            (__bridge CFStringRef)self,
                                                            CFSTR(""),
                                                            CFStringConvertNSStringEncodingToEncoding(encoding));
}

- (NSString *)hp_urlFriendlyFileName {
    NSString *s = self;
    NSCharacterSet *doNotWant = [NSCharacterSet characterSetWithCharactersInString:@"!*'\"();:@&=+$,/?%#[]% "];
    return [[s componentsSeparatedByCharactersInSet:doNotWant] componentsJoinedByString:@"_"];
}

- (BOOL)hasSuffixes:(NSArray *)suffixes
{
    __block BOOL f = NO;
    [suffixes enumerateObjectsUsingBlock:^(NSString *suffix, NSUInteger idx, BOOL *stop) {
        if ([self hasSuffix:suffix]) {
            f = YES;
            *stop = YES;
        }
    }];
    return f;
}

- (NSArray *)hp_jsLinks
{
    return [RX(@"http[^ '\"<>]+\\.js") matches:self];
}

- (NSString *)safe_substringWithRange:(NSInteger)location :(NSUInteger)length
{
    if (location < 0) {
        return nil;
    }
    
    if ((location + length) > self.length) {
        return nil;
    }
    
    return [self substringWithRange:NSMakeRange(location, length)];
}

@end

@implementation NSObject (isEmpty)

- (BOOL)mag_isEmpty
{
    return self == nil || ([self respondsToSelector:@selector(length)] && [(NSData *)self length] == 0) || ([self respondsToSelector:@selector(count)] && [(NSArray *)self count] == 0);
}
@end
