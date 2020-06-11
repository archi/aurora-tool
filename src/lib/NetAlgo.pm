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
    $algo{output_channels} = ();

    return \%algo;
}

sub debugString {
    my $n = shift;
    my @nstr;
    push @nstr, $n->{cell};
    if (defined $n->{params}) {
        push @nstr, $n->{params}->debugString();
    } else {
        push @nstr, "no_params";
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

    return '{' . join('; ', @nstr) . '}';
}

1;