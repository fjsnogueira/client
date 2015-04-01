//
//  KBLaunchCtl.m
//  Keybase
//
//  Created by Gabriel on 3/12/15.
//  Copyright (c) 2015 Gabriel Handford. All rights reserved.
//

#import "KBLaunchCtl.h"

#define PLIST_PATH (@"keybase.keybased.plist")

@implementation KBLaunchCtl

- (void)reload:(KBLaunchStatus)completion {
  [self unload:NO completion:^(NSError *unloadError, NSString *unloadOutput) {
    [self wait:NO attempt:1 completion:^(NSError *error, NSInteger pid) {
      [self load:YES completion:^(NSError *loadError, NSString *loadOutput) {
        [self wait:YES attempt:1 completion:^(NSError *error, NSInteger pid) {
          completion(loadError, pid);
        }];
      }];
    }];
  }];
}

- (NSString *)plist {
  NSString *launchAgentDir = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"LaunchAgents"];
  return [launchAgentDir stringByAppendingPathComponent:PLIST_PATH];
}

- (void)load:(BOOL)force completion:(KBLaunchExecution)completion {
  NSMutableArray *args = [NSMutableArray array];
  [args addObject:@"load"];
  if (force) [args addObject:@"-w"];
  [args addObject:self.plist];
  [self execute:@"/bin/launchctl" args:args completion:completion];
}

- (void)unload:(BOOL)disable completion:(KBLaunchExecution)completion {
  NSMutableArray *args = [NSMutableArray array];
  [args addObject:@"unload"];
  if (disable) [args addObject:@"-w"];
  [args addObject:self.plist];
  [self execute:@"/bin/launchctl" args:args completion:completion];
}

- (void)status:(KBLaunchStatus)completion {
  [self execute:@"/bin/launchctl" args:@[@"list"] completion:^(NSError *error, NSString *output) {
    for (NSString *line in [output componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]) {
      // TODO better parsing
      if ([line containsString:@"keybase.keybased"]) {
        NSInteger pid = [[[line componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] firstObject] integerValue];
        completion(nil, pid);
        return;
      }
    }
    completion(nil, -1);
  }];
}

- (void)wait:(BOOL)load attempt:(NSInteger)attempt completion:(KBLaunchStatus)completion {
  [self status:^(NSError *error, NSInteger pid) {
    if (load && pid != 0) {
      GHDebug(@"Pid: %@", @(pid));
      completion(nil, pid);
    } else if (!load && pid == 0) {
      completion(nil, pid);
    } else {
      if ((attempt + 1) >= 4) {
        completion(KBMakeError(-1, @"launchctl wait timeout"), 0);
      } else {
        GHDebug(@"Watiting for %@ (%@)", load ? @"load" : @"unload", @(attempt));
        [self wait:load attempt:attempt+1 completion:completion];
      }
    }
  }];
}

- (void)execute:(NSString *)command args:(NSArray *)args completion:(void (^)(NSError *error, NSString *output))completion {
  NSTask *task = [[NSTask alloc] init];
  task.launchPath = command;
  task.arguments = args;
  NSPipe *outpipe = [NSPipe pipe];
  [task setStandardOutput:outpipe];
  task.terminationHandler = ^(NSTask *t) {
    GHDebug(@"Task %@ exited with status: %@", t, @(t.terminationStatus));
    NSFileHandle *read = [outpipe fileHandleForReading];
    NSData *data = [read readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    dispatch_async(dispatch_get_main_queue(), ^{
      // TODO Check termination status and complete with error if > 0
      completion(nil, output);
    });
  };
  // Only do this for release versions?
  BOOL debug = NO;
#ifdef DEBUG
  debug = YES;
#endif

  _releaseOnly = NO;
  if (_releaseOnly && debug) {
    // Its release only and we are in debug
    completion(nil, nil);
  } else {
    [task launch];
  }
}

- (void)installLaunchAgent:(KBCompletionBlock)completion {
  // Install launch agent (if not installed)
  NSString *plist = self.plist;
  if (!plist) {
    NSError *error = KBMakeErrorWithRecovery(-1, @"Install Error", @"No launch agent destination.", nil);
    completion(error);
    return;
  }

  //
  // TODO
  // Only install if not exists or upgrade. We are currently always installing/updating the plist.
  //
  //if (![NSFileManager.defaultManager fileExistsAtPath:launchAgentPlistDest]) {
  NSString *launchAgentPlistSource = [[NSBundle mainBundle] pathForResource:PLIST_PATH.stringByDeletingPathExtension ofType:PLIST_PATH.pathExtension];

  if (!launchAgentPlistSource) {
    NSError *error = KBMakeErrorWithRecovery(-1, @"Install Error", @"No launch agent plist found in bundle.", nil);
    completion(error);
    return;
  }

  NSError *error = nil;

  // Remove if exists
  if ([NSFileManager.defaultManager fileExistsAtPath:plist]) {
    if (![NSFileManager.defaultManager removeItemAtPath:plist error:&error]) {
      if (!error) error = KBMakeErrorWithRecovery(-1, @"Install Error", @"Unable to remove existing luanch agent plist for upgrade.", nil);
      completion(error);
      return;
    }
  }

  if (![NSFileManager.defaultManager copyItemAtPath:launchAgentPlistSource toPath:plist error:&error]) {
    if (!error) error = KBMakeErrorWithRecovery(-1, @"Install Error", @"Unable to transfer launch agent plist.", nil);
    completion(error);
    return;
  }

  // We installed the launch agent plist
  GHDebug(@"Installed launch agent plist");

  [self reload:^(NSError *error, NSInteger pid) {
    completion(error);
  }];
}

//- (void)checkLaunch:(void (^)(NSError *error))completion {
//  launch_data_t config = launch_data_alloc(LAUNCH_DATA_DICTIONARY);
//
//  launch_data_t val;
//  val = launch_data_new_string("keybase.keybased");
//  launch_data_dict_insert(config, val, LAUNCH_JOBKEY_LABEL);
//  val = launch_data_new_string("/Applications/Keybase.app/Contents/MacOS/keybased");
//  launch_data_dict_insert(config, val, LAUNCH_JOBKEY_PROGRAM);
//  val = launch_data_new_bool(YES);
//  launch_data_dict_insert(config, val, LAUNCH_JOBKEY_KEEPALIVE);
//
//  launch_data_t msg = launch_data_alloc(LAUNCH_DATA_DICTIONARY);
//  launch_data_dict_insert(msg, config, LAUNCH_KEY_SUBMITJOB);
//
//  launch_data_t response = launch_msg(msg);
//  if (!response) {
//    NSError *error = KBMakeErrorWithRecovery(-1, @"Launchd Error", @"Unable to launch keybased agent.", nil);
//    completion(error);
//  } else if (response && launch_data_get_type(response) == LAUNCH_DATA_ERRNO) {
//    //strerror(launch_data_get_errno(response))
//    //NSError *error = KBMakeErrorWithRecovery(-1, @"Launchd Error", @"Unable to launch keybased agent (LAUNCH_DATA_ERRNO).", nil);
//    //completion(error);
//    completion(nil);
//  } else {
//    completion(nil);
//  }
//}

@end
