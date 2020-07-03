package Tools;

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

use strict;
use warnings;

our $sep = $^O eq "MSWin32" ? "\\" : "/";
our $version = "0.1.4-alpha";
our $url = "https://github.com/archi/aurora-tool";
our $copyright = "(c) 2020 Sebastian 'archi' Meyer, licensed under GPLv3";

# Cell names vary, e.g. in the NetList XML they're "Param EQ 1 ",
#  and in the .params they're "Param EQ 1".
# This function normalizes them:
sub normalize {
    my $in = lc shift;
    $in =~ s/\s*$//;
    $in =~ s/ /_/g;
    return $in;
}
1;
