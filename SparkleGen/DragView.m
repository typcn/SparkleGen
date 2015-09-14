//
//  DragView.m
//  SparkleGen
//
//  Created by TYPCN on 2015/9/14.
//  Copyright © 2015 TYPCN. All rights reserved.
//

#import "DragView.h"

extern NSMutableArray *versionArray;

@implementation DragView{
    BOOL isHighlighted;
}

- (void)awakeFromNib {
    [self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
}

- (BOOL)isHighlighted {
    return isHighlighted;
}

- (void)setHighlighted:(BOOL)value {
    isHighlighted = value;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)frame {
    [super drawRect:frame];
    if (isHighlighted) {
        [NSBezierPath setDefaultLineWidth:6.0];
        [[NSColor keyboardFocusIndicatorColor] set];
        [NSBezierPath strokeRect:frame];
    }
}


#pragma mark - Dragging

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    
    if ([[pboard types] containsObject:NSFilenamesPboardType]) {
        NSArray *paths = [pboard propertyListForType:NSFilenamesPboardType];
        for (NSString *path in paths) {
            NSError *error = nil;
            NSString *utiType = [[NSWorkspace sharedWorkspace]
                                 typeOfFile:path error:&error];
            if (![[NSWorkspace sharedWorkspace]
                  type:utiType conformsToType:(id)kUTTypeApplication]) {
                
                [self setHighlighted:NO];
                return NSDragOperationNone;
            }
        }
    }
    [self setHighlighted:YES];
    return NSDragOperationEvery;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
    [self setHighlighted:NO];
}


- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender  {
    return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    [self setHighlighted:NO];
    return YES;
}

- (void)concludeDragOperation:(id<NSDraggingInfo>)sender {
    NSArray *files = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
    NSString *fpath = [NSString stringWithFormat:@"%@/Contents/Info.plist",[files objectAtIndex:0]];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:fpath];
    dict[@"path"] = [files objectAtIndex:0];
    [versionArray addObject:dict];
}
@end
