return {
	lute = {
		lint = {
			rulepaths = { "lints" },
			ruleconfigs = {
				require_boundaries = {
					options = {
						sourcemap = "sourcemap.json",
						featureRoots = {
							"ServerScriptService",
							"StarterPlayer.StarterPlayerScripts",
							"ReplicatedStorage",
						},
						layers = { "Base", "Platform", "Core", "Features", "App" },
						isolatedLayers = { "Features" },
					},
				},
			},
		},
	},
}
