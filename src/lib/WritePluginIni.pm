package WritePluginIni;

use strict;
use warnings;

sub write {
    my $out_file = shift;
    my $result = shift;

    # Generate the "nhp" and so on...
    # nxo has to be manually generated from xolp/xohp (once those are added automatically)
    my $nxo;
    foreach my $key ("hp", "lshelv", "peq", "hshelv", "lp", "phase", "dly", "gain", "fir", "xolp", "xohp") {
        next if defined $result->{"n$key"};
        $result->{"n$key"} = 0;
        next if not defined $result->{$key};
        if ($key =~ m/^(xo)?(lp|hp)$/) {
            my $x = scalar @{$result->{$key}} / 4;
            $result->{"n$key"} = $x;
        } else {
            $result->{"n$key"} = scalar @{$result->{$key}};
        }
    }

    if (defined $result->{nxolp} or defined $result->{nxohp}) {
        die "Missmatch between number of XOLP (".
        (defined $result->{nxolp} ? $result->{nxolp} : 0)
        .") and number of XOHP (".
        (defined $result->{nxohp} ? $result->{nxohp} : 0)
        .")!" if not defined $result->{nxolp} or not defined $result->{nxohp} or $result->{nxolp} != $result->{nxohp};

        $result->{nxo} = $result->{nxolp};
        $result->{nxolp} = undef;
        $result->{nxohp} = undef;
    }

    open my $OUT, ">$out_file" or die "Could not open '$out_file' for writing: $!\n";

    # my $!!!@ lovely windows doesn't have JSON.pm, so let's be rude...

    # make the output more beautiful by printing one channel per line, unless it's just one datum per channel
    my $nchn = $result->{nchn};

    print $OUT "{\n";
    my $bad = 0;
    my $first = 1;
    foreach my $k (sort keys %{$result}) {
        next if not defined $result->{$k};
        print $OUT ",\n" if not $first;
        $first = 0;

        print $OUT "\"$k\":";
        my $type = ref $result->{$k};
        if ($type eq "") {
            print $OUT $result->{$k};
        } elsif ($type eq "ARRAY") {
            my $cnt = scalar @{$result->{$k}};
            my $insert_line_break = 4096;
            my $prefix = "";
            if ($cnt > $nchn and $cnt % $nchn == 0) {
                $insert_line_break = $cnt / $nchn;
                $prefix = sprintf("%".(length($k)+4)."s", "");
            }
            print $OUT "[";
            my $afirst = 1;
            foreach my $a (@{$result->{$k}}) {
                if ($insert_line_break == 0) {
                    print $OUT ",\n$prefix";
                    $insert_line_break = $cnt / $nchn;
                } else {
                    print $OUT ", " if not $afirst;
                }
                $insert_line_break--;
                $afirst = 0;
                if (not defined $a) {
                    $bad++;
                    print $OUT "undef";
                    print "Undefined array member for '$k'!\n";
                } else {
                    print $OUT $a;
                }
            }
            print $OUT "]";
        } else {
            print "Error: Don't know how to print '$k'!\n";
            $bad++;
        }
    }
    print $OUT "\n}";

    close $OUT;

    return 0 if $bad > 0;
    return 1;
}

1;
