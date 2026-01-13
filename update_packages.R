# ~/R/scripts/update_packages.R

log_file <- path.expand("~/R/logs/update_packages.log")
dir.create(path.expand("~/R/logs"), showWarnings = FALSE, recursive = TRUE)

sink(log_file)
cat("Package update started:", as.character(Sys.time()), "\n\n")

options(repos = c(CRAN = "https://cran.hafro.is/"))

# Remove stale locks
lib_paths <- .libPaths()
for (lib in lib_paths) {
  locks <- list.files(lib, pattern = "^00LOCK", full.names = TRUE)
  if (length(locks) > 0) {
    cat("Removing stale locks:", paste(locks, collapse = ", "), "\n")
    unlink(locks, recursive = TRUE)
  }
}

# CRAN updates
cat("\n--- CRAN Updates ---\n")
tryCatch({
  utils::update.packages(lib.loc = .libPaths()[1], ask = FALSE, checkBuilt = TRUE)
}, error = function(e) cat("Error:", conditionMessage(e), "\n"))

# GitHub updates
cat("\n--- GitHub Updates ---\n")
tryCatch({
  if (requireNamespace("remotes", quietly = TRUE)) {
    remotes::update_packages(upgrade = "always")
  }
}, error = function(e) cat("Error:", conditionMessage(e), "\n"))

cat("\n\nUpdate completed:", as.character(Sys.time()), "\n")
sink()

# Email the log - change to your email
system(paste0("mail -s 'R Package Update Report' YOUR_EMAIL@hafogvatn.is < ", path.expand(log_file)))
