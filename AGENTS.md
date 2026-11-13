# Game Boilerplate — agent instructions

## Code style

- Do not add comments to code. Luau directives such as `--!strict` are allowed.
- Keep `--!strict` at the top of every Luau file. Run `lune run check` before handing off code changes.
- The project uses Luau's new type solver: `luau-lsp.fflags.enableNewSolver` in `.vscode/settings.json`, which `lune run check` also reads. In Studio, set **Workspace > UseNewLuauTypeSolver** to `Enabled` so Script Analysis matches.
- Format with StyLua (tabs, 110 columns, double quotes). Never edit generated `Packages/`, `build/` or `sourcemap.json`.

### Naming

| Thing | Convention | Example |
| --- | --- | --- |
| Files, modules, folders | PascalCase, matching the returned table | `ShopService.luau`, `RateLimit.luau` |
| Services and controllers | PascalCase ending in `Service` or `Controller`; `Name` matches the file | `DataService`, `UIController` |
| Types | PascalCase; export shared ones with `export type` | `PlayerData.Data`, `Types.Screen` |
| Public functions, methods, fields and signals | PascalCase | `UIController:Open`, `DataService.PlayerLoaded` |
| Private fields | `_camelCase` | `self._trove` |
| Local variables and local functions | camelCase | `local activeSessions`, `local function refresh()` |
| Constants | camelCase locals, or PascalCase keys in a frozen `Config` table | `local maxRetries = 3`, `GameConfig.Name` |
| Unused parameters | `_` prefix | `_self`, `_player` |
| Packets | PascalCase verb or event name | `Buy`, `RoundStarted` |
| Tags and attributes | PascalCase | `Spinner`, `SpinSpeed`, `Ready` |
| Services and packages | Local named after the service or package | `local Players = game:GetService("Players")`, `local Trove = require(...Trove)` |

- Name things for what they are, not how they are used: `Catalog`, not `ShopHelper`.
- Avoid abbreviations except universally understood ones (`id`, `ui`, `dt`).
- Booleans read as questions: `isOpen`, `hasLoaded`, `StartsOpen`.

## Scope

- This is a generic game boilerplate. Keep it game-agnostic: no genre-specific systems, assets or design decisions unless the user asks. Ask before making material design decisions.
- Explicit user instructions take precedence.

## Setup and checks

Tools are pinned in `rokit.toml`: Rojo, Wally, StyLua, wally-package-types, luau-lsp, Lune and Asphalt. The only prerequisite is [Rokit](https://github.com/rojo-rbx/rokit). Project scripts are Lune scripts in `.lune/`, run from the project root.

```sh
rokit install
lune run install
rojo serve default.project.json --address 127.0.0.1
```

- `rokit install` installs the pinned tools. On first run it asks the user to trust each new tool author; that prompt needs a real terminal, so ask the user to run it rather than bypassing it.
- `lune run install` downloads the Roblox type definitions (`globalTypes.d.luau`, Git-ignored) if missing, runs `wally install`, then `wally-package-types` so package types (such as `Signal.Signal<T...>`) are visible to strict code. Run it on a fresh clone and after changing `wally.toml`; never run bare `wally install`.
- On Windows, `./scripts/install.ps1` and `./scripts/check.ps1` are thin wrappers: `install.ps1` runs `rokit install` then `lune run install`, and `check.ps1` runs `lune run check`. Keep logic in the Lune scripts, not the wrappers.
- Connect the Rojo plugin in Studio to `localhost:34873`. Once the game has a place, add `"servePlaceIds": [<placeId>]` to `default.project.json`.
- In Studio, enable **Game Settings > Security > Enable Studio Access to API Services** (the place must be published). Without it (or in an unpublished place), Scribe saves to an in-memory store: everything works, but data resets when Play stops, and output shows `[ProfileStore]: Roblox API services unavailable - data will not be saved`. Live servers always have DataStore access.
- In Play, output shows `[Game Boilerplate] Server services ready`, `Client controllers ready` and a Packet round trip. Both Bootstraps set a `Ready` attribute.
- `lune run check` is the one command to run after every change. It formats `src` and `.lune` with StyLua, regenerates the sourcemap, runs luau-lsp type and lint analysis, and does a Rojo build. Fix every error it reports and rerun it until it passes.
- `rojo build` output is code-only, not a replacement for the authored place.
- **Starting a new game from this boilerplate:** set `GameConfig.Name`, set `[creator] id` in `asphalt.toml` to the game's Roblox group ID, put the game's admins in `Config/AdminConfig.luau`, and add `servePlaceIds` once the place exists.

## Layout

| Files | Studio destination | Contents |
| --- | --- | --- |
| `src/server` | `ServerScriptService` | `Bootstrap.server.luau`, `Registry.luau`, `Services/`, `Components/` (create when needed) |
| `src/client` | `StarterPlayer.StarterPlayerScripts` | `Bootstrap.client.luau`, `Registry.luau`, `Controllers/`, `Components/` |
| `src/shared` | `ReplicatedStorage` | `Lifecycle`, `Packet/`, `Packets`, `PlayerData/`, `Assets` (generated), `Config/`, `Utils/` |
| `Packages` | `ReplicatedStorage.Packages` | Generated Wally dependencies |

- Edit code on disk; Rojo syncs it. Code lives directly in the service roots, with no Client/Server/Shared wrapper folders.
- Rojo owns mapped folders. Unknown children at service roots are preserved. Workspace, lighting, GUI and other art are edited and saved in Studio, not on disk.
- Tag authoring-only content in Workspace (prefab libraries, reference models, anything the game reads from a copy elsewhere) `EditorOnly`. `Bootstrap.server.luau` moves tagged instances into `ServerStorage.EditorOnly` before any system starts, so they stay editable in Studio but are never replicated to players. Never tag something code reads from Workspace.
- Server-only code (secrets, rules, data) belongs in `src/server`. Everything in `src/shared` is visible to clients.
- Put tunable constants in `src/shared/Config` as frozen tables, or in server modules if clients must not see them.
- Put pure logic in plain modules (such as a system's `Catalog.luau`) with no service dependencies.
- Keep `src/shared` tidy: its root holds only the framework (`Lifecycle`, `Packet`, `Packets`, `PlayerData`), the generated `Assets`, and folders. Reusable, game-agnostic helpers used by more than one system go in `src/shared/Utils` (such as `Utils/RateLimit`), one module per helper. Server-only helpers go in `src/server/Utils`. Helpers used by a single system stay inside that system's folder.

## Systems

A system is a service (server) or controller (client): a ModuleScript table run by `src/shared/Lifecycle.luau`.

- **Services** own state, validation and game rules. Never trust the client: validate every request on the server.
- **Controllers** own input, camera, UI and presentation. They request changes from services; they never decide outcomes.

### When to make a new system

Make a new service when a feature has all of:

- its own state that other code should change only through its methods (a shop's stock, a round's timer, a player's inventory),
- its own lifetime: connections, per-player setup and cleanup, or timers,
- its own requests from clients.

On the client, all UI belongs to one `UIController`, with one child module per screen (see UI below). Make a separate controller only for non-UI client behaviour with its own state and per-frame work: `CameraController`, `VehicleController`, `PlacementController`. Screens reach those controllers through the registry.

Do not make a system for:

- part of an existing feature: add a child module to that system instead (see below),
- behaviour attached to tagged instances: use a component,
- constants: use `src/shared/Config`,
- stateless helpers: use a plain module next to the code that uses it, or in `src/shared/Utils` if several systems need it.

If a system's methods start being about two unrelated things, or other systems keep reaching into its data, split it into two systems.

### Structuring a system across files

Keep each system's concerns in separate files. Once a system has more than one concern (or its file passes about 300 lines), turn it into a folder. Rojo maps a folder containing `init.luau` to a single ModuleScript with the other files as its children, so the registry `require` does not change.

```text
src/server/Services/ShopService/
	init.luau
	Catalog.luau
	Purchasing.luau
	Types.luau
src/client/Controllers/CameraController/
	init.luau
	Modes.luau
	Smoothing.luau
```

| File | Role |
| --- | --- |
| `init.luau` | The only file with `Name`, `Init`, `Start` and `Destroy`, and the only one in `Registry.luau`. Owns the system's state, connections and packet handlers, and routes each request to a child module. |
| Child modules (`Catalog`, `Purchasing`, `Modes`, ...) | One concern each. Plain modules: no lifecycle, no connections or state at module level, never registered. They receive what they need (the registry, the player, state) as arguments. |
| `Types.luau` | Types shared between the system's files. |

- Only `init.luau` wires children together. Children may require `Types` and pure siblings such as `Catalog`, but never `init.luau` and never in a cycle.
- Split by responsibility, not by line count: data lookup, validation and mutation, networking, and presentation belong in different files.
- Non-UI controllers follow the same pattern, for example `CameraController/init.luau` with `Modes.luau` and `Smoothing.luau`.

```lua
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerData = require(ReplicatedStorage.PlayerData)
local Catalog = require(script.Parent.Catalog)
local Types = require(script.Parent.Types)

local Purchasing = {}

function Purchasing.Buy(_context: Types.Context, player: Player, itemId: string): boolean
	local item = Catalog.Get(itemId)
	local data = PlayerData.Get(player)
	if not item or not data or data.Cash.Get() < item.Price then
		return false
	end
	data.Cash.Increment(-item.Price)
	return true
end

return Purchasing
```

```lua
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packets = require(ReplicatedStorage.Packets)
local Purchasing = require(script.Purchasing)
local Types = require(script.Types)

local ShopService = { Name = "ShopService" }
local context: Types.Context = { Services = {} }

function ShopService.Init(_self: any, registry: { [string]: any })
	context.Services = registry
end

function ShopService.Start(_self: any)
	Packets.Buy.OnServerInvoke = function(player: Player, itemId: string)
		return Purchasing.Buy(context, player, itemId)
	end
end

function ShopService.Destroy(_self: any)
	Packets.Buy.OnServerInvoke = nil
end

return ShopService
```

### UI

`UIController` (`src/client/Controllers/UIController`) owns every screen. It ships with no screens; its `modules` table is empty.

**Build UI in Studio, not in code.** Prefer ScreenGuis authored in StarterGui, with code finding and driving them. Only create UI in code (`Instance.new`, React or similar) if the user says they prefer that.

- Use the Roblox Studio MCP tools to create and edit UI in StarterGui: inspect the existing tree, add ScreenGuis and elements, and take screenshots to check the result.
- If no Roblox Studio MCP is connected, do not fall back to building UI in code. Tell the user to set it up using https://create.roblox.com/docs/studio/mcp, and continue with the code side (the screen module) meanwhile.
- UI in StarterGui is saved in the place file, not on disk; Rojo does not sync it. Remind the user to save the place after UI changes.

```text
src/client/Controllers/UIController/
	init.luau
	Types.luau
	Screens/
		<Name>.luau
```

- **Adding a screen:**
  1. Create a ScreenGui in StarterGui named after the screen.
  2. Add `Screens/<Name>.luau` using the template below.
  3. Add `<Name> = require(script.Screens.<Name>)` to the `modules` table in `init.luau`.
- **What `init.luau` does:**
  - Waits up to 15 seconds for each ScreenGui with `WaitFor`. If one is missing, it warns with the expected path and disables only that screen.
  - Sets `ResetOnSpawn = false` so screens survive respawns.
  - Creates each screen, tracks which are open, closes other modals when a modal opens, and destroys everything in `Destroy`.
- **API for other systems:** `UIController:Open(name)`, `UIController:Close(name)` and `UIController:IsOpen(name)`.
- **Screen contract** (`Types.luau`):
  - A screen module returns `{ new = function(context, gui): Screen }`.
  - The screen object has `Modal`, `StartsOpen`, `Open`, `Close` and `Destroy`.
  - Non-modal screens (HUD, notifications) can be open together. Opening a modal screen (shop, settings) closes other modals.
  - Screens may hold state because they are created objects. They own their connections through a Trove and clean them up in `Destroy`.
- **What screens receive:** `context.Controllers` (the controller registry), `context.Open` and `context.Close`. Screens never require each other; open another screen through `context.Open`.
- **What screens may do:** send requests through `Packets` and display player data through `PlayerData.Client` (see Player data). They never decide outcomes.
- **Finding elements:** look up authored elements by name inside `gui` and check their class (`IsA`) before use, so a renamed element fails visibly rather than erroring.
- **Complex client logic** such as a placement preview goes in its own controller, which the screen calls through `context.Controllers`.

```lua
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerData = require(ReplicatedStorage.PlayerData)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Types = require(script.Parent.Parent.Types)

local Hud = {}

function Hud.new(_context: Types.Context, gui: ScreenGui): Types.Screen
	local trove = Trove.new()

	local stopCash = PlayerData.Client.Cash.Observe(function(cash: number)
		local label = gui:FindFirstChild("Cash", true)
		if label and label:IsA("TextLabel") then
			label.Text = string.format("%d", cash)
		end
	end)
	trove:Add(function()
		stopCash()
	end)

	return {
		Modal = false,
		StartsOpen = true,
		Open = function(_self: Types.Screen)
			gui.Enabled = true
		end,
		Close = function(_self: Types.Screen)
			gui.Enabled = false
		end,
		Destroy = function(_self: Types.Screen)
			trove:Destroy()
		end,
	}
end

return Hud
```

### Adding a system

1. Create `src/server/Services/NameService.luau` or `src/client/Controllers/NameController.luau`.
2. Return a plain table with a unique `Name` matching the file name, and optional `Init`, `Start` and `Destroy`. Do not annotate it as `Lifecycle.System`: that type is read-only, so defining methods on an annotated table fails. The registry's `{ Lifecycle.System }` list checks the shape.
3. Add a `require` to that side's `Registry.luau`, after every system it depends on.

```lua
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerData = require(ReplicatedStorage.PlayerData)
local Packets = require(ReplicatedStorage.Packets)

local ExampleService = { Name = "ExampleService" }
local services: { [string]: any } = {}

function ExampleService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function ExampleService.Start(_self: any)
	services.DataService.PlayerLoaded:Connect(function(player: Player, data: PlayerData.Data)
		print(player.Name, "joined with", data.Cash.Get(), "cash")
	end)
	Packets.GetCash.OnServerInvoke = function(player: Player)
		local data = PlayerData.Get(player)
		return if data then data.Cash.Get() else 0
	end
end

function ExampleService.Destroy(_self: any)
	Packets.GetCash.OnServerInvoke = nil
end

return ExampleService
```

The matching packet in `Packets.luau` would be `GetCash = Packet("GetCash"):Response(Packet.NumberF64):RateLimit(5, 1)`, and a controller calls it with `local cash = Packets.GetCash:Fire()`.

### Lifecycle rules

- Order: every system's `Init` runs in registry order, then every `Start` in registry order. Startup happens once per session; there is no hot reload.
- `Init(self, registry)` receives the complete name-to-system table. Store it and set up local state only. Do not call other systems here: they may not be initialised yet.
- `Start(self)` connects events, binds packets and begins work. Other systems are safe to call from here on.
- Hooks must return promptly. Never yield or run permanent loops inside them; use `task.spawn` or connections instead.
- `Destroy(self)` disconnects connections, destroys instances and cancels owned threads. It must tolerate a partially completed `Init` and being called when `Start` never ran.
- Module loading must have no side effects: no connections, instances or yields at require time. The one exception is `ReplicatedStorage.PlayerData`: Scribe starts its player listeners (and `ProcessReceipt`, once products exist) the first time it is required, which is while the registries load.
- Errors in `Init`/`Start` are reported as `[System.Phase]`; the lifecycle then destroys initialised systems in reverse order and stops startup. Duplicate names and repeated starts are rejected.
- The server calls `Destroy` through `BindToClose`; the client bootstrap does so when destroyed. Both bootstraps set a `Ready` attribute once startup succeeds.

### Using other systems

- Access other systems through the registry captured in `Init` (`services.UIController:Open("Shop")`), not by requiring their modules directly. `PlayerData` is not a system: require it directly so its data stays typed. Direct requires break when the registry order changes and hide dependencies.
- Dependencies must point one way. If two systems need each other, give one a `Signal` (`ReplicatedStorage.Packages.Signal`) that the other connects to in `Start`, as `DataService.PlayerLoaded` does.
- Clean up with Trove (`ReplicatedStorage.Packages.Trove`), not hand-kept connection lists. A system keeps a module-level `local trove = Trove.new()`, uses `trove:Connect(signal, handler)` in `Start`, and calls `trove:Clean()` in `Destroy`; see `DataService` and `DebugController`. Wrap stop functions from packages (Scribe's `Observe`, `Iris:Connect`) in a closure, `trove:Add(function() stop() end)`: the new solver rejects a typed function value passed directly.

### Components

Use a component for behaviour attached to many tagged instances (doors, pickups, hazards, spinners). Use a system for game-wide state. Components use the Component package and CollectionService tags.

- Put client components in `src/client/Components` and server components in `src/server/Components`. Add the module's `require` to the `factories` list in `ComponentController` or `ComponentService`.
- A component module returns a factory `function(registry)` that creates and returns the class. The loader calls it in `Start`, so requiring the module has no side effects, and the component can reach systems through the registry.
- Cast the class to `any` and type `self` explicitly, because the package's inferred types do not work in strict mode. `src/client/Components/Spinner.luau` is the example: tag a part `Spinner` and optionally set a `SpinSpeed` attribute (degrees per second).
- Use `Construct` for setup, `Start` for connections, `Stop` for cleanup, and `HeartbeatUpdate`/`RenderSteppedUpdate` for per-frame work. Components start only under `workspace` and `Players` unless `Ancestors` is given.
- Server components own authoritative behaviour; client components are presentation only. Destroying the class stops tag tracking but does not stop already running instances, so it is suitable only at shutdown.

```lua
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Component = require(ReplicatedStorage.Packages.Component)

type Door = { Instance: Instance }

return function(services: { [string]: any })
	local Door = Component.new({ Tag = "Door" }) :: any

	function Door.Start(self: Door) end

	function Door.Stop(self: Door) end

	return Door
end
```

### Packages

Packages are in `ReplicatedStorage.Packages`. Add new ones to `wally.toml` and run `lune run install`. There are no server-only packages; to add one, add a `[server-dependencies]` section to `wally.toml` and map `ServerPackages` to `ServerScriptService.ServerPackages` in `default.project.json`. Commit `wally.toml` and `wally.lock`.

| Package | Use it for |
| --- | --- |
| `Trove` | Cleaning up connections, instances and threads owned by a system or component. |
| `Signal` | Custom events between systems. Also used by Packet for `OnServerEvent`/`OnClientEvent`. Prefer `Fire`; Packet uses `FireDeferred`. |
| `Component` | Tag-driven behaviour; see Components. |
| `Input` | Client input: `Input.Keyboard.new()`, `Input.Mouse.new()`, `Input.Gamepad.new()`, `Input.Touch.new()`, and `Input.PreferredInput.observe(callback)` to adapt UI to the current device. Create them in a controller's `Start` and `Destroy` them in `Destroy`. Its inferred types do not work under the new solver (signals type as `unknown`); for a single key binding, `UserInputService.InputBegan` is simpler and fully typed, as `DebugController` does. |
| `WaitFor` | Waiting for authored instances with a timeout, such as `WaitFor.Child(parent, "Name", 15)`. It returns an untyped Promise: cast it to `any` before chaining (`(WaitFor.Child(parent, "Name", 15) :: any):andThen(...)`), use `:andThen`/`:catch`, and on failure `warn` with the full path and leave that feature disabled rather than hanging. |
| `TableUtil` | Table helpers (`Copy`, `Sync`, `Reconcile`, `Map`, `Filter`, `Keys`, `Values`, ...). Use it instead of rewriting common helpers. |
| `Conch`, `ConchUi` | The in-game admin console; see Admin console. |
| `Iris` | Immediate-mode debug UI, admins and Studio only; see Debug UI. |
| `Scribe` | Saved, typed, replicated player data and developer products, configured only in `src/shared/PlayerData`; see Player data. Pinned exactly (`=2.7.0`): read its changelog before upgrading. It bundles its own ProfileStore. |

Promise, Symbol and Signal also arrive as dependencies of Component and WaitFor. Do not add packages that duplicate these, Packet or Scribe (no Comm, Net, TypedRemote, ProfileStore, Replica, ReplicaService, Cmdr, Janitor or Knit) without the user's agreement.

### Networking

- Define every Packet channel in `src/shared/Packets.luau`. The server errors if a packet is defined after the first frame.
- `Packet(name, ...types)` declares an event; `:Response(...types)` makes it a request with a 10-second default timeout. Raise `ResponseTimeout` for anything that waits on a save.
- Services bind `OnServerEvent`/`OnServerInvoke` in `Start` and clear them in `Destroy`. Validate the sender, every argument and range on the server.
- Rate limit every packet the client can send by chaining `:RateLimit(count, window)`, allowing `count` calls per `window` seconds per player: `Buy = Packet("Buy", Packet.String):Response(Packet.Boolean8):RateLimit(5, 1)`. The server drops excess calls before they reach handlers (warning in Studio). A dropped request gets no reply, so the client's `Fire` returns `ResponseTimeoutValue` after `ResponseTimeout`; debounce buttons on the client so normal use never hits the limit.
- A packet without `:RateLimit` cannot be sent by clients at all: the server drops it (warning in Studio). Leave server-to-client packets unlimited so clients cannot fire them.
- `Packet.Instance` arguments from a client are either `nil` or a real Instance, nothing else, but the client chooses which one. Check that the player may act on it (owner, distance, ancestry) before using it.
- Length limits are in bytes: `String`, `Buffer`, `Characters` and `Any` strings take at most 255, `StringLong` and `BufferLong` at most 65,535, and arrays at most 65,535 elements. Sending a longer value errors in the sender and nothing is sent. Before sending player-supplied text (names, chat, textbox input), check its byte length on the server, or use `StringLong`.
- The server reads at most 8,000 bytes per player per heartbeat, counting every client batch as at least 800. A batch over the limit is dropped whole (warning in Studio), so keep client-to-server payloads small. An array from a client is rejected if it claims more elements than its message has bytes and Instances.
- Number arguments from a client can be NaN or infinite, and `Static` arguments can be `nil`. Check them before use.
- `src/shared/Packet` is our fork of Suphi Kaner's Packet 1.7 with local security fixes: per-packet rate limits, rejecting unbuffered client messages, binding each awaited response to its packet, checking Instance and EnumItem arguments, bounding arrays by the size of their message, and erroring on over-long values instead of corrupting the stream. Do not replace it with an upstream or Wally copy; port upstream fixes by hand.
- For limits that are not per packet (per action, per target, shared across packets), use `Utils/RateLimit` directly: `local limiter = RateLimit.new(3, 10)`, then `limiter:Allow(player)`. Call `limiter:Remove(player)` when the player leaves.
- Packet is for actions and Scribe is for player data. Clients send requests and receive events through Packet; the server's player data reaches clients through Scribe (see Player data). Do not add packets that mirror player data.
- Prefer Packet over RemoteEvents and RemoteFunctions. Use attributes only for simple values that belong to an instance, such as a plot's owner or the Bootstraps' `Ready`.

### Player data

Player data is saved, typed and replicated by [Scribe](https://ericplane.github.io/Scribe/), configured in `src/shared/PlayerData/init.luau`. Read its docs before using a feature not described here.

- **Template:** `Template` in `PlayerData/init.luau` declares every field. Use declarators for rules: `Cash = Scribe.Int(0, { Min = 0 })`. Out-of-range writes are clamped, so check balances before spending: `Increment(-price)` on too little cash clamps to 0 instead of failing. Wrap fields that must not reach the client in `Scribe.ServerOnly(...)`, fields every client should see in `Scribe.Shared(...)`, and runtime-only state in `Scribe.Session(...)`.
- **Server reads and writes:** `PlayerData.Get(player)` returns the typed data, or `nil` while the player is loading or leaving. Check for nil in every handler and never keep the data across a yield. Read with `data.Cash.Get()` and write with `Set`, `Increment` and the other accessor methods; every write is validated, saved and sent to the owner. `PlayerData.Server.Get(player)` errors unless the player is loaded, so use it only inside `PlayerLoaded` handlers.
- **Client reads:** `PlayerData.Client.Cash.Observe(callback)` calls `callback(value)` at once (with the template default until data arrives) and after every change, and returns a function that stops observing; add it to a Trove (see Using other systems). Use `PlayerData.Client.WaitForData()` or `IsReady()` to gate one-off logic. The client mirror is read-only; changes go through Packet requests that a service validates.
- **Per-player setup:** connect to `DataService.PlayerLoaded(player, data)` in `Start`, not `Players.PlayerAdded`. It fires after the player's data is ready and after every system has started, so every service that connects in `Start` sees every player.
- **Per-player cleanup:** connect to `DataService.PlayerReleasing(player, data)`. It fires before the final save, on leave and on shutdown. Write final state into `data` there, without yielding. It may be skipped when another server takes over the session, so do not rely on it as the only place a value is written. Do not disconnect it in your own `Destroy`, or the shutdown save will miss you.
- **Keep traffic small:** change the deepest field that changed, group related writes with `PlayerData.Server.Batch`, and never change player data every frame (per-frame values belong in Packet events or client-side state).
- **Changing the template:** adding a field with a default needs nothing else; existing players get the default. Renaming, removing or changing a field's type needs a migration (see the Migrations section of Scribe's "Offline Profiles" guide). Never reset progress for invalid data.
- **Stores:** Studio saves to `PlayerData_Studio`, live servers to `PlayerData`. Keep `ProfileStoreIndex` and `ProfileKeyPrefix` unchanged once real players have data.

### Purchases

Scribe owns `MarketplaceService.ProcessReceipt` once any product is declared. Nothing else may set it; Roblox allows only one handler.

- **Adding a developer product:** add `Name = { Id = productId, Grant = function(data, player) ... end }` to `src/shared/PlayerData/Products.luau`. Scribe grants it, records the receipt in the player's profile, and confirms the purchase to Roblox only after a save contains both, so a crash cannot grant twice or lose a paid reward.
- **Grants change only the player's data**, such as `data.Cash.Increment(500)`. They must not yield, prompt or touch anything outside the profile; rewards outside the profile (server-wide effects, tools in the Backpack) are not protected against retries, so ask the user before adding them.
- `Products.luau` is in `src/shared`, so clients can read it. Product IDs are public anyway, but never put secrets or server-only logic in a grant.
- Prompt purchases by name from the client with `PlayerData.Client.PromptPurchase("Name")`; never grant from a client request.
- Game passes go in a `Passes` table in the Scribe options (`VIP = { Id = passId }`). Check ownership on the server with `PlayerData.Server.OwnsAsync(player, "VIP")`.

### Admin console

[Conch](https://alicesaidhi.github.io/conch/) is the admin console. `AdminService` starts it on the server and gives admins the `super-user` role; `AdminController` starts it on the client and binds **F4** for admins only. It is a package UI built in code, so the "build UI in Studio" rule does not apply to it.

- **Who is an admin:** `src/shared/Config/AdminConfig.luau` lists admin `UserIds`; with `AdminsInStudio`, everyone in a Studio session (Play, Team Test) is an admin. `Utils/IsAdmin` is the one check for both sides. The server's role check is what protects commands; the client check only decides whether F4 opens the console.
- **Adding a server command:** register it in `AdminService.Start` with `Conch.register(name, { permissions = { "permission-name" }, arguments = ..., callback = ... })`, or in an `AdminService/Commands.luau` child once there are several. Client-only commands go in `AdminController.Start`.
- **Every server command must list at least one permission.** Conch lets anyone run a command with an empty `permissions` list. `super-user` holds every permission.
- **Validate arguments in the callback.** Conch passes the arguments the client sent straight to the callback without checking their types, so check them (`typeof`, ranges, that a player is still in the game) as you would for a Packet handler.
- Never add a command that grants roles or edits `AdminConfig` at runtime. Change admins in `AdminConfig` and redeploy.
- Commands that change player data use `PlayerData.Get(player)` like any other server code.

### Debug UI

`DebugController` runs [Iris](https://sirmallard.github.io/Iris/) for admins only (`Utils/IsAdmin`, so everyone in Studio). Other players never create any Iris UI. **F3** toggles a Debug window with FPS, the player's `Cash`, and a checkbox for Iris's demo window, which shows every available widget.

- Add debug panels inside the `Iris:Connect` callback in `DebugController`, or in a `DebugController/Panels.luau` child once there are several. Like the admin console, Iris builds UI in code; the "build UI in Studio" rule does not apply to it.
- Debug panels only show and tweak values. Anything that changes server state goes through a Conch command or a Packet request that the server validates, never straight from an Iris button.
- Keep work in the callback light: it runs every frame for admins, even while the window is closed.

### Assets

Images, sounds, videos, animations and models that code references live as files in `assets/` and are uploaded with [Asphalt](https://github.com/jackTabsCode/asphalt). Art placed in the world is still built and saved in Studio.

- **Syncing:** `lune run assets` uploads new or changed files under the group in `asphalt.toml` and regenerates `src/shared/Assets.luau`. It refuses to run while `[creator] id` is the `0` placeholder. Uploads need an Open Cloud API key with `asset:read` and `asset:write`, created under that group, in the `ASPHALT_API_KEY` environment variable. Never put the key in a file in the repo. `lune run assets debug` processes files locally without uploading.
- **Using an asset:** `require(ReplicatedStorage.Assets)` gives a typed table that mirrors `assets/` without file extensions: `assets/Images/Logo.png` is `Assets.Images.Logo`, an `rbxassetid://` string. Never hard-code asset IDs in code.
- **Already on Roblox:** add existing assets to `[inputs.Assets.web]` in `asphalt.toml` (`"Images/Logo.png" = { id = 123 }`) so they appear in `Assets` without uploading.
- Commit `assets/`, `asphalt.lock.toml` and the generated `Assets.luau` so others can build without an API key. Never edit `Assets.luau` by hand; StyLua skips it.
