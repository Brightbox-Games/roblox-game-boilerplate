--!strict

export type Context = {
	-- The controller registry, for reaching other features' controllers
	Controllers: { [string]: any },
	Open: (name: string) -> (),
	Close: (name: string) -> (),
}

export type Topbar = {
	-- At least one of Label and Image
	Label: string?,
	Image: string?,
	Order: number?,
}

export type Screen = {
	Modal: boolean,
	StartsOpen: boolean,
	DisplayOrder: number?,
	-- A TopbarPlus icon that opens and closes the screen
	Topbar: Topbar?,
	-- A Vide component: runs once inside the screen's Vide root and returns its content,
	-- which UIController parents to the screen's ScreenGui. Clean up with Vide.cleanup.
	Render: (context: Context) -> Instance,
}

return {}
