#!/bin/bash
ThisDir=`dirname "$0"`
PpCmd="$ThisDir"/a/json-pretty-compact.sh
CpCmd=/usr/bin/cp
if [ $# -lt 2 ]; then
    echo usage: "$0" '<src_dir> <dest_dir>' 1>&2
    exit 1
fi
SrcDir="$1"
DstDir="$2"
[ ! -d "$SrcDir" ] || [ ! -d "$DstDir" ] && exit 2

"$PpCmd" "$SrcDir"/urdfmap_cut.json -o "$DstDir"/urdf.json -c 90
[ -f "$SrcDir"/update.json ] && "$PpCmd" "$SrcDir"/update-stub.json -o "$DstDir"/update.json -c 90
[ ! -f "$SrcDir"/update.json ] && [ -f "$SrcDir"/update-stub.json ] && \
    "$PpCmd" "$SrcDir"/update-stub.json -o "$DstDir"/update.json -c 90
[ ! -f "$SrcDir"/update.json ] && [ -f "$SrcDir"/update-with-tools-collider.json ] && \
    "$PpCmd" "$SrcDir"/update-with-tools-collider.json -o "$DstDir"/update.json -c 90
"$CpCmd" "$SrcDir"/linkmap.json "$DstDir"/
[ -f "$SrcDir"/shapes.json ] && "$CpCmd" "$SrcDir"/shapes.json "$DstDir"/
[ -f "$SrcDir"/testPairs.json ] && "$CpCmd" "$SrcDir"/testPairs.json "$DstDir"/
"$CpCmd" "$SrcDir"/meshes/out/* "$DstDir"/
