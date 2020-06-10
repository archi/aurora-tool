package NetAlgo;

use strict;
use warnings;
use ParamNode;

my @allNodes;

# set of nodes, mps [1..8] -> (inputselect_[1..8].nx1-1)
my @inputs;

# just the single master volume node
my $masterVolume = undef;

# maps numerical link id (from "link123") -> ("in" -> @incoming_algorithms, "out" -> @outgoing_algorithms)
my @attachedTo;

# So the simple net
#  inputselect_1.nx1-1 --Link1--> peq_1 --Link2--> mastervolume
# generates:
#  attachedTo[1] = {"in" => [inputselect_1.nx1-1], "out" => [peq_1]}
#  attachedTo[2] = {"in" => [peq_1], "out" => [mastervolume]}
# (the elements are nodes from 'addAlgo')

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
