DBItest::make_context(
  SQLite(),
  list(dbname = tempfile("DBItest", fileext = ".sqlite")),
  tweaks = DBItest::tweaks(
    constructor_relax_args = TRUE,
    placeholder_pattern = c("?", "$1", "$name", ":name")
  ),
  name = "RSQLite"
)
