const fs = require('fs');
const path = require('path');

const dirs = ['audit', 'conversations', 'messages', 'facebook', 'whatsapp'];

dirs.forEach(dir => {
  const filePath = path.join(__dirname, 'Nexus-Frontend/app/contacts/[id]', dir, 'page.tsx');
  if (fs.existsSync(filePath)) {
    let content = fs.readFileSync(filePath, 'utf8');
    
    if (!content.includes('useAppStore')) {
      content = content.replace("import React, { use } from 'react';", "import React, { use } from 'react';\nimport { useAppStore } from '@/store/store-provider';");
    }

    if (!content.includes('const contact =')) {
      content = content.replace("const { id } = use(params);", "const { id } = use(params);\n  const contact = useAppStore(state => state.currentContact);");
    }

    // Fix NxAuditViewer
    if (content.includes('<NxAuditViewer contactId={parseInt(id, 10)} />')) {
      content = content.replace('<NxAuditViewer contactId={parseInt(id, 10)} />', '<NxAuditViewer contactId={parseInt(id, 10)} contactName={contact?.name || "Unknown"} />');
    }

    // Fix NxMessageViewer
    if (content.includes('<NxMessageViewer contactId={parseInt(id, 10)} channel="all" />')) {
      content = content.replace('<NxMessageViewer contactId={parseInt(id, 10)} channel="all" />', '<NxMessageViewer contactId={parseInt(id, 10)} channel="all" contactName={contact?.name || "Unknown"} contactAvatar={contact?.avatar || undefined} />');
    }
    if (content.includes('<NxMessageViewer contactId={parseInt(id, 10)} channel="whatsapp" />')) {
      content = content.replace('<NxMessageViewer contactId={parseInt(id, 10)} channel="whatsapp" />', '<NxMessageViewer contactId={parseInt(id, 10)} channel="whatsapp" contactName={contact?.name || "Unknown"} contactAvatar={contact?.avatar || undefined} />');
    }
    if (content.includes('<NxMessageViewer contactId={parseInt(id, 10)} channel="facebook_messenger" />')) {
      content = content.replace('<NxMessageViewer contactId={parseInt(id, 10)} channel="facebook_messenger" />', '<NxMessageViewer contactId={parseInt(id, 10)} channel="facebook_messenger" contactName={contact?.name || "Unknown"} contactAvatar={contact?.avatar || undefined} />');
    }

    // Fix NxConversationsViewer
    if (content.includes('<NxConversationsViewer contactId={parseInt(id, 10)} />')) {
      content = content.replace('<NxConversationsViewer contactId={parseInt(id, 10)} />', '<NxConversationsViewer contactId={parseInt(id, 10)} contactName={contact?.name || "Unknown"} contactAvatar={contact?.avatar || undefined} />');
    }

    fs.writeFileSync(filePath, content);
    console.log("Patched " + dir);
  }
});
