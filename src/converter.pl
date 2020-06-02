#!/usr/bin/env perl

package main;
use strict;
use warnings;

# Find the library path, and allow loading libs from there
use Cwd;
my $lib_path;
BEGIN {
    my $bin = $0;
    $bin = getcwd . "/$bin" if $bin =~ m@^\./@;
    $bin =~ s@[^/\\]*\.pl$@@;
    $lib_path = $bin . "lib";
}
use lib $lib_path;

# Windows vs Linux dir separator (mostly for printing)
our $sep = "/";

# Additional global modules
use Getopt::Std;
use Getopt::Long;

# Additional local modules
use ParseParams;
use WritePluginIni;
use Assembler;

# Get & check parameters
my $input_dir = undef;
my $output_dir = undef;
my $help = 0;
my $project_name = undef;
our $verbose = 0;
GetOptions (
    'in=s' => \$input_dir,
    'out=s' => \$output_dir,
    'project=s' => \$project_name,
    'v|verbose' => \$verbose,
    'h|help' => \$help,
);

# help takes precedence
if ($help) {
    print "aurora plugin converter\n",
          "\n",
          "Usage: $0 --in [sigma_studio_export_dir]\n",
          "\n",
          "  --in       * Directory containing the SigmaStudio export files\n",
          "  --project    Name of the project (e.g. 8channels)\n",
          "  --out      * Name of the directory in which to put the result files\n",
          "\n";
    exit 0;
}

# ensure we have a trailing /
$input_dir =~ s@[/\\]*$@@ if defined $input_dir;
$input_dir .= $sep if defined $input_dir;
$output_dir =~ s@[/\\]*$@@ if defined $output_dir;
$output_dir .= $sep if defined $output_dir;

#
# Check the input dir (output dir is checked after reading, so it can be omitted for debugging)
#
my $bad = 0;
if (not defined $input_dir) {
    $bad++;
    print STDERR "Missing input directory (pass via --in)!\n";
} elsif (not -d $input_dir) {
    $bad++;
    print STDERR "Input directory '$input_dir' does not exist\n";
} elsif (not defined $project_name) {
    # Find the project name, if not defined
    my $multi = 0;
    while (my $file = <$input_dir*.params>) {
        $file =~ m@([^/\\]*)\.params$@;
        $file = $1;
        if (defined $project_name) {
            print STDERR "Input directory contains multiple .param-files, please use the --project parameter to select one! Found:\n" if $multi == 0;
            print STDERR " - $project_name\n" if $multi == 0;
            print STDERR " - $file\n";
            $multi = 1;
            $bad++;
        }
        $project_name = $file;
    }
    if (not defined $project_name) {
        print STDERR "Input directory does not seem to contain a project (no .params file found)\n";
        $bad++;
    }
}

# Check for the necessary files:
if ($bad == 0) {
    foreach my $req_file ("${project_name}_NetList.xml", "$project_name.params", "NumBytes_IC_1.dat", "TxBuffer_IC_1.dat") {
        next if -f "$input_dir$req_file";
        $bad++;
        print STDERR "Missing file '$input_dir$req_file'\n";
    }
}

# And we're done with parameter checking
if ($bad > 0) {
    print STDERR "Abortung due to errors :(\n";
    exit 1;
}

# Let the user know we've found all we need
print "Selected project '$input_dir$project_name' seems to contain all necessary files :)\n\n";

# Next up: Parse the params and XML file
# The code for these live in the lib/ dir, this is just the driver

my $params = ParseParams::parse($input_dir . $project_name . ".params");
exit 1 if not defined $params;

# TODO parse NetList.xml

# TODO build model and so on

#
# Check the output dir:
#
if (not defined $output_dir) {
    print STDERR "Missing output dir, pass via --out!\n";
    exit 1;
} elsif (not -d $output_dir) {
    print STDERR "Output directory '$output_dir' does not exist!\n";
    exit 1;
}

# assemble dsp.fw
if (Assembler::assemble($input_dir, $output_dir."dsp.fw")) {
    print "Assembled '${output_dir}dsp.fw'\n";
} else {
    exit 1;
}

# Write the plugin.ini
if (WritePluginIni::write($output_dir . "plugin.ini", $params)) {
    print "Wrote '${output_dir}plugin.ini'\n";
} else {
    exit 1;
}


print "\nScript finished without detected errors. Remember to ALWAYS review the output."; 
print "This script (and the result) come with no warranty for correctness. If this kills your speakers or DSP, it is your fault for not properly reviewing the output!\n";

exit 0;
