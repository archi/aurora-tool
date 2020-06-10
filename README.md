# About Aurora-Tool

This is my take at a tool to automatically generate Aurora Plugins from SigmaStudio Exports.
There is still a lot to do, but feel free to try it (just be careful).

# Status

## Working right now:

1. Generate plugin.ini for 8channel & 4FIR (XO not yet supported -> no HomeCinema71)
1. Assemble the dsp.fw
1. Basic, graphical user interface for the tool
1. Build stand-alone Windows & Linux executables
1. All necessary files are parsed (feel free to open Issues if parsing your input file fails)

## Not yet supported:

1. XO
1. HTML page generation

# Roadmap:

v0.2:

1. Parse the XML File and create necessary internal datastructures [Done]
1. Unified error handling, to allow reporting error to GUI users without a huge pain (currently, error messages only really end up on the console - which will be a problem if users with no console experience hit bugs)

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
