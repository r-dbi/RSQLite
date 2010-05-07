.onUnload <- function(libpath) {
    library.dynam.unload("RSQLite", libpath)
}

.test <- function(dir, pattern = ".*_test\\.R$")
{
    .failure_details <- function(result) {
        res <- result[[1L]]
        if (res$nFail > 0 || res$nErr > 0) {
            Filter(function(x) length(x) > 0,
                   lapply(res$sourceFileResults,
                          function(fileRes) {
                              names(Filter(function(x) x$kind != "success",
                                           fileRes))
                          }))
        } else list()
    }

    if (missing(dir)) {
        dir <- system.file("unitTests", package="RSQLite")
        if (!nzchar(dir)) {
            dir <- system.file("UnitTests", package="RSQLite")
            if (!nzchar(dir))
                stop("unable to find unit tests, no 'unitTests' dir")
        }
    }

    ## Run unit tests from the directory containing the test files.
    ## This allows tests to refer to data files with relative paths
    cwd <- getwd()
    on.exit(setwd(cwd))
    setwd(dir)

    require("RUnit", quietly=TRUE) || stop("RUnit package not found")
    RUnit_opts <- getOption("RUnit", list())
    RUnit_opts$verbose <- 0L
    RUnit_opts$silent <- TRUE
    RUnit_opts$verbose_fail_msg <- TRUE
    options(RUnit = RUnit_opts)
    suite <- defineTestSuite(name="RSQLite RUnit Tests", dirs=getwd(),
                             testFileRegexp=pattern,
                             rngKind="default",
                             rngNormalKind="default")
    result <- runTestSuite(suite)
    cat("\n\n")
    printTextProtocol(result, showDetails=FALSE)
    if (length(details <- .failure_details(result)) >0) {
        cat("\nTest files with failing tests\n")
        for (i in seq_along(details)) {
            cat("\n  ", basename(names(details)[[i]]), "\n")
            for (j in seq_along(details[[i]])) {
                cat("    ", details[[i]][[j]], "\n")
            }
        }
        cat("\n\n")
        stop("unit tests failed for package RSQLite")
    }
    result
}
