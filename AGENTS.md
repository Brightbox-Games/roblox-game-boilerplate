# Game Boilerplate — agent instructions

## Code style

- Do not add comments to code. Luau directives such as `--!strict` are allowed.
- Keep `--!strict` at the top of every Luau file. Run `lune run check` before handing off code changes.
- The project uses Luau's new type solver: `luau-lsp.fflags.enableNewSolver` in `.vscode/settings.json`, which `lune run check` also reads. In Studio, set **Workspace > UseNewLuauTypeSolver** to `Enabled` so Script Analysis matches.
- Format with StyLua (tabs, 110 columns, double quotes). Never edit generated `Packages/`, `build/`, `sourcemap.json`, `*.test.rogen.json` or `*.project.json`.

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

Tools are pinned in `rokit.toml`: Rojo, Rogen (writes the Rojo project files), Wally, StyLua, wally-package-types, luau-lsp, Lute (the require lint), Lune, Asphalt, and the offline engine tools ree, ror and rur-native (see Testing, profiling and previews). The only prerequisite is [Rokit](https://github.com/rojo-rbx/rokit). Project scripts are Lune scripts in `.lune/`, run from the project root.

```sh
rokit install
lune run install
lune run dev
```

- `rokit install` installs the pinned tools. On first run it asks the user to trust each new tool author; that prompt needs a real terminal, so ask the user to run it rather than bypassing it.
- `lune run sourcetools` (optional) builds ree, ror and rur from source at the versions `rokit.toml` pins, into `~/.local/share/anime-vanguards` (`ANIME_VANGUARDS_HOME` to move it), and unlocks the features listed under "Source-build features". It needs Rust 1.90 or later (macOS: `brew install rustup && rustup default stable`), Node 18 or later, and Roblox Studio installed for fonts and textures. Rerun it after bumping those pins. It applies `patches/<tool>/*.patch` after each checkout and resets local edits in the checkouts.
- `lune run install` downloads the Roblox type definitions (`globalTypes.d.luau`, Git-ignored) if missing, runs `wally install`, then `wally-package-types` on `Packages` and `DevPackages` so package types (such as `Signal.Signal<T...>`) are visible to strict code. Run it on a fresh clone and after changing `wally.toml`; never run bare `wally install`.
- On Windows, `./scripts/install.ps1` and `./scripts/check.ps1` are thin wrappers: `install.ps1` runs `rokit install` then `lune run install`, and `check.ps1` runs `lune run check`. Keep logic in the Lune scripts, not the wrappers.
- `lune run dev [place]` (default `game`) writes the project files and sourcemap, then runs `rogen sourcemap <place>.test --watch` (keeps the place's test project and `sourcemap.json` current for the editor) and `rogen serve <place>` (rewrites the place's project file as folders appear) together.
- Each place has a config, `<place>.rogen.json`; the first place is `game` (see Places). `<place>.project.json` is the place. `<place>.test.project.json` is the same tree plus `DevPackages` (test-only packages) and `tests/` as `ReplicatedStorage.Tests`; type checking, the offline tools and, for `game`, the editor use it. Never serve or build a test project: it would put test code in the place.
- Connect the Rojo plugin in Studio to `localhost:34873`. Once the game has a place, add `"servePlaceIds": [<placeId>]` to `game.rogen.json`.
- In Studio, enable **Game Settings > Security > Enable Studio Access to API Services** (the place must be published). Without it (or in an unpublished place), Scribe saves to an in-memory store: everything works, but data resets when Play stops, and output shows `[ProfileStore]: Roblox API services unavailable - data will not be saved`. Live servers always have DataStore access.
- In Play, output shows `[Game Boilerplate] Server services ready`, `Client controllers ready` and a Packet round trip. Both Bootstraps set a `Ready` attribute.
- `lune run check` is the one command to run after every change. It formats `src`, `.lune` and `tests` with StyLua, rejects empty folders in `src`, writes the project files and runs `rogen check` (any routing warning fails), then for every place regenerates the sourcemap, runs luau-lsp type and lint analysis and the `require_boundaries` lint (see Require boundaries) on that place's files, and does a Rojo build of `<place>.project.json` into `build/<place>.rbxlx`. `lune run check --frozen` checks formatting and project files without writing them, for CI. Fix every error it reports and rerun it until it passes.
- `rojo build` output is code-only, not a replacement for the authored place.
- **Starting a new game from this boilerplate:** set `Name` in `src/common/Features/Game/GameConfig@Shared.luau`, set `name` in `game.rogen.json`, set `[creator] id` in `asphalt.toml` to the game's Roblox group ID, put the game's admins in `src/common/Core/Access/AdminConfig.luau`, and add `servePlaceIds` once the place exists.

## Layout

Code is grouped by layer, then by feature. Shared code is in `src/common`; each place (see Places) adds `src/<place>`. Rogen routes each file by its folder names (see Rogen).

| Layer | Holds | May require |
| --- | --- | --- |
| `Base` | Pure Luau with no Roblox or game knowledge: `Lifecycle`, `RateLimit` | Nothing outside itself |
| `Platform` | Roblox-aware, game-agnostic modules: `Packet`, server `EditorOnly` | `Base` |
| `Core` | Features the others build on: `Data` (`DataService`, `PlayerData` with `Products`), `Sync` (`SyncService`, `SyncController`), `Access` (`IsAdmin`, `AdminConfig`), `Packets`, `Assets` (generated) | `Base`, `Platform` |
| `Features` | Game features: `Admin`, `Components` (game-agnostic components such as `Spinner`), `Debug`, `Game` (`GameService`, `AppController`, `GameConfig`), `UI` | `Base`, `Platform`, `Core` |
| `App` | The composition roots: `Bootstrap`, `Registry` and the component loader (`ComponentService`, `ComponentController`) on each side | Anything |

Every layer may also require `Packages`. In `Features`, a module requires only its own feature, so features never require each other. In `Base`, `Platform` and `Core`, a module may also require other features of its own layer (a Core feature can build on `Data`); keep those dependencies one-way, since Luau errors on a require cycle.

| Files | Studio destination |
| --- | --- |
| `src/common/<Layer>/<Feature>/<Name>@Server.luau` | `ServerScriptService.<Layer>.<Feature>.<Name>` |
| `src/common/<Layer>/<Feature>/<Name>@Client.luau` | `StarterPlayer.StarterPlayerScripts.<Layer>.<Feature>.<Name>` |
| `src/common/<Layer>/<Feature>/<Name>@Shared.luau` | `ReplicatedStorage.<Layer>.<Feature>.<Name>` (visible to clients) |
| `src/common/<Layer>/<Name>@<Side>.luau`, `*.server.luau`, `*.client.luau` (`Base`, `Platform`, `App`, `Core/Packets`) | `<Service>.<Layer>.<Name>` |
| `src/<place>/...` | The same paths, in that place only |
| `Packages` | `ReplicatedStorage.Packages` (generated Wally dependencies) |
| `tests`, `DevPackages` | `ReplicatedStorage.Tests`, `ReplicatedStorage.DevPackages`, in test projects only; never in the game |

So `src/common/Core/Data/DataService@Server.luau` is `ServerScriptService.Core.Data.DataService`, `src/common/Base/Lifecycle.luau` (in a folder marked `@Shared`) is `ReplicatedStorage.Base.Lifecycle`, and `src/common/App/Registry@Server.luau` is `ServerScriptService.App.Registry`.

- Edit code on disk; Rojo syncs it. The `@Side` suffix comes off the name in the game. A feature has only the sides it needs.
- Rojo owns mapped folders. Unknown children at service roots are preserved. Workspace, lighting, GUI and other art are edited and saved in Studio, not on disk.
- Tag authoring-only content in Workspace (prefab libraries, reference models, anything the game reads from a copy elsewhere) `EditorOnly`. `Bootstrap.server.luau` moves tagged instances into `ServerStorage.EditorOnly` before any system starts, so they stay editable in Studio but are never replicated to players. Never tag something code reads from Workspace.
- Server-only code (secrets, rules, data) is `@Server`. Everything `@Shared` is visible to clients.
- Put tunable constants in a frozen table named after the feature, `@Shared` (`src/common/Features/Game/GameConfig@Shared.luau`), or `@Server` if clients must not see them.
- Put pure logic in plain modules (such as a system's `Catalog.luau`) with no service dependencies.
- New game code goes in a feature in `Features`. Move a feature down to `Core` only when other features must build on it; player data stays in `Core/Data` in `src/common` so every place shares one store. Reusable, game-agnostic helpers go in `Base` if they need nothing from Roblox, or in `Platform` (as `<Name>@Shared.luau`, or `@Server` if server-only) if they do, one module per helper. Helpers used by a single feature stay in that feature.

### Requires

- Require by instance path: `require(ReplicatedStorage.Core.Access.IsAdmin)`, `require(ReplicatedStorage.Core.Data.PlayerData)`, `require(script.Parent.AdminConfig)` within a folder. `rogen where <file>` prints the require that reaches a file.
- Client code under `StarterPlayerScripts` is cloned into each player, so it reaches its own side through `script` (`require(script.Parent.Parent.Features.Admin.AdminController)` in the client `Registry`), never through `StarterPlayer`. `rogen where` prints no require for these files for the same reason.
- Follow the layer table: lower layers never require higher ones, features never require each other, and modules reach other systems through the registry (see Using other systems). Shared code never requires server or client code, and client code never requires server code. Only `App` requires every layer. `lune run check` enforces all of this (see Require boundaries), and luau-lsp fails on a require that no longer matches the tree.

## Rogen

[Rogen](https://rogen-roblox.vercel.app/docs/v2) writes the Rojo project files from folder names, so a file's path on disk is not its path in the game.

- `<place>.rogen.json` is the only project config you edit. Its `routes` send `Server` to `ServerScriptService`, `Client` to `StarterPlayer/StarterPlayerScripts` and `Shared` to `ReplicatedStorage`. Its `sourcePaths` are `src/common` then `src/<place>`. Its `tree` holds what names cannot place, such as `Packages`. Put `servePlaceIds` and other Rojo keys there.
- Every file names its side, one of these ways:
  - A suffix on the name: `ShopService@Server.luau`, `ShopController@Client.luau`, `ShopConfig@Shared.luau`. Rojo's `Bootstrap.server.luau` and `Bootstrap.client.luau` route by themselves.
  - A folder module takes the suffix on the folder, `PlayerData@Shared/` with `init.luau`; its children carry no suffix.
  - A folder whose files all run on one side holds an empty marker file named `@Shared`, `@Server` or `@Client`, and its files carry no suffix (`Base`, `Core/Access`).
- A feature is a folder in a layer, and its files sit directly in it: `src/common/Features/Shop/ShopService@Server.luau` is `ServerScriptService.Features.Shop.ShopService`. Do not add `Server/`, `Client/` or `Shared/` folders. Several files on one side that belong together go in a folder with the suffix, `Commands@Server/`, which is a folder in the game.
- The outermost route wins: a `@Server` file inside a folder marked `@Shared` ships to clients. Never mix sides inside a marked or suffixed folder.
- There is no `*` fallback route: a file that names no side is left out of the game, so server code that forgets its route never reaches clients, and `lune run check` fails on it. Rogen's `^` and `(...)` names are not used here.
- `rogen where <file>` prints where a file lands, and the require that reaches it, in each place that reads it; `rogen where <place>.rogen.json` lists every file of a place, and `rogen where game ServerScriptService.Core.Data.DataService:18` maps an error line from Studio back to the file. In a worktree nested inside another checkout (such as `.claude/worktrees/`), Rogen finds the outer checkout's project file first, so name the config there.
- Run `lune run check` after adding, moving, renaming or deleting files. It rewrites the project files, and `rogen check` fails on any routing warning. A new file inside a marked folder or a folder module needs nothing else; any other new file, a new feature or an override in a place changes the project files, which `lune run check` writes, so commit them with your change. Delete folders you empty: Rogen maps an empty folder, Git does not keep it, so `lune run check` fails on one.
- Each place's `<place>.project.json` and `<place>.test.project.json` are generated and committed, so plain Rojo still works without Rogen. `.lune/Project.luau` generates `<place>.test.rogen.json` (Git-ignored) from each place's config; never edit it or a project file. `lune run check --frozen`, for CI, fails when a committed project file is out of date.
- Client code reaches its own side through `script.Parent`, never through `StarterPlayer` (see Requires).

## Places

Every `<place>.rogen.json` except the generated `*.test.rogen.json` is a place, a separate Roblox place of the same game. `game` is the first. Each place reads `src/common`, then its own `src/<place>`; a file in `src/<place>` replaces the `src/common` file at the same path, so a place overrides a module (or a whole `Registry.luau`, to add place-only systems) by copying it to the same path in its folder. Place-only features go in `src/<place>/Features/<Feature>/`. A place with no files of its own keeps a `.gitkeep`, as `src/game` does, so its source path exists.

`lune run check` and `lune run test` cover every place. `lune run dev <place>` serves one. `lune run ree` and `lune run rur` mount the place named by the `PLACE` environment variable, `game` by default: `PLACE=lobby lune run ree run --harness tests/Server/Boot.luau --run-context server`.

**Adding a place:**

1. Copy `game.rogen.json` to `<place>.rogen.json`, set `name`, a free `servePort` (the game uses `34873`) and `"sourcePaths": ["src/common", "src/<place>"]`.
2. Create `src/<place>` with the place's own files, or a `.gitkeep`.
3. Run `lune run check` and `lune run test`, and commit the config and both generated project files.

## Require boundaries

`lune run check` runs [Lute](https://lute.luau.org)'s `require_boundaries` rule (`lints/require_boundaries.luau`, configured in `.config.luau`) on each place's files. It reads the sourcemap, follows each instance-path `require`, and fails on shared code that requires a side, client code that requires server code, a lower layer that requires a higher one, a module that requires another feature of its own layer, and a require of an instance no file provides.

- `layers` lists the layers from lowest to highest: `Base`, `Platform`, `Core`, `Features`, `App`. The highest layer may require any layer and feature; side rules still apply to it. Instances outside the layers, such as `Packages`, may be required from anywhere.
- A crossed boundary means the code is in the wrong place: move it down a layer, or reach the other system through the registry. Ask the user before changing `layers`.
- The rule sees only requires it can resolve statically (`script`, `game:GetService`, `.Name`, and `WaitForChild`/`FindFirstChild` with a string).
- The rule is our fork of Rogen's: it adds the `layers` option. Rogen's MIT license is in `lints/LICENSE`; port upstream fixes by hand.

## Systems

A system is a service (server) or controller (client): a ModuleScript table run by `ReplicatedStorage.Base.Lifecycle`. It is a `@Server` or `@Client` file in its feature folder, or a folder module with that suffix once it has several files.

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
- constants: use the feature's config module (see Layout),
- stateless helpers: use a plain module next to the code that uses it, or in `Base` or `Platform` if several features need it.

If a system's methods start being about two unrelated things, or other systems keep reaching into its data, split it into two systems.

### Structuring a system across files

Keep each system's concerns in separate files. Once a system has more than one concern (or its file passes about 300 lines), turn it into a folder. Rojo maps a folder containing `init.luau` to a single ModuleScript with the other files as its children, so the registry `require` does not change.

```text
src/common/Features/Shop/ShopService@Server/
	init.luau
	Catalog.luau
	Purchasing.luau
	Types.luau
src/common/Features/Camera/CameraController@Client/
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
local PlayerData = require(ReplicatedStorage.Core.Data.PlayerData)
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
local Packets = require(ReplicatedStorage.Core.Packets)
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

`UIController` (`src/common/Features/UI/UIController@Client`, the `UI` feature) owns every screen, whichever feature it belongs to. Screens are [Vide](https://centau.github.io/vide/) components built in code; it ships one example, `Hud`.

**Build UI in code with Vide, not in Studio.** Do not author ScreenGuis in StarterGui. Check layout with rur (see Testing, profiling and previews), not the Studio MCP.

```text
src/common/Features/UI/UIController@Client/
	init.luau
	Types.luau
	ScribeVide.luau
	Screens/
		<Name>.luau
```

- **Adding a screen:** add `Screens/<Name>.luau` using the template below, and `<Name> = require(script.Screens.<Name>)` to the `modules` table in `init.luau`.
- **What `init.luau` does:**
  - Creates a ScreenGui per screen, named after it, under PlayerGui (`ResetOnSpawn = false`, `ZIndexBehavior = Sibling`, the screen's `DisplayOrder`), mounts the screen's `Render` into it with `Vide.mount`, and binds `Enabled` to the screen's open state.
  - Keeps each screen's open state in a Charm signal, closes other modals when a modal opens, and unmounts and destroys everything in `Destroy`. A screen whose `Render` errors is disabled with a warning; the others still mount.
  - Creates a [TopbarPlus](https://1foreverhd.github.io/TopbarPlus/) icon for a screen with `Topbar`. The icon opens and closes the screen, and follows it when something else opens or closes it.
- **API for other systems:** `UIController:Open(name)`, `UIController:Close(name)`, `UIController:IsOpen(name)`, and `UIController:OpenState(name)`, a Charm getter for use in effects.
- **Screen contract** (`Types.luau`): a screen module returns a table with `Modal`, `StartsOpen`, optional `DisplayOrder`, optional `Topbar = { Label?, Image?, Order? }`, and `Render(context): Instance`.
  - `Render` runs once, inside the screen's Vide root, and returns the content (usually one Frame) that goes in the ScreenGui. Do not return a ScreenGui.
  - Vide reruns only what reads a source: pass a function for a property that changes (`Text = function() return `Cash: {cash()}` end`), a plain value for one that does not.
  - Release anything that is not a Vide instance with `Vide.cleanup(function() stop() end)`; Trove is not used in screens.
  - Non-modal screens (HUD, notifications) can be open together. Opening a modal screen (shop, settings) closes other modals.
- **What screens receive:** `context.Controllers` (the controller registry), `context.Open` and `context.Close`. Screens never require each other; open another screen through `context.Open`. Screens are part of the `UI` feature, so they reach other features through `context.Controllers`, and `Core` (such as `PlayerData`) directly, never by requiring another feature's modules.
- **Reading state** (see State):
  - Player data: `local cash, stop = useScribe(PlayerData.Client.Cash)` with `local useScribe = require(script.Parent.Parent.ScribeVide)(Vide)`, then `Vide.cleanup(function() stop() end)`. `ScribeVide.luau` is Scribe's official adapter; copy it again from Scribe's `addons/ui` when upgrading Scribe.
  - Charm signals another system exposes: `VideCharm.useSignalState(getter)` returns a Vide source.
  - State only the screen uses: `Vide.source(initial)`.
- **What screens may do:** send requests through `Packets` and display state. They never decide outcomes.
- **Vide types:** `Vide.create` is typed only for common classes (Frame, TextLabel, TextButton, ImageLabel, ScrollingFrame, UICorner, UIListLayout, UIGridLayout, UIGradient, ScreenGui, ...). For others (`UIPadding`, `UIStroke`, `UIScale`, `UIFlexItem`), use `local createAny = Vide.create :: any`, as `Hud` does.
- **Complex client logic** such as a placement preview goes in its own controller, which the screen calls through `context.Controllers`.

```lua
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerData = require(ReplicatedStorage.Core.Data.PlayerData)
local Vide = require(ReplicatedStorage.Packages.Vide)
local ScribeVide = require(script.Parent.Parent.ScribeVide)
local Types = require(script.Parent.Parent.Types)

local create = Vide.create
local useScribe = ScribeVide(Vide)

local Shop: Types.Screen = {
	Modal = true,
	StartsOpen = false,
	Topbar = { Label = "Shop", Order = 1 },
	Render = function(context: Types.Context): Instance
		local cash, stopCash = useScribe(PlayerData.Client.Cash)
		Vide.cleanup(function()
			stopCash()
		end)

		return create("Frame")({
			Name = "Shop",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(400, 300),
			create("TextLabel")({
				Size = UDim2.new(1, 0, 0, 32),
				Text = function()
					return `Cash: {cash()}`
				end,
			}),
			create("TextButton")({
				Position = UDim2.new(1, -32, 0, 0),
				Size = UDim2.fromOffset(32, 32),
				Text = "X",
				Activated = function()
					context.Close("Shop")
				end,
			}),
		})
	end,
}

return Shop
```

### State

Each kind of state has one home:

| State | Where | How the UI reads it |
| --- | --- | --- |
| Per-player, saved or replicated to its owner | Scribe (`Core/Data`, see Player data) | `ScribeVide` |
| Global, owned by the server, every client sees it (round phase, timers, events) | A Charm signal in the owning service, synced by `Core/Sync` | `VideCharm.useSignalState` on the controller's getter |
| Client-only, shared between systems (selected item, settings) | A Charm signal in the owning controller | `VideCharm.useSignalState` |
| Local to one screen | `Vide.source` inside `Render` | Directly |

- [Charm](https://github.com/littensy/charm): `local getRound, setRound = Charm.signal("Lobby")`; `Charm.computed(fn)` derives, `Charm.effect(fn)` reruns when signals it reads change, and `Charm.listen`/`Charm.subscribe(getter, callback)` react to one value. Each returns a stop function: add it to the system's Trove with `trove:Add(function() stop() end)`. Tables in signals are immutable: set a new table (`setState(table.clone(...))`), never mutate the current one.
- Expose a signal's getter, never its setter, as a field of the owning system (`AppController.PlayerCount`), so only the owner changes it.
- Do not mirror Scribe data into Charm or sync per-player data through `Core/Sync`.

**Syncing global state (`Core/Sync`):** `SyncService` sends registered Charm getters to every client through [charm-sync](https://github.com/littensy/charm#client-server-sync), as delta patches over the `Sync` packet (`Packet.Any`, server to client only). Each client asks once with `SyncReady`.

1. On the server, in the owning service's `Init`: `services.SyncService:Add("<Feature>.<Name>", getter)`.
2. On the client, in the owning controller's `Init`: create a signal of the same type and `controllers.SyncController:Add("<Feature>.<Name>", setter)`. Register in `Init`, never later: the first patch arrives right after every controller's `Init`, and a patch for an unregistered key is dropped with a warning.
3. Expose the client getter on the controller for screens and other systems.

`GameService` and `AppController` do this for `Game.PlayerCount`, which `Hud` shows. Keys are `<Feature>.<Name>` and must match on both sides. A value that becomes `nil` is removed on the client (charm-sync sends it as `None`, which `patch` applies). Synced values must be plain data: no Instances or functions.

### Adding a system

1. Create `src/common/Features/<Feature>/NameService@Server.luau` or `src/common/Features/<Feature>/NameController@Client.luau`, in an existing feature or a new feature folder (`src/<place>/Features/...` for a place-only system).
2. Return a plain table with a unique `Name` matching the file name, and optional `Init`, `Start` and `Destroy`. Do not annotate it as `Lifecycle.System`: that type is read-only, so defining methods on an annotated table fails. The registry's `{ Lifecycle.System }` list checks the shape.
3. Add a `require` to that side's registry, after every system it depends on: `require(ServerScriptService.Features.<Feature>.NameService)` in `src/common/App/Registry@Server.luau`, `require(script.Parent.Parent.Features.<Feature>.NameController)` in `src/common/App/Registry@Client.luau`. A place-only system goes in the place's copy of the registry (see Places).

```lua
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerData = require(ReplicatedStorage.Core.Data.PlayerData)
local Packets = require(ReplicatedStorage.Core.Packets)

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

The matching packet in `Core/Packets@Shared.luau` would be `GetCash = Packet("GetCash"):Response(Packet.NumberF64):RateLimit(5, 1)`, and a controller calls it with `local cash = Packets.GetCash:Fire()`.

### Lifecycle rules

- Order: every system's `Init` runs in registry order, then every `Start` in registry order. Startup happens once per session; there is no hot reload.
- `Init(self, registry)` receives the complete name-to-system table. Store it and set up local state only. Do not call other systems here: they may not be initialised yet.
- `Start(self)` connects events, binds packets and begins work. Other systems are safe to call from here on.
- Hooks must return promptly. Never yield or run permanent loops inside them; use `task.spawn` or connections instead.
- `Destroy(self)` disconnects connections, destroys instances and cancels owned threads. It must tolerate a partially completed `Init` and being called when `Start` never ran.
- Module loading must have no side effects: no connections, instances or yields at require time. The one exception is `ReplicatedStorage.Core.Data.PlayerData`: Scribe starts its player listeners (and `ProcessReceipt`, once products exist) the first time it is required, which is while the registries load.
- Errors in `Init`/`Start` are reported as `[System.Phase]`; the lifecycle then destroys initialised systems in reverse order and stops startup. Duplicate names and repeated starts are rejected.
- The server calls `Destroy` through `BindToClose`; the client bootstrap does so when destroyed. Both bootstraps set a `Ready` attribute once startup succeeds.

### Using other systems

- Access other systems through the registry captured in `Init` (`services.UIController:Open("Shop")`), not by requiring their modules directly. `PlayerData` is not a system: require it directly so its data stays typed. Direct requires break when the registry order changes and hide dependencies.
- Dependencies must point one way. If two systems need each other, give one a `Signal` (`ReplicatedStorage.Packages.Signal`) that the other connects to in `Start`, as `DataService.PlayerLoaded` does.
- Clean up with Trove (`ReplicatedStorage.Packages.Trove`), not hand-kept connection lists. A system keeps a module-level `local trove = Trove.new()`, uses `trove:Connect(signal, handler)` in `Start`, and calls `trove:Clean()` in `Destroy`; see `DataService` and `DebugController`. Wrap stop functions from packages (Scribe's `Observe`, `Iris:Connect`) in a closure, `trove:Add(function() stop() end)`: the new solver rejects a typed function value passed directly.

### Components

Use a component for behaviour attached to many tagged instances (doors, pickups, hazards, spinners). Use a system for game-wide state. Components use the Component package and CollectionService tags.

- A feature's components live in a `Components@Client/` or `Components@Server/` folder in that feature: `src/common/Features/Shop/Components@Client/ShopSign.luau`, `src/common/Features/Shop/Components@Server/Door.luau`. Game-agnostic components live in the `Components` feature next to the loaders, as `Spinner` does.
- Add the module's `require` to the `factories` list in `ComponentController` (`src/common/App/ComponentController@Client.luau`, for example `require(script.Parent.Parent.Features.Shop.Components.ShopSign)`) or `ComponentService` (`src/common/App/ComponentService@Server.luau`, for example `require(ServerScriptService.Features.Shop.Components.Door)`). The loaders are in `App` because they require every feature's components.
- A component module returns a factory `function(registry)` that creates and returns the class. The loader calls it in `Start`, so requiring the module has no side effects, and the component can reach systems through the registry.
- Cast the class to `any` and type `self` explicitly, because the package's inferred types do not work in strict mode. `src/common/Features/Components/Spinner@Client.luau` is the example: tag a part `Spinner` and optionally set a `SpinSpeed` attribute (degrees per second).
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

Packages are in `ReplicatedStorage.Packages`. Add new ones to `wally.toml` and run `lune run install`. Test-only packages (Jest) are `[dev-dependencies]` in `DevPackages`, which only the test projects map. There are no server-only packages; to add one, add a `[server-dependencies]` section to `wally.toml`, and mount `ServerPackages` at `ServerScriptService.ServerPackages` in the `tree` of every place's config. Commit `wally.toml` and `wally.lock`.

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
| `Vide` | Building UI in code; see UI. Pinned exactly (`=0.4.1`, also what Conch UI uses). |
| `Charm`, `CharmSync`, `VideCharm` | Charm signals for shared and global state, charm-sync for syncing them (only through `Core/Sync`), and `VideCharm.useSignalState` to read a signal in Vide; see State. Pinned exactly (0.x breaks APIs between minors). |
| `TopbarPlus` | Topbar icons. `UIController` makes them from a screen's `Topbar`; use it directly only for icons that are not screens. Untyped: require it as `:: any`. |
| `Scribe` | Saved, typed, replicated player data and developer products, configured only in `src/common/Core/Data/PlayerData@Shared`; see Player data. Pinned exactly (`=2.7.0`): read its changelog before upgrading. It bundles its own ProfileStore. |

Promise, Symbol and Signal also arrive as dependencies of Component and WaitFor. Do not add packages that duplicate these, Packet or Scribe (no Comm, Net, TypedRemote, ProfileStore, Replica, ReplicaService, Cmdr, Janitor or Knit) without the user's agreement.

### Networking

- Define every Packet channel in `src/common/Core/Packets@Shared.luau` (`ReplicatedStorage.Core.Packets`); a place adds its own channels by overriding that file. The server errors if a packet is defined after the first frame.
- `Packet(name, ...types)` declares an event; `:Response(...types)` makes it a request with a 10-second default timeout. Raise `ResponseTimeout` for anything that waits on a save.
- Services bind `OnServerEvent`/`OnServerInvoke` in `Start` and clear them in `Destroy`. Validate the sender, every argument and range on the server.
- Rate limit every packet the client can send by chaining `:RateLimit(count, window)`, allowing `count` calls per `window` seconds per player: `Buy = Packet("Buy", Packet.String):Response(Packet.Boolean8):RateLimit(5, 1)`. The server drops excess calls before they reach handlers (warning in Studio). A dropped request gets no reply, so the client's `Fire` returns `ResponseTimeoutValue` after `ResponseTimeout`; debounce buttons on the client so normal use never hits the limit.
- A packet without `:RateLimit` cannot be sent by clients at all: the server drops it (warning in Studio). Leave server-to-client packets unlimited so clients cannot fire them.
- `Packet.Instance` arguments from a client are either `nil` or a real Instance, nothing else, but the client chooses which one. Check that the player may act on it (owner, distance, ancestry) before using it.
- Length limits are in bytes: `String`, `Buffer`, `Characters` and `Any` strings take at most 255, `StringLong` and `BufferLong` at most 65,535, and arrays at most 65,535 elements. Sending a longer value errors in the sender and nothing is sent. Before sending player-supplied text (names, chat, textbox input), check its byte length on the server, or use `StringLong`.
- The server reads at most 8,000 bytes per player per heartbeat, counting every client batch as at least 800. A batch over the limit is dropped whole (warning in Studio), so keep client-to-server payloads small. An array from a client is rejected if it claims more elements than its message has bytes and Instances.
- Number arguments from a client can be NaN or infinite, and `Static` arguments can be `nil`. Check them before use.
- Never use `Packet.Any` in a packet clients can send. It accepts tables nested thousands deep with arbitrary keys, which a handler that walks or saves the value cannot safely handle. Declare a typed shape instead.
- `src/common/Platform/Packet@Shared` (`ReplicatedStorage.Platform.Packet`) is our fork of Suphi Kaner's Packet 1.7 with local security fixes: per-packet rate limits, rejecting unbuffered client messages, binding each awaited response to its packet, checking Instance and EnumItem arguments, bounding arrays by the size of their message, erroring on over-long values instead of corrupting the stream, and keeping sends alive when one fails. It always sends buffers: the upstream unbuffered mode (`Settings.UseBuffers`) has been removed. Do not replace it with an upstream or Wally copy; port upstream fixes by hand.
- For limits that are not per packet (per action, per target, shared across packets), use `ReplicatedStorage.Base.RateLimit` directly: `local limiter = RateLimit.new(3, 10)`, then `limiter:Allow(player)`. Call `limiter:Remove(player)` when the player leaves.
- Packet is for actions and Scribe is for player data. Clients send requests and receive events through Packet; the server's player data reaches clients through Scribe (see Player data). Do not add packets that mirror player data.
- Prefer Packet over RemoteEvents and RemoteFunctions. Use attributes only for simple values that belong to an instance, such as a plot's owner or the Bootstraps' `Ready`.

### Player data

Player data is saved, typed and replicated by [Scribe](https://ericplane.github.io/Scribe/), configured in `src/common/Core/Data/PlayerData@Shared/init.luau`. It stays in `src/common`, so every place uses one store. Read its docs before using a feature not described here.

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

- **Adding a developer product:** add `Name = { Id = productId, Grant = function(data, player) ... end }` to `src/common/Core/Data/PlayerData@Shared/Products.luau`. Scribe grants it, records the receipt in the player's profile, and confirms the purchase to Roblox only after a save contains both, so a crash cannot grant twice or lose a paid reward.
- **Grants change only the player's data**, such as `data.Cash.Increment(500)`. They must not yield, prompt or touch anything outside the profile; rewards outside the profile (server-wide effects, tools in the Backpack) are not protected against retries, so ask the user before adding them.
- `Products.luau` is inside `PlayerData@Shared`, so clients can read it. Product IDs are public anyway, but never put secrets or server-only logic in a grant.
- Prompt purchases by name from the client with `PlayerData.Client.PromptPurchase("Name")`; never grant from a client request.
- Game passes go in a `Passes` table in the Scribe options (`VIP = { Id = passId }`). Check ownership on the server with `PlayerData.Server.OwnsAsync(player, "VIP")`.

### Admin console

[Conch](https://alicesaidhi.github.io/conch/) is the admin console, in the `Admin` feature. `AdminService` starts it on the server and gives admins the `super-user` role; `AdminController` starts it on the client and binds **F4** for admins only. It is a package UI built in code, so the "build UI in Studio" rule does not apply to it.

- **Who is an admin:** `src/common/Core/Access/AdminConfig.luau` lists admin `UserIds`; with `AdminsInStudio`, everyone in a Studio session (Play, Team Test) is an admin. `ReplicatedStorage.Core.Access.IsAdmin` is the one check for both sides. The server's role check is what protects commands; the client check only decides whether F4 opens the console.
- **Adding a server command:** register it in `AdminService.Start` with `Conch.register(name, { permissions = { "permission-name" }, arguments = ..., callback = ... })`, or in an `AdminService/Commands.luau` child once there are several. Client-only commands go in `AdminController.Start`.
- **Every server command must list at least one permission.** Conch lets anyone run a command with an empty `permissions` list. `super-user` holds every permission.
- **Validate arguments in the callback.** Conch passes the arguments the client sent straight to the callback without checking their types, so check them (`typeof`, ranges, that a player is still in the game) as you would for a Packet handler.
- Never add a command that grants roles or edits `AdminConfig` at runtime. Change admins in `AdminConfig` and redeploy.
- Commands that change player data use `PlayerData.Get(player)` like any other server code.

### Debug UI

`DebugController` (`src/common/Features/Debug/DebugController@Client.luau`) runs [Iris](https://sirmallard.github.io/Iris/) for admins only (`ReplicatedStorage.Core.Access.IsAdmin`, so everyone in Studio). Other players never create any Iris UI. **F3** toggles a Debug window with FPS, the player's `Cash`, and a checkbox for Iris's demo window, which shows every available widget.

- Add debug panels inside the `Iris:Connect` callback in `DebugController`, or in a `DebugController/Panels.luau` child once there are several. Like the admin console, Iris builds UI in code; the "build UI in Studio" rule does not apply to it.
- Debug panels only show and tweak values. Anything that changes server state goes through a Conch command or a Packet request that the server validates, never straight from an Iris button.
- Keep work in the callback light: it runs every frame for admins, even while the window is closed.

### Assets

Images, sounds, videos, animations and models that code references live as files in `assets/` and are uploaded with [Asphalt](https://github.com/jackTabsCode/asphalt). Art placed in the world is still built and saved in Studio.

- **Syncing:** `lune run assets` uploads new or changed files under the group in `asphalt.toml` and regenerates `src/common/Core/Shared/Assets.luau` (`ReplicatedStorage.Core.Assets`, in `Core` so every feature may require it), then rewrites the project files. It refuses to run while `[creator] id` is the `0` placeholder. Uploads need an Open Cloud API key with `asset:read` and `asset:write`, created under that group, in the `ASPHALT_API_KEY` environment variable. Never put the key in a file in the repo. `lune run assets debug` processes files locally without uploading.
- **Using an asset:** `require(ReplicatedStorage.Core.Assets)` gives a typed table that mirrors `assets/` without file extensions: `assets/Images/Logo.png` is `Assets.Images.Logo`, an `rbxassetid://` string. Never hard-code asset IDs in code.
- **Already on Roblox:** add existing assets to `[inputs.Assets.web]` in `asphalt.toml` (`"Images/Logo.png" = { id = 123 }`) so they appear in `Assets` without uploading.
- Commit `assets/`, `asphalt.lock.toml` and the generated `Assets.luau` so others can build without an API key. Never edit `Assets.luau` by hand; StyLua skips it.

### Testing, profiling and previews

Three offline tools run the game's own Luau and draw Roblox content without Studio: **ree** (an emulated engine), **ror** (a 3D renderer) and **rur-native** (a UI renderer), all from [Anime-Vanguards](https://github.com/Anime-Vanguards). Use them before reaching for the Studio MCP for anything they cover; keep the Studio MCP for authoring world content, and for what they cannot simulate (physics beyond free fall, a client and server talking to each other). They are pinned exactly: their flags and output formats change between versions, so re-run `lune run test` and the commands below after a bump. They are GPL-2.0: use them as tools, never copy their code into this repo. Write their outputs under `build/` (Git-ignored).

**Tests (`lune run test`).** Runs every harness in `tests/Server` (as a Play-mode server) and `tests/Client` (as a client) through ree and fails on any `FAIL` line, any error, or a harness that never prints `@done`. It runs them once per place, each against that place's `<place>.test.project.json`. `tests/Server/Jest.luau` is the harness that runs every Jest spec. Run it after changing systems, networking, player data or controllers. It takes under a second.

**Jest specs.** Unit tests are [Jest](https://roblox.github.io/jest-roblox) specs, `tests/**/<Name>.spec.luau`, run unmodified Jest Roblox in a ree server. Write a spec for a module's behaviour (a helper, a system's child module, `Lifecycle`, `PlayerData` rules); write a harness only for whole-game boot checks and for code that needs native requires. `tests/Unit` has examples.

- Start with `local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)` and take `describe`, `it`, `expect` and `jest` from it. Require the module under test normally; each spec file gets fresh copies of the modules it requires.
- All spec files share one ree run: one `Players` service and one in-memory DataStore. Give each spec's players unique names and remove them at the end.
- `toThrow` sees the innermost error. For code that catches and rethrows with its own message (`Lifecycle`'s `[System.Phase]`), assert with `pcall` and check the message, as `Lifecycle.spec` does.
- Jest's runtime cannot resolve `@self/...` requires, which Charm, CharmSync and VideCharm use, so a spec cannot require them or anything that does (systems that use Charm, UI screens). Test those in a harness instead; `tests/Server/Sync.luau` runs charm-sync through `Packet.Any`.
- `print` inside a test is captured by Jest. Warnings code under test emits (Scribe's anomalies, the known emulator gaps) appear in the run's output and are expected.
- ree has no `debug.loadmodule` or `loadstring`, which Jest needs, and lacks a Studio service Jest probes. `tests/Server/Jest.luau` shims both; if a ree or Jest upgrade breaks specs, start there. The shim rewrites `export type` to `type` while loading modules, which is safe because nothing exports types at runtime.

- A harness is a module returning `function(context: any)`. It prints `PASS <label>` / `FAIL <label>` for each check and `@done` at the end; copy the `check` helper from `tests/Server/Boot.luau`.
- ree does not run Scripts, so a harness starts the systems itself, as the Bootstraps do: `Lifecycle.new(require(...Registry))` then `:Start()`, and `:Destroy()` at the end.
- A server run has empty in-memory DataStores every run, no players until the harness adds one (`Instance.new("Player")` parented to `Players`), and `FireClient` reaches no client. Test data flows through `DataService.PlayerLoaded` and `PlayerData.Get`, as `tests/Server/Boot.luau` does.
- A client run has no server, so anything that waits for the server at load must be stood in for. `tests/Client/Boot.luau` replaces `Packets` with `context.StandIn` and creates the `ScribeTransport` and `conch_networking` remote folders; reuse that setup. When a package upgrade renames those remotes, update the stand-ins.
- Known emulator gaps the runner allows, and nothing else: Scribe's `SUBSYSTEM_HOOK_ERROR` naming `HasRobloxSubscription` (ree's Player lacks it), and Conch UI's `executor:257` layout error. Add a gap to `isKnownGap` in `.lune/test.luau` only after confirming it is the emulator, not our code.
- A `Start` that yields shows up here as a client or server that stalls: keep waits in `task.spawn`, as `AdminController` does.

**Ad-hoc runs and profiling.** `lune run ree run --harness <file> --run-context server --seconds 30` (or `client`) runs one harness, ending early at `@done`, with the place's test project mounted (`PLACE`, default `game`; see Places), and prints a JSON report of every output line. Add `--profile all --profile-out build/profile/<name>` to profile it, then read `ree profile report build/profile/<name>` (work per frame priced as a Roblox client pays it, top functions, allocations). Compare two profiles with `ree profile diff <before> <after>`.

**Performance work starts with a ree profile.** Before optimizing anything, write or reuse a harness that exercises the code (`tests/Server/Boot.luau` boots every service), profile it with `lune run ree run --harness <file> --run-context server --seconds 30 --profile all --profile-out build/profile/before` (or `--run-context client`), and read `ree profile report build/profile/before` to find the functions and lines that actually cost time. After the change, profile again into `build/profile/after` and compare with `ree profile diff build/profile/before build/profile/after`. Report the before and after numbers with the change. Do not optimize code the profile does not show as costly. Use Studio's MicroProfiler through the Studio MCP only for what ree does not simulate: physics, rendering and real network replication.

**3D previews (ror).** Record a harness that builds what you want to see, then render it: `lune run ree record --harness <file> --out build/ree/<name> --seconds 0.2`, then `lune run ror render build/ree/<name>/scene.rbxm --out build/ror/<name> --views iso` (also `front`, `top`, `turntable:8`). `lune run ror render` also takes `.rbxm`/`.rbxl` files directly.

**UI previews (rur-native).** `lune run rur render --module <file.luau> --dir build/rur/<name>` renders UI built by a module, with the project mounted as for `lune run ree`. Return the top Frame unparented; a module that returns a ScreenGui renders nothing, without a warning. For UI that needs a player, return `function(_target)` that parents the ScreenGui to `Players.LocalPlayer.PlayerGui` and add `--mode play --all-layers true`. `--model <file.rbxm>` renders a saved UI tree. Read `render.png`, and `scene.json` for every element's laid-out rectangle and text; output and errors from the module are in `scene.json` `diagnostics`. It does not see StarterGui in the place file.
- **Previewing a screen:** a module that creates `ReplicatedStorage.ScribeTransport` with `Down` and `Up` RemoteEvents (Scribe's client needs them), requires the screen from `StarterPlayer.StarterPlayerScripts.Features.UI.UIController.Screens.<Name>`, calls its `Render` inside `Vide.root` with a stand-in context (`Controllers` holding fake getters, such as `{ AppController = { PlayerCount = function() return 12 end } }`, and no-op `Open`/`Close`), and returns the Frame. Write it under `build/`.

**Use instead of the Studio MCP.** Reach for these before starting Play or running code in Studio. Each takes about a second or less unless noted. Write throwaway harnesses and variant files under `build/`; the `context.*` helpers are fields of the harness's argument.

- **Live-server branches:** add `--studio false` to `lune run ree run` and `RunService:IsStudio()` is false, as on a live server. Use it for code behind `IsStudio()`: `Core/Access/IsAdmin` and `AdminsInStudio`, the `PlayerData` / `PlayerData_Studio` store choice, Packet's Studio-only warnings. `tests/Client/Boot.luau` fails its admin check with it, as expected.
- **Leaks:** `local take = context.Census()` before the scenario, then `print(take())` after it, prints JSON of live threads (where made, where suspended, what resumes them), connections by the line that connected them, pending timers, and live instances by class and top-level parent. Take it twice; what only grows is the leak. Trees outside the DataModel show as `(nil) <Class> <Name>`.
- **What keeps something alive:** `print(context.Holders({ "Player Leaver" }))` explains orphaned roots whose "Class Name" starts with a filter: another instance's property, queued work, an engine pin, or the shortest Luau path from a module, handler, thread or the registry. Scribe's log ring keeps players named in its warnings until newer entries replace them; that is bounded, not a leak.
- **Who wrote a property:** after `local drain = context.TraceWrites({ "CFrame", "Text" }, 3)`, `drain()` returns every Parent write and every write of the listed properties since the last call, each with `Kind`, `Instance`, `Property`, `Old`, `New` and `Stack` (`Chunk:line`, innermost first). `"*"` watches every property and attribute.
- **Devices:** `--device touch|gamepad|phone` changes what `UserInputService` reports in a client run. `phone` is touch and prices profiled work at 2.77x desktop: use it to check a frame budget against a phone, not to rank code.
- **Randomness:** runs are deterministic. To try another outcome, pass `--context '{"Seed":7}'` and call `context.SetRandomSeed(context.Seed)` (math.random and later `Random.new()`) and `context.ReseedRandoms(context.Seed)` (Randoms already made).
- **Compare implementations:** `lune run ree profile try build/whatif/<Name>.luau --out build/whatif/<Name> --variants a,b` runs each variant at each size in a fresh engine and writes `compare.txt` (work, instructions, allocations and heap per call, and the winner) and `compare.json`; it exits 1 if the variants return different results. The file returns `{ sizes = { ... }, setup = function(n) ... end, variants = { { name = "a", run = function(data) ... end }, ... }, check = true }`. To compare a rewrite of a project module, use `module = "ReplicatedStorage/Base/RateLimit"` and `versions = { before = "<path>", after = "<path>" }` (paths relative to the file) with `setup(n, Module)` and `run(data, Module)`. The first variant is the baseline, and a dictionary runs in name order, so always pass `--variants`. It takes about 4 s; `--no-time` keeps the exact figures and takes about 0.4 s.
- **Draw cost:** `lune run ror cost build/ree/<name>/scene.rbxm --out build/ror/<name>-cost --views iso --fov 70` prints draw calls and triangles per pass for each view, what culling hides and the biggest savings, and writes `cost.json`, `<view>.draws.png` and `<view>.heat.png`. After a change, run it into a new `--out` with `--camera-from build/ror/<name>-cost --compare build/ror/<name>-cost`.
- **What a render shows:** render with `--ids`, then `lune run ror inspect build/ror/<name>` lists each view's parts by share of the image, and `--view iso --at x,y` names the part at a pixel. Read this before opening the PNG.
- **Visual regression:** render the second scene with `--ids --camera-from build/ror/<before>`, then `lune run ror diff build/ror/<before> build/ror/<after>` reports the share of changed pixels, their region and the parts that gained or lost pixels, and writes `<after>/diff/<view>.diff.png` (`--json` for JSON).
- **Motion over time:** `lune run ror video build/ree/<name>/scene.rbxm --playback build/ree/<name>/playback.json --duration 2 --size 960x540 --out build/ror/<name>-video` writes `sheet.png` (moments labelled with time and particle count; read this first), `video.mp4` and `summary.json`. Use it for tweens, spinners and particles. mp4 needs ffmpeg on PATH; otherwise pass `--format apng`.
- **Phone layout:** `lune run rur render --module <file> --dir build/rur/<name>-phone --viewport 844x390 --scale 1 --device touch`. Check numbers in `scene.json`, not only the PNG: `nodes[].rect` is `[x, y, w, h]` in logical pixels, `props.text` is the text, and a `text.lines[].width` larger than its node's width means overflow.
- **Clicks and keys:** `--actions '[{"t":0.6,"type":"click","node":"Panel.Buy"}]'` clicks a node by path suffix (or `x`/`y`); `key`, `text`, `wheel` and `drag` also work. Set `--time` after the last action. Prints from handlers land in `scene.json` `diagnostics.output`.
- **Animations:** `lune run rur sequence --module <file> --dir build/rur/<name>-seq --mode play --from 0 --to 0.5 --fps 30` writes `frames/00000.png`…, `trace.json` (per node, `[frame, x, y, w, h, rotation]` rows when they change), `video.mp4` and `video-quarter.mp4`. Check a tween's endpoints and overshoot in `trace.json`.
- **Still unavailable:** `ror studio calibrate` needs Windows. `ror compare` and `rur compare` work on macOS after `lune run sourcetools` (see below).

**Source-build features.** After `lune run sourcetools`, these also work. Each wrapper finds the checkouts itself.

- **Build scripts in one step:** `lune run ror render build/ror/<Name>.luau --views iso --out build/ror/<Name>` runs a script and renders what it puts in the Workspace, with the project mounted. The script returns `function(context) ... end`, like a ree harness. `lune run ror video` and `lune run ror cost` take scripts too.
- **In-world GUIs:** `lune run ror` renders draw SurfaceGuis and BillboardGuis. A render missing them warns `GUIs not drawn: rur not found`.
- **UI as text:** `lune run rur inspect tree build/rur/<name>` prints the laid-out tree with each element's rectangle, text, font size and text bounds; `node <path substring>` gives a node's full JSON, `at <x,y>` the elements under a point, `crop <path substring>` a zoomed image of one element. Use it before opening `render.png`.
- **UI regressions:** render before and after into two folders, then `lune run rur inspect diff build/rur/<before> build/rur/<after> --out build/rur/<name>-diff.png` lists added, removed and moved elements and the changed pixel share.
- **Profiles in depth:** `lune run ree profile render build/profile/<name> --view <view> --out - --format txt` prints a view as text; `--out <file.png>` draws it. Views: `issues` (allocation churn, cache misses, table growth), `source` (cost per line), `flame`, `calls`, `alloc`, `heap`, `timeline`, and `diff` with two folders. `lune run ree profile view build/profile/<name>` opens the interactive viewer in a terminal. A person can also open the profile's `report.html`, or drag `profile.speedscope.json` into https://www.speedscope.app.
- **Exports from an open Studio:** `lune run bridge` connects ror to the Studio MCP (robloxstudio-mcp must be running with its plugin **Connected**). While it runs, `lune run ror render Workspace.Map --studio "<place name>"` renders an instance from the open place, and `lune run ror studio export "<place name>" Workspace.Map --out build/ror/Map.rbxm` saves it, read-only. Prefer this to screenshots through the MCP when checking built content. Name an instance, not a service: `SerializationService` cannot export `Workspace` itself. `<place name>` is the name `get_connected_instances` reports.
- **Checking ror against Studio:** with `lune run bridge` running, `lune run ror studio open` opens ror's own capture place (`ror-capture.rbxl`) in Studio. Then `lune run ror compare build/ror/<Name>.rbxm --views iso,front --out build/ror/<Name>-compare` loads the model into that place, captures Studio's viewport and ror's render from the same cameras, and writes `studio.png`, `ror.png`, `diff.png`, `side-by-side.png` and per-view match scores. Use it before relying on ror renders for visual decisions about new content. `lune run ror studio status`, `studio luau -e <code>` and `studio capture` work on the capture place only. On macOS, captures come from robloxstudio-mcp at logical pixels (whatever size the Studio window gives the viewport), and ror cannot close the capture place: close its window in Studio when done (`studio open --restart` refuses while it is open). ror misses some Studio built-in textures on macOS (the SpawnLocation decal, for one), and compare reports these under `missing`. - **Checking rur against Studio:** with `lune run bridge` running and a scratch place open (`lune run ror studio open` gives one), `lune run rur compare --story <file> --viewport 800x480 --time 1 --studio ror-capture --out build/rur/<name>-compare` mounts the UI in that Studio, captures it, renders it with rur at the same scale and writes `studio.png`, `diff.png`, `side-by-side.png` and `report.json` (pixel agreement, and every GuiObject's rect matched by path). `--fixture <file.luau>` takes a fixture instead of a story. The wrappers set `RUR_STUDIO_MCP_PORT` to the bridge and, off Windows, `RUR_STUDIO_CAPTURE=engine`: Studio's own `CaptureService` at full Retina resolution, mounted under StarterGui and removed afterwards. Always pass `--studio` naming a scratch place, never the user's open place. The viewport must fit inside Studio's (`report.json` says so when it does not).
- The macOS support for ror is our local patch, `patches/ror/macos-studio.patch`, which `lune run sourcetools` applies after checking out the pinned tag; when bumping ror, rebase the patch and rerun sourcetools.
