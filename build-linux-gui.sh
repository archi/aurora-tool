#!/bin/sh

bin=aurora-tool
rm -f $bin
pp -o $bin src/gui.pl --lib=src/lib -M Driver -M Tk::Bitmap -g -z 9
pkg="$bin-$(./$bin --version).xz"
rm -f $pkg
tar cJf $pkg $bin
