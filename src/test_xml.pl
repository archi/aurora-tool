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
use CollectedData;
use WritePluginIni;

sub error {
    my $str = shift;
    while (my $a = shift) {
        $str = $str . " " . $a;
    }
    die $str;

    return undef;
}

my $dsp = "HomeCinema71";
my $data = CollectedData::new();
ParseParams::parse("../test/$dsp/$dsp.params", $data);
NetParser::parse("../test/$dsp/${dsp}_NetList.xml", $data);
$data->postProcess();
WritePluginIni::write("../test/$dsp/plugin.ini", $data->{result_for_pluginini});


exit 0;
