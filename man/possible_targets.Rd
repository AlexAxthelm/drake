% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/config.R
\name{possible_targets}
\alias{possible_targets}
\title{Function \code{possible_targets}}
\usage{
possible_targets(plan)
}
\arguments{
\item{plan}{workflow plan data frame}
}
\value{
character vector of possible targets
}
\description{
internal function, returns the list of
possible targets that you can select with the \code{targets}
argument to \code{\link{make}()}.
}
\examples{
\dontrun{
load_basic_example()
possible_targets(my_plan)
}
}
\seealso{
\code{\link{make}}
}
