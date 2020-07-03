#!/usr/bin/perl -w

#	This file is part of aurora-tool
# 	Official repository: https://github.com/archi/aurora-tool
#   (c) Sebastian Meyer, 2020
#
#   The aurora-tool is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   aurora-tool is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with aurora-tool.  If not, see <http://www.gnu.org/licenses/>.

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
