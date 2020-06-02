This is my take at a tool to automatically generate Aurora Plugins from SigmaStudio Exports.

Working right now:

0. Generate plugin.ini for 8channel & 4FIR (XO not yet supported)
0. Assemble the dsp.fw

Not supported:

0. XO
0. HTML Generation

Next up is parsing the NetList.xml, so I can build a modell of the Plugin.
From that modell, I hope to be able to automatically figure out the XOs for the plugin.ini.

Additionally, I'd like to write a small HTML/JS app that takes the modell and displays the appropriate DSP controls (and/or generate [part] of that app from the script).

This is written in Perl on Linux. But if you're on Windows, I suppose this should run with StrawberryPerl (I'll give it a try, but not today).

Run 'perl convert.pl --help' to see the usage.
