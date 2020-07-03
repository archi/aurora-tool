package Driver;

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

# local modules
use ParseParams;
use WritePluginIni;
use Assembler;
use Tools;
use NetParser;
use NetAlgo;
use CollectedData;

sub logError {
    my $self = shift;
    $self->{errors}++;
    while (my $line = shift) {
        push @{$self->{errorStrings}}, $line;
    }
}

sub hasErrors {
    my $self = shift;
    return $self->{errors} > 0;
}

sub create {
    my $input_dir = shift;
    my $output_dir = shift;
    my $project_name = shift;

    my %self;
    $self{errors} = 0;
    $self{errorStrings} = [];
    bless \%self;

    # check input dir
    if (not defined $input_dir) {
        logError(\%self, "Missing input directory!");
    } else {
        $input_dir =~ s@[/\\]*$@@;
        $input_dir .= $Tools::sep;
        if (not -d $input_dir) {
            logError(\%self, "Input directory does not exist!");
        } else {
            $self{input_dir} = $input_dir;
        }
    }

    # check output dir
    if (not defined $output_dir) {
        logError(\%self, "Missing output directory!");
    } else {
        $output_dir =~ s@[/\\]*$@@;
        $output_dir .= $Tools::sep;
        if (not -d $output_dir) {
            logError(\%self, "Output directory does not exist!");
        } else {
            $self{output_dir} = $output_dir;
        }
    }

    # Do not continue if there are already errors
    if (hasErrors(\%self)) {
        return \%self;
    }

    # determine the project
    if (not defined $project_name) {
        # Find the project name, if not defined
        my $multi = 0;
        while (my $file = <$input_dir*.params>) {
            $file =~ m@([^/\\]*)\.params$@;
            $file = $1;
            if (defined $project_name) {
                logError(\%self, "Input directory contains multiple .param-files, please select which select one to use") if $multi == 0;
                logError(\%self, " - $project_name") if $multi == 0;
                logError(\%self, " - $file");
                $multi = 1;
            }
            $project_name = $file;
        }

        # Again, no project, no point in trying to continue
        if (not defined $project_name) {
            logError(\%self, "Input directory does not seem to contain a SigmaStudio export (no .params file found)");
            return \%self;
        }
    }

    $self{project_name} = $project_name;

    # Check for the necessary files:
    foreach my $req_file ("${project_name}_NetList.xml", "$project_name.params", "NumBytes_IC_1.dat", "TxBuffer_IC_1.dat") {
        next if -f "$input_dir$req_file";
        logError(\%self, "Missing file '$input_dir$req_file'");
    }

    return \%self;
}

sub doEverything {
    my $self = shift;

#    return 0 if $self->hasErrors();
#    return 0 if not $self->parseParams();
#    return 0 if not $self->parseNetList();
#
#    Net::postProcess();
#    Net::detectCrossovers($self->{params});
#
#    return 0 if not $self->buildDspFw();
#    return 0 if not $self->buildPluginIni();
#    return 1;
    my $data = CollectedData::new();

    my $params_file = $self->{input_dir} . $self->{project_name} . ".params";
    if (not ParseParams::parse($params_file, $data)) {
        logError("Could not parse '$params_file'");
        return 0;
    }

    my $xml_file = $self->{input_dir} . $self->{project_name} . "_NetList.xml";
    if (not NetParser::parse($xml_file, $data)) {
        logError("Could not parse XML '$xml_file'");
        return 0;
    }
    
    $data->postProcess();

    my $dsp_file = $self->{output_dir}."dsp.fw";
    if (not Assembler::assemble($self->{input_dir}, $dsp_file)) {
        logError("Coult not assemble '$dsp_file'");
        return 0;
    }

    my $pluginini = $self->{output_dir}."plugin.ini";
    if (not WritePluginIni::write($pluginini, $data->{result_for_pluginini})) {
        logError("Could not generate '$pluginini'");
        return 0;
    }

    return 1;
}

1;
