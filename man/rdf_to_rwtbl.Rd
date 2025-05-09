% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/rdf_to_rwtbl.R
\name{rdf_to_rwtbl}
\alias{rdf_to_rwtbl}
\alias{rdf_to_rwtbl2}
\title{Convert an rdf to a tibble}
\usage{
rdf_to_rwtbl(rdf, scenario = NULL, keep_cols = FALSE, add_ym = TRUE)

rdf_to_rwtbl2(file, scenario = NA_character_, keep_cols = FALSE, add_ym = TRUE)
}
\arguments{
\item{rdf}{An rdf object (from \code{\link[=read_rdf]{read_rdf()}}).}

\item{scenario}{An optional parameter, that if it is not \code{NULL} or \code{NA}
(default) will be added to the tibble as another variable. Coerced to a
character if it is not already a character.}

\item{keep_cols}{Either boolean, or a character vector of column names to
keep in the returned tibble. The values of \code{keep_cols} work as follows:
\itemize{
\item \code{FALSE} (default) only includes the defaults columns: \code{Timestep},
\code{TraceNumber}, \code{ObjectSlot}, and \code{Value}. \code{Scenario} is also returned if
\code{scenario} is specified.
\item \code{TRUE}, all columns are returned (see Details).
\item A character vector, e.g., \code{c("ObjectName", "Unit")}, allows the user to
include other columns that are not always required, in addition to the
"default" set of columns. If any of the values in \code{keep_cols} are not
found, a warning will post, but all other columns will be returned.
}}

\item{add_ym}{Boolean that controls whether or not \code{Year} and \code{Month} columns
are added to the returned tibble. If \code{TRUE} (default), they will be added,
and if \code{FALSE} they will not be added. They are constructed from the dates
in the \code{Timestep} column.}

\item{file}{The relative or absolute rdf filename.}
}
\value{
A tbl_df with additional attributes from the rdf object.
}
\description{
\code{rdf_to_rwtbl()} converts an rdf list to a tibble.
}
\details{
The rdf object is converted to a data frame, and then converted to a
\code{\link[tibble:tibble]{tibble::tibble()}}. All of the \code{meta} entries in the rdf object
are stored as attributes in the returned tibble. These attributes are:
\code{mrm_config_name}, \code{owner}, \code{description}, \code{create_date}, and \code{n_traces}.

All possible columns, depending on the specific values passed to \code{scenario},
\code{keep_cols}, and \code{add_ym} are:
\itemize{
\item TimeStep
\item Year
\item Month
\item Value
\item ObjectName
\item SlotName
\item ObjectSlot
\item TraceNumber
\item InputDMIName
\item RulesetFileName
\item ObjectType
\item Unit
\item Scale
}

If the rdf contains a scalar slot(s), the scalar slot value(s) will be
repeated for every timestep.
}
\examples{
rdftbl <- rdf_to_rwtbl(keyRdf)
# same as previous, except you do not want "Year" and "Month" columns
rdftbl <- rdf_to_rwtbl(keyRdf, add_ym = FALSE)
# but you do want to keep the object name seperately:
rdftbl <- rdf_to_rwtbl(keyRdf, add_ym = FALSE, keep_cols = "Object")
rdftbl <- rdf_to_rwtbl(sysRdf, scenario = "ISM1988_2014,2007Dems,IG,2002")

# rdf_to_rwtbl2 wants a file path instead of an rdf object
rdfPath <- system.file(
  "extdata/Scenario/ISM1988_2014,2007Dems,IG,Most/KeySlots.rdf", 
  package = "RWDataPlyr"
)
rdftbl <- rdf_to_rwtbl2(rdfPath)

}
\seealso{
\code{\link[=read_rdf]{read_rdf()}}
}
