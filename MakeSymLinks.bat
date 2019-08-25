REM Symlinks can safely be deleted if desired, and will not be created if the folder already exists.
mklink /J bin\data data\external\data
mklink /J bin\gfx data\external\gfx
mklink /J bin\music data\external\music
mklink /J bin\sound data\external\sound
mklink /J bin\styles data\external\styles
mklink /H bin\bass.dll data\external\bass.dll

if not exist "bin\levels" mkdir "bin\levels"
mklink /J "bin\levels\Test Levels" "data\external\levels\Test Levels"