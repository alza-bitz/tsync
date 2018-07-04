#!/usr/bin/env sh

set -e

if [ "$#" -lt "1" -o "$#" -gt "2" ]
then
  printf 'Usage: %s <source> <destination>\n' "$0"
  exit 1
else
  src="${1%/}"
  dst="${2%/}"
  parallel=8
#  dry=true
fi

expected="ffmpeg rsync"
results=$(for cmd in $expected; do command -V $cmd; done)
actual=$(printf "%s\n" "$results" | while read first _; do printf "%s%s" "$sep" "${first%%*:}"; sep=" "; done)
[ "$expected" = "$actual" ] || { printf "Expected commands on PATH: %s, actual: %s\n" "$expected" "$actual" 1>&2; exit 1; }

tmp=$(mktemp -d)
trap "rm -rf $tmp; exit" INT TERM EXIT

generate() {
  # TODO some debate about whether to include .cue, .log, .m3u etc
  find "$src"  | tee /tmp/tsync.generate
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
  done | tee /tmp/tsync.filter
}

transform() {
  # posix printf doesn't have %q for escaping $ etc, so use sed instead
  sed 's|\$|\\$|' |
  while read -r path
  do
    dir=${path%/*}
    file=${path##*/}
    if [ $dry ]
    then
      printf 'mkdir -p "%s/%s"; ' $tmp "${dir#$src/}"
      printf 'touch "%s/%s/%s.mp3"' $tmp "${dir#$src/}" "${file%.*}"
      printf '\n'
    else
      printf 'mkdir -p "%s/%s"; ' $tmp "${dir#$src/}"
      # TODO handle finished/up-to-date mp3's in $tmp (don't transcode again)
      printf 'ffmpeg -v error -y -i "%s" -c:a libmp3lame -q:a 0 -c:v copy -id3v2_version 3 -write_id3v1 1 "%s/%s/%s.mp3"; ' "$path" $tmp "${dir#$src/}" "${file%.*}"
      printf 'echo "%s/%s/%s.mp3"' "$tmp" "${dir#$src/}" "${file%.*}"
      printf '\n'
    fi
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
  < /tmp/tsync.filter sed 's|\.flac$|\.mp3|; s|'"$src"'||' >>/tmp/tsync.include
  rsync ${dry:+-n} -av --delete --include-from /tmp/tsync.include --exclude-from /tmp/tsync.exclude --filter "-s *" "$src/" $tmp/ "$dst"
}

generate |
filter |
transform |
run

sync
