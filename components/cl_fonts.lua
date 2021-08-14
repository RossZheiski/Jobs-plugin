local PLUGIN = PLUGIN;

function PLUGIN:LoadNutFonts(font, genericFont)
	font = genericFont
	surface.CreateFont("JobEditorTitle", {
		font = "Dosis",
		size = ScreenScale(8),
		scanlines = 1,
		antialias = true,
	})
	surface.CreateFont("JobHighlight", {
		font = "Dosis",
		size = ScreenScale(8),
		weight = 1000,
		scanlines = 1,
		antialias = true,
	})
	surface.CreateFont("JobDescription", {
		font = "Dosis",
		size = ScreenScale(7),
		scanlines = 1,
		antialias = true,
	})
	surface.CreateFont("JobBtns", {
		font = "Dosis",
		size = ScreenScale(6),
		scanlines = 1,
		antialias = true,
	})
	// Taxi
	surface.CreateFont("TaxiTitle", {
		font = "Consolas",
		size = ScreenScale(15),
		scanlines = 1,
		antialias = true,
	})
	surface.CreateFont("TaxiRules", {
		font = "Constantia",
		size = ScreenScale(8),
		scanlines = 1,
		antialias = true,
		italic = true
	})
	surface.CreateFont("TaxiBtns", {
		font = "Dosis",
		size = ScreenScale(8),
		scanlines = 1,
		antialias = true,
	})
	surface.CreateFont("TaxiBtnsLower", {
		font = "Dosis",
		size = ScreenScale(7),
		scanlines = 1,
		antialias = true,
	})
end;