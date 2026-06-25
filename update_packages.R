# ~/R/scripts/update_packages.R
log_file     <- path.expand("~/R/logs/update_packages.log")
summary_file <- path.expand("~/R/logs/update_summary.log")
dir.create(path.expand("~/R/logs"), showWarnings = FALSE, recursive = TRUE)

log_con <- file(log_file, open = "wt")          # full verbose log on disk
sink(log_con, type = "output")
sink(log_con, type = "message")
on.exit({                                        # safety net: always tear down + close
  sink(type = "message")
  sink(type = "output")
  close(log_con)
}, add = TRUE)

started <- Sys.time()
cat("Package update started:", as.character(started), "\n\n")

options(repos = c(
  HAFRO = "https://cran.hafro.is/",
  CRAN  = "https://cloud.r-project.org/",
  INLA  = "https://inla.r-inla-download.org/R/stable"
))

# Remove stale locks
lib_paths <- .libPaths()
for (lib in lib_paths) {
  locks <- list.files(lib, pattern = "^00LOCK", full.names = TRUE)
  if (length(locks) > 0) {
    cat("Removing stale locks:", paste(locks, collapse = ", "), "\n")
    unlink(locks, recursive = TRUE)
  }
}

# Snapshot installed versions so we can diff before/after
installed_versions <- function() {
  ip <- installed.packages()
  stats::setNames(ip[, "Version"], rownames(ip))
}
before <- installed_versions()
warns  <- character(0)

# Run all updates, capturing warnings (failed installs surface as warnings)
withCallingHandlers({

  cat("\n--- CRAN Updates ---\n")
  tryCatch({
    old <- utils::old.packages(lib.loc = .libPaths()[1])
    if (!is.null(old) && nrow(old) > 0) {
      cat(nrow(old), "package(s) to update:", paste(old[, "Package"], collapse = ", "), "\n")
    } else {
      cat("No CRAN packages need updating.\n")
    }
    utils::update.packages(lib.loc = .libPaths()[1], ask = FALSE,
                           checkBuilt = TRUE, INSTALL_opts = "--no-lock",
                           quiet = TRUE)
  }, error = function(e) cat("Error:", conditionMessage(e), "\n"))

  cat("\n--- GitHub Updates ---\n")
  tryCatch({
    if (requireNamespace("remotes", quietly = TRUE)) {
      remotes::update_packages(upgrade = "never", quiet = TRUE)
      remotes::install_github("jacobkasper/spatialJ", upgrade = "always", quiet = TRUE)
    }
  }, error = function(e) cat("Error:", conditionMessage(e), "\n"))

}, warning = function(w) {
  warns <<- c(warns, conditionMessage(w))
  invokeRestart("muffleWarning")
})

after <- installed_versions()

# Build the summary
common      <- intersect(names(before), names(after))
updated     <- sort(common[after[common] != before[common]])
new_install <- sort(setdiff(names(after), names(before)))
failed      <- sort(unique(sub(".*package [‘’'\"]([^‘’'\"]+)[‘’'\"].*", "\\1",
                  grep("had non-zero exit status", warns, value = TRUE))))

finished     <- Sys.time()
summary_lines <- c(
  "R Package Update Report",
  paste("Started: ", format(started)),
  paste("Finished:", format(finished)),
  "",
  "========== SUMMARY =========="
)
for (p in updated)     summary_lines <- c(summary_lines, sprintf("  updated:   %s (%s -> %s)", p, before[p], after[p]))
for (p in new_install) summary_lines <- c(summary_lines, sprintf("  installed: %s (%s)", p, after[p]))
for (p in failed)      summary_lines <- c(summary_lines, sprintf("  FAILED:    %s", p))
if (!length(updated) && !length(new_install) && !length(failed))
  summary_lines <- c(summary_lines, "  nothing to update")
if (length(failed))
  summary_lines <- c(summary_lines, "",
                     paste0("  (failure details in ", log_file, " on the server)"))

# Echo the summary into the full log too, then write it out for emailing
cat("\n", paste(summary_lines, collapse = "\n"), "\n", sep = "")
writeLines(summary_lines, summary_file)

cat("\n\nUpdate completed:", as.character(finished), "\n")

# Email only the summary (on.exit handles sink teardown afterward)
system(paste0("mail -s \"R Package Update Report\" youremail@domain.com < ",
              shQuote(summary_file)))