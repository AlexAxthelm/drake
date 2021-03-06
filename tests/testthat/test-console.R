context("console")

test_with_dir("console", {
  dclean()
  config <- dbug()
  config$verbose <- TRUE
  expect_output(console(imported = FALSE, target = "myinput",
    config = config))
  expect_output(
    console_parallel_stage(targets = letters, config = config))
  x50 <- paste(rep(0:9, 5), collapse = "")
  x51 <- paste0(x50, 0)
  o1 <- capture.output(console(imported = FALSE, target = x50,
    config = config))
  o2 <- capture.output(console(imported = FALSE, target = x51,
    config = config))
  expect_equal(nchar(o1), nchar(o2), 50)
  dots <- "\\.\\.\\.$"
  expect_false(grepl(dots, o1))
  expect_true(grepl(dots, o2))
  dclean()
})

test_with_dir("console_parallel_stage() works", {
  config <- list(verbose = FALSE)
  expect_silent(console_parallel_stage(
    targets = character(0), config = config))
  expect_silent(console_parallel_stage(
    targets = "my_target", config = config))
  config <- list(verbose = TRUE)
  expect_silent(console_parallel_stage(
    targets = character(0), config = config))
  expect_output(console_parallel_stage(
    targets = "my_target", config = config))
})
