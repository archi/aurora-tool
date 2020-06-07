package Net;

use strict;
use warnings;
use ParamNode;

my @inputs;
my $masterVolume = undef;
my @attachedTo;

sub addAlgo {
    my %algo;
    bless \%algo;

    my $cell = shift;
    $algo{cell} = $cell;
    $algo{params} = ParamNode::find($cell);
    $algo{in} = ();
    $algo{out} = ();

    if ($cell =~ m/inputselect_([0-9]+)\.nx1-1$/) {
        $inputs[$1 - 1] = \%algo;
    } elsif ($cell eq "mastervolume") {
        $masterVolume = \%algo;
    }

    return \%algo;
}

sub addLink {
    my $algo = shift;
    my $dir = shift;
    my $id = shift;

    push @{$algo->{$dir}}, $id;
    if (not defined $attachedTo[$id]) {
        $attachedTo[$id]->{in} = ();
        $attachedTo[$id]->{out} = ();
    }
    push @{$attachedTo[$id]->{$dir eq "in" ? "out" : "in"}}, $algo;
}

sub debugLine {
    my $chn = shift;
    if (not defined $inputs[$chn - 1]) {
        print "No channel #$chn\n";
        return undef;
    }

    die "Don't have a masterVolume!" if not defined $masterVolume;

    my @strs;
    foreach my $n (@{generateSimpleLine($chn - 1)}) {
        if (defined $n->{params}) {
            push @strs, $n->{params}->debugString();
        } else {
            push @strs, "undef";
        }
    }
    print "#$chn:", join ("->", @strs), "\n"; 
}

sub generateSimpleLine {
    my $chn = shift;
    my $node = $inputs[$chn];
    my @nodeList;
    while ($node ne $masterVolume) {
        push @nodeList, $node;
        print $node->{cell}, "\n";
        if (defined @{$node->{out}}[0]) {
            my $link = @{$node->{out}}[0];
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
