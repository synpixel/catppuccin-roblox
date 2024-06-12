local fs = require("@lune/fs")
local process = require("@lune/process")
local net = require("@lune/net")

local FILE_PATH = "palette.luau"

type CatppuccinPalette = {
	[string]: {
		[string]: { hex: string },
	},
}

local function collectKeys<Key>(t: { [Key]: any })
	local keys: { Key } = {}

	for key in t do
		table.insert(keys, key)
	end

	return keys
end

local function fetchCatppuccinPalette(): CatppuccinPalette
	local response = net.request("https://raw.githubusercontent.com/catppuccin/palette/main/palette.json")
	if not response.ok then
		error(`{response.statusCode} {response.statusMessage}`)
	end

	return net.jsonDecode(response.body)
end

local function definePaletteFlavorType(palette: CatppuccinPalette)
	local flavorNames = collectKeys(palette)
	for index, flavorName in flavorNames do
		flavorNames[index] = `"{flavorName}"`
	end

	return `export type PaletteFlavor = {table.concat(flavorNames, " | ")}`
end

local function definePaletteColorType(palette: CatppuccinPalette)
	local colorNames: { string } = nil

	for _, flavor in palette do
		colorNames = collectKeys(flavor.colors)
		break
	end

	for index, colorName in colorNames do
		colorNames[index] = `"{colorName}"`
	end

	return `export type PaletteColor = {table.concat(colorNames, " | ")}`
end

local function definePaletteColorsType(palette: CatppuccinPalette)
	local definition = "export type PaletteTheme = {"

	for _, flavor in palette do
		for colorName in flavor.colors do
			definition ..= `{colorName}: Color3,`
		end

		break
	end

	definition ..= "}"
	return definition
end

local function definePaletteType(palette: CatppuccinPalette)
	local definition = "export type Palette = {"

	for flavorName in palette do
		definition ..= `{flavorName}: PaletteTheme,`
	end

	definition ..= "}"
	return definition
end

local function definePalette(palette: CatppuccinPalette)
	local definition = "local palette: Palette = {"

	for flavorName, flavor in palette do
		definition ..= `{flavorName} = \{`

		for colorName, color in flavor.colors do
			definition ..= `{colorName} = Color3.fromHex("{color.hex}"),`
		end

		definition ..= "},"
	end

	definition ..= "}"
	return definition
end

local function generateLuauFile(palette: CatppuccinPalette)
	return table.concat({
		"--!strict",
		definePaletteFlavorType(palette),
		definePaletteColorType(palette),
		definePaletteColorsType(palette),
		definePaletteType(palette),
		definePalette(palette),
		"return palette",
	}, "\n\n")
end

local palette = fetchCatppuccinPalette()

fs.writeFile(FILE_PATH, generateLuauFile(palette))
process.spawn("stylua", { "--indent-type Tabs", "--indent-width 1", FILE_PATH }, { shell = true })
