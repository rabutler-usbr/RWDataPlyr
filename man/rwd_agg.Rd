% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/rwd_agg.R
\name{rwd_agg}
\alias{rwd_agg}
\title{Class to specify how to aggregate RiverWare data}
\usage{
rwd_agg(x = NULL, rdfs = NULL)
}
\arguments{
\item{x}{A data.frame with required column names and valid entries; see
\emph{Details} and \emph{Aggregation Specification} sections.}

\item{rdfs}{A vector of rdf names; see \emph{Details} and
\emph{Aggregation Specification} sections.}
}
\description{
\code{rwd_agg()} creates a RiverWare data aggregator (\code{rwd_agg}) object, which
lets users specify how specific RiverWare slots should be aggregated.
}
\details{
\code{rwd_agg} objects can be created in three ways:
\enumerate{
\item By providing a data.frame, with the following expected columns \code{file},
\code{slot}, \code{period}, \code{summary}, \code{eval}, \code{t_s}, and \code{variable}. Each row in the
data.frame should include all of the information for how each individual
slot will be aggregated. See the \emph{Aggregation Specification} section below
for details on how to specify each column.
\item By providing a vector of rdf files. If specified in this manor, all of the
slots in each rdf file will be read in to a \code{rwtbl}, but will not be
aggregated/summarized.

In this case, the \code{variable} names are automatically constructed from the
\code{ObjectSlot} names. The variable names are constructed as the all lower
case version of the object_slot name. If the slot name is "Pool Elevation",
it is shortened to "pe", otherwise the full object and slot name are used.
If there are any spaces, they are replaced with underscores.
\item By reading in a csv file with \code{\link[=read_rwd_agg]{read_rwd_agg()}}. This csv file must have
the correct column names and meet other requirements described below. To
ensure it has the correct column names, \code{\link[=rwd_agg_template]{rwd_agg_template()}} can be used
to create a blank csv file for the user to fill in.
}
}
\section{Aggregation Specification}{


In order to specify how each slot should be aggregated, each column should
include specific keywords, which are described below. It is up to the user
to specify which rdf file contains each slot. In a general case, the user
specifies the \code{slot} that is found in a specific rdf file (\code{file}). A
\code{summary} function is applied to a subset \code{period} of the \code{slot}, and then
compared (\code{eval}) to a threshold (\code{t_s}) and saved as the \code{variable}.
\itemize{
\item \emph{file:} specifies the rdf file that contains the slot.
\item \emph{slot:} the full RiverWare slot name, i.e., "Object.Slot".
\item \emph{period:} the period that the slot should be summarized over. This should
either be a function name, a full month name (found in \link{month.name}), or
the keyword "asis".
\itemize{
\item \emph{function name:} Specifying a function name allows for pre-specified
or custom functions to group together several months in the \emph{period}.
This package provides the following functions: \code{cy()}, \code{wy()},
\code{eocy()}, and \code{eowy()}. \code{cy()} indicates the data will be summarized
over the calendar year, i.e., January - December, while \code{wy()}
summarizes over the water year, i.e., October - September. \code{eocy()}
selects the end of the calendar year, and \code{eowy()} selects the end of
the water year. When specified in the \code{slot_agg} object, leave off the
parenthesis, i.e., only specify the function name. If \code{wy()} is
specified, the function will remove data for any water years that have
less than 7 months of data. This "tolerance" is specified by the
\code{rwdataplyr.wy_month_tol} option, and can be modified by updating this
option to another number. For standard monthly data that starts in
January and ends in December, this results in keeping the first water
year, since it includes 9 months of data, and removing the final water
year, since it includes only three months of data. Setting this option
to 0 will result in keeping any water year data that has at least one
month of data; setting this option to 11, ensures that there must be
a full water year of data for that year to be kept.

This can also be a user specified custom function; see the
\emph{Custom Period Functions} section for details on constructing the custom
functions.
\item \emph{full month name:} When the full month name is specified, data will
be filtered to only include data for that particular month. To select
multiple months of data, use a function as described above. If the
month specified is not found in \link{month.name}, an error will occur.
\item \emph{asis:} If the keyword "asis" is specified, the data is returned for
its native timestep, i.e, monthly data will return monthly data and
annual data will return annual.
}
\item \emph{summary:} the summary function that should be applied to the period
specified as a function name, or \code{NA}. If the \code{period} specified is "asis"
or returns only one month, e.g., \code{eocy()}, then the summary should be \code{NA}.
The summary function should only return one value; for that reason, most
of the \code{Summary} \link{S4groupGeneric}s work. Notably, \code{range()} will not
since it returns two values. There is no reason that a custom function
will not work here, but it has not been tested.
\item \emph{eval:} the comparison operator to use (see the \code{Compare}
\link{S4groupGeneric}s). If no comparison is desired, then \code{NA} should be used.
If \code{eval} is specified the value returned from applying the \code{summary} to
the \code{period} will be compared to the threshold specified by \code{t_s}. The
results of the comparison are returned as 0 and 1 instead of \code{TRUE} and
\code{FALSE}.
\item \emph{t_s:} either the threshold to be compared to if \code{eval} is not \code{NA} or a
value to scale the result by, e.g,. 0.001 to convert from acre-ft to
thousand acre-ft. \code{NA} can also be specified to not scale the data.
\item \emph{variable:} the variable name that will be used to identify the results
of applying the period, summary, comparison/scaling to. All variable names
should be unique.
}

For example, to determine if the minimum water year elevation at Lake Powell
is below elevation 3550 feet, the following would be specified:

\if{html}{\out{<div class="sourceCode">}}\preformatted{data.frame(
  file = "KeySlots.rdf",
  slot = "Powell.Pool Elevation",
  period = "wy",
  summary = "min",
  eval = "<",
  t_s = 3550,
  variable = "powellLt3550",
  stringsAsFactors = FALSE
)
}\if{html}{\out{</div>}}
}

\section{Custom Period Functions}{


Users can specify custom period functions to make it easier to group months
together in custom ways. For example a function could return all of the
summer months, or the more complicated case groups months across different
calendar years together. In fact, \code{wy()} is an example of a function that
does this; another example might be grouping December - February together
for winter months.

The custom period function should return a list with three elements:
\itemize{
\item \code{fun} - a function that will modify a rwtbl and properly determine the
new \code{Year}s based on the custom period.
\item \code{filter_months} - the months that should be grouped together.
\item \code{group_tbl} - how to group the returned rwtbl; likely either \code{c("Year")} or
\code{c("Year", "Month")}
}

See the "RWDataPlyr Workflow" vignette for example implementations of both
the summer and winter custom functions described above.
}

\examples{
# determine if Powell's minimum water year elevation is < 3550'
rwd_agg(
  data.frame(
    file = "KeySlots.rdf",
    slot = "Powell.Pool Elevation",
    period = "wy",
    summary = "min",
    eval = "<",
    t_s = 3550,
    variable = "powellLt3550",
    stringsAsFactors = FALSE
  )
)

# get all the monthly slots in KeySlots.rdf
rwd_agg(rdfs = "KeySlots.rdf")

}
\seealso{
\code{\link[=rwd_agg_template]{rwd_agg_template()}}, \code{\link[=read_rwd_agg]{read_rwd_agg()}}
}
