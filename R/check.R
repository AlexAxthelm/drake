#' @title Function \code{check}
#' @description Check a workflow plan, etc. for obvious
#' errors such as circular dependencies and
#' missing input files.
#' @seealso \code{link{plan}}, \code{\link{make}}
#' @export
#' @return invisibly return \code{plan}
#' @param plan workflow plan data frame, possibly from
#' \code{\link{plan}()}.
#' @param targets character vector of targets to make
#' @param envir environment containing user-defined functions
#' @examples
#' \dontrun{
#' load_basic_example()
#' check(my_plan)
#' unlink('report.Rmd')
#' check(my_plan)
#' }
check <- function(plan, targets = drake::possible_targets(plan),
  envir = parent.frame()) {
  force(envir)
  config <- build_config(plan = plan, targets = targets, envir = envir,
    verbose = TRUE, parallelism = "mclapply",
    jobs = 1, packages = character(0),
    prepend = character(0), prework = character(0), command = character(0),
    args = character(0))
  check_config(config)
  check_strings(config$plan)
  invisible(plan)
}

check_config <- function(config) {
  stopifnot(is.data.frame(config$plan))
  if (!all(c("target", "command") %in% colnames(config$plan)))
    stop("The columns of your workflow plan data frame ",
      "must include 'target' and 'command'.")
  stopifnot(nrow(config$plan) > 0)
  stopifnot(length(config$targets) > 0)
  missing_input_files(config)
  warn_bad_symbols(config$plan$target)
}

missing_input_files <- function(config) {
  missing_files <- next_targets(config$graph) %>%
    Filter(f = is_file) %>%
    unquote %>%
    Filter(f = function(x) !file.exists(x))
  if (length(missing_files))
    warning("missing input files:\n", multiline_message(missing_files))
  invisible(missing_files)
}

warn_bad_symbols <- function(x) {
  x <- unquote(x)
  bad <- which(!is_parsable(x)) %>% names
  if (!length(bad))
    return(invisible())
  warning("Possibly bad target names:\n", multiline_message(bad))
  invisible()
}

check_strings <- function(plan) {
  x <- stri_extract_all_regex(plan$command, "(?<=\").*?(?=\")")
  names(x) <- plan$target
  x <- x[!is.na(x)]
  if (!length(x))
    return()
  x <- lapply(x, function(y) {
    if (length(y) > 2)
      return(y[seq(from = 1, to = length(y), by = 2)]) else return(y)
  })
  cat("Double-quoted strings were found in plan$command.",
    "Should these be single-quoted instead?",
    "Remember: single-quoted strings are file target dependencies",
    "and double-quoted strings are just ordinary strings.",
    sep = "\n")
  for (target in seq_len(length(x))) {
    cat("\ntarget:", names(x)[target], "\n")
    cat("strings in command:\n", multiline_message(quotes(x[[target]],
      single = FALSE)), "\n", sep = "")
  }
}

multiline_message <- function(x) {
  paste0("  ", x) %>% paste(collapse = "\n")
}
