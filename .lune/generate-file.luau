local fs = require("@lune/fs")
local net = require("@lune/net")

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
	local definition = "export type PaletteColor = "

	for _, flavor in palette do
		local colorNames = collectKeys(flavor.colors)

		for index, colorName in colorNames do
			definition ..= "\n"
			definition ..= "    "

			if index > 1 then
				definition ..= "| "
			end

			definition ..= `"{colorName}"`
		end

		break
	end

	return definition
end

local function definePaletteColorsType(palette: CatppuccinPalette)
	local definition = "export type PaletteTheme = {"

	for _, flavor in palette do
		for colorName in flavor.colors do
			definition ..= "\n"
			definition ..= "    "
			definition ..= `{colorName}: Color3,`
		end

		break
	end

	definition ..= "\n"
	definition ..= "}"
	return definition
end

local function definePaletteType(palette: CatppuccinPalette)
	local definition = "export type Palette = {"

	for flavorName in palette do
		definition ..= "\n"
		definition ..= "    "
		definition ..= `{flavorName}: PaletteTheme,`
	end

	definition ..= "\n"
	definition ..= "}"
	return definition
end

local function definePalette(palette: CatppuccinPalette)
	local definition = "local palette: Palette = {"

	for flavorName, flavor in palette do
		definition ..= "\n"
		definition ..= "    "
		definition ..= `{flavorName} = \{`

		for colorName, color in flavor.colors do
			definition ..= "\n"
			definition ..= "    "
			definition ..= "    "
			definition ..= `{colorName} = Color3.fromHex("{color.hex}"),`
		end

		definition ..= "\n"
		definition ..= "    "
		definition ..= "},"
	end

	definition ..= "\n"
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
		"return palette\n",
	}, "\n\n")
end

local palette = fetchCatppuccinPalette()
fs.writeFile("palette.luau", generateLuauFile(palette))
