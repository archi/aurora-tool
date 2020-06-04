#!/usr/bin/perl -w
use strict;
use warnings;

use Cwd;
my $lib_path;
BEGIN {
    my $bin = $0;
    $bin = getcwd . "/$bin" if $bin =~ m@^\./@;
    $bin =~ s@[^/\\]*\.pl$@@;
    $lib_path = $bin . "src/lib";
}
use lib $lib_path;
use Driver;

my $base = "aurora-tool";
my $exe;
my @zip;
my @pp;
my $sep;

my $version = Driver::version();
print "Version: $version\n";
my $zip_file="$base-$version";

if ($^O eq "MSWin32") {
	$exe = "$base.exe";
	$zip_file .= "-win64.zip";
	$sep = "\\";
	$ENV{PATH} = "c:\\strawberry\\perl\\bin;" . $ENV{PATH};
	push @zip, "c:\\Program Files\\7-Zip\\7z.exe", "a", "-bd", "-r", $zip_file, $exe;
	push @pp, "c:\\strawberry\\perl\\site\\bin\\pp.bat";
} else {
	$exe = $base;
	$zip_file .= "-linux64.xz";
	$sep = "/";
	push @zip, "cJf", $zip_file, $exe;
	push @pp, "pp";
}

for my $f ($exe, $zip_file) {
	if (-f $f) {
		print "Removing old '$f'\n";
		unlink($f);
	} elsif (-d $f or -e $f) {
		print "'$f' already exists, but is not a file?!\n";
		exit 1;
	}
}

# build exe:
push @pp,
	"-o", $exe,
	"src${sep}gui.pl",
	"--lib", "src${sep}lib",
	"-M", "Driver",
	"-M", "Tk::Bitmap",
	"-g",
	"-z", "6";

print "Packaging '$exe'...\n";
system(@pp) == 0 or die "Error running pp: $?\n";
die "Could not find '$exe' after building with pp!?\n" if not -f $exe;

# create zip
print "Creating zip...\n";
system(@zip) == 0 or die "Error running 7z: $?\n";
die "Could not find '$zip_file' after zipping!?\n" if not -f $zip_file;

print "\n\nDone building $base version $version :)\n";
