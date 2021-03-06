context("edge-cases")

test_with_dir("graph does not fail if input file is binary", {
  dclean()
  x <- plan(y = readRDS("input.rds"))
  saveRDS(as.list(mtcars), "input.rds")
  expect_silent(out <- plot_graph(x, verbose = FALSE))
  unlink("input.rds", force = TRUE)
  dclean()
})

test_with_dir("different graphical arrangements for Makefile parallelism", {
  dclean()
  e <- new.env()
  x <- plan(a = 1, b = f(2))
  e$f <- function(x) x
  con <- config(x, envir = e, verbose = FALSE)
  expect_equal(1, max_useful_jobs(x, envir = e, config = con,
    parallelism = "mclapply", jobs = 1))
  expect_equal(1, max_useful_jobs(x, envir = e, config = con,
    parallelism = "parLapply", jobs = 1))
  expect_equal(2, max_useful_jobs(x, envir = e, config = con,
    parallelism = "Makefile", jobs = 1))
  dclean()
})

test_with_dir("Vectorized nested functions work", {
  dclean()
  e <- new.env(parent = globalenv())
  eval(parse(text = "f <- Vectorize(function(x) g(x), \"x\")"),
    envir = e)
  eval(parse(text = "g <- function(x) x + y"), envir = e)
  e$y <- 7
  config <- dbug()
  config$envir <- e
  config$plan <- plan(a = f(1:10))
  config$targets <- "a"
  expect_equal(deps(e$f), "g")
  expect_equal(deps(e$g), "y")

  testrun(config)
  if ("a" %in% ls(config$envir)){
    rm(a, envir = config$envir)
  }
  expect_equal(readd(a), 8:17)
  k <- readd(f)
  expect_equal(k(2:5), 9:12)
  expect_equal(character(0), outdated(config$plan, envir = config$envir,
    verbose = FALSE))
  config$envir$y <- 8
  expect_equal("a", outdated(config$plan, envir = config$envir,
    verbose = FALSE))

  # Target "a" should react.
  testrun(config)
  expect_equal(character(0), outdated(config$plan, envir = config$envir,
    verbose = FALSE))
  expect_equal(readd(a), 9:18)

  # Change a vectorized function and see target "a" react.
  eval(parse(text = "f <- Vectorize(function(x){g(x) + 3}, \"x\")"),
    envir = e)
  testrun(config)
  expect_equal(justbuilt(config), "a")
  expect_equal(readd(a), 12:21)
  dclean()
})

test_with_dir("stringsAsFactors can be TRUE", {
  dclean()
  f <- function(x) {
    return(x)
  }
  myplan <- data.frame(target = "a", command = "f(\"helloworld\")",
    stringsAsFactors = TRUE)
  expect_true(is.factor(myplan$target))
  expect_true(is.factor(myplan$command))
  make(myplan, verbose = FALSE)
  expect_equal(readd(a), "helloworld")
  dclean()
})

test_with_dir("circular non-DAG workflows quit in error", {
  dclean()
  p <- plan(a = b, b = c, c = a)
  expect_error(tmp <- capture.output(check(p)))
  expect_error(make(p, verbose = FALSE))
  dclean()
})

# Target/import conflicts are unpredictable. A warning should
# be enough.
test_with_dir("target conflicts with current import or another target", {
  dclean()
  config <- dbug()
  config$plan <- rbind(config$plan, data.frame(target = "f",
    command = "1+1"))
  expect_silent(tmp <- capture.output(check(plan = config$plan,
    envir = config$envir)))
  config$plan$target <- "repeated"
  expect_error(check(plan = config$plan))
})

test_with_dir("target conflicts with previous import", {
  dclean()
  config <- dbug()
  testrun(config)
  config$plan$command[2] <- "g(1+1)"
  config$plan <- rbind(config$plan, data.frame(target = "f",
    command = "1+1"))
  config$targets <- config$plan$target
  testrun(config)
  expect_equal(justbuilt(config), sort(c("'intermediatefile.rds'",
    "combined", "f", "final", "yourinput")))
  dclean()
})

test_with_dir("can use semicolons and multi-line commands", {
  dclean()
  plan <- plan(list = c(x = "a<-1; a", y = "b<-2\nb"))
  make(plan, verbose = FALSE)
  expect_false(any(c("a", "b") %in% ls()))
  expect_true(all(cached(x, y, search = FALSE)))
  expect_equal(cached(search = FALSE), c("x", "y"))
  dclean()
})

test_with_dir("true targets can be functions", {
  dclean()
  generator <- function() return(function(x) {
    x + 1
  })
  plan <- plan(myfunction = generator(), output = myfunction(1))
  config <- make(plan, verbose = FALSE, return_config = TRUE)
  expect_equal(readd(output), 2)
  expect_true(is.list(config$cache$get("myfunction")))
  myfunction <- readd(myfunction)
  expect_equal(myfunction(4), 5)
  dclean()
})

test_with_dir("warn when file target names do not match actual filenames", {
  dclean()
  x <- plan(y = 1, file_targets = TRUE)
  expect_warning(con <- make(x, verbose = FALSE, return_config = TRUE))
  dclean()
})

test_with_dir("stress test hashing decisions", {
  dclean()
  file <- "input.rds"
  expect_true(should_rehash_file(
    file = file, new_mtime = 0, old_mtime = 0, size_cutoff = Inf))
  expect_true(should_rehash_file(
    file = file, new_mtime = 1, old_mtime = 0, size_cutoff = Inf))
  expect_true(should_rehash_file(
    file = file, new_mtime = 0, old_mtime = 1, size_cutoff = Inf))
  expect_true(should_rehash_file(
    file = file, new_mtime = 0, old_mtime = 0, size_cutoff = -1))
  expect_true(should_rehash_file(
    file = file, new_mtime = 1, old_mtime = 0, size_cutoff = -1))
  expect_true(should_rehash_file(
    file = file, new_mtime = 0, old_mtime = 1, size_cutoff = -1))
  saveRDS(1, file = file)
  expect_true(file.exists(file))
  expect_true(should_rehash_file(
    file = file, new_mtime = 1, old_mtime = 0, size_cutoff = Inf))
  expect_true(should_rehash_file(
    file = file, new_mtime = 0, old_mtime = 1, size_cutoff = Inf))
  expect_true(should_rehash_file(
    file = file, new_mtime = 0, old_mtime = 0, size_cutoff = Inf))
  expect_true(should_rehash_file(
    file = file, new_mtime = 1, old_mtime = 0, size_cutoff = -1))
  expect_false(should_rehash_file(
    file = file, new_mtime = 0, old_mtime = 1, size_cutoff = -1))
  expect_false(should_rehash_file(
    file = file, new_mtime = 0, old_mtime = 0, size_cutoff = -1))
  unlink(file, force = TRUE)
  dclean()
})
