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

### GitHub API rate limits

To avoid rate limit errors when updating GitHub packages, create a Personal Access Token:

1. Go to https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Name it (e.g., "hafdruna-r-updates")
4. Select scope: `public_repo` (or `repo` for private packages)
5. Generate and copy the token

Add it to `~/.Renviron`:
```
GITHUB_PAT=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

## Configuration

The script emails its report to the address in the `UPDATE_REPORT_EMAIL`
environment variable. Set it in `~/.Renviron` (alongside `GITHUB_PAT`):

```
UPDATE_REPORT_EMAIL=you@example.com
```

If `UPDATE_REPORT_EMAIL` is unset, the script runs normally and skips the
email step.

## Logs

- `~/R/logs/update_packages.log` - full verbose output of the most recent run
  (overwritten each run)
- `~/R/logs/update_summary.log` - the concise success/failure summary that
  gets emailed
- `~/R/logs/cron.log` - catches anything cron sees that the script's own
  logging doesn't (e.g. startup errors before logging begins); normally
  near-empty

## Known issues

- **`terra` / `mapgl` fail to build on hafdruna.** The current CRAN `terra`
  requires GDAL >= 3.8, but the system GDAL is 3.6.2 (Debian bullseye). The
  build fails on the 3-argument `GDALMDArray::AsClassicDataset` call, which
  only exists from GDAL 3.8 onwards. Until the system GDAL is upgraded (or a
  newer GDAL module is made available), pin an older compatible `terra`:
  ```r
  remotes::install_version("terra", version = "1.7-78",
                           repos = "https://cloud.r-project.org")
  ```
  `mapgl` should install once a working `terra` is in place.