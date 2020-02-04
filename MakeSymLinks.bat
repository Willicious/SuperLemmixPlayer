REM Symlinks can safely be deleted if desired, and will not be created if the folder already exists.
mklink /J bin\data data\external\data
mklink /J bin\gfx data\external\gfx
mklink /J bin\music data\external\music
mklink /J bin\sound data\external\sound
mklink /J bin\styles data\external\styles
mklink /H bin\bass.dll data\external\bass.dll
mklink /H bin\NLPackerDefaultData.ini data\external\NLPackerDefaultData.ini

if not exist "bin\style_zips" mkdir "bin\style_zips"
mklink /H "bin\style_zips\styles_md5s.ini" "data\styles_md5s.ini"

if not exist "bin\levels" mkdir "bin\levels"
mklink /J "bin\levels\Test Levels" "data\external\levels\Test Levels"
mklink /J "bin\levels\CovoxLemmings" "data\external\levels\CovoxLemmings"
mklink /J "bin\levels\ExtraLevels" "data\external\levels\ExtraLevels"
mklink /J "bin\levels\HolidayLemmings" "data\external\levels\HolidayLemmings"
mklink /J "bin\levels\Lemmings" "data\external\levels\Lemmings"
mklink /J "bin\levels\MazuLems" "data\external\levels\MazuLems"
mklink /J "bin\levels\OhNoMoreLemmings" "data\external\levels\OhNoMoreLemmings"
mklink /J "bin\levels\PrimaLemmings" "data\external\levels\PrimaLemmings"
mklink /J "bin\levels\XmasLemmings" "data\external\levels\XmasLemmings"
