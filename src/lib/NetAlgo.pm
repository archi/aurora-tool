package NetAlgo;

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
