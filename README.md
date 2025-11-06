# Tiled-TMJ-Loader-for-Luau-Zune


This is a module for loading TMJ (JSON [Tiled](/https://www.mapeditor.org/) format).

Currently only supports Tiled version 1.11.2, to my knowledge, likely supports earlier and later versions. TMJ lacks some features that the standard TMX format typically has, however it is far simpler to parse and implement.

This module only supports drawing the first layer at the moment, however adding support for it will be easy and added next.

Requires [Zune](/https://github.com/Scythe-Technology/zune), a Luau runtime, and [Raylib](/https://github.com/Scythe-Technology/luau-raylib) bindings made with the FFI library provided in Zune.


My current implementation is kind of hacky and I will likely be handling the loading in a completely different manner eventually. You are expected to use the source rects (Tile IDs) and destination rects (Tiles) with DrawTexturePro.
