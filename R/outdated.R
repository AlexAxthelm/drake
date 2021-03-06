#' @title Function outdated
#' @description Check which targets are out of date and need to be rebuilt.
#' IMPORTANT: you must be in the root directory of your project.
#' @export
#' @seealso \code{\link{missed}}, \code{\link{plan}},
#' \code{\link{make}}, \code{\link{plot_graph}}
#' @examples
#' \dontrun{
#' load_basic_example()
#' outdated(my_plan)
#' make(my_plan)
#' outdated(my_plan)
#' }
#' @param plan same as for \code{\link{make}}
#' @param targets same as for \code{\link{make}}
#' @param envir same as for \code{\link{make}}
#' @param verbose same as for \code{\link{make}}
#' @param parallelism same as for \code{\link{make}}
#' @param jobs same as for \code{\link{make}}
#' @param packages same as for \code{\link{make}}
#' @param prework same as for \code{\link{make}}
#' @param config option internal runtime parameter list of
#' \code{\link{make}(...)},
#' produced with \code{\link{config}()}.
#' Computing this
#' in advance could save time if you plan multiple calls to
#' \code{outdated()}.
outdated <-  function(
  plan,
  targets = drake::possible_targets(plan),
  envir = parent.frame(),
  verbose = TRUE,
  parallelism = drake::default_parallelism(),
  jobs = 1,
  packages = (.packages()),
  prework = character(0),
  config = NULL
  ){
  force(envir)
  if (is.null(config)){
    config <- config(
      plan = plan,
      targets = targets,
      envir = envir,
      verbose = verbose,
      parallelism = parallelism,
      jobs = jobs,
      packages = packages,
      prework = prework
      )
  }
  all_targets <- intersect(V(config$graph)$name, config$plan$target)
  rebuild <- Filter(
    x = all_targets,
    f = function(target){
      hashes <- hashes(target, config)
      !target_current(target = target, hashes = hashes, config = config)
    }
    )
  if (!length(rebuild)){
    return(invisible(character(0)))
  } else{
    lapply(
      rebuild,
      function(vertex){
        subcomponent(config$graph, v = vertex, mode = "out")$name
      }
      ) %>%
    unlist() %>%
    unique() %>%
    sort()
  }
}

#' @title Function \code{missed}
#' @description Report any import objects required by your workflow
#' plan but missing from your workspace.
#' IMPORTANT: you must be in the root directory of your project.
#' @export
#' @seealso \code{\link{outdated}}
#' @param plan workflow plan data frame, same as for function
#' \code{\link{make}()}.
#' @param targets names of targets to bulid, same as for function
#' \code{\link{make}()}.
#' @param envir environment to import from, same as for function
#' \code{\link{make}()}.
#' @param verbose logical, whether to output messages to the console.
#' @param jobs The \code{outdated()} function is called internally,
#' and it needs to import objects and examine your
#' input files to see what has been updated. This could take some time,
#' and parallel computing may be needed
#' to speed up the process. The \code{jobs} argument is number of parallel jobs
#' to use for faster computation.
#' @param parallelism Choice of parallel backend to speed up the computation.
#' See \code{?parallelism_choices} for details. The Makefile option is not
#' available here. Drake will try to pick the best option for your system by
#' default.
#' @param font_size numeric, font size of the node labels in the graph
#' @param packages same as for \code{\link{make}}
#' @param prework same as for \code{\link{make}}
#' @param config option internal runtime parameter list of
#' \code{\link{make}(...)},
#' produced with \code{\link{config}()}.
#' Computing this
#' in advance could save time if you plan multiple calls to
#' \code{missed()}.
#' @examples
#' \dontrun{
#' load_basic_example()
#' missed(my_plan)
#' rm(reg1)
#' missed(my_plan)
#' }
missed <- function(
  plan,
  targets = drake::possible_targets(plan),
  envir = parent.frame(),
  verbose = TRUE,
  jobs = 1,
  parallelism = drake::default_parallelism(),
  packages = (.packages()),
  prework = character(0),
  font_size = 20,
  config = NULL
  ){
  force(envir)
  if (is.null(config)){
    config <- config(
      plan = plan,
      targets = targets,
      envir = envir,
      verbose = verbose,
      parallelism = parallelism,
      jobs = jobs,
      packages = packages,
      prework = prework
      )
  }
  graph <- config$graph
  imports <- setdiff(V(graph)$name, plan$target)
  missing <- Filter(
    x = imports,
    f = function(x){
      missing_import(x, envir = envir)
    }
    )
  if (!length(missing)){
    return(invisible(character(0)))
  }
  return(missing)
}
