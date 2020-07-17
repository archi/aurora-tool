package Layouter;

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

use CollectedData;

use constant NODE => 0;
use constant BRANCH => 1;
use constant BELOW => 0;
use constant ABOVE => 1;

sub generate {
    my $layout_js = shift;
    my $data = shift;

    my $grid = createGrid();

    # create the basic grid
    # right now, branching to the same channel,
    #  (e.g. XO to PEQ for LFE and FIR for HF; then merge again)
    #  is not properly handled...
    foreach my $channel (0 .. (scalar(@{$data->{inputs}}) - 1)) {
        print "Input $channel\n";
        my $line = $grid->addLine();
        $grid->addNodesToLine($data, @{$data->{inputs}}[$channel], $channel, $line);
    }

    # I suppose there must be instances where this loops forever?
    while($grid->alignBranches()) {
        print "Updated alignment...\n";
    }

    $grid->export($layout_js);

    return 1;
}

sub export {
    my $self = shift;

    print "var dsplines = [\n";
    my $line_idx = 0;
    while ($line_idx < $self->{next_line}) {
        print ",\n" if $line_idx > 0;
        print "  [";
        my $line_arr = @{$self->{line_items}}[$line_idx];
        my $el_cnt = scalar @{$line_arr};
        my $el_idx = 0;
        while ($el_idx < $el_cnt) {
            print ", " if $el_idx > 0;
            $self->exportElement(
                $self->{line_items}[$line_idx][$el_idx],
                $self->{line_items_types}[$line_idx][$el_idx]);
            ++$el_idx;
        }
        print "\n  ]";
        ++$line_idx;
    }

    print "\n];\n";

}

sub exportElement {
    my $self = shift;
    my $el = shift;
    my $type = shift;
    print "\n    ", ($type == BRANCH ? "BR" : "  "), $el->{virtual_index_in_line}, ":", $el->debugString();
}

sub addNodesToLine {
    my $grid = shift;
    my $data = shift;
    my $start_at = shift;
    my $channel = shift;
    my $line = shift;

    $data->visitNodesRecursive($start_at, CollectedData::FORWARD, sub {
            # if we got here, we can add the node to the current channel's line
            my $node = shift;
            $grid->appendNode($line, $node);
            return $node;
        }, sub {
            # this is were the logic happens:
            my $next_node = shift;
            my $index_of_next_node = shift;
            shift; # undefined data
            my $previous_node = shift;
            return 1 if not defined $previous_node;

            # end on master volume
            return undef if $next_node == $data->{masterVolume};

            # check if we're branching to another channel
            if (not $next_node->affectsChannel($channel) and not $next_node->equalChannels($previous_node)) {
                $grid->insertBranchAfterNode($line, $previous_node, $next_node);

                if (not $next_node->belongsToChannel($channel)) {
                    print "  !! ($index_of_next_node) not following to $next_node = ",$next_node->debugString(),"\n";
                    return undef;
                }

                #  XO is
                #  0 -|-> HP ----------> out0
                #     |-> LP -\
                #  7 ---> LP -|-> nxm -> out7
                # so if a node only has the current channel as input, but affects another channel:
                #  add that as a new line below the current line
                #  (the offset will be later correct in the alignment code)

                print "  ** ($index_of_next_node) following branch to $next_node = ",$next_node->debugString(),"\n";
                my $sub_line = $grid->insertLineAfter($line);
                $grid->appendNode($sub_line, $next_node);
                $grid->addNodesToLine($data, $next_node, $channel, $sub_line);
                return undef;
            }

            if ($index_of_next_node != 0) {
                print "   Ignoring node on branch to same output: $next_node = ",$next_node->debugString(),"\n0";
                return undef;
            }

            # decide whether to follow, or add to the nodes_on_frontier
            print "  => ($index_of_next_node) follow to $next_node = ",$next_node->debugString(),"\n";
            return 1;
        });
}

sub alignBranches {
    my $self = shift;

    #
    # align branches, e.g. if we have a grid
    #   A1 -> A2 -> A3
    #      \_____       <- branch from A1 to B3
    #            \--v
    #   B1 -> B2 -> B3
    # make it:
    #   A1 -> -- ---> A2 -> A3
    #   B1 -> B2 -\-> B3
    # (B3 is later filled up)
    #

    # 1. iterate over all nodes
    # 2. if the above is found, update all nodes' virtual_index_in_line to match up
    # 3. repeat until no more changes are found (handled by call-site while non-zero value is returned)

    # 1. iterate
    my $line_idx = 0;
    while ($line_idx < $self->{next_line}) {
        my $line_arr = @{$self->{line_items}}[$line_idx];
        my $el_cnt = scalar @{$line_arr};
        my $el_idx = 0;
        while ($el_idx < $el_cnt) {
            # check if the current element is followed by branches, and gather the maximum virtual id
            my $max_virt = $self->nodeBranchMaxVirtualIndex($line_idx, $el_idx, $el_cnt);
            if (defined $max_virt) {
                return 1 if $self->fixupVirtualIndices($line_idx, $el_idx, $el_cnt, $max_virt) > 0;
            }

            ++$el_idx;
        }

        ++$line_idx;

    }

    # nothing changed -> return 0 to break the loop
    return 0;
}

sub fixupVirtualIndices {
    my $self = shift;
    my $line_idx = shift;
    my $el_idx = shift;
    my $el_cnt = shift;
    my $max = shift;

    my $fixes = 0;
    while ($el_idx < $el_cnt) {
        my $el = $self->{line_items}[$line_idx][$el_idx];
        if ($el->{virtual_index_in_line} < $max) {
            $self->increaseVirtualIndex($el, $max - $el->{virtual_index_in_line});
            ++$fixes;
        }
        last if ($self->{line_items_types}[$line_idx][$el_idx] == NODE);
        $el_idx++;
    }
    return $fixes;
}

sub increaseVirtualIndex {
    my $self = shift;
    my $el = shift;
    my $inc_by = shift;
    my $el_line = $el->{belongs_to_line};
    my $el_idx = $el->{index_in_line};
    my $el_cnt = scalar @{$self->{line_items}[$el_line]};

    while ($el_idx < $el_cnt) {
        $self->{line_items}[$el_line][$el_idx]->{virtual_index_in_line} += $inc_by;
        ++$el_idx;
    }
}

sub nodeBranchMaxVirtualIndex {
    my $self = shift;
    my $line_idx = shift;
    my $el_idx = shift;
    my $el_cnt = shift;

    my $max = 0;
    while ($el_idx < $el_cnt) {
        my $el_virt_idx = $self->{line_items}[$line_idx][$el_idx]->{virtual_index_in_line};
        $max = $el_virt_idx if not defined $max or $el_virt_idx > $max;
        return $max if ($self->{line_items_types}[$line_idx][$el_idx] == NODE);
        $el_idx++;
    }
    return undef;
}

sub createGrid {
    my %self;
    bless \%self;

    $self{next_line} = 0;
    $self{line_items} = ();
    $self{line_items_types} = ();

    return \%self;
}

#
# Append an item to a line
#
sub appendNode {
    my $self = shift;
    my $line = shift;
    my $item = shift;
    if (not defined @{$self->{line_items}}[$line]) {
        $item->{index_in_line} = 0;
    } else {
        $item->{index_in_line} = scalar @{$self->{line_items}[$line]};
    }

    $item->{virtual_index_in_line} = $item->{index_in_line};
    $item->{belongs_to_line} = $line;

    push       @{$self->{line_items}[$line]}, $item;
    push @{$self->{line_items_types}[$line]}, NODE;
}

#
# Insert a branch
#
sub insertBranchAfterNode {
    my $self = shift;
    my $line = shift;
    my $existing_item = shift;
    my $item_to_insert = shift;

    splice       @{$self->{line_items}[$line]}, $existing_item->{index_in_line} + 1, 0, $item_to_insert;
    splice @{$self->{line_items_types}[$line]}, $existing_item->{index_in_line} + 1, 0, BRANCH;
}

#
# Add a new line
#
sub addLine {
    my $self = shift;
    my $id = $self->{next_line};

    $self->{next_line}++;

    push @{$self->{line_order}}, $id;

    return $id;
}

# insert a line before existing line
sub insertLineBefore {
    my $self = shift;
    my $existing = shift;
    return $self->_insertLine($existing, 0);
}

# insert a line after existing line
sub insertLineAfter {
    my $self = shift;
    my $existing = shift;
    return $self->_insertLine($existing, 1);
}

sub _insertLine {
    my $self = shift;
    my $existing = shift;
    my $after = shift;

    my $new_id = $self->{next_line};
    $self->{next_line}++;

    my @new_order;
    my $inserted = 0;
    foreach my $i (@{$self->{line_order}}) {
        if ($i != $existing) {
            push @new_order, $i;
            next;
        }

        if ($after) {
            push @new_order, $i, $new_id;
        } else {
            push @new_order, $new_id, $i;
        }
        $inserted = 1;
    }

    if ($inserted == 0) {
        print "Could not insert line after '$existing'. Appending to the line order...\n";
        push @new_order, $new_id;
    }

    $self->{line_order} = \@new_order;
    return $new_id;
}

1;

