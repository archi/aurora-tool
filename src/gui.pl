#!/usr/bin/perl -w

package main;

use strict;
use warnings;
use Tk;
use Tk::FileSelect;

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

my $version = Driver::version();

# store user select dirs here
my $params_file = undef;
my $output_dir = undef;

# Create Main Window
my $main = MainWindow->new(-title => "aurora-tool GUI v$version");
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
        -background => 'grey',
        -state => 'disable',
    )->pack(
        -side => 'right',
        -padx => 6,
    );
        
    $entry->configure(-foreground => 'black');

    push @gui_elements, $button;
}

sub errorBox {
    my $msg = shift;
    $main->messageBox(
        -title => 'Error',
        -type => 'ok',
        -message => $msg);
    disableAll(0);
}

sub build {
    disableAll(1);
    glob $output_dir;
    glob $params_file;
    glob $main;

    if (not defined $output_dir or not defined $params_file) {
        errorBox('Please specify all necessary parameters!');
        return;
    }

    my $input_dir = $params_file;
    $input_dir =~ s@([^/\\]*)\.params$@@;
    my $project_name = $1;

    my $driver = Driver::create($input_dir, $output_dir, $project_name);
    if ($driver->hasErrors()) {
        errorBox(join("\n", @{$driver->{errorStrings}}));
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
createInput($main, 'SigmaStudio export to use:',
    sub {
        my $select = $main->FileSelect();
        $select->configure(
            -defaultextension => 'params',
            -filelabel => 'Please select the .params-file from the SigmaStudio export.',
        );
        $params_file = $select->Show();
        return $params_file;
    });

createInput($main, 'Where to save the plugin:',
    sub {
        $output_dir = $main->chooseDirectory();
        return $output_dir;
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
        "This is the aurora-tool GUI v$version, by archi.",
        'Source and Issue tracker: https://github.com/archi/aurora-tool',
        'I am not affiliated with the FreeDSP project.'));

mkLabel('red', join("\n",
        'This software comes without any warranty, make sure to verify its output!',
        'I am not responsible for any damage caused by this software or its output!',
    ));

print "This is aurora-tool GUI v$version\n";
MainLoop();
