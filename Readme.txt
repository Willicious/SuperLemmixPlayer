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
  backwards-compatible: Has a lot of workarounds to enable continued use of old
                        formats, until the new ones are ready.
  master: Makes use exclusively of new formats, except in cases where new formats
          for a type of data have not yet been implemented.
          
Old versions up to V1.43n-F / V1.43n-F-alt can be found under the "ancient" folder
of branches. Versions older than the latest core version (the second set of digits
in the version number) can be found under the "old" folder of branches. The branches
for versions that match the current core version are found under the "current" folder
of branches.

NOTE: LemResourceBuilder was last modified in 31E8175. If you had to recompile
      it, you'll need to do so again!