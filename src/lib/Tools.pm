package Tools;

use strict;
use warnings;

our $sep = $^O eq "MSWin32" ? "\\" : "/";
our $version = "0.1.3-alpha";
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
