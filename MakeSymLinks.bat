REM Symlinks can safely be deleted if desired, and will not be created if the folder already exists.
mklink /J bin\data data\external\data
mklink /J bin\gfx data\external\gfx
mklink /J bin\music data\external\music
mklink /J bin\sketches data\external\sketches
mklink /J bin\sound data\external\sound
mklink /J bin\styles data\external\styles
mklink /H bin\bass.dll data\external\bass.dll
mklink /H bin\NLPackerDefaultData.ini data\external\NLPackerDefaultData.ini

if not exist "bin\levels" mkdir "bin\levels"
mklink /J "bin\levels\SuperLemmix Welcome Pack" "data\external\levels\SuperLemmix Welcome Pack"
mklink /J "bin\levels\DMA Lemmings Compilation" "data\external\levels\DMA Lemmings Compilation"

if exist "data\external\levels\Lemminas Origins" (
mklink /J "bin\levels\Lemminas Origins" "data\external\levels\Lemminas Origins")
