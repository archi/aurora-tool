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
our $assets_path;
BEGIN {
    my $bin = $0;
    $bin = getcwd . "/$bin" if $bin =~ m@^\./@;
    $bin =~ s@[^/\\]*\.pl$@@;
    $lib_path = $bin . "lib";
    $assets_path = $bin . "assets";
}
use lib $lib_path;

# Additional global modules
use Getopt::Std;
use Getopt::Long;

# Only needs the driver
use Driver;
use Tools;

# Get & check parameters
my $input_dir = undef;
my $output_dir = undef;
my $help = 0;
my $project_name = undef;
our $verbose = 0;
GetOptions (
    'in=s' => \$input_dir,
    'out=s' => \$output_dir,
    'project=s' => \$project_name,
    'v|verbose' => \$verbose,
    'h|help' => \$help,
);

# help takes precedence
if ($help) {
    print "aurora-tool v$Tools::version, plugin converter for the cli\n",
          $Tools::copyright, "\n",
          "\n",
          "Usage: $0 --in <dir> --out <dir> [--project <name>]\n",
          "\n",
          "  --in       * Directory containing the SigmaStudio export files\n",
          "  --project    Name of the project (e.g. 8channels)\n",
          "  --out      * Name of the directory in which to put the result files\n",
          "\n",
          "E.g. $0 --in ../../8channel/ --out plugin/ --project 8channel\n",
          "\n",
          "Website: $Tools::url\n";
    exit 0;
}

my $driver = Driver::create($input_dir, $output_dir, $project_name);

if (not $driver->hasErrors()) {
    $driver->doEverything();
}

if ($driver->hasErrors()) {
    print STDERR join("\n", @{$driver->{errorStrings}});
    print STDERR "\n\nUse --help to get help.\n";
    exit 1;
}

print "\nScript finished without detected errors. Remember to ALWAYS review the output."; 
print "This script (and the result) come with no warranty for correctness. If this kills your speakers or DSP, it is your fault for not properly reviewing the output!\n";

exit 0;
