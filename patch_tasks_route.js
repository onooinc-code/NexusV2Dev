const fs = require('fs');
const file = 'c:/Users/hedra/Desktop/Sourcecode/NexusV2/Nexus-backend/routes/api.php';
let code = fs.readFileSync(file, 'utf8');

code = code.replace(/Route::resource\('tasks',\s*\\?App\\?Http\\?Controllers\\?TaskController::class\);/g, "Route::apiResource('tasks', \\App\\Http\\Controllers\\TaskController::class);");
fs.writeFileSync(file, code);
