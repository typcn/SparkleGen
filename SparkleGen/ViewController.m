//
//  ViewController.m
//  SparkleGen
//
//  Created by TYPCN on 2015/9/14.
//  Copyright © 2015 TYPCN. All rights reserved.
//

#import "ViewController.h"

NSMutableArray *versionArray;

@implementation ViewController{
    MGSFragaria *fragaria;
    NSUserDefaults *def;
    NSDictionary* plistDict;
    NSString *privKey;
    NSString *binaryDelta;
    NSString *saveDir;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    versionArray = [[NSMutableArray alloc] init];
    
    fragaria = [[MGSFragaria alloc] init];
    [fragaria setObject:self forKey:MGSFODelegate];
    [fragaria embedInView:self.editorView];
    [self setSyntaxDefinition:@"XML"];

    plistDict = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Property" ofType:@"plist"]];
    def = [NSUserDefaults standardUserDefaults];
    
    NSString *tpl = [def objectForKey:@"APPCAST_TMPL"];
    if([tpl length] > 0){
        [fragaria setString:tpl];
    }else{
        [fragaria setString:plistDict[@"APPCAST_TMPL"]];
    }
    
    CGColorRef bg = [[NSColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0] CGColor];
    
    [self.latestBuildView setWantsLayer:YES];
    [self.latestBuildView.layer setBackgroundColor:bg];
    [self.prevBuildView setWantsLayer:YES];
    [self.prevBuildView.layer setBackgroundColor:bg];
    
    [self setStringValue:[def objectForKey:@"inlang"] forInput:_langInput];
    [self setStringValue:[def objectForKey:@"releaseNote"] forInput:_releaseNoteUrlInput];
    [self setStringValue:[def objectForKey:@"deltaBase"] forInput:_deltaBaseInput];
    [self setStringValue:[def objectForKey:@"binaryBase"] forInput:_binaryBaseInput];
    
    privKey = [def objectForKey:@"privKey"];
    binaryDelta = [def objectForKey:@"binaryDelta"];
    
}

- (void)setStringValue:(NSString *)str forInput:(id)inp{
    if(!str){
        return;
    }
    [inp setStringValue:str];
}

- (IBAction)setPrivKey:(id)sender {
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:YES];
    [openDlg setCanChooseDirectories:NO];
    [openDlg setPrompt:@"Select"];
    long res = [openDlg runModal];
    if(res == 1){
        privKey = [[openDlg URL] path];
        [def setObject:privKey forKey:@"privKey"];
        [sender setTitle:@"Saved"];
    }
}

- (IBAction)setBinaryDelta:(id)sender {
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:YES];
    [openDlg setCanChooseDirectories:NO];
    [openDlg setPrompt:@"Select"];
    long res = [openDlg runModal];
    if(res == 1){
        binaryDelta = [[openDlg URL] path];
        [def setObject:binaryDelta forKey:@"binaryDelta"];
        [sender setTitle:@"Saved"];
    }
}


- (IBAction)saveAsTemplate:(id)sender {
    [def setObject:[fragaria string] forKey:@"APPCAST_TMPL"];
}

- (IBAction)resetTmpl:(id)sender {
    [fragaria setString:plistDict[@"APPCAST_TMPL"]];
}


- (void)setSyntaxDefinition:(NSString *)name
{
    [fragaria setObject:name forKey:MGSFOSyntaxDefinitionName];
}

- (NSString *)syntaxDefinition
{
    return [fragaria objectForKey:MGSFOSyntaxDefinitionName];
}

- (IBAction)genAction:(id)sender {
    if(!privKey|| [privKey length] < 1){
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Please select Private Key to continue"];
        [alert runModal];
        return;
    }
    
    double latestBuild = 0;
    NSString *latestVerStr = @"";
    NSMutableDictionary *versionMap = [[NSMutableDictionary alloc] init];
    
    NSDictionary *latestBinary;
    for (NSDictionary *object in versionArray) {
        double buildnum = [object[@"CFBundleVersion"] doubleValue];
        if(buildnum > latestBuild){
            latestBuild = buildnum;
            latestBinary = object;
            latestVerStr = object[@"CFBundleVersion"];
        }
        versionMap[object[@"CFBundleVersion"]] = object;
    }
    
    bool needDelta = true;
    
    if([versionMap count] < 1){
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Empty binary"];
        [alert runModal];
        return;
    }else if([versionMap count] == 1){
        needDelta = false;
    }
    
    NSLog(@"Latest build is %f",latestBuild);
    
    NSString *AppName = latestBinary[@"CFBundleName"];
    NSString *AppCastURL = latestBinary[@"SUFeedURL"];
    NSString *VerStr = latestBinary[@"CFBundleShortVersionString"];
    NSString *minSystem = latestBinary[@"LSMinimumSystemVersion"];
    NSString *language = [self.langInput stringValue];
    NSString *releaseNote = [self.releaseNoteUrlInput stringValue];
    [def setObject:language forKey:@"inlang"];
    [def setObject:releaseNote forKey:@"releaseNote"];
    
    
    NSString *binaryStr = [self getEnclosure:latestBinary];
    if(!binaryStr){
        return;
    }
    NSMutableString *deltaStr = [[NSMutableString alloc] initWithString:@""];
    
    if(needDelta){
        if(!binaryDelta || [binaryDelta length] < 1){
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"Please select BinaryDelta to continue"];
            [alert runModal];
            return;
        }
        for(id key in versionMap){
            if([key isEqualToString:latestVerStr]){
                continue;
            }
            NSString *xml = [self getDeltaEnclosure:versionMap[key] andNewFile:latestBinary];
            if(!xml || [xml length] < 1){
                continue;
            }
            [deltaStr appendString:xml];
        }
    }

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterMediumStyle;
    [formatter setDateFormat:@"MMM dd YYYY HH:mm:SS 'GMT'ZZZ (zzzz)"];
    NSString *dateStr = [formatter stringFromDate:[NSDate date]];
    
    NSString *tmpl = [fragaria string];
    tmpl = [tmpl stringByReplacingOccurrencesOfString:@"{{AppName}}"          withString:AppName];
    tmpl = [tmpl stringByReplacingOccurrencesOfString:@"{{AppCastURL}}"       withString:AppCastURL];
    tmpl = [tmpl stringByReplacingOccurrencesOfString:@"{{Version}}"          withString:VerStr];
    tmpl = [tmpl stringByReplacingOccurrencesOfString:@"{{minSystem}}"        withString:minSystem];
    tmpl = [tmpl stringByReplacingOccurrencesOfString:@"{{Language}}"         withString:language];
    tmpl = [tmpl stringByReplacingOccurrencesOfString:@"{{releaseNoteLink}}"  withString:releaseNote];
    tmpl = [tmpl stringByReplacingOccurrencesOfString:@"{{latestEnclosure}}"  withString:binaryStr];
    tmpl = [tmpl stringByReplacingOccurrencesOfString:@"{{deltas}}"           withString:deltaStr];
    tmpl = [tmpl stringByReplacingOccurrencesOfString:@"{{pubDate}}"          withString:dateStr];
    [fragaria setString:tmpl];
    
    [self.view.window setTitle:@"SparkleGen - All done"];
}

- (NSString *)getEnclosure:(NSDictionary *)file{
    NSString *binaryBase = [self.binaryBaseInput stringValue];
    [def setObject:binaryBase forKey:@"binaryBase"];
    
    NSString *appExe = file[@"CFBundleExecutable"];
    NSString *version = file[@"CFBundleVersion"];
    
    NSString *appDir = [file[@"path"] stringByDeletingLastPathComponent];
    saveDir = [NSString stringWithFormat:@"%@/update_%@",appDir,version];
    [[NSFileManager defaultManager] createDirectoryAtPath:saveDir withIntermediateDirectories:YES attributes:nil error:NULL];
    
    NSString *zip_name = [NSString stringWithFormat:@"%@/%@.zip",saveDir,version];
    
    NSString *cmd = [NSString stringWithFormat:@"/usr/bin/zip -r \"%@\" \"%@\"",zip_name , file[@"path"]];
    
    [self.view.window setTitle:@"Archiving.."];
    
    int rv = system([cmd cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if(rv != EXIT_SUCCESS){
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText: @"ZIP failed !"];
        [alert runModal];
        return NULL;
    }
    
    NSString *url = [[NSString stringWithFormat:@"%@/%@/%@.zip",binaryBase,appExe,version] lowercaseString];
    
    [self.view.window setTitle:@"Signing archive.."];
    
    NSString *sig = [self signFile:zip_name];
    
    NSXMLElement *root = [[NSXMLElement alloc] initWithName:@"enclosure"];
    [root addAttribute:[NSXMLNode attributeWithName:@"url" stringValue:url]];
    [root addAttribute:[NSXMLNode attributeWithName:@"sparkle:version" stringValue:version]];
    [root addAttribute:[NSXMLNode attributeWithName:@"sparkle:dsaSignature" stringValue:sig]];
    [root addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"application/octet-stream"]];
    
    return [root XMLString];
}

- (NSString *)getDeltaEnclosure:(NSDictionary *)oldFile andNewFile:(NSDictionary *)newFile{
    NSString *deltaBase = [self.deltaBaseInput stringValue];
    [def setObject:deltaBase forKey:@"deltaBase"];
    
    NSString *appExe = newFile[@"CFBundleExecutable"];
    
    NSString *old_ver = oldFile[@"CFBundleVersion"];
    NSString *new_ver = newFile[@"CFBundleVersion"];
    
    NSString *old_path = oldFile[@"path"];
    NSString *new_path = newFile[@"path"];
    
    NSString *patch_name = [NSString stringWithFormat:@"%@/%@_%@.delta",saveDir,old_ver,new_ver];
    
    NSString *cmd = [NSString stringWithFormat:@"\"%@\" create \"%@\" \"%@\" \"%@\"",binaryDelta,
                                                                            old_path,new_path,patch_name];
    [self.view.window setTitle:@"Running BinaryDelta.."];
    NSString *retn = [self unixSinglePathCommandWithReturn:cmd withStdErr:true];
    
    if(![retn containsString:@"Done"]){
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText: @"BinaryDelta failed !"];
        if(retn){
            [alert setInformativeText:retn];
        }
        [alert runModal];
        return NULL;
    }

    NSString *url = [[NSString stringWithFormat:@"%@/%@/%@_%@.delta",deltaBase,appExe,old_ver,new_ver] lowercaseString];
    
    [self.view.window setTitle:@"Signing delta.."];
    NSString *sig = [self signFile:patch_name];
    
    NSXMLElement *root = [[NSXMLElement alloc] initWithName:@"enclosure"];
    [root addAttribute:[NSXMLNode attributeWithName:@"url" stringValue:url]];
    [root addAttribute:[NSXMLNode attributeWithName:@"sparkle:version" stringValue:new_ver]];
    [root addAttribute:[NSXMLNode attributeWithName:@"sparkle:deltaFrom" stringValue:old_ver]];
    [root addAttribute:[NSXMLNode attributeWithName:@"sparkle:dsaSignature" stringValue:sig]];
 
    return [root XMLString];
}

- (IBAction)publishAction:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"You can set the action in ViewController.m , integration with S3 SDK or CDN API"];
    [alert runModal];

}

- (NSString *)signFile:(NSString *)file{
    NSString *cmd = [NSString stringWithFormat:@"/usr/bin/openssl dgst -sha1 -binary < \"%@\" | /usr/bin/openssl dgst -dss1 -sign \"%@\" | /usr/bin/openssl enc -base64",file,privKey];
    return [self unixSinglePathCommandWithReturn:cmd withStdErr:false];
}

- (NSString *)unixSinglePathCommandWithReturn:(NSString *) command withStdErr:(BOOL)err{
    // performs a unix command by sending it to /bin/sh and returns stdout.
    // trims trailing carriage return
    // not as efficient as running command directly, but provides wildcard expansion
    
    NSPipe *newPipe = [NSPipe pipe];
    NSFileHandle *readHandle = [newPipe fileHandleForReading];
    NSData *inData = nil;
    NSString* returnValue = nil;
    
    NSTask * unixTask = [[NSTask alloc] init];
    [unixTask setStandardOutput:newPipe];
    if(err){
        [unixTask setStandardError:newPipe];
    }
    [unixTask setLaunchPath:@"/bin/sh"];
    [unixTask setArguments:[NSArray arrayWithObjects:@"-c", command , nil]];
    [unixTask launch];
    [unixTask waitUntilExit];
    [unixTask terminationStatus];
    
    while ((inData = [readHandle availableData]) && [inData length]) {
        
        returnValue= [[NSString alloc]
                      initWithData:inData encoding:[NSString defaultCStringEncoding]];
        
        returnValue = [returnValue substringToIndex:[returnValue length]-1];
    }

    return returnValue;
    
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

@end
