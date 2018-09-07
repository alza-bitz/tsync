# tsync

Synchronize source and destination directories, with transcoding for media files.

Useful if you want to mirror a lossless media collection to a lossy one, for example to make it faster to upload the collection onto the cloud.

- For transcoding, currently only flac media files are supported for the source, and only mp3 files are supported for the destination.
- The ffmpeg command is used for transcoding, in such a way that all embedded metadata and artwork will also be synchronized.
- The rsync command is used to synchronize any other files in the source directory structure, and also ensure that any files or directories that exist in the destination but not in the source are removed (in order to handle any file or directory renaming in the source since the last run).
- Where an equivalent destination file already exists, it will only be synchronized if the source file is newer (by timestamp).
- Transcoding is done in parallel using up to 8 concurrent ffmpeg processes.

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

-d: Perform a dry-run of the sync.

## License

Copyright © 2018 Alex Coyle

Released under the MIT license.
