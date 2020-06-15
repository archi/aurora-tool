#!/usr/bin/perl -w

use strict;
use warnings;

my $ref = shift;
my $new = shift;

die "need a reference plugin.ini as 1st param\n" if not defined $ref;
die "need a plugin.ini to check as 2nd param\n" if not defined $new;
die "expecting exactly two parameters\n" if defined shift;

print "Reference: $ref\n";
print "To check: $new\n";

sub load_ini {
    my $ini = shift;
    my %data;

    open my $fh, "<$ini" or die "Could not open '$ini' for reading: $!\n";
    die "Expecting opening '{'!\n" if not <$fh> =~ m/^{\s*$/;

    my $key = undef;
    my @arr;
    while (my $line = <$fh>) {
        if ($line =~ s/^"([^"]+)"://) {
            $key = $1;
        }

        if ($line =~ s/^(\d+)//) {
            $data{$key} = $1;
        } elsif ($line =~ s/^\[//) {
            # TODO parse array (multiple lines!)
            die "ARRAY\n";
        }

        last unless $line =~ m/^,\s*$/;
    }
    
    die "Expecting closing '}'!\n" if not <$fh> =~ m/^}\s*$/;
    close $fh;
}

load_ini($ref);
load_ini($new);

# TODO compare the output
