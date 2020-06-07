package Net;

use strict;
use warnings;
use ParamNode;

use constant FORWARD => 0;
use constant REVERSE => 1;
use constant ANY => 2;

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

sub addAlgo {
    my %algo;
    bless \%algo;

    my $cell = shift;
    $algo{cell} = $cell;
    $algo{params} = ParamNode::find($cell);
    $algo{link_in} = ();
    $algo{link_out} = ();
    $algo{input_channels} = ();

    if ($cell =~ m/inputselect_([0-9]+)\.nx1-1$/) {
        $inputs[$1 - 1] = \%algo;
    } elsif ($cell eq "mastervolume") {
        $masterVolume = \%algo;
    }

    push @allNodes, \%algo;

    return \%algo;
}

sub addLink {
    my $algo = shift;
    my $dir = shift;
    my $id = shift;

    push @{$algo->{"link_" . $dir}}, $id;
    if (not defined $attachedTo[$id]) {
        $attachedTo[$id]->{in} = ();
        $attachedTo[$id]->{out} = ();
    }
    push @{$attachedTo[$id]->{$dir eq "in" ? "out" : "in"}}, $algo;
}

sub postProcess {
    foreach my $i (0 .. (scalar(@inputs) - 1)) {
        markChannels($inputs[$i], $i, FORWARD);
    }

    my $i = 0;
    foreach my $link_in (@{$masterVolume->{link_in}}) {
        foreach my $node_in (@{$attachedTo[$link_in]->{in}}) {
            markChannels($node_in, $i, REVERSE);
        }
        $i++;
    }
}

# node: node to start from
# direction: FORWARD or REVERSE
# map ($node, $data): the function to call on the node (return 0 to stop recursion, else 1)
# follow ($next_node, $index_of_next_node, $data): the function to select which link to follow (optional, follows all links by default, return 0 not to follow)
# data: additional data passed to map/selector
sub visitNodesRecursive {
    my $node = shift;
    my $direction = shift;
    my $map = shift;
    my $follow = shift;
    my $data = shift;

    return if not $map->($node, $data);
    my $index_of_next_node = -1;
    foreach my $link (@{$node->{$direction == FORWARD ? "link_out" : "link_in"}}) {
        my $d = $direction == FORWARD ? "out" : "in";
        next if not defined $attachedTo[$link]->{$d};
        foreach my $next_node (@{$attachedTo[$link]->{$d}}) {
            $index_of_next_node++;
            next if defined $follow and not $follow->($index_of_next_node, $data);
            visitNodesRecursive($next_node, $direction, $map, $follow, $data); 
        }
    }
}

sub markChannels {
    my $node = shift;
    my $channel = shift;
    my $dir = shift;

    visitNodesRecursive($node, $dir, sub {
            my $node = shift;
            push @{$node->{$dir == FORWARD ? "input_channels" : "output_channels"}}, $channel;
    });
}

#
# Debug & testing code below here
#

sub debugLine {
    my $chn = shift;
    if (not defined $inputs[$chn]) {
        print "No channel #$chn\n";
        return undef;
    }

    die "Don't have a masterVolume!" if not defined $masterVolume;

    my @strs;
    foreach my $n (@{generateSimpleLine($chn)}) {
        my @nstr;
        if (defined $n->{params}) {
            push @nstr, $n->{params}->debugString();
        } else {
            push @nstr, "undef";
        }

        if (defined $n->{input_channels}) {
            push @nstr, 'cin=[' . join(',', @{$n->{input_channels}}) . ']';
        } else {
            push @nstr, 'cin=[?]';
        }

        if (defined $n->{output_channels}) {
            push @nstr, 'cout=[' . join(',', @{$n->{output_channels}}) . ']';
        } else {
            push @nstr, 'cout=[?]';
        }

        push @nstr, 'lin='.scalar(@{$n->{link_in}});
        push @nstr, 'lout='.scalar(@{$n->{link_out}});
        
        push @nstr, 'nin='.scalar(@{$n->{node_in}}) if defined $n->{node_in};
        push @nstr, 'nout='.scalar(@{$n->{node_out}}) if defined $n->{node_out};
    
        push @strs, '{' . join('; ', @nstr) . '}';
    }
    print "#$chn-> ", join ("\n  -> ", @strs), "\n"; 
}

sub generateSimpleLine {
    my $chn = shift;
    my $node = $inputs[$chn];
    my @nodeList;
    while ($node ne $masterVolume) {
        push @nodeList, $node;
        die "undef?!\n" if not defined $node;
        print $node->{cell}, "\n";
        if (defined @{$node->{link_out}}[0]) {
            my $link = @{$node->{link_out}}[0];
            last if (not defined $attachedTo[$link]);
            $node = $attachedTo[$link]->{out}[0];
        } else {
            last;
        }
    }
    push @nodeList, $masterVolume if (defined $node);
    return \@nodeList;
}

1;
