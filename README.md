This is my take at a tool to automatically generate Aurora Plugins from SigmaStudio Exports.

Working right now:

0. Generate plugin.ini for 8channel & 4FIR (XO not yet supported)
0. Assemble the dsp.fw

Not supported:

0. XO
0. HTML Generation

Next up is:

0. parsing the NetList.xml, so I can build a model of the Plugin. From that model, I hope to be able to automatically figure out the XOs for the plugin.ini.
0. Put the Driver code in a module
0. Add a small GUI for non-cli users
0. Build a windows exe without need for a perl installation

Additionally, I'd like to write a small HTML/JS app that takes the modell and displays the appropriate DSP controls (and/or generate [part] of that app from the script).

This is written in Perl on Linux. But if you're on Windows, I suppose this should run with StrawberryPerl (I'll give it a try, but not today).

I plan to have this buildable with some windows-executable builder like PAR/pp (see https://metacpan.org/pod/pp), so I/we can easily distribute it to Windows users who lack the technical background for running this via the command line (also, the... lovely... SigmaStudio doesn't run on Linux, so I'm stuck with Windows as well).
I will try this sooner than later. Worst case I might realize this doesn't work with Perl GUI applications (I've never used that part), in which case the GUI will needs to be done in Qt/C++.

For now, run 'perl convert.pl --help' to see the usage.
