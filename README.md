This is my take at a tool to automatically generate Aurora Plugins from SigmaStudio Exports.

**Working right now:**

1. Generate plugin.ini for 8channel & 4FIR (XO not yet supported)
1. Assemble the dsp.fw
1. Simple GUI
1. Build stand-alone Windows & Linux executables

**Not supported:**

0. XO
0. HTML page generation

**Roadmap:**

v0.2: XML Hell

1. Parse the XML File and create an internal datastructure
1. Dump the internal data structure in a JSON file (for later use with HTML/JS Interface)

v0.3: XOs

1. Automatically detect XOs, so homecinema71-style plugins can be processed

v0.4: Layouting

1. Write a layout engine that produces a JSON file for later use

v0.5: Basic HTML/JS

1. Should display the generated layout (using dummy widgets)
1. Control plugin-independent settings

v0.6 (and beyond): Controls!

1. Write JS widgets to control the various stuff (PEQ, HP, LP, XO...)

v1.0:

1. Generate plugin with all the important controls
1. Have some tests
1. Write a proper tutorial on how to use the tool
