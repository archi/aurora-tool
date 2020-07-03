package ParamNode;

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
use Tools;

# Map normalized cell names (e.g. param_eq_1) to their corresponding tuple (address, type)
# In case PEQ, also add addresses of additional bands as additional_bands

sub create {
    my $data = shift;
    my $type = shift;
    my $raw_name = $data->{cell_name};
    my $name = Tools::normalize($raw_name);

    my %self;
    $self{name} = $name;
    $self{type} = $type;
    $self{address} = $data->{address};
    $self{raw_data} = $data;
    $self{nodes} = {};
    bless \%self;

    printf("ParamNode: '%s'@%i (%s) => %s (type=$type)\n", $data->{cell_name}, $data->{address}, $data->{name}, $name) if $main::verbose;
    return \%self;
}

sub debugString {
    my $self = shift;
    return "(" . $self->{name} . ", " . $self->{type} .", " . $self->{address} .")";
}

1;
