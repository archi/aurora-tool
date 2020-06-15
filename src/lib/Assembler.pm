package Assembler;

use strict;
use warnings;

sub assemble {
    my $input_dir = shift;
    my $dsp_file = shift;
    my $tx_bytes = read_txbuffer($input_dir . "TxBuffer_IC_1.dat");
    my $num_bytes = read_numbytes($input_dir . "NumBytes_IC_1.dat");
    return write_dsp_fw($dsp_file, $tx_bytes, $num_bytes);
}

sub read_txbuffer {
    my $file = shift;
    open my $IN, "<$file" or die "Could not open TxBuffer file '$file' for reading: $!\n";
    my @bytes;
    while (my $line = <$IN>) {
        while ($line =~ s/^\s*(0x[a-fA-F0-9]{2}),(.*)/$2/) {
            push @bytes, hex($1);
        }
    }
    close $IN;
    return \@bytes;
}

sub read_numbytes {
    my $file = shift;
    open my $IN, "<$file" or die "Could not open NumBytes file '$file' for reading: $!\n";
    my @bytes;
    while (my $line = <$IN>) {
        while ($line =~ s/^\s*([0-9]+),(.*)/$2/) {
            push @bytes, int($1);
        }
    }
    close $IN;
    return \@bytes;
}

sub write_dsp_fw {
    my $file = shift;
    my $tx_bytes = shift;
    my $num_bytes = shift;

    open my $OUT, ">:raw", "$file" or die "Could not open dsp.fw file '$file' for writing: $!\n";

    my $offset = 0;
    my $limit = scalar @{$tx_bytes};
    foreach my $num (@{$num_bytes}) {
        # the num is the section size
        # it's output LBF in 4 bytes, followed by the actual data
        foreach my $s (24, 16, 8, 0) {
            print $OUT sprintf("%c", ($num >> $s) & 0xff);
        }

        while ($num > 0) {
            if ($offset >= $limit) {
                print STDERR "Ran out out of bounds assembling the dsp.fw!";
                close $OUT;
                unlink $file;
                return 0;
            }
            print $OUT sprintf("%c", ($tx_bytes->[$offset]) & 0xff);
            $offset++;
            $num--;
        }
    }
    close $OUT;
    return 1;
}
1;
