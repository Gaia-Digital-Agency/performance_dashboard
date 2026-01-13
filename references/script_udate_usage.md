# Site Updates Script Usage Guide

The `site_updates.sh` script makes it easy to keep your dashboard in sync with your sites.json file.

## What It Does

When you run this script, it will:

1. **Read sites.json** - Load all websites you want to monitor
2. **Clean the database** - Remove any sites that are no longer in sites.json
3. **Check audit status** - Show how many sites have data vs pending
4. **Run Lighthouse audits** - Test all sites for performance, accessibility, SEO, and best practices
5. **Display results** - Show a summary of the database and recent audits

## Usage

### Basic Usage (Foreground)

Run audits and see progress in real-time:

```bash
./site_updates.sh
```

This will run all audits sequentially and show you the progress as it happens. Great for the first run or when you want to watch the progress.

### Background Mode

Run audits in the background (recommended for large site lists):

```bash
./site_updates.sh --background
```

The audits will run in the background. Monitor progress with:

```bash
tail -f /tmp/lighthouse_audits.log
```

### Force Re-audit

Re-audit ALL sites even if they already have data:

```bash
./site_updates.sh --force
```

Useful when you want to refresh all scores, not just pending sites.

## Typical Workflow

1. **Update sites.json** - Add or remove websites
   ```bash
   nano sites.json  # or use your favorite editor
   ```

2. **Run the sync script**
   ```bash
   ./site_updates.sh --background
   ```

3. **Monitor progress** (optional)
   ```bash
   tail -f /tmp/lighthouse_audits.log | grep "Running\|Successfully"
   ```

4. **View the dashboard**
   ```bash
   # Make sure services are running
   ./start.sh

   # Open in browser
   open http://localhost:3000
   ```

## Timing

- Each site takes approximately **30-60 seconds** to audit
- For 28 sites, expect approximately **15-25 minutes** total
- Background mode doesn't block your terminal

## Troubleshooting

### Script won't run
```bash
chmod +x site_updates.sh
```

### Database connection errors
Make sure your `.env` file has the correct database credentials:
```
DB_USER=gaiada_user
DB_HOST=localhost
DB_DATABASE=lighthouse_reports
DB_PASSWORD=your_password
DB_PORT=5432
```

### Audits fail
Check the log file:
```bash
cat /tmp/lighthouse_audits.log
```

Common issues:
- Site is down or unreachable
- Slow network connection causing timeouts
- Invalid URL in sites.json

## Examples

### Example sites.json
```json
[
  "https://example.com",
  "https://www.another-site.com",
  "https://myapp.io"
]
```

### Expected Output
```
=========================================
Site Updates & Audit Script
=========================================

Step 1: Reading sites from sites.json...
✓ Found 28 sites in sites.json

Step 2: Checking database for sites not in sites.json...
✓ No outdated sites to remove

Step 3: Checking audit status...
  Sites in sites.json: 28
  Sites with data: 7
  Sites pending audit: 21

Step 4: Running Lighthouse audits...
✓ Audits started in background (PID: 12345)

=========================================
Site updates complete!
=========================================
```

## Integration with Scheduler

The automatic scheduler (`scheduler.js`) runs daily at 11:00 PM. You only need to run `site_updates.sh` when:

- You've updated sites.json
- You want to force a refresh of all scores
- You want immediate results instead of waiting for the scheduled run

## Monitoring the Dashboard

After running the script:

1. Start the services (if not already running):
   ```bash
   ./start.sh
   ```

2. Open the dashboard:
   ```
   http://localhost:3000
   ```

3. You'll see:
   - Sites with completed audits show colored scores (green/orange/red)
   - Sites pending audits show "Pending..." in gray
   - Refresh the page as audits complete to see updated scores
