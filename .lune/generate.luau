local net = require("@lune/net")
local fs = require("@lune/fs")

type PaletteSchemaColors = { [string]: { hex: string } }

type PaletteSchema = {
	latte: {
		colors: PaletteSchemaColors,
	},
	frappe: {
		colors: PaletteSchemaColors,
	},
	macchiato: {
		colors: PaletteSchemaColors,
	},
	mocha: {
		colors: PaletteSchemaColors,
	},
}

local palette = {}

local function generateOutput()
	local file = ""

	file ..= "export type Palette = {"

	for name, theme in palette do
		file ..= "\n	"
		file ..= `{name}: PaletteColor,`
	end

	file ..= "\n}\n\n"

	file ..= "export type PaletteColor = {"

	for _, theme in palette do
		for color, _ in theme do
			file ..= "\n	"
			file ..= `{color}: Color3,`
		end

		break
	end

	file ..= "\n}\n\n"

	file ..= "local palette: Palette = {"

	for name, theme in palette do
		file ..= "\n    "
		file ..= `{name} = \{\n`

		for color, hex in theme do
			file ..= "        "
			file ..= `{color} = Color3.fromHex("{hex}"),\n`
		end

		file ..= "	},"
	end

	file ..= "\n}\n\n"
	file ..= "return palette\n"
	return file
end

local paletteData: PaletteSchema
if fs.isFile("palette.json") then
	paletteData = net.jsonDecode(fs.readFile("palette.json"))
else
	local response = net.request("https://raw.githubusercontent.com/catppuccin/palette/main/palette.json")
	fs.writeFile("palette.json", response.body)
	paletteData = net.jsonDecode(response.body)
end

for name, theme in paletteData do
	palette[name] = {}

	for color, value in theme.colors do
		palette[name][color] = value.hex
	end
end

fs.writeFile("palette.luau", generateOutput())
