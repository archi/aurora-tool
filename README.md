# About Aurora-Tool

This is my take at a tool to automatically generate Aurora Plugins from SigmaStudio Exports.
There is still a lot to do, but feel free to try it (just be careful).

# Status

## Working right now:

1. Generate plugin.ini for the three example plugins
1. Assemble the dsp.fw
1. Create a basic dsp.html (based on original interface)
1. Basic, graphical user interface for the tool
1. Build stand-alone Windows & Linux executables

## What can be controlled:

The dsp.html is a copy of the 8channel variant from 2.0.3, with all the 8channel-specific controls removed.
Hence, with the generated plugin you can control:

1. AddOns
2. Master Volume
3. Input Selects (just assumes 8 channels)
4. Presets
5. Update Firmware

## Not yet supported:

1. Actual HTML controls beyond AddOn/Input Select/Master Volume and Presets

# Roadmap:

1. Unified error handling, to allow reporting error to GUI users without a huge pain (currently, error messages only really end up on the console - which will be a problem if users with no console experience hit bugs)
1. Write a layout engine that produces a JSON file for later use
1. Should display the generated layout (using dummy widgets)
1. Control plugin-independent settings with improved controls
1. Write JS widgets to control the various stuff (PEQ, HP, LP, XO...)
1. Generate plugin with all the important controls
1. Have some more tests
1. Write a proper tutorial on how to use the tool...
1. ...or create a short video (using the tool is really simple ;-)
