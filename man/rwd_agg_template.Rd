% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/rwd_agg_helpers.R
\name{rwd_agg_template}
\alias{rwd_agg_template}
\title{Create a \code{rwd_agg} template}
\usage{
rwd_agg_template(file, path = ".", examples = FALSE)
}
\arguments{
\item{file}{The file name to use for the template}

\item{path}{The path to create the template at}

\item{examples}{Boolean; When \code{FALSE} (default), the template includes only
headers. When \code{TRUE}, the template will include several examples of
specifying how each slot should be summarized.}
}
\description{
\code{rwd_agg_template()} creates a template csv file to use to create a RiverWare
data aggregator (\link{rwd_agg}).
}
\examples{
rwd_agg_template(file = "rwa_slots.csv", path = tempdir())
rwd_agg_template(file = "rwa_slots.csv", path = tempdir(), examples = TRUE)

}
\seealso{
\code{\link[=read_rwd_agg]{read_rwd_agg()}}
}
