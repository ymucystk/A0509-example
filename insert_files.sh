#!/bin/bash
# Add the file names under public directory to 'package.json'
set -e
TmpFile=`mktemp`
JsonFile=`mktemp`
echo '  "files": [' > "$TmpFile"
ls -1 public/*/* |\
    head -n $((`ls -1 public/*/* |wc -l`-1)) |\
    sed -e 's/^/"/;s/$/",/' >> "$TmpFile"
ls -1 public/*/* |tail -1 |sed -e 's/^/"/;s/$/"/' >> "$TmpFile"
echo '  ],' >> "$TmpFile"
cat package.json |\
sed -e '/^[ \t]*"name":.*,/s|^\([^"]*"name"[ \t]*:[ \t]*"\)\([^"]*".*\)$|\1@ucl-nuee/\2|' |\
sed -e ':loop' -e '/,/!{N;b loop' -e '}'  \
    -e '/"version"/r'"$TmpFile" \
    -e '/^[ \t]*"main":.*,/d' \
    -e '/^[ \t]*"scripts":.*,/d' \
    -e '/^[ \t]*"author":.*,/s/^\([^"]*"[^"]*"[ \t]*:[ \t]*"\)[^"]*\(".*\)$/\1Created automatically from URDF\2/' \
    > "$JsonFile" && \
    /usr/bin/mv package.json{,.ORIG} && \
    /usr/bin/mv "$JsonFile" package.json
/usr/bin/rm "$TmpFile"
