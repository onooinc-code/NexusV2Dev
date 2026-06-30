const fs = require('fs');
const file = 'c:/Users/hedra/Desktop/Sourcecode/NexusV2/Nexus-backend/app/Models/MCPServer.php';
let code = fs.readFileSync(file, 'utf8');

code = code.replace(
  "return $this->belongsToMany(Agent::class, 'agent_mcp_servers');",
  "return $this->belongsToMany(Agent::class, 'agent_mcp_servers', 'mcp_server_id', 'agent_id');"
);

fs.writeFileSync(file, code);
