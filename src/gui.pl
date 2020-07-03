#!/usr/bin/perl -w

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

package main;

use strict;
use warnings;
use Tk;
use Tk::FileSelect;
use File::Path 'make_path';

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

use Driver;
use Tools;

# store user select dirs here (this will be assigned the Tk input box, not the actual variable!)
my $params_file = undef;
my $output_dir = undef;

# Create Main Window
my $main = MainWindow->new(-title => "aurora-tool GUI v$Tools::version");
$main->geometry('+400+400');
$main->bind('<Escape>' => sub { $main->destroy(); exit 0; });

# these GUI elements are to be disabled when building
my @gui_elements;

sub disableAll {
    my $disable = shift;
    glob @gui_elements;
    foreach my $e (@gui_elements) {
        $e->configure(-state => $disable ? 'disabled' : 'normal');
    }
}

# create an input line attached to $main, with label $name
# when clicking the [...] button, use callback $cb to determine the action
#  (the callback's return value will be put into the input box)
sub createInput {
    my $main = shift;
    my $name = shift;
    my $cb = shift;
    my $frame = $main->Frame(
        -borderwidth => 3,
        -background => 'white')->pack(
        -side => 'top',
        -fill => 'x'
    );
    my $label = $frame->Label(
        -text => $name,
        -background => 'white',
        -foreground => 'black')->pack(
        -side => 'left',
    );
    
    my $entry = undef;
    my $button = $frame->Button(
        -text => '...',
        -command => sub {
            return if not defined $cb;
            disableAll(1);
            my $txt = $cb->();
            $txt = "" if not defined $txt;
            $entry->configure(-text => $txt);
            disableAll(0);
        }
    )->pack(
        -side => 'right',
        -padx => 6);
    
    $entry = $frame->Entry(
        -width => 40,
    )->pack(
        -side => 'right',
        -padx => 6,
    );
        
    $entry->configure(-foreground => 'black');

    push @gui_elements, $button, $entry;
    return $entry;
}

sub errorBox {
    my $msg = shift;
    $main->messageBox(
        -title => 'Error',
        -icon => 'error',
        -type => 'Ok',
        -message => $msg);
    disableAll(0);
}

sub build {
    disableAll(1);
    glob $output_dir;
    glob $params_file;
    glob $main;
    
    my $output_dir_val = $output_dir->cget('-text');
    my $params_file_val = $params_file->cget('-text');
    
    if (defined $params_file_val) {
        $params_file_val = undef if $params_file_val =~ m/^\s*$/;
    }
    
    if (defined $output_dir_val) {
        $output_dir_val = undef if $output_dir_val =~ m/^\s*$/;
    }

    if (not defined $output_dir_val or not defined $params_file_val) {
        my $msg = 'Please specify all necessary parameters:';
        $msg .= "\nMissing the SigmaStudio Export." if not defined $params_file_val;
        $msg .= "\nMissing output directory" if not defined $output_dir_val;
        errorBox($msg);
        return;
    }

    my $input_dir = $params_file_val;
    $input_dir =~ s@([^/\\]*)\.params$@@;
    my $project_name = $1;
    
    if (not -d $output_dir_val) {
        my $answer = $main->messageBox(
            -title => 'Warning',
            -icon => 'question',
            -type => 'OkCancel',
            -message => 'The output directory does not exist, should it be created?',
        );
        
        if (lc $answer eq 'cancel') {
            disableAll(0);
            return;
        }
        
        my $error = undef;
        make_path($output_dir_val, {error => \$error});
        if ($error and @$error) {
            errorBox("Error creating output directory:\n" . join("\n", @$error));
            return;
        }
    }

    my $driver = Driver::create($input_dir, $output_dir_val, $project_name);
    if ($driver->hasErrors()) {
        errorBox("Error building:\n" . join("\n", @{$driver->{errorStrings}}));
        return;
    }

    if (not $driver->doEverything()) {
        errorBox(join("\n", @{$driver->{errorStrings}}));
        return;
    }

    $main->messageBox(
        -title => 'Success',
        -type => 'ok',
        -message => "Plugin has been built.\n\nRemember to review the result before uploading it to your FreeDSP Aurora!");
    disableAll(0);
}

# Add the selectors
$params_file = createInput($main, 'SigmaStudio export to use:',
    sub {
        my $types = [
            ['SigmaStudio Parameters File', '.params'],
            ['All Files',                    '*']
        ];
        my $file = $main->getOpenFile(
            -filetypes => $types,
            -title => "Select SigmaStudio export"
        );
        $file = undef if defined $file and $file eq "";
        return $file;
    });

$output_dir = createInput($main, 'Where to save the plugin:',
    sub {
        my $dir = $main->chooseDirectory();
        return $dir;
    });

# add buttons
my $buttonFrame = $main->Frame(
    -borderwidth => 3,
    -background => 'white')->pack(
    -side => 'top',
    -fill => 'x');

my $buildButton = $buttonFrame->Button(
    -text => 'Build',
    -command => \&build,
    )->pack(
    -side => 'right',
    -pady => 6);
push @gui_elements, $buildButton;

my $quitButton = $buttonFrame->Button(
    -text => 'Quit',
    -command => sub { $main->destroy(); exit 0; },
    )->pack(
    -side => 'left',
    -pady => 6);
push @gui_elements, $quitButton;


sub mkLabel {
    my $bg = shift;
    my $text = shift;
    my $frame = $main->Frame(
    -borderwidth => 3,
    -background => $bg)->pack(
    -side => 'top',
    -fill => 'x');

    my $label = $frame->Label(
        -text => $text,
        -background => $bg,
        -foreground => 'black',
        -justify => 'left')->pack(
        -side => 'left',
    );
}

mkLabel('white', join("\n",
        "This is the aurora-tool GUI v$Tools::version",
        "Source and Issue tracker: $Tools::url",
        $Tools::copyright, 
        'I am not affiliated with the FreeDSP project.'));

mkLabel('red', join("\n",
        'This software comes without any warranty, make sure to verify its output!',
        'I am not responsible for any damage caused by this software or its output!',
    ));

print "This is aurora-tool GUI v$Tools::version\n";
MainLoop();
