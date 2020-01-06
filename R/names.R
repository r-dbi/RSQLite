set_tidy_names <- function(x) {
  new_names <- tidy_names(names2(x))
  names(x) <- new_names
  x
}

names2 <- function(x) {
  name <- names(x)
  if (is.null(name)) {
    name <- rep("", length(x))
  }
  name
}

tidy_names <- function(name) {
  name[is.na(name)] <- ""
  append_pos(name)
}

append_pos <- function(name) {
  need_append_pos <- name == ""
  append_pos <- which(need_append_pos)
  name[append_pos] <- paste0(name[append_pos], "..", append_pos)
  name
}
