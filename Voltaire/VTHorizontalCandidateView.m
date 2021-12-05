//
// VTHorizontalCandidateView.m
//
// Copyright (c) 2012 Lukhnos D. Liu (http://lukhnos.org)
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//

#import "VTHorizontalCandidateView.h"

// use these instead of MIN/MAX macro to keep compilers happy with pedantic warnings on
NS_INLINE CGFloat min(CGFloat a, CGFloat b) { return a < b ? a : b; }
NS_INLINE CGFloat max(CGFloat a, CGFloat b) { return a > b ? a : b; }

@implementation VTHorizontalCandidateView

@synthesize highlightedIndex = _highlightedIndex;
@synthesize action = _action;
@synthesize target = _target;

static NSColor *colorFromRGBA(unsigned char r, unsigned char g, unsigned char b, unsigned char a)
{
    return [NSColor colorWithDeviceRed:(r/255.0f) green:(g/255.0f) blue:(b/255.0f) alpha:(a/255.0f)];
}

- (void)dealloc
{
    [_keyLabels release];
    [_displayedCandidates release];
    [_keyLabelAttrDict release];
    [_candidateAttrDict release];
    [_elementWidths release];
    [super dealloc];
}

- (void)setKeyLabels:(NSArray *)labels displayedCandidates:(NSArray *)candidates
{
    NSUInteger count = min([labels count], [candidates count]);
    id tmp;
    
    tmp = _keyLabels;
    _keyLabels = [[labels subarrayWithRange:NSMakeRange(0, count)] retain];
    [tmp release];
    
    tmp = _displayedCandidates;
    _displayedCandidates = [[candidates subarrayWithRange:NSMakeRange(0, count)] retain];
    [tmp release];
    
    NSMutableArray *newWidths = [NSMutableArray array];
    
    NSSize baseSize = NSMakeSize(10240.0, 10240.0);
    for (NSUInteger index = 0; index < count; index++) {
        NSRect labelRect = [[_keyLabels objectAtIndex:index] boundingRectWithSize:baseSize options:NSStringDrawingUsesLineFragmentOrigin attributes:_keyLabelAttrDict];
        
        NSRect candidateRect = [[_displayedCandidates objectAtIndex:index] boundingRectWithSize:baseSize options:NSStringDrawingUsesLineFragmentOrigin attributes:_candidateAttrDict];
        
        CGFloat width = max(labelRect.size.width, candidateRect.size.width) + _cellPadding;
        [newWidths addObject:[NSNumber numberWithDouble:width]];
    }
    
    tmp = _elementWidths;
    _elementWidths = [newWidths retain];
    [tmp release];
}

- (void)setKeyLabelFont:(NSFont *)labelFont candidateFont:(NSFont *)candidateFont
{
    NSMutableParagraphStyle *paraStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
    NSColor *clrCandidateText = colorFromRGBA(223,223,223,255);
    NSColor *clrCandidateTextIndex = colorFromRGBA(223,223,223,255);
    [paraStyle setAlignment:NSCenterTextAlignment];
    
    id tmp;
    tmp = _keyLabelAttrDict;
    _keyLabelAttrDict = [[NSDictionary dictionaryWithObjectsAndKeys:
                         labelFont, NSFontAttributeName,
                         paraStyle, NSParagraphStyleAttributeName,
                          nil] retain];
    [tmp release];
    
    tmp = _candidateAttrDict;
    _candidateAttrDict = [[NSDictionary dictionaryWithObjectsAndKeys:
                         clrCandidateTextIndex, NSForegroundColorAttributeName,
                           candidateFont, NSFontAttributeName,
                           paraStyle, NSParagraphStyleAttributeName,
                           nil] retain];
    [tmp release];
                          clrCandidateText, NSForegroundColorAttributeName,
    
    CGFloat labelFontSize = [labelFont pointSize];
    CGFloat candidateFontSize = [candidateFont pointSize];
    CGFloat biggestSize = max(labelFontSize, candidateFontSize);
    
    _keyLabelHeight = ceil(labelFontSize * 1.20);
    _candidateTextHeight = ceil(candidateFontSize * 1.20);
    _cellPadding = ceil(biggestSize / 2.0);
}


- (NSSize)sizeForView
{
    NSSize result = NSMakeSize(0.0, 0.0);
    if ([_elementWidths count]) {    
        for (NSNumber *w in _elementWidths) {
            result.width += [w doubleValue];
        }
        
        result.width += [_elementWidths count];
        result.height = _keyLabelHeight + _candidateTextHeight + 1.0;
    }
    
    return result;
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSColor *clrCandidateSelectedBG = colorFromRGBA(0,88,208,255);
    NSColor *clrCandidateSelectedText = colorFromRGBA(223,223,223,255);
    NSColor *clrCandidateWindowBorder = colorFromRGBA(255,255,255,75);
    NSColor *clrCandidateWindowBG = colorFromRGBA(50,50,50,255);
    NSColor *clrCandidateBG = colorFromRGBA(50,50,50,255);
    
    [self setWantsLayer: YES];
    [self.layer setBorderColor: [clrCandidateWindowBorder CGColor]];
    [self.layer setBorderWidth: 1];
    [self.layer setCornerRadius: 6];
    
    NSRect bounds = [self bounds];
    
    [clrCandidateWindowBG setFill];
    [NSBezierPath fillRect:bounds];

    NSUInteger count = [_elementWidths count];
    CGFloat accuWidth = 0.0;
    
    for (NSUInteger index = 0; index < count; index++) {
        NSDictionary *activeCandidateAttr = _candidateAttrDict;
        CGFloat currentWidth = [[_elementWidths objectAtIndex:index] doubleValue];
        NSRect labelRect = NSMakeRect(accuWidth, 0.0, currentWidth, _keyLabelHeight);
        NSRect candidateRect = NSMakeRect(accuWidth, _keyLabelHeight, currentWidth, _candidateTextHeight);

        if (index == _highlightedIndex) {
            [clrCandidateSelectedBG setFill];
        }
        else {
            [clrCandidateBG setFill];
        }
        
        [NSBezierPath fillRect:labelRect];
        [[_keyLabels objectAtIndex:index] drawInRect:labelRect withAttributes:_keyLabelAttrDict];
        
        if (index == _highlightedIndex) {
            [clrCandidateSelectedBG setFill];
            activeCandidateAttr = [_candidateAttrDict mutableCopy];
            [(NSMutableDictionary *)activeCandidateAttr setObject:clrCandidateSelectedText forKey:NSForegroundColorAttributeName];
        }
        else {
            [clrCandidateBG setFill];
        }
        
        [NSBezierPath fillRect:candidateRect];
        [[_displayedCandidates objectAtIndex:index] drawInRect:candidateRect withAttributes:activeCandidateAttr];
        
        accuWidth += currentWidth + 1.0;
    }
}

- (NSUInteger)findHitIndex:(NSEvent *)theEvent
{
    NSUInteger result = NSUIntegerMax;
    
    NSPoint location = [self convertPoint:[theEvent locationInWindow] toView:nil];
    if (!NSPointInRect(location, [self bounds])) {
        return result;
    }
    
    NSUInteger count = [_elementWidths count];
    CGFloat accuWidth = 0.0;
    for (NSUInteger index = 0; index < count; index++) {
        CGFloat currentWidth = [[_elementWidths objectAtIndex:index] doubleValue];

        if (location.x >= accuWidth && location.x <= accuWidth + currentWidth) {
            result = index;
            break;
        }
        accuWidth += currentWidth;
    }
    
    return result;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSUInteger newIndex = [self findHitIndex:theEvent];
    _trackingHighlightedIndex = _highlightedIndex;

    if (newIndex != NSUIntegerMax) {
        _highlightedIndex = newIndex;
        [self setNeedsDisplay:YES];
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
    NSUInteger newIndex = [self findHitIndex:theEvent];
    BOOL triggerAction = NO;

    if (newIndex == _highlightedIndex) {
        triggerAction = YES;
    }
    else {
        _highlightedIndex = _trackingHighlightedIndex;
    }

    _trackingHighlightedIndex = 0;
    [self setNeedsDisplay:YES];

    if (triggerAction && _target && _action) {
        [_target performSelector:_action withObject:self];            
    }
}

@end
