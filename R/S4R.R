## S4/Splus/R compatibility 

#' R compatibility with S version 4/S-Plus 5+ support functions
#' 
#' These objects ease the task of porting functions into R from S Version 4 and
#' S-Plus 5.0 and later.  See the documentation of the lower-case functions
#' there. May be obsolete in the future.
#' 
#' 
#' @aliases ErrorClass usingR
#' @keywords internal
usingR <- function(major=0, minor=0){
  if(is.null(version$language))
    return(FALSE)
  if(version$language!="R")
    return(FALSE)
  version$major>=major && version$minor>=minor
}

## constant holding the appropriate error class returned by try() 
if(usingR()){
  ErrorClass <- "try-error"
} else {
  ErrorClass <- "Error"  
}
