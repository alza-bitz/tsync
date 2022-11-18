#!/usr/bin/env sh

set -e

usage() {
  printf 'Usage: %s [-d] <source> <destination>\n' "$0"
  exit 1
}

if [ "$#" -lt "2" -o "$#" -gt "3" ]
then
  usage
else
  if [ "$#" -eq "3" ]
  then
    if [ "$1" != "-d" ]
    then
      usage
    else
      dry=true
      shift
    fi
  fi
  src="${1%/}"
  dst="${2%/}"
  parallel=8
fi

expected="ffmpeg rsync"
results=$(set +e; for cmd in $expected; do command -V $cmd; done; set -e)
actual=$(printf "%s\n" "$results" | while read first _; do printf "%s%s" "$sep" "${first%%*:}"; sep=" "; done)
[ "$expected" = "$actual" ] || { printf "Expected commands on PATH: %s, actual: %s\n" "$expected" "$actual" 1>&2; exit 1; }

tmp=$(mktemp -d)
trap "rm -rf $tmp; exit" INT TERM EXIT

generate() {
  find "$src" -type d -o -name "*.flac" | tee /tmp/tsync.generate
}

filter() {
  while read -r path
  do
    dir=${path%/*}
    file=${path##*/}
    # files with valid src format
    [ "${path%.flac}" = "$path" ] && continue
    # files that don't exist in dst
    [ ! -f "$dst/${dir#$src/}/${file%.*}.mp3" ] && { printf '%s\n' "$path" && continue; }
    # files that have changed (src is newer)
    [ "$path" -nt "$dst/${dir#$src/}/${file%.*}.mp3" ] && printf '%s\n' "$path"
  done
}

transform() {
  # posix printf doesn't have %q for escaping $ etc, so use sed instead
  sed 's|\$|\\$|' |
  while read -r path
  do
    dir=${path%/*}
    file=${path##*/}
    printf 'organization=$(ffprobe -loglevel error -show_entries format_tags=organization -of default=noprint_wrappers=1:nokey=1 "%s"); ' "$path"
    printf 'mkdir -p "%s/%s"; ' $tmp "${dir#$src/}"
    printf 'ffmpeg -v error -y -i "%s" -c:a libmp3lame -q:a 0 -c:v copy -id3v2_version 3 -write_id3v1 1 -metadata organization= -metadata publisher="$organization" "%s/%s/%s.mp3"; ' "$path" $tmp "${dir#$src/}" "${file%.*}"
    printf 'mkdir -p "%s/%s"; ' "$dst" "${dir#$src/}"
    printf 'mv "%s/%s/%s.mp3" "%s/%s/"; ' $tmp "${dir#$src/}" "${file%.*}" "$dst" "${dir#$src/}"
    printf 'echo "%s/%s/%s.mp3"' "$dst" "${dir#$src/}" "${file%.*}"
    printf '\n'
  done
}

run() {
  tr '\n' '\0' |
  xargs -P$parallel -I {} -0 ${dry:+echo} sh -c "(set -e; {}); [ \$? -ne 0 ] && exit 255; exit 0"
}

sync() {
  # escape [ ] for rsync file lists.. why!?!?
  < /tmp/tsync.generate sed '\|.flac$|!d; s|\.flac$|\.mp3|; s|'"$src"'||; s|\[|\\[|; s|\]|\\]|' >/tmp/tsync.exclude
  < /tmp/tsync.generate sed '\|\.flac$|d; s|'"$src"'||' >/tmp/tsync.include
  rsync ${dry:+-n} -rtv --delete --include-from /tmp/tsync.include --exclude-from /tmp/tsync.exclude --exclude .tsync --filter "-s *" "$src/" "$dst"
}

generate |
filter |
transform |
run

sync
