#!/usr/bin/perl -w

package main;
use strict;
use warnings;

# Find the library path, and allow loading libs from there
use Cwd;
my $lib_path;
BEGIN {
    my $bin = $0;
    $bin = getcwd . "/$bin" if $bin =~ m@^\./@;
    $bin =~ s@[^/\\]*\.pl$@@;
    $lib_path = $bin . "lib";
}
use lib $lib_path;

# Additional global modules
use Getopt::Std;
use Getopt::Long;

use ParseParams;
use NetParser;

sub error {
    my $str = shift;
    while (my $a = shift) {
        $str = $str . " " . $a;
    }
    die $str;

    return undef;
}

ParseParams::parse("../test/8channels/8channels.params");
NetParser::parse("../test/8channels/8channels_NetList.xml");

for my $i (1..8) {
    Net::debugLine($i);
}

exit 0;
