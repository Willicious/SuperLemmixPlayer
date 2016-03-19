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

NOTE: LemResourceBuilder was last modified in V1.42n. If you had to recompile
      it, you'll need to do so again!