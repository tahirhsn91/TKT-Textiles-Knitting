/**
 * E2E Screenshot Capture Script
 * Captures actual application screenshots for all three user journeys
 * Outputs: screenshots/ directory with timestamped images
 */

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// Configuration
const BASE_URL = 'http://localhost:3001';
const SCREENSHOTS_DIR = path.join(process.cwd(), 'screenshots');
const APP_URL = process.env.APP_URL || BASE_URL;

// Test users
const users = {
  admin: {
    username: 'admin',
    password: 'tkttextiles12#',
    name: 'Hassan',
    role: 'Admin'
  },
  manager: {
    username: 'manager',
    password: 'manager123#',
    name: 'Khurram',
    role: 'Manager'
  },
  supervisor: {
    username: 'supervisor',
    password: 'supervisor123#',
    name: 'Iftikhar',
    role: 'Supervisor'
  }
};

// Routes to capture for each role
const routesByRole = {
  admin: [
    { path: '/login', name: '01-login-page' },
    { path: '/dashboard', name: '02-admin-dashboard' },
    { path: '/settings', name: '03-user-management' },
    { path: '/transactions', name: '04-transactions-list' },
    { path: '/daily-production', name: '05-production-tracking' },
    { path: '/yarn-receipts', name: '06-yarn-receipts' },
    { path: '/daily-deliveries', name: '07-daily-deliveries' },
    { path: '/maintenance/machine', name: '08-machine-maintenance' },
    { path: '/reports/yarn-balance', name: '09-yarn-balance-report' }
  ],
  manager: [
    { path: '/login', name: '01-login-page' },
    { path: '/dashboard', name: '02-manager-dashboard' },
    { path: '/transactions', name: '03-transactions-list' },
    { path: '/daily-production', name: '04-production-tracking' },
    { path: '/yarn-receipts', name: '05-yarn-receipts' },
    { path: '/daily-deliveries', name: '06-daily-deliveries' },
    { path: '/transactions/monthly-salary-entry', name: '07-payroll-entry' },
    { path: '/transactions/advances', name: '08-advances-management' },
    { path: '/reports/yarn-balance', name: '09-reports' }
  ],
  supervisor: [
    { path: '/login', name: '01-login-page' },
    { path: '/dashboard', name: '02-supervisor-dashboard' },
    { path: '/daily-production', name: '03-production-tracking' },
    { path: '/yarn-receipts', name: '04-yarn-receipts' },
    { path: '/daily-deliveries', name: '05-daily-deliveries' },
    { path: '/maintenance/machine', name: '06-maintenance-reporting' }
  ]
};

// Create screenshots directory
if (!fs.existsSync(SCREENSHOTS_DIR)) {
  fs.mkdirSync(SCREENSHOTS_DIR, { recursive: true });
}

async function captureScreenshots() {
  let browser;
  try {
    console.log('🚀 Starting Playwright browser...');
    browser = await chromium.launch({ 
      headless: true,
      args: ['--no-sandbox', '--disable-setuid-sandbox']
    });

    for (const [userKey, userCreds] of Object.entries(users)) {
      console.log(`\n📸 Capturing screenshots for ${userCreds.role} (${userCreds.name})...`);
      
      const context = await browser.newContext({
        viewport: { width: 1280, height: 800 }
      });

      const page = await context.newPage();
      
      // Set reasonable timeouts
      page.setDefaultTimeout(60000);
      page.setDefaultNavigationTimeout(60000);

      try {
        // Step 1: Navigate to login page
        console.log(`  → Navigating to login page...`);
        await page.goto(`${APP_URL}/login`, { waitUntil: 'load' });
        await page.waitForTimeout(2000);
        
        // Capture login page
        const loginDir = path.join(SCREENSHOTS_DIR, userKey, 'login');
        fs.mkdirSync(loginDir, { recursive: true });
        await page.screenshot({ 
          path: path.join(loginDir, '01-login-page.png'),
          fullPage: false 
        });
        console.log(`  ✓ Login page captured`);

        // Step 2: Perform login with better selectors
        console.log(`  → Logging in as ${userCreds.username}...`);
        
        // Try multiple selector strategies
        try {
          // Wait for inputs to be visible
          await page.waitForSelector('input', { timeout: 10000 });
          
          // Get all inputs
          const inputs = await page.$$('input');
          console.log(`  → Found ${inputs.length} input fields`);
          
          if (inputs.length >= 2) {
            // First input is usually username
            await inputs[0].fill(userCreds.username);
            await page.waitForTimeout(500);
            
            // Second input is password
            await inputs[1].fill(userCreds.password);
            await page.waitForTimeout(500);
          }
          
          // Find and click login button
          const loginButtons = await page.$$('button');
          console.log(`  → Found ${loginButtons.length} buttons`);
          
          if (loginButtons.length > 0) {
            // Usually the first or last button is login
            await loginButtons[0].click();
          }
        } catch (err) {
          console.error(`  ⚠ Form fill error: ${err.message}`);
          // Capture error state
          await page.screenshot({ 
            path: path.join(loginDir, '02-login-error.png'),
            fullPage: false 
          });
        }
        
        // Wait for navigation
        try {
          await page.waitForNavigation({ waitUntil: 'load', timeout: 20000 });
        } catch (err) {
          console.log(`  ⚠ Navigation timeout, continuing anyway...`);
        }
        
        await page.waitForTimeout(3000);
        
        console.log(`  ✓ Login flow completed`);

        // Step 3: Capture screenshots for each route
        const routes = routesByRole[userKey] || [];
        
        for (const route of routes) {
          try {
            console.log(`  → Capturing: ${route.name}...`);
            await page.goto(`${APP_URL}${route.path}`, { waitUntil: 'load', timeout: 30000 });
            await page.waitForTimeout(2000);
            
            const routeDir = path.join(SCREENSHOTS_DIR, userKey, 'routes');
            fs.mkdirSync(routeDir, { recursive: true });
            
            await page.screenshot({
              path: path.join(routeDir, `${route.name}.png`),
              fullPage: false
            });
            
            console.log(`  ✓ ${route.name}`);
          } catch (error) {
            console.error(`  ✗ Failed to capture ${route.name}: ${error.message}`);
          }
        }

        console.log(`\n✅ Screenshots captured for ${userCreds.role}`);

      } catch (error) {
        console.error(`Error capturing screenshots for ${userKey}:`, error.message);
      } finally {
        await context.close();
      }
    }

    console.log(`\n📁 All screenshots saved to: ${SCREENSHOTS_DIR}`);
    
    // List captured files
    console.log('\n📸 Captured Screenshots:');
    const walkDir = (dir, prefix = '') => {
      const files = fs.readdirSync(dir);
      files.sort();
      files.forEach(file => {
        const fullPath = path.join(dir, file);
        const stat = fs.statSync(fullPath);
        if (stat.isDirectory()) {
          console.log(`  ${prefix}├── ${file}/`);
          walkDir(fullPath, prefix + '│   ');
        } else {
          console.log(`  ${prefix}├── ${file}`);
        }
      });
    };
    
    if (fs.existsSync(SCREENSHOTS_DIR)) {
      walkDir(SCREENSHOTS_DIR);
    }

  } catch (error) {
    console.error('Fatal error:', error);
    process.exit(1);
  } finally {
    if (browser) {
      await browser.close();
    }
  }
}

// Run the capture
captureScreenshots().catch(console.error);
