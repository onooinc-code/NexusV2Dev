const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, 'Nexus-Frontend/app/contacts/[id]/layout.tsx');
let content = fs.readFileSync(filePath, 'utf8');

content = content.replace("              </button>\n            ))}\n          </div>", "              </Link>\n            ))}\n          </div>");

fs.writeFileSync(filePath, content);
console.log("Fixed button to Link");
