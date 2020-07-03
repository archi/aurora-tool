#!/usr/bin/perl -w

use strict;
use warnings;

my $ref = shift;
my $new = shift;

die "need a reference plugin.ini as 1st param\n" if not defined $ref;
die "need a plugin.ini to check as 2nd param\n" if not defined $new;
die "expecting exactly two parameters\n" if defined shift;

sub load_ini {
    my $ini = shift;
    my %data;

    open my $fh, "<$ini" or die "Could not open '$ini' for reading: $!\n";
    die "Expecting opening '{'!\n" if not <$fh> =~ m/^{\s*$/;

    my $key = undef;
    my $line_c = 0;
    while (my $line = <$fh>) {
        $line_c++;
        
        # skip comments and empty lines
        next if ($line =~ m/^\s*#/);
        next if ($line =~ m/^\s*$/);

        # parse the key
        if ($line =~ s/^"([^"]+)"://) {
            $key = $1;
        }

        # parse the value
        if ($line =~ s/^(\d+)//) {
            #simple: "key": 1234
            $data{$key} = $1;
        } elsif ($line =~ s/^\[//) {
            my @arr;
            my $arr_line = $line_c;
            # parse array (multiple lines!)
            # "key": [123, 456, 789]
            while (not $line =~ s/^\]//) {
                while ($line =~ s/\s*([0-9]+)(,)?\s*//) {
                    push @arr, $1;
                }

                # end of line?
                if ($line eq "") {
                    $line = <$fh>;
                    $line_c++;

                    # need to skip comments again...
                    while (defined $line and $line =~ m/^\s*#/) {
                        $line = <$fh>;
                        $line_c++;
                    }

                    die "Unexpected end of file while parsing array starting in line $arr_line!" if not defined $line;
                }
            }

            # store the array
            $data{$key} = \@arr;
        }

        last unless $line =~ m/^,\s*$/;
    }
    
    die "Expecting closing '}'!\n" if not <$fh> =~ m/^}\s*$/;
    close $fh;

    return \%data;
}

# parse the two inputs
print "Reference: $ref\n";
my $dref = load_ini($ref);
print "To check: $new\n";
my $dnew = load_ini($new);

my $error_c = 0;

# now check that everything from the reference is also in the script output
foreach my $key (keys %{$dref}) {
    if (not defined $dnew->{$key}) {
        print "Error: Reference has key '$key', but script output not!\n";
        $error_c++;
        next;
    }

    if (ref $dnew->{$key} ne ref $dref->{$key}) {
        print "Error: Type missmatch for '$key'!\n";
        $error_c++;
        next;
    }

    if (ref $dnew->{$key} eq "ARRAY") {
        if (scalar @{$dnew->{$key}} != scalar @{$dref->{$key}}) {
            print "Error: Array length missmatch for '$key'!\n";
            $error_c++;
            next;
        }

        my $i = 0;
        my @bad;
        while ($i < scalar @{$dnew->{$key}}) {
            if (@{$dnew->{$key}}[$i] ne @{$dref->{$key}}[$i]) {
                push @bad, $i;
            }
            $i++;
        }
        
        if (scalar @bad > 0) {
            print "Error: Array '$key', content missmatch at indices ", join(", ", @bad), "\n";
            $error_c++;
            if (scalar @bad <= 4) {
                foreach my $idx (@bad) {
                    print "    [$idx] ref=", @{$dref->{$key}}[$idx], " != output=", @{$dnew->{$key}}[$idx], "\n";
                }
            } else {
                print "    More than four errors, not printing them...\n";
            }
        }

        
        next;
    }

    if ($dnew->{$key} ne $dref->{$key}) {
        print "Error: Reference for '$key' is '", $dref->{$key}, "', but script produced '", $dnew->{$key}, "'\n";
        $error_c++;
    }
}

# and the other way around: make sure the script output doesn't contain data that the reference doesn't have
foreach my $key (keys %{$dnew}) {
    next if defined $dref->{$key};
    print "Error: Script produced key '$key', which is not present in the reference!\n";
    $error_c++;
}

print "Errors: $error_c\n";
if ($error_c > 0) {
    exit 1;
}
