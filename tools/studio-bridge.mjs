import { readFileSync } from "node:fs";
import { createServer } from "node:net";
import { homedir } from "node:os";
import { join } from "node:path";

const listenPort = Number(process.env.STUDIO_BRIDGE_PORT ?? 58790);
const mcpPort = Number(process.env.ROBLOX_STUDIO_PORT ?? 58741);
const mcpUrl = `http://127.0.0.1:${mcpPort}`;

function token() {
	return readFileSync(join(homedir(), ".robloxstudio-mcp", "auth-token"), "utf8").trim();
}

async function callTool(name, body) {
	const response = await fetch(`${mcpUrl}/mcp/${name}`, {
		method: "POST",
		headers: { "content-type": "application/json", "x-mcp-auth": token() },
		body: JSON.stringify(body),
	});
	const text = await response.text();
	if (!response.ok) {
		throw new Error(`robloxstudio-mcp ${name} failed (${response.status}): ${text}`);
	}
	const json = JSON.parse(text);
	if (json && Array.isArray(json.content)) {
		const joined = json.content.map((part) => part.text ?? "").join("");
		if (json.isError) {
			throw new Error(joined);
		}
		try {
			return JSON.parse(joined);
		} catch {
			return joined;
		}
	}
	return json;
}

function rows(value) {
	if (Array.isArray(value)) return value;
	for (const key of ["instances", "standalone", "rows", "studios"]) {
		if (Array.isArray(value?.[key])) return value[key];
	}
	return [];
}

async function listStudios() {
	const studios = rows(await callTool("get_connected_instances", {})).map((row) => ({
		id: row.instance_id ?? row.instanceId ?? row.id,
		name: row.place_name ?? row.placeName ?? row.name ?? row.title ?? String(row.id),
	}));
	return { studios };
}

function returnedValue(result) {
	if (typeof result !== "object" || result === null) return result;
	for (const key of ["returnValue", "return_value", "returned", "result", "value"]) {
		if (key in result) return result[key];
	}
	return result;
}

async function executeLuau(args) {
	const result = await callTool("execute_luau", { code: args.code, instance_id: args.studio_id || undefined });
	const value = returnedValue(result);
	return typeof value === "string" ? value : JSON.stringify(value);
}

const tools = [
	{ name: "list_roblox_studios", description: "Open Studio windows", inputSchema: { type: "object", properties: {} } },
	{
		name: "execute_luau",
		description: "Run Luau in a Studio's edit DataModel and return what the chunk returned",
		inputSchema: {
			type: "object",
			properties: { studio_id: { type: "string" }, datamodel_type: { type: "string" }, code: { type: "string" } },
			required: ["code"],
		},
	},
];

async function handle(message) {
	if (message.method === "initialize") {
		return {
			protocolVersion: message.params?.protocolVersion ?? "2024-11-05",
			capabilities: { tools: {} },
			serverInfo: { name: "robloxstudio-mcp-bridge", version: "0.1.0" },
		};
	}
	if (message.method === "tools/list") return { tools };
	if (message.method === "tools/call") {
		const { name, arguments: args = {} } = message.params ?? {};
		if (name === "list_roblox_studios") {
			return { content: [{ type: "text", text: JSON.stringify(await listStudios()) }] };
		}
		if (name === "execute_luau") {
			return { content: [{ type: "text", text: await executeLuau(args) }] };
		}
		throw new Error(`unknown tool ${name}`);
	}
	if (message.method === "ping") return {};
	throw new Error(`unknown method ${message.method}`);
}

createServer((socket) => {
	let pending = "";
	socket.setEncoding("utf8");
	socket.on("data", (chunk) => {
		pending += chunk;
		let newline;
		while ((newline = pending.indexOf("\n")) >= 0) {
			const line = pending.slice(0, newline).trim();
			pending = pending.slice(newline + 1);
			if (!line) continue;
			let message;
			try {
				message = JSON.parse(line);
			} catch {
				continue;
			}
			if (message.id === undefined) continue;
			handle(message).then(
				(result) => socket.write(JSON.stringify({ jsonrpc: "2.0", id: message.id, result }) + "\n"),
				(error) =>
					socket.write(
						JSON.stringify({ jsonrpc: "2.0", id: message.id, error: { code: -32000, message: String(error.message ?? error) } }) + "\n",
					),
			);
		}
	});
	socket.on("error", () => {});
}).listen(listenPort, "127.0.0.1", () => {
	console.log(`studio bridge on 127.0.0.1:${listenPort} -> ${mcpUrl}`);
});
