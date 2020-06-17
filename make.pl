#!/usr/bin/perl -w
use strict;
use warnings;

use Cwd;
use File::Path "remove_tree";
use File::Copy;
my $lib_path;
BEGIN {
    my $bin = $0;
    $bin = getcwd . "/$bin" if $bin =~ m@^\./@;
    $bin =~ s@[^/\\]*\.pl$@@;
    $lib_path = $bin . "src/lib";
}
use lib $lib_path;
use Tools;

my $base = "aurora-tool";
my $version = $Tools::version;
print "Version: $version\n";

my $dir = "$base-$version";
my @lib_list;
my $lib_dir;
my $exe;
my @zip;
my @pp;
my $sep;
my $zip_file;
if ($^O eq "MSWin32") {
	$exe = "$base.exe";
	$dir .= "-win64";
	$sep = "\\";
    $lib_dir = "c:\\strawberry\\c\\bin";
    $zip_file = $dir . ".zip";
	$ENV{PATH} = "c:\\strawberry\\perl\\bin" . ";" . $ENV{PATH};
	push @zip, "c:\\Program Files\\7-Zip\\7z.exe", "a", "-bd", "-r", $zip_file, $dir;
	push @pp, "c:\\strawberry\\perl\\site\\bin\\pp.bat";
    
    push @lib_list, 
        "libiconv-2__.dll",
        "liblzma-5__.dll",
        "libxml2-2__.dll",
        "zlib1__.dll";
} else {
	$exe = $base;
	$dir .= "-linux64";
    $zip_file = $dir . ".xz";
	$sep = "/";
	push @zip, "tar", "crJf", $zip_file, $dir;
	push @pp, "pp";
}

remove_tree($dir) if -e $dir;
die "Could not remove dir '$dir'!\n" if -e $dir;
mkdir ($dir) or die "Could not create '$dir': $!\n";

if (-e $zip_file) {
	print "Removing old '$zip_file'\n";
	unlink($zip_file) or die "Could not unlink '$zip_file': $!\n";
}

if (defined $lib_dir) {
    foreach my $lib (@lib_list) {
        my $f = $lib_dir . $sep . $lib;
        die "Missing lib: '$f'\n" if not -e $f;
        copy($f, $dir . $sep . $lib) or die "Could not copy lib '$lib' to package: $!\n";
    }
}

# build exe:
push @pp,
	"-o", $dir . $sep . $exe,
	"src${sep}gui.pl",
	"--lib", "src${sep}lib",
	"-M", "Driver",
	"-M", "Tk::Bitmap",
	"-g",
	"-z", "1";

print "Packaging '$exe'...\n";
system(@pp) == 0 or die "Error running pp: $?\n";
die "Could not find '$exe' after building with pp!?\n" if not -f $dir . $sep . $exe;

# create zip
print "Creating zip...\n";
system(@zip) == 0 or die "Error running 7z: $?\n";
die "Could not find '$zip_file' after zipping!?\n" if not -f $zip_file;

print "\n\nDone building $base version $version :)\n";
