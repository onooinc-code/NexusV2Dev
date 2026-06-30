const fs = require('fs');
const file = 'c:/Users/hedra/Desktop/Sourcecode/NexusV2/Nexus-Frontend/store/index.ts';
let code = fs.readFileSync(file, 'utf8');

// Replace imports
code = code.replace(
  "import apiClient from '@/lib/api/client';",
  "import { ContactsApi, AgentsApi, WorkflowsApi, TasksApi, MemoryApi, MCPServersApi } from '@/lib/api';"
);

// Contacts
code = code.replace(/await apiClient\.get\('(\/contacts)'\)/g, 'await ContactsApi.getAll()');
code = code.replace(/await apiClient\.get\(`\/contacts\/\$\{id\}`\)/g, 'await ContactsApi.getById(id)');
code = code.replace(/await apiClient\.post\('(\/contacts)', payload\)/g, 'await ContactsApi.create(payload)');
code = code.replace(/await apiClient\.put\(`\/contacts\/\$\{id\}`, payload\)/g, 'await ContactsApi.update(id, payload)');
code = code.replace(/await apiClient\.delete\(`\/contacts\/\$\{id\}`\)/g, 'await ContactsApi.delete(id)');

code = code.replace(/await apiClient\.get\(`\/contacts\/\$\{id\}\/timeline`\)/g, 'await ContactsApi.getTimeline(id)');
code = code.replace(/await apiClient\.get\(`\/contacts\/\$\{id\}\/notes`\)/g, 'await ContactsApi.getNotes(id)');
code = code.replace(/await apiClient\.post\(`\/contacts\/\$\{id\}\/notes`, data\)/g, 'await ContactsApi.addNote(id, data)');
code = code.replace(/await apiClient\.delete\(`\/contacts\/\$\{id\}\/notes\/\$\{noteId\}`\)/g, 'await ContactsApi.deleteNote(id, noteId)');

code = code.replace(/await apiClient\.post\(`\/contacts\/\$\{contactId\}\/relationships`, data\)/g, 'await ContactsApi.addRelationship(contactId, data)');
code = code.replace(/await apiClient\.delete\(`\/contacts\/\$\{contactId\}\/relationships\/\$\{relationshipId\}`\)/g, 'await ContactsApi.deleteRelationship(contactId, relationshipId)');

code = code.replace(/await apiClient\.post\(`\/contacts\/\$\{contactId\}\/preferences`, data\)/g, 'await ContactsApi.addPreference(contactId, data)');
code = code.replace(/await apiClient\.put\(`\/contacts\/\$\{contactId\}\/preferences\/\$\{prefId\}`, data\)/g, 'await ContactsApi.updatePreference(contactId, prefId, data)');
code = code.replace(/await apiClient\.delete\(`\/contacts\/\$\{contactId\}\/preferences\/\$\{prefId\}`\)/g, 'await ContactsApi.deletePreference(contactId, prefId)');

code = code.replace(/await apiClient\.post\(`\/contacts\/\$\{contactId\}\/aliases`, data\)/g, 'await ContactsApi.addAlias(contactId, data)');
code = code.replace(/await apiClient\.delete\(`\/contacts\/\$\{contactId\}\/aliases\/\$\{aliasId\}`\)/g, 'await ContactsApi.deleteAlias(contactId, aliasId)');

// Tasks
code = code.replace(/await apiClient\.get\('(\/tasks)'\)/g, 'await TasksApi.getAll()');
code = code.replace(/await apiClient\.post\('(\/tasks)', payload\)/g, 'await TasksApi.create(payload)');
code = code.replace(/await apiClient\.patch\(`\/tasks\/\$\{id\}\/status`, \{ status \}\)/g, 'await TasksApi.updateStatus(id, status)');
code = code.replace(/await apiClient\.delete\(`\/tasks\/\$\{id\}`\)/g, 'await TasksApi.delete(id)');

// Workflows
code = code.replace(/await apiClient\.get\('(\/workflows)'\)/g, 'await WorkflowsApi.getAll()');

// Agents
code = code.replace(/await apiClient\.get\('(\/agents)'\)/g, 'await AgentsApi.getAll()');
code = code.replace(/await apiClient\.put\(`\/agents\/\$\{id\}`, data\)/g, 'await AgentsApi.update(id, data)');
code = code.replace(/await apiClient\.post\(`\/agents\/\$\{id\}\/simulate`, body\)/g, 'await AgentsApi.simulate(id, body)');
code = code.replace(/await apiClient\.post\(`\/agents\/\$\{id\}\/run`, body\)/g, 'await AgentsApi.run(id, body)');
code = code.replace(/await apiClient\.post\(`\/agents\/\$\{id\}\/quarantine`, \{ reason \}\)/g, 'await AgentsApi.quarantine(id, reason)');
code = code.replace(/await apiClient\.get\(`\/agents\/\$\{id\}\/status`\)/g, 'await AgentsApi.getStatus(id)');

// Personas
code = code.replace(/await apiClient\.get\('(\/agent-personas)'\)/g, 'await AgentsApi.getPersonas()');
code = code.replace(/await apiClient\.post\('(\/agent-personas)', data\)/g, 'await AgentsApi.createPersona(data)');
code = code.replace(/await apiClient\.put\(`\/agent-personas\/\$\{id\}`, data\)/g, 'await AgentsApi.updatePersona(id, data)');
code = code.replace(/await apiClient\.delete\(`\/agent-personas\/\$\{id\}`\)/g, 'await AgentsApi.deletePersona(id)');

// MCP Servers
code = code.replace(/await apiClient\.get\('(\/mcp-servers)'\)/g, 'await MCPServersApi.getAll()');
code = code.replace(/await apiClient\.post\('(\/mcp-servers)', data\)/g, 'await MCPServersApi.create(data)');
code = code.replace(/await apiClient\.put\(`\/mcp-servers\/\$\{id\}`, data\)/g, 'await MCPServersApi.update(id, data)');
code = code.replace(/await apiClient\.delete\(`\/mcp-servers\/\$\{id\}`\)/g, 'await MCPServersApi.delete(id)');
code = code.replace(/await apiClient\.post\(`\/mcp-servers\/\$\{name\}\/connect`\)/g, 'await MCPServersApi.connect(name)');
code = code.replace(/await apiClient\.post\(`\/mcp-servers\/\$\{name\}\/disconnect`\)/g, 'await MCPServersApi.disconnect(name)');

// Memories
code = code.replace(/await apiClient\.get\('(\/memories)'\)/g, 'await MemoryApi.getAll()');
code = code.replace(/await apiClient\.post\('(\/memories)', payload\)/g, 'await MemoryApi.create(payload)');
code = code.replace(/await apiClient\.delete\(`\/memories\/\$\{numericId\}`\)/g, 'await MemoryApi.delete(numericId)');

fs.writeFileSync(file, code);
console.log('Store index.ts updated');
