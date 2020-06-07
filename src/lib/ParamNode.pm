package ParamNode;

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
    return "(" . $self->{name} . ", " . $self->{type} .")";
}

1;
