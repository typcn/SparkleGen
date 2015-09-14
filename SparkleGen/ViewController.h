//
//  ViewController.h
//  SparkleGen
//
//  Created by TYPCN on 2015/9/14.
//  Copyright © 2015 TYPCN. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGSFragaria/MGSFragaria.h"

@interface ViewController : NSViewController

@property (weak) IBOutlet NSView *editorView;
@property (weak) IBOutlet NSView *latestBuildView;
@property (weak) IBOutlet NSView *prevBuildView;



@property (weak) IBOutlet NSFormCell *langInput;
@property (weak) IBOutlet NSFormCell *releaseNoteUrlInput;
@property (weak) IBOutlet NSFormCell *binaryBaseInput;
@property (weak) IBOutlet NSFormCell *deltaBaseInput;



- (void)setSyntaxDefinition:(NSString *)name;
- (NSString *)syntaxDefinition;

@end

