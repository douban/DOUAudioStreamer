/* vim: set ft=objc fenc=utf-8 sw=2 ts=2 et: */
/*
 *  DOUAudioStreamer - A Core Audio based streaming audio player for iOS/Mac:
 *
 *      https://github.com/douban/DOUAudioStreamer
 *
 *  Copyright 2013-2016 Douban Inc.  All rights reserved.
 *
 *  Use and distribution licensed under the BSD license.  See
 *  the LICENSE file for full text.
 *
 *  Authors:
 *      Chongyu Zhu <i@lembacon.com>
 *
 */

#import "MainViewController.h"
#import "PlayerViewController.h"
#import "Track+Provider.h"

@implementation MainViewController

- (void)viewDidLoad
{
  [self setTitle:@"DOUAudioStreamer ♫"];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *const kCellIdentifier = @"MainViewController_CellIdentifier";

  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellIdentifier];
  }

  switch ([indexPath row]) {
  case 0:
    [[cell textLabel] setText:@"Remote Music"];
    break;

  case 1:
    [[cell textLabel] setText:@"Local Music Library"];
    break;

  default:
    abort();
  }

  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  PlayerViewController *playerViewController = [[PlayerViewController alloc] init];
  switch ([indexPath row]) {
  case 0:
    [playerViewController setTitle:@"Remote Music ♫"];
    [playerViewController setTracks:[Track remoteTracks]];
    break;

  case 1:
    [playerViewController setTitle:@"Local Music Library ♫"];
    [playerViewController setTracks:[Track musicLibraryTracks]];
    break;

  default:
    abort();
  }

  [[self navigationController] pushViewController:playerViewController
                                         animated:YES];
}

@end
