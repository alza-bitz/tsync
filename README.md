# tsync

Synchronize source and destination directories with transcoding for media files, preserving metadata and artwork etc.

## Motivation

The ability to maintain a smaller, lossy copy of a lossless music collection. For example, an mp3 format copy of a flac music collection.

- Make it faster to sync the collection onto the cloud, and less costly in terms of cloud storage.
- Make it faster to sync the collection onto a USB flash drive, and less costly in terms of USB storage.
- Re-encode the collection from lossless to lossy as and when lossy compression technology improves.

## Features

- Transcoding of flac media files to mp3 (using the ffmpeg command).
- All metadata and artwork will also be synchronized (using the ffmpeg command).
- Ensure that any files or directories that exist in the destination but not in the source are removed, in order to handle any file or directory renaming in the source since the last run (using the rsync command).
- Where an equivalent destination file already exists, it will only be synchronized if the source file is newer (by timestamp).
- Transcoding is done in parallel using up to 8 concurrent ffmpeg processes.

## Donations

Donations are most welcome! This will help me to add new features, improve performance and fix bugs.

## Current Limitations

- For transcoding, currently only flac media files are supported for the source, and only mp3 files are supported for the destination.

## Dependencies

### For Installation

- curl

### For Usage

- ffmpeg
- rsync
- xargs

## Install
```
curl https://raw.githubusercontent.com/alzadude/tsync/master/install.sh | sudo sh
```

## Usage
```
tsync [-d] <source-directory> <destination-directory>
```
### Options
```
-d  Perform a dry-run of the sync
```
## Bug Reports
Please report any possible bugs as GitHub issues in this project, and remember to include the steps performed, what was expected and the actual result.

## Feature Requests
Requests are welcome, please create them as GitHub issues in this project. However, before creating any new requests, please check the Unreleased section at the top of the (Changelog first, to see if the feature is already planned for.

## License

Copyright © 2018 Alex Coyle

Released under the MIT license.
