package NetAlgo;

use strict;
use warnings;
use ParamNode;

sub new {
    my %algo;
    bless \%algo;

    my $cell = shift;
    $algo{cell} = $cell;
    $algo{params} = shift;
    $algo{link_in} = ();
    $algo{link_out} = ();
    $algo{input_channels} = ();

    return \%algo;
}

1;
