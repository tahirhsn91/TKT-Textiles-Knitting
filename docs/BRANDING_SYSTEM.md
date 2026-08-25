# White-Labeling & Branding System

## Overview

The White-Labeling system enables dynamic, tenant-specific branding for the SaaS platform. Each tenant can customize:

- Company name and logo
- Color scheme (primary, secondary, accent, text, navbar, sidebar)
- Email templates with custom branding
- Theme presets for quick style switching
- Custom CSS for advanced customization
- Favicon and email assets

## Database Schema

### branding_config
Stores the primary branding configuration for each tenant.

```sql
CREATE TABLE branding_config (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER UNIQUE,
  company_name VARCHAR(255),
  logo_url VARCHAR(500),
  primary_color VARCHAR(7),        -- Hex color (#RRGGBB)
  secondary_color VARCHAR(7),
  accent_color VARCHAR(7),
  text_color VARCHAR(7),
  navbar_background VARCHAR(7),
  sidebar_background VARCHAR(7),
  custom_css TEXT,                 -- For advanced CSS customization
  ...
);
```

### email_templates
Stores customizable email templates per tenant.

```sql
CREATE TABLE email_templates (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER,
  template_key VARCHAR(100),       -- invitation, password-reset, invoice, etc.
  template_html TEXT,              -- HTML email template
  include_logo BOOLEAN,            -- Auto-inject company logo
  include_footer BOOLEAN,
  custom_footer_text TEXT,
  ...
);
```

### theme_presets
Pre-built or custom color themes for quick switching.

```sql
CREATE TABLE theme_presets (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER,
  preset_name VARCHAR(100),        -- "Classic Blue", "Modern Dark", etc.
  preset_key VARCHAR(50),          -- "classic-blue", "modern-dark"
  primary_color VARCHAR(7),
  secondary_color VARCHAR(7),
  accent_color VARCHAR(7),
  is_default BOOLEAN,
  ...
);
```

### logo_uploads
Tracks all logo uploads per tenant.

```sql
CREATE TABLE logo_uploads (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER,
  filename VARCHAR(255),
  original_filename VARCHAR(255),
  storage_url VARCHAR(500),
  file_size INTEGER,
  logo_type VARCHAR(50),           -- "primary", "favicon", "email"
  is_active BOOLEAN,
  ...
);
```

## Backend Services

### BrandingService (`services/branding-service.ts`)

```typescript
// Get branding config
const config = await brandingService.getBrandingConfig(tenantId);

// Update config
const updated = await brandingService.updateBrandingConfig(tenantId, {
  company_name: 'Acme Textiles',
  primary_color: '#FF6B35',
});

// Upload logo
const logo = await brandingService.uploadLogo(tenantId, file, 'primary');

// Get theme presets
const presets = await brandingService.getThemePresets(tenantId);

// Apply theme preset
await brandingService.applyThemePreset(tenantId, 'modern-dark');

// Manage email templates
const template = await brandingService.upsertEmailTemplate(
  tenantId,
  'invoice-confirmation',
  { template_html: '...' }
);

// Generate CSS variables
const css = brandingService.generateThemeCSS(config);
```

## API Endpoints

### Configuration

**GET /api/v1/branding/config**
- Get branding configuration for current tenant
- Returns: BrandingConfig object

**PUT /api/v1/branding/config**
- Update branding configuration
- Body: `{ company_name, primary_color, secondary_color, ... }`
- Returns: Updated BrandingConfig

**GET /api/v1/branding/package**
- Get complete branding package (config + CSS + presets)
- Returns: BrandingPackage with CSS variables ready for injection

### Logos

**POST /api/v1/branding/logo** (multipart/form-data)
- Upload logo for tenant
- Files: `logo` (JPEG, PNG, SVG, WebP, max 5MB)
- Body: `{ logoType: 'primary' }`
- Returns: Logo upload record with storage URL

**GET /api/v1/branding/logos**
- Get all logos for current tenant
- Returns: Array of logo records

**DELETE /api/v1/branding/logo/:logoId**
- Delete a logo
- Returns: Success message

### Themes

**GET /api/v1/branding/themes**
- Get all theme presets for current tenant
- Returns: Array of ThemePreset

**POST /api/v1/branding/themes/apply/:presetKey**
- Apply a preset theme
- Returns: Updated BrandingConfig

**POST /api/v1/branding/themes**
- Create custom theme preset
- Body: `{ preset_name, preset_key, primary_color, secondary_color, accent_color }`
- Returns: Created ThemePreset

### Email Templates

**GET /api/v1/branding/email-templates**
- Get all email templates
- Returns: Array of EmailTemplate

**GET /api/v1/branding/email-templates/:templateKey**
- Get specific email template (e.g., 'invoice-confirmation')
- Returns: EmailTemplate

**POST /api/v1/branding/email-templates/:templateKey**
- Create or update email template
- Body: `{ template_name, subject_line, template_html, include_logo, include_footer }`
- Returns: EmailTemplate

## Frontend Integration

### useBranding Hook

```typescript
import { useBranding } from '@/hooks/useBranding';

function MyComponent() {
  const { 
    branding, 
    loading, 
    error,
    updateBranding,
    applyTheme,
    uploadLogo,
    refreshBranding
  } = useBranding();

  if (loading) return <div>Loading...</div>;

  return (
    <div>
      <img src={branding?.config.logo_url} alt="logo" />
      <h1>{branding?.config.company_name}</h1>
      
      <button onClick={() => applyTheme('modern-dark')}>
        Apply Dark Theme
      </button>
    </div>
  );
}
```

### CSS Variables

Branding automatically injects CSS variables into `<style id="branding-css">`:

```css
:root {
  --color-primary: #1F2937;
  --color-secondary: #3B82F6;
  --color-accent: #F59E0B;
  --color-text: #111827;
  --color-background: #FFFFFF;
  --color-navbar-bg: #1F2937;
  --color-navbar-text: #FFFFFF;
  --color-sidebar-bg: #F9FAFB;
  --color-sidebar-text: #111827;
  --font-family: Inter, sans-serif;
  --font-size-base: 16px;
  --border-radius: 6px;
}
```

Use in your components:

```css
.navbar {
  background-color: var(--color-navbar-bg);
  color: var(--color-navbar-text);
}

.button-primary {
  background-color: var(--color-primary);
  border-radius: var(--border-radius);
}
```

## Logo Upload

### Frontend Example

```typescript
const handleLogoUpload = async (file: File) => {
  try {
    await uploadLogo(file);
    alert('Logo uploaded successfully!');
  } catch (error) {
    alert('Failed to upload logo');
  }
};

<input 
  type="file" 
  accept=".jpg,.jpeg,.png,.svg,.webp"
  onChange={(e) => handleLogoUpload(e.target.files?.[0]!)}
/>
```

### Backend Configuration

Logos are stored in `public/uploads/logos/` by default.

To use S3 or other cloud storage, modify `BrandingService.uploadLogo()`:

```typescript
async uploadLogo(tenantId, file, logoType) {
  // Upload to S3 instead of local storage
  const s3Url = await uploadToS3(file);
  
  // Update database
  await db('logo_uploads').insert({
    storage_url: s3Url,
    storage_provider: 's3',
    ...
  });
}
```

## Email Template Variables

Email templates support variable substitution:

```html
<html>
  <body>
    <img src="{{LOGO_URL}}" alt="logo" />
    <h1>Welcome to {{COMPANY_NAME}}!</h1>
    
    <p>Hi {{USER_NAME}},</p>
    <p>Your order {{ORDER_ID}} has been confirmed.</p>
    
    <p>Best regards,<br/>{{COMPANY_NAME}} Team</p>
  </body>
</html>
```

Available variables:
- `{{COMPANY_NAME}}` - Tenant company name
- `{{LOGO_URL}}` - Tenant logo URL
- `{{USER_NAME}}` - Recipient name
- `{{ORDER_ID}}` - Order identifier
- `{{INVOICE_ID}}` - Invoice identifier
- `{{TIMESTAMP}}` - Current date/time

## Theme Presets

Default presets for all tenants:

- **Classic Blue** (default) - Professional look with blue accent
- **Modern Dark** - Dark theme for modern appearance
- **Professional** - Corporate colors (navy + gold)
- **Minimal Green** - Clean green-based palette

Tenants can create custom presets:

```javascript
POST /api/v1/branding/themes

{
  "preset_name": "Sunset",
  "preset_key": "sunset",
  "primary_color": "#FF6B35",
  "secondary_color": "#F7931E",
  "accent_color": "#FDB462"
}
```

## Custom CSS

For advanced styling, tenants can add custom CSS:

```javascript
PUT /api/v1/branding/config

{
  "custom_css": ".sidebar { box-shadow: 0 0 20px rgba(0,0,0,0.1); }"
}
```

## Security Considerations

✅ **Tenant Isolation** - Each tenant's branding is isolated via tenant_id  
✅ **File Validation** - Logo uploads validated by type and size  
✅ **CSS Injection Prevention** - Custom CSS validated before storage  
✅ **Access Control** - Branding endpoints require tenant authentication  
✅ **Audit Trail** - Logo uploads tracked with user and timestamp  

## Default Branding (Fallback)

If branding config not found, system uses defaults:

```javascript
{
  company_name: "TKT Textiles",
  primary_color: "#1F2937",
  secondary_color: "#3B82F6",
  accent_color: "#F59E0B",
  // ... other colors
}
```

## Performance Tips

1. **Cache branding** - Frontend caches branding package in localStorage
2. **CDN logos** - Use CDN for logo images (S3 CloudFront)
3. **CSS injection** - CSS injected once, reused across components
4. **Lazy loading** - Email templates fetched on-demand

## Troubleshooting

**Logo not updating?**
- Clear browser cache
- Verify file size < 5MB
- Check storage directory permissions

**Colors not applying?**
- Verify hex color format (#RRGGBB)
- Check CSS variable injection in DevTools
- Refresh page to reload CSS

**Email templates not rendering?**
- Verify template_html contains valid HTML
- Test variable substitution with {{VARIABLE}} syntax
- Check email client compatibility (Outlook, Gmail, etc.)

## Migration from Single-Tenant

If migrating from single-tenant TKT Textiles:

1. Create branding_config for existing tenant (id=1)
2. Copy current branding to config
3. Update email templates with variables
4. Set up logo upload directory
5. Test theme switching

Example migration:

```javascript
// Insert initial branding for TKT Textiles
INSERT INTO branding_config (tenant_id, company_name, primary_color, ...)
VALUES (1, 'TKT Textiles', '#1F2937', ...);

// Migrate email templates
INSERT INTO email_templates (tenant_id, template_key, template_html, ...)
VALUES (1, 'invoice-confirmation', '...', ...);
```

## Related Documentation

- [Multi-Tenancy Architecture](./MULTI_TENANCY.md)
- [API Documentation](./API.md)
- [Frontend Setup](../frontend/README.md)
