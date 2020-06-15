package CollectedData;

use strict;
use warnings;

use NetAlgo;

use constant FORWARD => 0;
use constant REVERSE => 1;
use constant ANY => 2;

sub new {
    my %self;
    
    # Data from param.ini:
    $self{paramNodes} = ();
    
    # Data from NetList.xml   

    # All nodes
    $self{netNodes} = ();
    
    # set of nodes, mps [1..8] -> (inputselect_[1..8].nx1-1)
    $self{inputs} = [];
    
    # maps numerical link id (from "link123") -> ("in" -> @incoming_algorithms, "out" -> @outgoing_algorithms)
    # So the simple net
    #  inputselect_1.nx1-1 --Link1--> peq_1 --Link2--> mastervolume
    # generates:
    #  attachedTo[1] = {"in" => [inputselect_1.nx1-1], "out" => [peq_1]}
    #  attachedTo[2] = {"in" => [peq_1], "out" => [mastervolume]}
    # (the elements are nodes from 'addAlgo')
    $self{attachedTo} = ();
    
    # just the single master volume node
    $self{masterVolume} = undef;
    
    bless \%self;
    return \%self;
}

sub addParamNode {
    my $self = shift;
    my $node = shift;
    my $name = $node->{name};

    return 0 if (defined $self->{paramNodes}->{$name});
    $self->{paramNodes}->{$name} = $node;
    return 1;
}

sub findParamNode {
    my $self = shift;
    my $name = shift;
    if (not defined $self->{paramNodes}->{$name}) {
        return undef;
    }
    return $self->{paramNodes}->{$name};
}

sub addAlgo {
    my $self = shift;
    my $cell_name = shift;
    
    my $algo = NetAlgo::new($cell_name, $self->findParamNode($cell_name));
    
    push @{$self->{netNodes}}, $algo;
    
    if ($cell_name =~ m/inputselect_([0-9]+)\.nx1-1$/) {
        @{$self->{inputs}}[$1 - 1] = $algo;
    } elsif ($cell_name eq "mastervolume") {
        $self->{masterVolume} = $algo;
    }
    
    return $algo;
}

sub addLink {
    my $self = shift;
    my $algo = shift;
    my $dir = shift;
    my $id = shift;

    push @{$algo->{"link_" . $dir}}, $id;
    if (not defined @{$self->{attachedTo}}[$id]) {
        @{$self->{attachedTo}}[$id] = {
            "in" => [],
            "out" => [],
        };
    }
    push @{@{$self->{attachedTo}}[$id]->{$dir eq "in" ? "out" : "in"}}, $algo;
}

sub getLinkNodes {
    my $self = shift;
    my $link_id = shift;
    my $dir = shift;
    $dir = "out" if $dir eq FORWARD;
    $dir = "in" if $dir eq REVERSE;
    
    return undef if not defined @{$self->{attachedTo}}[$link_id];
    return undef if not defined @{$self->{attachedTo}}[$link_id]->{$dir};
    return @{$self->{attachedTo}}[$link_id]->{$dir};
}

sub postProcess {
    my $self = shift;
    
    foreach my $i (0 .. (scalar(@{$self->{inputs}}) - 1)) {
        $self->markChannels(@{$self->{inputs}}[$i], $i, FORWARD);
    }

    my $i = 0;
    foreach my $link_id (@{$self->{masterVolume}->{link_in}}) {
        my $incoming = $self->getLinkNodes($link_id, "in");
        next if not defined $incoming;
        foreach my $node_in (@{$incoming}) {
            $self->markChannels($node_in, $i, REVERSE);
        }
        $i++;    
    }
    
    
    foreach my $input (@{$self->{inputs}}) {
       $self->classifyXOs($input);
    }
    $self->purgeXOdups("lp");
    $self->purgeXOdups("hp");
}

sub markChannels {
    my $self = shift;
    my $node = shift;
    my $channel = shift;
    my $dir = shift;

    $self->visitNodesRecursive($node, $dir, sub {
        my $node = shift;
        push @{$node->{$dir == FORWARD ? "input_channels" : "output_channels"}}, $channel;
        return 1;
    });
}

sub purgeXOdups {
    my $self = shift;
    my $pass = shift;
    
    my %is_xo;
    foreach my $id (@{$self->{result_for_pluginini}->{"xo" . $pass}}) {
        $is_xo{$id} = 1;
    }
    
    my @new_array;
    foreach my $id (@{$self->{result_for_pluginini}->{$pass}}) {
        if (defined $is_xo{$id} and $is_xo{$id} == 1) {
            next;
        }
        push @new_array, $id;
    }
    
    $self->{result_for_pluginini}->{$pass} = \@new_array;
}

# mark XOs and put them in the result_for_pluginini data
# this causes the XO's HPs+LPs to be duplicated:
#  * once in the result_for_pluginini->{xo?p}, and
#  * once in the result_for_pluginini->{?p} array
# The purgeXOdups later removes the dups from the {?p} arrays
sub classifyXOs {
    my $self = shift;
    my $input = shift;
    
    my $channel_count = scalar @{$input->{output_channels}};
    return if $channel_count < 2;
    
    my %input_data;
    $input_data{channel_count} = $channel_count;
    $input_data{followup_pass} = "xxx";
    $input_data{depth} = "";
    
    $self->visitNodesRecursive($input, FORWARD, sub {
        my $node = shift;
        return undef if $node == $self->{masterVolume};
        shift; # data, is undef
        my $parent = shift;
        
        my %data;
        foreach my $k (keys %{$parent}) {
            $data{$k} = $parent->{$k};
        }
        $data{depth} .= "| ";
        
        my $channel_count = scalar @{$node->{output_channels}};
        $data{channel_count} = $channel_count;
        
        if (not defined $node->{params}) {
            # print $parent->{depth}, "...\n";
            return \%data;
        }
        
        # print
            # $parent->{depth},
            # $node->debugString(),
            # " -> ";
        
        if ($node->{params}->{type} =~ m/^(h|l)p$/) {
            my $ps = $parent->{followup_pass};
            my $is_xo = 0;
            if ($channel_count < $parent->{channel_count}) {
                my $s = $node->{cell} . "";
                $s =~ s/_\d+$/_/g;
                $data{followup_pass} = $s;
                $is_xo = 1;
            } elsif ($node->{cell} =~ m/^$ps\d+$/){
                $is_xo = 1;
            }
            
            if ($is_xo == 1) {
                $node->{params}->{type} = "xo" . $node->{params}->{type};
                push @{$self->{result_for_pluginini}->{$node->{params}->{type}}}, $node->{params}->{address};
            }
        }
        
        # print $node->{params}->{type},
            # "\n";
        
        return \%data;
    }, undef, undef, \%input_data);
}

# node: node to start from
# direction: FORWARD or REVERSE
# map ($node, $data, $previous_return_value): the function to call on the node (return 0 to stop recursion, else 1)
# follow ($next_node, $index_of_next_node, $data): the function to select which link to follow (optional, follows all links by default, return 0 not to follow)
# data: additional data passed to map/selector
# previous_return_value: data returned by parent call to map
sub visitNodesRecursive {
    my $self = shift;
    my $node = shift;
    my $direction = shift;
    my $map = shift;
    my $follow = shift;
    
    my $data = shift;
    my $previous_return_value = shift;

    my $return_value = $map->($node, $data, $previous_return_value);
    return if not defined $return_value;
    
    my $index_of_next_node = -1;
    foreach my $link_id (@{$node->{$direction == FORWARD ? "link_out" : "link_in"}}) {
        my $d = $direction == FORWARD ? "out" : "in";
        my $linked_nodes = $self->getLinkNodes($link_id, $direction);
        next if not defined $linked_nodes;
        foreach my $next_node (@{$linked_nodes}) {
            $index_of_next_node++;
            next if defined $follow and not $follow->($index_of_next_node, $data);
            $self->visitNodesRecursive($next_node, $direction, $map, $follow, $data, $return_value); 
        }
    }
}

#
# Debug & testing code below here
#

# TODO port to CollectedData
sub debugLine {
    my $self = shift;
    my $chn = shift;
    if (not defined @{$self->{inputs}}[$chn]) {
        print "No channel #$chn\n";
        return undef;
    }

    die "Don't have a masterVolume!" if not defined $self->{masterVolume};

    my @strs;
    foreach my $n (@{$self->generateSimpleLine($chn)}) {
        push @strs, $n->debugString();
    }
    print "#$chn-> ", join ("\n  -> ", @strs), "\n"; 
}

sub generateSimpleLine {
    my $self = shift;
    my $chn = shift;
    my $node = @{$self->{inputs}}[$chn];
    my @nodeList;
    while ($node ne $self->{masterVolume}) {
        push @nodeList, $node;
        die "undef?!\n" if not defined $node;
        print $node->{cell}, "\n";
        if (defined @{$node->{link_out}}[0]) {
            my $link = @{$node->{link_out}}[0];
            my $linked_nodes = $self->getLinkNodes($link, "out");
            last if not defined $linked_nodes;
            $node = @{$linked_nodes}[0];
        } else {
            last;
        }
    }
    push @nodeList, $self->{masterVolume} if (defined $node);
    return \@nodeList;
}

1;
