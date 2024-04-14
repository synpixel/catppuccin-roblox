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
	local file = "return {"

	for name, theme in palette do
		file ..= "\n    "
		file ..= `{name} = \{`

		for color, hex in theme do
			file ..= "\n        "
			file ..= `{color} = Color3.fromHex("{hex}"),`
		end

		file ..= "},\n"
	end

	file ..= "}"
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
