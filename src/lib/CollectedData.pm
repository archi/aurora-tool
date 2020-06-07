package CollectedData;

sub new {
    my %self;
    $self->{paramNodes} = ();
    bless \%self;
    return \%self;
}

sub addParamNode {
    my $self = shift;
    my $node = shift;
    my $nodeName = $node->{name};

    return 0 if (defined $self->{paramNodes}->{$nodeName});
    $self->{paramNodes}->{$nodeName} = shift;
    return 1;
}

sub findParamNode {
    my $self = shift;
    my $name = shift;
    return undef if not defined $self->{paramNodes}->{$name};
    return $self->{paramNodes}->{$name};
}

1;
