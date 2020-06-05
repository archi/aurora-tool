This is my take at a tool to automatically generate Aurora Plugins from SigmaStudio Exports.

**Working right now:**

0. Generate plugin.ini for 8channel & 4FIR (XO not yet supported)
0. Assemble the dsp.fw
0. Simple GUI
0. Build stand-alone Windows & Linux executables

**Not supported:**

0. XO
0. HTML page generation

**Roadmap:**

v0.2: XML Hell
0. Parse the XML File and create an internal datastructure
0. Dump the internal data structure in a JSON file (for later use with HTML/JS Interface)

v0.3: XOs
0. Automatically detect XOs, so homecinema71-style plugins can be processed

v0.4: Layouting
0. Write a layout engine that produces a JSON file for later use

v0.5: Basic HTML/JS
0. Should display the generated layout (using dummy widgets)
0. Control plugin-independent settings

v0.6 (and beyond): Controls!
0. Write JS widgets to control the various stuff (PEQ, HP, LP, XO...)

v1.0:
0. Generate plugin with all the important controls
0. Have some tests

This is written in Perl on Linux. But if you're on Windows, this should run with StrawberryPerl.
You can also create a Windows executable (this needs perl as well) for distribution.
I will look into automatically building this and uploading it somewhere.

For now, run 'perl convert.pl --help' to see the usage.
