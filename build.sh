rm -rf dist/

cmake --build ./build --config Debug --target all -j 10 --

mkdir dist/
cp -R build/fonts dist/fonts
cp -R build/shaders dist/shaders
cp -R build/resources dist/resources
mkdir dist/songs/

cp build/config.ini dist/config.ini

cp build/engine.exe dist/engine.exe
cp build/FRACTUAL.exe dist/FRACTUAL.exe

cp build/INIFileParser.dll dist/INIFileParser.dll
cp build/openal32.dll dist/openal32.dll
cp build/sfml-audio-2.dll dist/sfml-audio-2.dll
cp build/sfml-audio-d-2.dll dist/sfml-audio-d-2.dll
cp build/sfml-graphics-2.dll dist/sfml-graphics-2.dll
cp build/sfml-graphics-d-2.dll dist/sfml-graphics-d-2.dll
cp build/sfml-system-2.dll dist/sfml-system-2.dll
cp build/sfml-system-d-2.dll dist/sfml-system-d-2.dll
cp build/sfml-window-2.dll dist/sfml-window-2.dll
cp build/sfml-window-d-2.dll dist/sfml-window-d-2.dll