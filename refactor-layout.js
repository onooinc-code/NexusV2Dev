const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, 'Nexus-Frontend/app/contacts/[id]/layout.tsx');
let content = fs.readFileSync(filePath, 'utf8');

// 1. Add imports
if (!content.includes("import Link from 'next/link';")) {
  content = content.replace("import { useRouter }", "import { useRouter, usePathname } from 'next/navigation';\nimport Link from 'next/link';\n//");
}

// 2. Change signature
content = content.replace(
  "export default function ContactDetailPage({ params }: { params: Promise<{ id: string }> }) {",
  "export default function ContactLayout({ children, params }: { children: React.ReactNode, params: Promise<{ id: string }> }) {"
);

// 3. Add pathname
if (!content.includes("const pathname = usePathname();")) {
  content = content.replace("const router = useRouter();", "const router = useRouter();\n  const pathname = usePathname();");
}

// 4. Change buttons to Links
content = content.replace(/<button\s+key=\{tab\.value\}\s+onClick=\{[^}]+\}\s+className=\{`([^`]+)`\}\s*>/g, 
  `<Link\n                  key={tab.value}\n                  href={\`/contacts/\${resolvedParams.id}/\${tab.value}\`}\n                  className={\`$1\`.replace('activeTab === tab.value', 'pathname.includes(tab.value)')}\n                >`);

content = content.replace(/<\/button>\s*\}\)\}\s*<\/div>\s*\{\/\* Tab Panes \*\/\}/g, 
  `</Link>\n              ))}\n            </div>\n\n            {/* Tab Panes */}`);

// 5. Replace Tab Panes content with {children}
const startIdx = content.indexOf('{/* Tab Panes */}');
const endIdx = content.indexOf('{/* Edit Profile Drawer */}');

if (startIdx !== -1 && endIdx !== -1) {
  const before = content.slice(0, startIdx);
  const after = content.slice(endIdx);
  content = before + '{/* Tab Panes */}\n            <div className="mt-4 space-y-4">\n              {children}\n            </div>\n\n        ' + after;
}

// 6. Fix Link className replace
content = content.replace("`px-4 py-3 text-sm font-medium border-b-2 transition-colors flex items-center gap-2 cursor-pointer ${activeTab === tab.value ? 'border-nexus-blue text-nexus-blue' : 'border-transparent text-gray-400 hover:text-gray-200'}`", "`px-4 py-3 text-sm font-medium border-b-2 transition-colors flex items-center gap-2 cursor-pointer ${pathname.includes(tab.value) ? 'border-nexus-blue text-nexus-blue' : 'border-transparent text-gray-400 hover:text-gray-200'}`");

fs.writeFileSync(filePath, content);
console.log("Refactored layout.tsx successfully.");
