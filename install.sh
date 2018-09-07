#!/usr/bin/env sh

set -e

curl -f -o /usr/local/bin/tsync https://raw.githubusercontent.com/alzadude/tsync/master/tsync.sh
chmod 755 /usr/local/bin/tsync
