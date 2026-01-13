#!/bin/bash

# site_updates.sh
# This script syncs the database with sites.json and runs Lighthouse audits

set -e  # Exit on error

echo "========================================="
echo "Site Updates & Audit Script"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if sites.json exists
if [ ! -f "sites.json" ]; then
    echo -e "${RED}Error: sites.json not found!${NC}"
    exit 1
fi

# Load environment variables
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Get the list of sites from sites.json
echo -e "${YELLOW}Step 1: Reading sites from sites.json...${NC}"
SITES_FROM_JSON=$(node -e "
const sites = require('./sites.json');
console.log(sites.join('\n'));
")

SITE_COUNT=$(echo "$SITES_FROM_JSON" | wc -l | tr -d ' ')
echo -e "${GREEN}✓ Found $SITE_COUNT sites in sites.json${NC}"
echo ""

# Get current sites in database
echo -e "${YELLOW}Step 2: Checking database for sites not in sites.json...${NC}"
SITES_TO_DELETE=$(psql -U "$DB_USER" -d "$DB_DATABASE" -t <<EOF 2>/dev/null || echo ""
SELECT url FROM reports
WHERE url NOT IN (
    SELECT unnest(ARRAY[$(echo "$SITES_FROM_JSON" | sed "s/^/'/;s/$/'/" | paste -sd, -)])
)
GROUP BY url;
EOF
)

if [ -z "$SITES_TO_DELETE" ]; then
    echo -e "${GREEN}✓ No outdated sites to remove${NC}"
else
    echo -e "${YELLOW}Found sites to remove from database:${NC}"
    echo "$SITES_TO_DELETE"

    # Delete outdated sites
    while IFS= read -r site; do
        site=$(echo "$site" | xargs)  # Trim whitespace
        if [ ! -z "$site" ]; then
            psql -U "$DB_USER" -d "$DB_DATABASE" <<EOF > /dev/null 2>&1
DELETE FROM reports WHERE url = '$site';
EOF
            echo -e "${GREEN}  ✓ Deleted: $site${NC}"
        fi
    done <<< "$SITES_TO_DELETE"
fi
echo ""

# Check which sites need auditing
echo -e "${YELLOW}Step 3: Checking audit status...${NC}"
AUDITED_COUNT=$(psql -U "$DB_USER" -d "$DB_DATABASE" -t <<EOF 2>/dev/null | tr -d ' '
SELECT COUNT(DISTINCT url) FROM reports;
EOF
)
PENDING_COUNT=$((SITE_COUNT - AUDITED_COUNT))

echo -e "  Sites in sites.json: ${GREEN}$SITE_COUNT${NC}"
echo -e "  Sites with data: ${GREEN}$AUDITED_COUNT${NC}"
echo -e "  Sites pending audit: ${YELLOW}$PENDING_COUNT${NC}"
echo ""

# Ask user if they want to run audits
if [ $PENDING_COUNT -gt 0 ] || [ "$1" == "--force" ]; then
    echo -e "${YELLOW}Step 4: Running Lighthouse audits...${NC}"
    echo -e "${YELLOW}This will take approximately $((SITE_COUNT * 1)) minutes (30-60 seconds per site)${NC}"
    echo ""

    if [ "$1" == "--background" ]; then
        echo -e "${GREEN}Starting audits in background...${NC}"
        nohup node -e "
const { runAllAudits } = require('./runner.js');
console.log('Starting audits for all sites...');
runAllAudits()
    .then(() => console.log('✓ All audits completed successfully!'))
    .catch(err => console.error('Error during audits:', err));
" > /tmp/lighthouse_audits.log 2>&1 &

        echo -e "${GREEN}✓ Audits started in background (PID: $!)${NC}"
        echo -e "${YELLOW}Monitor progress with: tail -f /tmp/lighthouse_audits.log${NC}"
    else
        # Run audits in foreground
        node -e "
const { runAllAudits } = require('./runner.js');
console.log('Starting audits for all sites...');
runAllAudits()
    .then(() => {
        console.log('');
        console.log('\x1b[32m✓ All audits completed successfully!\x1b[0m');
    })
    .catch(err => {
        console.error('\x1b[31mError during audits:\x1b[0m', err);
        process.exit(1);
    });
"
    fi
else
    echo -e "${GREEN}✓ All sites are up to date!${NC}"
fi

echo ""
echo "========================================="
echo -e "${GREEN}Site updates complete!${NC}"
echo "========================================="
echo ""

# Show final stats
echo "Database Status:"
psql -U "$DB_USER" -d "$DB_DATABASE" <<EOF
SELECT
    COUNT(DISTINCT url) as unique_sites,
    COUNT(*) as total_reports,
    MAX(created_at) as latest_audit
FROM reports;
EOF

echo ""
echo "Recent Audits:"
psql -U "$DB_USER" -d "$DB_DATABASE" <<EOF
SELECT
    url,
    performance_score,
    accessibility_score,
    seo_score,
    created_at
FROM reports
ORDER BY created_at DESC
LIMIT 5;
EOF
