--!strict

export type Product = {
	Id: number,
	Grant: (data: any, player: Player) -> (),
}

local Products: { [string]: Product } = {}

return Products
