package ParamNode;

use strict;
use warnings;
use Tools;

# Map normalized cell names (e.g. param_eq_1) to their corresponding tuple (address, type)
# In case PEQ, also add addresses of additional bands as additional_bands
my %nodes;

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
    bless \%self;

    printf("ParamNode: '%s'@%i (%s) => %s (type=$type)\n", $data->{cell_name}, $data->{address}, $data->{name}, $name) if $main::verbose;

    if (not defined $nodes{$name}) {
        $self{additional_bands} = [];
        $nodes{$name} = \%self;
    } elsif ($type eq "peq") {
        # Handle PEQ: Multiple addresses (one per band)
        push @{$nodes{$name}->{additional_bands}}, $data->{address};
    } else {
        # everything that's not a PEQ should have only a single address/node
        die ("Error: Duplicate node '$name' in .params-file!\n");
    }
    return \%self;
}

sub find {
    my $name = Tools::normalize(shift);
    return $nodes{$name} if defined $nodes{$name};
    return undef;
}

1;
