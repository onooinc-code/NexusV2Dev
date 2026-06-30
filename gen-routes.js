const fs = require('fs');
const path = require('path');

const routes = {
  'ai-analysis': '<NxAiAnalysisTab contactId={parseInt(id, 10)} />',
  'intelligence': '<NxIntelligencePanel contactId={parseInt(id, 10)} />',
  'memories': '<NxMemoriesViewer contactId={parseInt(id, 10)} />',
  'conversations': '<NxConversationsViewer contactId={parseInt(id, 10)} />',
  'messages': '<NxMessageViewer contactId={parseInt(id, 10)} channel="all" />',
  'whatsapp': '<NxMessageViewer contactId={parseInt(id, 10)} channel="whatsapp" />',
  'facebook': '<NxMessageViewer contactId={parseInt(id, 10)} channel="facebook_messenger" />',
  'rules': '<NxRulesViewer contactId={parseInt(id, 10)} />',
  'topics': '<NxTopicsViewer contactId={parseInt(id, 10)} />',
  'audit': '<NxAuditViewer contactId={parseInt(id, 10)} />'
};

const imports = {
  'ai-analysis': "import { NxAiAnalysisTab } from '@/components/NxAiAnalysisTab';",
  'intelligence': "import { NxIntelligencePanel } from '@/components/NxIntelligencePanel';",
  'memories': "import { NxMemoriesViewer } from '@/components/NxMemoriesViewer';",
  'conversations': "import { NxConversationsViewer } from '@/components/NxConversationsViewer';",
  'messages': "import { NxMessageViewer } from '@/components/NxMessageViewer';",
  'whatsapp': "import { NxMessageViewer } from '@/components/NxMessageViewer';",
  'facebook': "import { NxMessageViewer } from '@/components/NxMessageViewer';",
  'rules': "import { NxRulesViewer } from '@/components/NxRulesViewer';",
  'topics': "import { NxTopicsViewer } from '@/components/NxTopicsViewer';",
  'audit': "import { NxAuditViewer } from '@/components/NxAuditViewer';"
};

const baseDir = path.join(__dirname, 'Nexus-Frontend/app/contacts/[id]');

for (const [route, component] of Object.entries(routes)) {
  const dirPath = path.join(baseDir, route);
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
  
  const content = `"use client";
import React, { use } from 'react';
${imports[route]}

export default function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  return (
    <div className="animate-in fade-in duration-300">
      ${component}
    </div>
  );
}
`;
  fs.writeFileSync(path.join(dirPath, 'page.tsx'), content);
  console.log('Generated ' + route);
}
