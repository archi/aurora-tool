package ParseParams;

use strict;
use warnings;
use ParamNode;

# This contains all the patterns + functions to parse a single type of "Cell Name"
# It's filed later in this file (after all the subs)
my %name_to_handler;

sub parse {
    my $in_file = shift;

    my $collectedData = shift;

    # the aim is to fill an output result hash with all the necessary data
    # my prototype plugininigen.pl would convert that to JSON, but the actual script will do other things with that
    # i use 'result' to avoid confusion with dsp 'output'
    my %result_for_pluginini;

    # Open the file, and parse it
    open my $IN, "<$in_file" or die "Could not open '$in_file' for reading: $!\n";
    my %data;
    my @name_to_handler_ptrns = keys %name_to_handler;
    while (my $line = <$IN>) {
        next unless $line =~ m/^(Cell Name|Parameter Name|Parameter Address|Parameter Value)\s+=\s*(.*)$/;
        my $param = $2;
        my $key = $1;
        $key =~ s/ /_/g;
        $key = lc $key;
        $key =~ s/^parameter_//;
        $param =~ s/\s*$//g;
        $data{$key} = $key eq "address" ? int($param) : $param;
        if ($key eq "cell_name") {
            foreach my $ptrn (@name_to_handler_ptrns) {
                if ($param =~ m/^$ptrn$/) {
                    $data{_handler} = $name_to_handler{$ptrn};
                    $data{1} = $1 if defined $1;
                    $data{2} = $2 if defined $2;
                    $data{3} = $3 if defined $3;
                    $data{4} = $4 if defined $4;
                    $data{5} = $5 if defined $5;
                    $data{6} = $6 if defined $6;
                    # add more if necessary
                }
            }
        } elsif ($key eq "value") {
            my $type = undef;
            $type = $data{_handler}->(\%data, \%result_for_pluginini) if defined $data{_handler};
            if (defined $type) {
                my $node = ParamNode::create(\%data, $type);

                if (not $collectedData->addParamNode($node)) {
                    if ($type eq "peq") {
                        my $parentNode = $collectedData->findParamNode($node->{name});
                        # Handle PEQ: Multiple addresses (one per band)
                        push @{$parentNode->{additional_bands}}, $data{address};
                    } else {
                        # everything that's not a PEQ should have only a single address/node
                        # TODO return 0
                        die ("Error: Duplicate node '".$node->{name}."' in .params-file!\n");
                    }
                }
            }
            %data = ();
        }
    }
    close $IN;

    # Not needed in the future, but rely on it for now
    $collectedData->{result_for_pluginini} = \%result_for_pluginini;

    return 1;
}

# now we want to translate things like 
# > Cell Name         = InputSelect_8.Nx1-1_UAC
# > Parameter Name    = monomuxSigma300ns44index
# > Parameter Address = 20413
# > Parameter Value   = 7
# > Parameter Data :
# > 0x00, 0x00, 0x00, 0x07, 
# into the correct format for plugin.ini
# The aim is to do as much with pattern matching instead of hardcoding detectors.
# so we build this map of pattern (on cell name) -> handler:
# I'll explain the structure on one example.

# Here we parse the InputSelect's
# So the pattern should grab us the size ($1) and the name ($2)
# Which input this is (e.g. 7) we get from the "Parameter Value"
$name_to_handler{"InputSelect_(.)\.Nx1-1(.*)"} = sub {
    # this is a hash references with the collected data:
    # 1 => regex match 1 (This inputSelect's size, e.g. 8)
    # 2 => regex match 2 (This InputSelect's source, e.g. "_UAC")
    # ... (this goes up to 6, but we're only using two here)
    # cell_name => Cell Name
    # name => Parameter Name
    # address => Parameter Address
    # value => Parameter Value
    my $data = shift;
    
    # Input could be any of "_Analog", "_UAC", "_ESP32" (ignored), "_Exp", "_SPDIF" and "" (= port)
    # Let's normalize that to the plugin.ini format:
    my $input_type = lc $data->{2};
    # "" is "port"
    $input_type = "port" if $input_type =~ m/^\s*$/;
    
    $input_type =~ s/^_//;
    
    # esp32 is ignored for now
    return undef if $input_type eq "esp32";

    # get the result parameter to fill it
    my $result = shift;
        
    # now we have analog, uac, exp, spdif and port -- these are also the names used in the plugin.ini
    # check if the corresponding array already exists in the output hash, if not, create it:
    $result->{$input_type} = [] if not defined $result->{$input_type};
    
    # now put the address at the correct location in the array
    # and remember, the channel in InputSelect_$$CHANNEL$$ counts from 1 to 8, the array from 0 to 7
    my $channel = int($data->{1});
    $result->{$input_type}[$channel - 1] = $data->{address};
    
    # last but not least, the input select tells us how many channels we have
    # make sure this is consistent with whatever we know (or use it as initial knowledge)
    if (not defined $result->{nchn} or $result->{nchn} < $channel) {
        $result->{nchn} = $channel;
    }

    # Return the type, for adding this to the ParamNode data
    return "input_$input_type";
};

$name_to_handler{"MasterVolume"} = sub {
    my $data = shift;
    # we have Parameter Name HWGainADAU145XAlg9target and HWGainADAU145XAlg9slew_mode
    # 8channel uses the '...target' variant, so we do the same here:
    return if not $data->{name} =~ m/^HWGainADAU.*target$/;
    my $result = shift;
    if (not defined ($result->{master})) {
        $result->{master} = $data->{address};
        return "mastervolume";
    } elsif ($result->{master} ne $data->{address}) {
        die "Can not detect MasterVolume address, is it " . $result->{master} . " or " . $data->{address} . "?\n";
    }
    return undef;
};

$name_to_handler{"BypassVolPoti"} = sub {
    my $data = shift;
    my $result = shift;
    if (not defined ($result->{vpot})) {
        $result->{vpot} = $data->{address};
        return "bypassvolpoti";
    } elsif ($result->{vpot} ne $data->{address}) {
        die "Can not detect BypassVolPoti address, is it " . $result->{vpot} . " or " . $data->{vpot} . "?\n";
    }
    return undef;
};

# high pass and low pass
$name_to_handler{"(L|H)P([0-9]+)_([0-9]+)"} = sub {
    my $data = shift;
    my $result = shift;
    # the high passes have 5 parameter addresses each
    # we're interested in the lowest one, with the name ending in B2_1
    # (i'm not 100% sure on that, so we'll check the address to be safe)
    
    my $pass = ($data->{1} eq "L") ? "lp" : "hp";
    $result->{$pass} = [] if (not defined $result->{$pass});
    
    # we compute the array index from HPx_y
    # e.g.:
    #  0: HP1_1
    #  1: HP1_2
    #  2: HP1_3
    #  3: HP1_4
    #  4: HP2_1
    my $idx = 4 * (int($data->{2}) - 1) + int($data->{3}) - 1;
    
    # name ending in B2_1 => add the value
    if ($data->{name} =~ m/B2_1$/) {
        $result->{$pass}[$idx] = $data->{address};
        return $pass;
    } elsif (defined $result->{$pass}[$idx]) {
        die "high/low pass address assumption failed!" if $result->{$pass}[$idx] > $data->{address};
    }
    return undef;
};

# virtually the same as above, but different index computation
$name_to_handler{"(Low Shelv|High Shelv|Phase) ([0-9]+)"} = sub {
    my $data = shift;
    my $result = shift;
    # the shelfs also have 5 parameter addresses each
    # we're interested in the lowest one, with the name ending in B2_1
    # (i'm not 100% sure on that, so we'll check the address to be safe)
    
    my $arr = undef;
    if (($data->{1} eq "Low Shelv")) {
        $arr = "lshelv";
    } elsif (($data->{1} eq "High Shelv")) {
        $arr = "hshelv";
    } elsif (($data->{1} eq "Phase")) {
        $arr = "phase";
    }
    
    die "Internal error" if not defined $arr;
    $result->{$arr} = [] if (not defined $result->{$arr});
    
    # index for "Low Shelv x" is probably (x - 1)
    my $idx = (int($data->{2}) - 1);
    
    # name ending in B2_1 => add the value
    if ($data->{name} =~ m/B2_1$/) {
        $result->{$arr}[$idx] = $data->{address};
        return $arr;
    } elsif (defined $result->{$arr}[$idx]) {
        die "high/low shelv address assumption failed!" if $result->{$arr}[$idx] > $data->{address};
    }
    return undef;
};

# delay and gain are again pretty similar
$name_to_handler{"(Delay|Gain|FIR) ?([0-9]+)"} = sub {
    my $data = shift;
    my $result = shift;
    
    # delay's name is 'DelaySigma300Alg1delay', and Gain 'HWGainADAU145XAlg2target'
    # filter out 'HWGainADAU145XAlg2slew_mode'
    return if $data->{name} =~ m/slew_mode$/;
    
    my $arr = undef;
    if (($data->{1} eq "Delay")) {
        $arr = "dly";
    } elsif (($data->{1} eq "Gain")) {
        $arr = "gain";
    } elsif (($data->{1} eq "FIR")) {
        $arr = "fir";
    }
    
    die "Internal error" if not defined $arr;
    $result->{$arr} = [] if (not defined $result->{$arr});
    
    my $idx = (int($data->{2}) - 1);
    $result->{$arr}[$idx] = $data->{address};
    return $arr;
};

# parametric eq are similar, but a little bit too different again: I want to handle different # of PEQ per channel, so more magic is necessary
$name_to_handler{"Param EQ ([0-9]+)"} = sub {
    my $data = shift;
    my $result = shift;
    # each PEQ consists of multiple bands.
    # eq. "Param EQ 1" has
    #  - General2ndOrderDPSigma300Alg6B2_1 [that's the address we want]
    #  - General2ndOrderDPSigma300Alg6B1_1
    #  - General2ndOrderDPSigma300Alg6B0_1
    #  - General2ndOrderDPSigma300Alg6A2_1
    #  - General2ndOrderDPSigma300Alg6A1_1
    # but now comes the next band, still part of "Param EQ 1":
    #  - General2ndOrderDPSigma300Alg6B2_2
    #  - General2ndOrderDPSigma300Alg6B1_2
    #  - General2ndOrderDPSigma300Alg6B0_2
    #  - General2ndOrderDPSigma300Alg6A2_2
    #  - General2ndOrderDPSigma300Alg6A1_2
    # and so on for all the other bands
    # NOW, careful: I'm doing this because I want to have 15 bands per PEQ in the first two channels, and for the test
    #  i do not care. so we just push them into the array and hope the order in the params-file is what we want in the output array :(
    
    return undef if (not $data->{name} =~ m/^.*300Alg[0-9]+B2_([0-9])+$/);
    
    $result->{peq} = [] if (not defined $result->{peq});
    push @{$result->{peq}}, $data->{address};
    return "peq";
};

1;
