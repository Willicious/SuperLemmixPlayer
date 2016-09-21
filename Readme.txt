NeoLemmix

by namida
Based on Lemmix by EricLang

Compiling NeoLemmix has only been tested under Delphi 7. You will need to
install the Graphics32 library into Delphi (or extract it to a subfolder
here, then add that subfolder to the Search path).

Graphics32 can be downloaded here:
  https://sourceforge.net/projects/graphics32/files/latest/download?source=files
Installation instructions:
  http://graphics32.org/documentation/Docs/Installation.htm

Note that you need to compile the required resource files first! To do this
the easy way - just run LemResourceBuilder and click each button once. If
this gives an error, you may need to modify LemResourceBuilder's source and
replace the path to brcc32.exe with the correct path for your system. (I
believe using GoRC.exe instead works, too.)

From commit 21D0B58 onwards; the following use is made for branches:
  backwards-compatible: Releases based on (mostly) old formats and NXP files.
  new-formats: Releases that are working towards solely using the new formats.
  master: Changes that need to be integrated into both of the other two branches.

NOTE: LemResourceBuilder was last modified in 31E8175. If you had to recompile
      it, you'll need to do so again!