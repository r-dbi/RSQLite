# Functions used to connect to Connections Pane in Rstudio
# Implementing connections contract: https://rstudio.github.io/rstudio-extensions/connections-contract.html
sqlite_ListObjectTypes <- function(con) {
  object_types <- list(table = list(contains="data"))

  types <- dbGetQuery(con, "SELECT DISTINCT type FROM sqlite_master")[[1]]
  if (any(types =="view")){
    object_types <- c(object_types, view=list(contains="data"))
  }
  object_types
}

sqlite_ListObjects <- function(con, catalog = NULL, schema = NULL, name = NULL, type = NULL, ...) {
  objects <- dbGetQuery(con, "SELECT name,type FROM sqlite_master")
  objects <- objects[objects$type %in% c("table","view"),]
  objects
}

sqlite_ListColumns <- function(con, table = NULL, view = NULL,
                                           catalog = NULL, schema = NULL, ...) {
  if (is.null(table)){
    table <- view
  }

  tb <- dbGetQuery(
    con,
    paste("SELECT * FROM",dbQuoteIdentifier(con, table),"WHERE FALSE")
  )

  name <- names(tb)
  type <- sapply(tb, class)

  data.frame(
    name = name,
    type = type,
    stringsAsFactors = FALSE
  )
}

sqlite_PreviewObject <- function(con, rowLimit, table = NULL, view = NULL, ...) {
  # extract object name from arguments
  name <- if (is.null(table)) view else table
  dbGetQuery(con, paste("SELECT * FROM", dbQuoteIdentifier(con, name)), n = rowLimit)
}

sqlite_ConnectionIcon <- function(con) {
  system.file("icons/sqlite.png", package="RSQLite")
}

sqlite_ConnectionActions <- function(con) {
  actions <- list()
  actions <- c(actions, list(
    Help = list(
      icon = "",
      callback = function() {
        utils::browseURL("https://rsqlite.r-dbi.org/")
      }
    )
  ))

  actions
}


get_host <- function(con){
  if (con@dbname == ""){
    return("")
  }
  paste0("<",con@dbname, ">")
}

##### Functions that trigger update in Rstudio Connections tab

on_connection_opened <- function(con) {
  observer <- getOption("connectionObserver")
  if (is.null(observer))
    return(invisible(NULL))

  code <- paste0(
"library(DBI)
con <- dbConnect(RSQLite::SQLite(), dbname=\"",con@dbname,"\")
")
  icon <- sqlite_ConnectionIcon(con)

  host <- get_host(con)

    # let observer know that connection has opened
  observer$connectionOpened(
    # connection type
    type = "RSQLite",

    # name displayed in connection pane (to be improved)
    displayName = paste0("SQLite "
                        , host
                        , if (con@dbname == "") " (temporary)"
                        ),

    host = host,

    icon = icon,

    # connection code
    connectCode = code,

    # disconnection code
    disconnect = function() {
      dbDisconnect(con, shutdown = TRUE)
    },

    listObjectTypes = function () {
      sqlite_ListObjectTypes(con)
    },

    # table enumeration code
    listObjects = function(...) {
      sqlite_ListObjects(con, ...)
    },

    # column enumeration code
    listColumns = function(...) {
      sqlite_ListColumns(con, ...)
    },

    # table preview code
    previewObject = function(rowLimit, ...) {
      sqlite_PreviewObject(con, rowLimit, ...)
    },

    # other actions that can be executed on this connection
    actions = sqlite_ConnectionActions(con),

    # raw connection object
    connectionObject = con
  )
}

on_connection_updated <- function(con, hint) {
  observer <- getOption("connectionObserver")
  if (is.null(observer))
    return(invisible(NULL))

  host <- get_host(con)
  observer$connectionUpdated("RSQLite", host, hint = hint)
}

on_connection_closed <- function(con) {
  observer <- getOption("connectionObserver")
  if (is.null(observer))
    return(invisible(NULL))

  host <- get_host(con)
  observer$connectionClosed("RSQLite", host)
}
