--!strict
local serde: _zune_serde_json = zune.serde.json
local fs: _zune_fs = zune.fs
local raylib = require("@raylib")

local lib = raylib.lib
local struct = raylib.structs

local MapLoader = {}

export type Map = {
    TileInfo: {
        scale: vector,
        startposition: vector,
        LayerAmount: number
    },
    Tiles: {
            [number]: {
                [number]: {raylib.Rectangle}
        }
    },
    TileIDs: {[number]: raylib.Rectangle},
    Textures: {[number]: raylib.Texture2D}
}

--[[+

@tm_formatting

TMX/TMJ texture atlases go from left -> right in increments of tile width,
moving down a tile height at the end of the current image slice.

Starts from 0.

TMX/TMJ have a "tilecount" from an embedded tilset that may be offset by 1 (so 39 -> 40), but sometimes they don't

TMX/TMJ files use numbered dictionaries in {} scopes, starting from 1.
Although most JSON formatting extensions will read them as "0."
Almost every instance of an array/table/dictionary will be defaulted to 1 in Lua/Luau.

+]]--

function MapLoader:LoadMap(Map: string, Atlas: string): (Map?, raylib.Texture2D?)
    
    local Raw: string = fs.readFile(Map)
    local MapData = serde.decode(Raw)

    local Mapped: Map = {
        TileInfo = {
            scale = vector.zero,
            startposition = vector.zero,
            LayerAmount = 0
        },
        Tiles = {},
        TileIDs = {},
        Textures = {}
    }

    local width: number = MapData["width"]

    local tilewidth: number = MapData["tilewidth"]
    local tileheight: number = MapData["tileheight"]
    local tilesets: {[string | number]: any} = MapData["tilesets"]
    local tilecount: number = tilesets[1]["tilecount"]
    local tilemargin: number = tilesets[1]["margin"]
    local tilespacing: number = tilesets[1]["spacing"]

    if not tilecount then
        error("Map has no embedded TSX")
        return nil, nil
    else
        tilecount -= 1
    end

    local atlascolumns: number = tilesets[1]["columns"]

    local num: number = 0
    local cX: number = 0
    local cY: number = 0

    local AtlasImg: raylib.Image = lib.LoadImage(Atlas)

    
    
    local Texture: raylib.Texture2D = lib.LoadTextureFromImage(AtlasImg) do    
        Mapped.Textures[0] = Texture
    
        buffer.writei32(Texture, 16, 10)
        local ptr = zune.ffi.ptrFromAddress(Texture)
        lib.GenTextureMipmaps(ptr)
    end

    local CurrentLayer: number
    local Rect: raylib.Rectangle 

    --Destinations
    for i: number, layer in MapData["layers"] do
        if not layer["data"] then
            continue 
        end

        CurrentLayer = i

        for Index: number, Tile: number in layer["data"] do
            if num == width then
                num = 0; cX = 0; cY += tileheight
            end; num += 1

            Rect = struct.Rectangle:new{
                x = cX,
                y = cY,
                width = tilewidth,
                height = tileheight
            }

            if not Mapped.Tiles[CurrentLayer] then
                Mapped.Tiles[CurrentLayer] = {}
            end

            if not Mapped.Tiles[CurrentLayer][Tile] then
                Mapped.Tiles[CurrentLayer][Tile] = {}
            end

            table.insert(Mapped.Tiles[CurrentLayer][Tile], Rect)

            cX += tilewidth
        end

        cX = 0; cY = 0; num = 0
    end

    cX = tilemargin; cY = tilemargin; num = 0

    --Source Tiles

    local SourceRect: raylib.Rectangle

    for i: number = 1, tilecount, 1 do
        if num == atlascolumns then
            num = 0; cX = 1; cY += tileheight + tilemargin
        end; num += 1

        SourceRect = struct.Rectangle:new{
            x = math.floor(cX + tilemargin),
            y = math.floor(cY + tilemargin),
            width = tilewidth - tilespacing,
            height = tileheight - tilespacing
        }

        Mapped.TileIDs[i] = SourceRect

        
        cX += tilewidth + tilemargin

    end

    Mapped.TileInfo = {
        startposition = vector.zero,
        scale = vector.create(tilewidth, tileheight),
        LayerAmount = CurrentLayer
    }
    
    return Mapped, Texture
end

return MapLoader
