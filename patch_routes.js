const fs = require('fs');
const file = 'c:/Users/hedra/Desktop/Sourcecode/NexusV2/Nexus-backend/routes/api.php';
let code = fs.readFileSync(file, 'utf8');

const newRoutes = `
/**
 * Hedra Soul Routes
 */
Route::group(['prefix' => 'v1/hedra-soul', 'middleware' => ['api', 'auth:sanctum']], function () {
    Route::get('/sessions', [\\App\\Http\\Controllers\\HedraSoulController::class, 'getSessions']);
    Route::get('/approvals', [\\App\\Http\\Controllers\\HedraSoulController::class, 'getApprovals']);
    Route::get('/notifications', [\\App\\Http\\Controllers\\HedraSoulController::class, 'getNotifications']);
    Route::get('/status', [\\App\\Http\\Controllers\\HedraSoulController::class, 'getStatus']);
});

`;

code = code.replace('// Fallback route', newRoutes + '// Fallback route');
fs.writeFileSync(file, code);
