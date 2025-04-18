
read_rdf_header <- function(con, pos, end)
{
  obj <- list()

  repeat {
    line <- con[pos, 1]

    pos <- pos + 1 # advancing line to read
    if(line == end) break
    
    splitLine <- strsplit(line, ':', fixed = TRUE)[[1]]
    name <- splitLine[1]
    
    if (length(splitLine) > 1) {
      
      if (substr(splitLine[2], 1, 1) == ' ') {
        splitLine[2] <- substr(splitLine[2], 2, nchar(splitLine[2]))
      }
      
      contents <- paste(splitLine[2:length(splitLine)], collapse = ':')
    } else {
      contents <- NA
    }
    
    obj[[name]] <- contents
    
    # 1 passed to this function sometimes; when it is, it forces it to read
    # one line and parse
    if (end == 1) break 
  }
  
  #returns the object
  
  return(list(data = obj, position = pos))
}

#' Read the initial meta data from the rdf file; this is the descriptor:pair 
#' data up through the END_PACKAGE_PREAMBLE keyword. These are read once for
#' each rdf file and there is only one set of meta data regardless of the 
#' number of traces.
#' @noRd
read_rdf_meta <- function(rdf.mat, rdf.obj)
{
  rdf.tmp <- read_rdf_header(rdf.mat, rdf.obj$position, 'END_PACKAGE_PREAMBLE')
  rdf.obj[['meta']] <- rdf.tmp$data
  rdf.obj$position <- rdf.tmp$position
  return(rdf.obj)
}

read_rdf_run <- function(rdf.mat, rdf.obj)
{
  this.run <- length(rdf.obj$runs) + 1
  rdf.tmp <- read_rdf_header(rdf.mat,rdf.obj$position,'END_RUN_PREAMBLE')
  rdf.obj$runs[[this.run]] <- rdf.tmp$data
  rdf.obj$position <- rdf.tmp$position
  
  # Check if trace is specified in the file
  if ("trace" %in% names(rdf.obj$runs[[this.run]])) {
    trace_num <- rdf.obj$runs[[this.run]][["trace"]]
    
    # If we find an existing item with this index, warn and use a unique index
    if (trace_num %in% names(rdf.obj$runs)) {
      warning(paste0("Duplicate trace number found: ", trace_num, 
                     ". Using sequential numbering instead."))
    } else {
      # Use the actual trace number as the name of the list element
      names(rdf.obj$runs)[this.run] <- trace_num
    }
  } else {
    # If no trace number was found, assign the current index
    rdf.obj$runs[[this.run]]$trace <- as.character(this.run)
  }
  
  #time steps
  nts <- as.integer(rdf.obj$runs[[this.run]]$time_steps)
  #for non-mrm files
  if (length(nts) == 0) {
    nts <- as.integer(rdf.obj$runs[[this.run]]$timesteps)
  }
  
  rr <- rdf.obj$position:(rdf.obj$position + nts -1)
  rdf.obj$runs[[this.run]][['times']] <- rdf.mat[rr, 1]
  rdf.obj$position <- rdf.obj$position + nts 

  #Series
  nob <- 0
  repeat {
    
    nob <- nob + 1
    rdf.tmp <- read_rdf_header(rdf.mat,rdf.obj$position, 'END_SLOT_PREAMBLE')
    rdf.obj$runs[[this.run]][['objects']][[nob]] <- rdf.tmp$data
    rdf.obj$position <- rdf.tmp$position
    
    # name the object after their object.slot name
    obj.name <- rdf.obj$runs[[this.run]][['objects']][[nob]]$object_name
    slot.name <- rdf.obj$runs[[this.run]][['objects']][[nob]]$slot_name
    name <- paste(obj.name, slot.name, sep = '.')
    names(rdf.obj$runs[[this.run]][['objects']])[nob] <- name
    
    # read in the extr two header pieces
    rdf.tmp <- read_rdf_header(rdf.mat,rdf.obj$position, 1)
    rdf.obj$runs[[this.run]][['objects']][[nob]]$units <- rdf.tmp$data[[1]]
    rdf.obj$position <- rdf.tmp$position
    rdf.tmp <- read_rdf_header(rdf.mat,rdf.obj$position, 1)
    rdf.obj$runs[[this.run]][['objects']][[nob]]$scale <- rdf.tmp$data[[1]]
    rdf.obj$position <- rdf.tmp$position

    # Figure out when the END_COLUMN keyword shows up
    #rdf_tmp <- read_rdf_header(rdf.mat, rdf.obj$position, "END_COLUMN")
    ec_pos <- Position(function(x) x > rdf.obj$position, rdf.obj$end_col_i) 
    ec_i <- rdf.obj$end_col_i[ec_pos] + 1
    
    # remove the already used indeces so next Position call doesn't have to
    # search for indeces that are already used
    rdf.obj$end_col_i <- rdf.obj$end_col_i[
      (ec_pos + 1):length(rdf.obj$end_col_i)
    ]
    
    if (ec_i == rdf.obj$position + 2) {
      # must be a scalar slot
      row_nums <- rdf.obj$position
    } else if (ec_i - rdf.obj$position - 1 == nts) {
      row_nums <- rdf.obj$position:(ec_i - 2)
    } else {
      stop(
        "rdf includes an unexpected number of data points.\n",
        "`read.rdf()` expects the data entries to either be 1, or\n",
        "the number of time steps."
      )
    }
    
    rdf.obj$runs[[this.run]][['objects']][[nob]]$values <- as.numeric(
      rdf.mat[row_nums, 1]
    )
    rdf.obj$position <- rdf.obj$position + length(row_nums)
    
    #END_COLUMN,END_SLOT, table slots need support here
    #dummy <- readLines(rdf.con,n=2) # just advances position by 2??
    
    
    if (rdf.mat[rdf.obj$position+2,1] == 'END_RUN') {
      rdf.obj$position <- rdf.obj$position + 3
      break
    } else {
      rdf.obj$position <- rdf.obj$position + 2
    }
  }
  
  return(rdf.obj)
}

#' Read an rdf file into R.
#' 
#' `read.rdf()` reads an rdf file into R and formats it as a multi-level list 
#' containing all of the metadata included in the rdf file.  rdf files are 
#' generated by RiverWare and are documented in the 
#' [RiverWare documentation](http://www.riverware.org/HelpSystem/index.html).
#' 
#' `read.rdf()`uses [data.table::fread()] to read in the file, which provides
#' performance benefits as compared to earlier versions of the function. 
#' 
#' `read.rdf2()` is deprecated and will be removed in a future release.
#' 
#' @param iFile The input rdf file that will be read into R.
#' @param rdf Boolean; if `TRUE`, then an rdf object is returned. If `FALSE`, 
#'   then a character vector is returned.
#' 
#' @return An rdf object or character vector.
#'   
#' @examples
#' zz <- read_rdf(system.file(
#'   'extdata/Scenario/ISM1988_2014,2007Dems,IG,Most', 
#'   "KeySlots.rdf", 
#'   package = "RWDataPlyr"
#' ))
#' 
#' @export

read.rdf <- function(iFile, rdf = TRUE)
{
  check_rdf_file(iFile)
  
  rdf.obj <- list()
  # read entire file into memory
  rdf.mat <- as.matrix(data.table::fread(
    iFile, 
    sep = '\t', 
    header = FALSE, 
    data.table = FALSE
  ))
  
  if (!rdf) {
    return(rdf.mat)
  }
  
  rdf.obj$position <- 1 # initialize where to read from
  rdf.obj <- read_rdf_meta(rdf.mat, rdf.obj)
  
  rdf.obj$end_col_i <- which(rdf.mat == "END_COLUMN")
  
  # Read each trace/run using the expected number of runs
  expected_runs <- as.numeric(rdf.obj$meta$number_of_runs)
  
  # Initialize runs list
  rdf.obj$runs <- list()
  
  # Counter for runs actually processed
  runs_processed <- 0
  
  # Continue reading until we've processed all expected runs or reached end of file
  while (runs_processed < expected_runs && rdf.obj$position < nrow(rdf.mat)) {
    rdf.obj <- read_rdf_run(rdf.mat, rdf.obj)
    runs_processed <- runs_processed + 1
  }
  
  rdf.obj$position <- NULL # remove position before returning
  rdf.obj$end_col_i <- NULL
  
  structure(
    rdf.obj,
    class = "rdf"
  )
}

#' @describeIn read.rdf Deprecated version of `read.rdf()`
#' @export

read.rdf2 <- function(iFile)
{
  .Deprecated("read.rdf")
  
  read.rdf(iFile, rdf = TRUE)
}

#' @rdname read.rdf
#' @export
read_rdf <- read.rdf

check_rdf_file <- function(file)
{
  if (tools::file_ext(file) != "rdf") {
    stop(
      file, " does not appear to be an rdf file.",
      call. = FALSE
    )
  }
  
  if (!file.exists(file)) {
    stop(
      file, " does not exist.",
      call. = FALSE
    )
  }
  
  invisible(file)
}
