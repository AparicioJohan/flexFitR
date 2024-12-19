#' @importFrom utils install.packages menu
ensure_packages <- function(packages) {
  # Function to check and install missing CRAN packages
  missing_packages <- packages[!sapply(packages, requireNamespace, quietly = TRUE)]
  if (length(missing_packages) > 0) {
    if (interactive()) {
      cat("The following packages are missing:\n", paste(missing_packages, collapse = ", "), "\n")
      choice <- menu(c("Yes", "No"), title = "Would you like to install them now?")
      if (choice == 1) { # User chose "Yes"
        install.packages(missing_packages, quiet = TRUE)
        # Re-check if packages were successfully installed
        missing_packages <- missing_packages[!sapply(missing_packages, requireNamespace, quietly = TRUE)]
        if (length(missing_packages) > 0) {
          message("The following packages could not be installed: ", paste(missing_packages, collapse = ", "))
          return(FALSE)
        }
      } else { # User chose "No"
        message("Please manually install the missing packages: ", paste(missing_packages, collapse = ", "))
        return(FALSE)
      }
    } else { # Non-interactive session
      message("The following packages are required but not installed: ", paste(missing_packages, collapse = ", "))
      message("Please install them manually using install.packages().")
      return(FALSE)
    }
  }
  return(TRUE)
}
