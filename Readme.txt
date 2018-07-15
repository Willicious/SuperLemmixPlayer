NeoLemmix

by Namida Verasche and Stephan Neupert,
based on Lemmix by Eric Langedijk,
inspired by Lemmings by DMA.

The main branch is "new-master", which gives users access to most data files 
allowing them to easily mod their copy of the game.
This branch has to be compiled on Delphi XE6. 

The "master" branch contains preserves the older versions that stored everything
in binary files (though the latest commits contain partial progress towards the
new file system).
Starting from commit 60368de the code compiles only on Delphi XE6.
From commit 7b338fa to 60368de the code compiles both on Delphi XE6 and Delphi 7.
Older commits only compile on Delphi 7.

No version currently exists that can be compiled on Lazarus. This implies in 
particular that the only way to play NeoLemmix on Linux systems is via Wine.

Whether the game compiles on other Delphi versions is unknown.

Compile instructions for the NeoLemmix player:
- NeoLemmix requires the Graphics32 library, including GR32PNG.
  Graphics32 for Delphi XE6 can be downloaded here (use the master branch, not stable!):
    https://github.com/graphics32/graphics32
  GR32PNG for Delphi XE6 can be downloaded here:
    https://github.com/graphics32/GR32PNG
  Warning: Most other versions of Graphics32 found elsewhere will not compile on 
           Delphi XE6 without modifications. 
- Build NeoLemmix.dpr. No special build scripts are required.

Further comments:
- Compiled versions of NeoLemmix will be placed in the subfolder "bin".
- All extrenal files needed to run NeoLemmix.exe are contained in "data/external".
  Some of the files (like the ones in "styles") are optional and only required for playing
  certain levels.
- NXPConverter: 
  This is a tool to convert old binary level pack files to the new text-based file format.
  The project file is "NXPConvert.dpr" in "Tools/NXPConvert".
  Again no special build script is needed, though it uses several units from the main game.
- GSConverter:
  This is a tool to convert old binary graphic styles to the new .png-based file format.
  The project file is "GSConvert.dpr" in "Tools/GSConvert".
  Again no special build script is needed.



