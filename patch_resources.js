const fs = require('fs');
const file = 'c:/Users/hedra/Desktop/Sourcecode/NexusV2/Nexus-backend/routes/api.php';
let code = fs.readFileSync(file, 'utf8');

code = code.replace(/Route::resource\('mcp-servers',\s*\\?App\\?Http\\?Controllers\\?MCPServerController::class\);/g, "Route::apiResource('mcp-servers', \\App\\Http\\Controllers\\MCPServerController::class);");
code = code.replace(/Route::resource\('agent-personas',\s*\\?App\\?Http\\?Controllers\\?AgentPersonaController::class\);/g, "Route::apiResource('agent-personas', \\App\\Http\\Controllers\\AgentPersonaController::class);");

fs.writeFileSync(file, code);
