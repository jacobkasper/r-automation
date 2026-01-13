# R Environment Automation

Automated R package updates and environment configuration for MFRI servers.

## Files

- `Rprofile.example` - Daily package update check on R startup (copy to `~/.Rprofile`)
- `update_packages.R` - Standalone script for cron-based updates with email reports

## Setup

### Interactive updates (on R startup)
```bash
cp Rprofile.example ~/.Rprofile
```

### Scheduled updates (cron)
```bash
mkdir -p ~/R/scripts ~/R/logs
cp update_packages.R ~/R/scripts/
crontab -e
```

Add:
```
0 1 * * * /usr/bin/Rscript /heima/$USER/R/scripts/update_packages.R >> /heima/$USER/R/logs/cron.log 2>&1
```

## Configuration

Edit the email address in `update_packages.R` to receive reports.
