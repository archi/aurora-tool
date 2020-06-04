This is my take at a tool to automatically generate Aurora Plugins from SigmaStudio Exports.

Working right now:

0. Generate plugin.ini for 8channel & 4FIR (XO not yet supported)
0. Assemble the dsp.fw
0. Simple GUI (needs perl-tk)

Not supported:

0. XO
0. HTML Generation

Next up is:

0. parsing the NetList.xml, so I can build a model of the Plugin. From that model, I hope to be able to automatically figure out the XOs for the plugin.ini.
0. use a nicer file selector (the Tk-selector is a visual pain)


Additionally, I'd like to write a small HTML/JS app that takes the modell and displays the appropriate DSP controls (and/or generate [part] of that app from the script).

This is written in Perl on Linux. But if you're on Windows, this should run with StrawberryPerl.
You can also create a Windows executable (this needs perl as well) for distribution.
I will look into automatically building this and uploading it somewhere.

For now, run 'perl convert.pl --help' to see the usage.
