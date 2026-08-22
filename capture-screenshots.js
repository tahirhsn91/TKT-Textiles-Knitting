/**
 * E2E Screenshot Capture Script (Enhanced)
 * 
 * Improvements:
 * - Waits for all API calls to resolve (networkidle state)
 * - Validates session is alive after login
 * - Detects and waits for loading screens to disappear
 * - Proper wait times between navigation
 * - Session health checks
 * - Retry logic for failed captures
 */

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// Configuration
const BASE_URL = 'http://localhost:3001';
const SCREENSHOTS_DIR = path.join(process.cwd(), 'screenshots-fixed');
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

/**
 * Wait for loading indicators to disappear
 */
async function waitForLoadingComplete(page, timeout = 30000) {
  const startTime = Date.now();
  
  while (Date.now() - startTime < timeout) {
    try {
      // Check for common loading indicators
      const loaders = await page.locator('[class*="loading"], [class*="spinner"], [class*="skeleton"]').count();
      
      if (loaders === 0) {
        console.log('    ✓ No loading indicators detected');
        return true;
      }
      
      await page.waitForTimeout(500);
    } catch (err) {
      // Selector not found = no loaders
      return true;
    }
  }
  
  console.log('    ⚠ Timeout waiting for loading to complete (continuing anyway)');
  return false;
}

/**
 * Wait for API calls to complete (network idle)
 */
async function waitForNetworkIdle(page, timeout = 30000) {
  try {
    await page.waitForLoadState('networkidle', { timeout });
    console.log('    ✓ Network idle reached');
    return true;
  } catch (err) {
    console.log('    ⚠ Network idle timeout, waiting additional time...');
    await page.waitForTimeout(3000);
    return false;
  }
}

/**
 * Check if session is still valid
 */
async function validateSession(page) {
  try {
    // Check for auth token in storage (TKT uses 'tkt_auth_token' key)
    const token = await page.evaluate(() => localStorage.getItem('tkt_auth_token') || '');
    
    if (!token) {
      console.log('    ✗ No auth token found - session may be invalid');
      return false;
    }
    
    // Check current URL - if redirected to login, session is dead
    const currentUrl = page.url();
    if (currentUrl.includes('/login')) {
      console.log('    ✗ Redirected to login - session expired');
      return false;
    }
    
    console.log('    ✓ Session valid (token: ' + token.substring(0, 20) + '...)');
    return true;
  } catch (err) {
    console.error('    ⚠ Session validation error:', err.message);
    return false;
  }
}

/**
 * Enhanced login with session validation
 */
async function performLogin(page, userCreds, retries = 3) {
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      console.log(`  → Login attempt ${attempt}/${retries} as ${userCreds.username}...`);
      
      // Navigate to login if not already there
      const currentUrl = page.url();
      if (!currentUrl.includes('/login')) {
        await page.goto(`${APP_URL}/login`, { waitUntil: 'load' });
        await page.waitForTimeout(2000);
      }
      
      // Wait for form to be visible
      await page.waitForSelector('input', { timeout: 10000 });
      
      // Get input fields
      const inputs = await page.$$('input');
      if (inputs.length < 2) {
        throw new Error(`Expected 2 inputs, found ${inputs.length}`);
      }
      
      // Fill credentials
      console.log('  → Filling credentials...');
      await inputs[0].fill(userCreds.username);
      await page.waitForTimeout(300);
      await inputs[1].fill(userCreds.password);
      await page.waitForTimeout(300);
      
      // Find and click login button
      const buttons = await page.$$('button');
      if (buttons.length === 0) {
        throw new Error('No button found on login page');
      }
      
      console.log('  → Clicking login button...');
      await buttons[0].click();
      
      // Wait for navigation with longer timeout
      await page.waitForNavigation({ waitUntil: 'load', timeout: 30000 });
      console.log('  → Navigation complete');
      
      // Wait for page to settle
      await page.waitForTimeout(2000);
      
      // Validate session
      const sessionValid = await validateSession(page);
      if (!sessionValid) {
        console.log(`  ⚠ Session validation failed on attempt ${attempt}`);
        if (attempt < retries) {
          await page.goto(`${APP_URL}/login`, { waitUntil: 'load' });
          continue;
        }
        throw new Error('Session validation failed after retries');
      }
      
      console.log(`  ✓ Login successful on attempt ${attempt}`);
      return true;
      
    } catch (error) {
      console.error(`  ✗ Login attempt ${attempt} failed: ${error.message}`);
      
      if (attempt < retries) {
        console.log(`  → Retrying in 2 seconds...`);
        await page.waitForTimeout(2000);
      }
    }
  }
  
  throw new Error(`Login failed after ${retries} attempts`);
}

/**
 * Capture screenshot with proper wait states
 */
async function capturePageScreenshot(page, screenshotPath) {
  try {
    // Wait for network to be idle
    await waitForNetworkIdle(page, 20000);
    
    // Wait for any loading indicators to disappear
    await waitForLoadingComplete(page, 10000);
    
    // Additional wait for DOM to settle
    await page.waitForTimeout(1500);
    
    // Check session is still valid
    const sessionValid = await validateSession(page);
    if (!sessionValid) {
      console.log('    ⚠ Session became invalid before capture');
    }
    
    // Take screenshot
    await page.screenshot({
      path: screenshotPath,
      fullPage: false
    });
    
    console.log(`  ✓ Screenshot saved: ${path.basename(screenshotPath)}`);
    return true;
    
  } catch (error) {
    console.error(`  ✗ Screenshot capture failed: ${error.message}`);
    return false;
  }
}

async function captureScreenshots() {
  let browser;
  try {
    console.log('🚀 Starting Playwright browser...\n');
    browser = await chromium.launch({ 
      headless: true,
      args: ['--no-sandbox', '--disable-setuid-sandbox']
    });

    for (const [userKey, userCreds] of Object.entries(users)) {
      console.log(`\n${'='.repeat(60)}`);
      console.log(`📸 CAPTURING SCREENSHOTS FOR ${userCreds.role.toUpperCase()} (${userCreds.name})`);
      console.log(`${'='.repeat(60)}\n`);
      
      const context = await browser.newContext({
        viewport: { width: 1280, height: 800 }
      });

      const page = await context.newPage();
      
      // Set extended timeouts for slower connections
      page.setDefaultTimeout(60000);
      page.setDefaultNavigationTimeout(60000);

      try {
        // Step 1: Login with validation
        console.log('\n1️⃣  AUTHENTICATION');
        console.log('-'.repeat(40));
        
        await performLogin(page, userCreds);
        
        // Validate session after login
        const sessionValid = await validateSession(page);
        if (!sessionValid) {
          throw new Error('Session invalid after login - cannot continue');
        }

        // Step 2: Capture screenshots for each route
        console.log('\n2️⃣  CAPTURING FEATURE SCREENS');
        console.log('-'.repeat(40));
        
        const routes = routesByRole[userKey] || [];
        let successCount = 0;
        let failureCount = 0;
        
        for (const route of routes) {
          try {
            console.log(`\n  [${successCount + failureCount + 1}/${routes.length}] ${route.name}`);
            
            // Navigate to route
            console.log(`  → Navigating to ${route.path}...`);
            await page.goto(`${APP_URL}${route.path}`, { 
              waitUntil: 'load',
              timeout: 30000 
            });
            
            // Wait for page to fully load
            await waitForNetworkIdle(page, 20000);
            await waitForLoadingComplete(page, 10000);
            await page.waitForTimeout(2000);
            
            // Validate session is still alive
            const sessionStillValid = await validateSession(page);
            if (!sessionStillValid) {
              throw new Error('Session expired during navigation');
            }
            
            // Capture screenshot
            const routeDir = path.join(SCREENSHOTS_DIR, userKey, 'routes');
            fs.mkdirSync(routeDir, { recursive: true });
            
            const success = await capturePageScreenshot(
              page,
              path.join(routeDir, `${route.name}.png`)
            );
            
            if (success) {
              successCount++;
            } else {
              failureCount++;
            }
            
          } catch (error) {
            console.error(`  ✗ Failed to capture ${route.name}: ${error.message}`);
            failureCount++;
          }
        }

        console.log(`\n✅ ${userCreds.role} screenshots complete`);
        console.log(`  ✓ Successful: ${successCount}/${routes.length}`);
        if (failureCount > 0) {
          console.log(`  ✗ Failed: ${failureCount}/${routes.length}`);
        }

      } catch (error) {
        console.error(`\n❌ Error capturing screenshots for ${userKey}:`, error.message);
      } finally {
        await context.close();
      }
    }

    console.log(`\n${'='.repeat(60)}`);
    console.log('📁 All screenshots processed');
    console.log(`${'='.repeat(60)}`);
    
    console.log(`\n✅ Screenshots saved to: ${SCREENSHOTS_DIR}`);
    
    // List captured files
    console.log('\n📸 Captured Files:');
    if (fs.existsSync(SCREENSHOTS_DIR)) {
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
            const size = (stat.size / 1024).toFixed(1);
            console.log(`  ${prefix}├── ${file} (${size} KB)`);
          }
        });
      };
      walkDir(SCREENSHOTS_DIR);
    }

  } catch (error) {
    console.error('❌ Fatal error:', error);
    process.exit(1);
  } finally {
    if (browser) {
      await browser.close();
    }
  }
}

// Run the capture
console.log('🎬 E2E Screenshot Capture Script (Enhanced)\n');
captureScreenshots().catch(console.error);
