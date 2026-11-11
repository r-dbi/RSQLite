#ifndef RSQLITE_SQLITEARROWCOLUMN_H
#define RSQLITE_SQLITEARROWCOLUMN_H

#include <string>

#include "sqlite3-cpp.h"
#include "DbArrow.h"
#include "SqliteColumnDataSource.h"

// The Arrow type of a result column.
//
// SQLite is dynamically typed, so the type is decided from the first value
// seen (int64, double, utf8 or binary), or from the declared type of the
// column: the date and time types when `extended_types` is set, otherwise the
// affinity, which only matters when every value of the first chunk is NULL.
// Columns without a declared type that never see a value are of the null type.
//
// An Arrow stream fixes the type with its first chunk, its schema is a
// contract. A data frame fetch keeps it open, like the default path does:
// columns stay undecided while they see only NULL, integers widen to double,
// and the null type is decided again by the next fetch. It also stores times
// and timestamps as doubles in seconds, which keep the default path's
// precision and range, where an Arrow stream has microseconds, and ends text
// at its first NUL without checking it for UTF-8, as the default path does.
enum ARROW_KIND {
  AK_UNDECIDED,
  AK_NA,
  AK_INT64,
  AK_DOUBLE,
  AK_STRING,
  AK_BINARY,
  AK_DATE,
  AK_TIME,
  AK_TIMESTAMP
};

class SqliteArrowColumn {
  sqlite3_stmt* stmt;
  const int j;
  const std::string name;
  const bool with_alt_types;
  SqliteColumnDataSource source;

  ARROW_KIND kind;
  // Set when the schema has been handed out: the kind is final from then on
  bool frozen;
  // Set while the column builds arrays for a data frame fetch
  bool data_frame;

  // Child array of the chunk under construction, and its type: the null type
  // for an undecided column whose chunk ends while it is open
  nanoarrow::UniqueArray array;
  ARROW_KIND array_kind;
  // Rows of the current chunk seen while undecided (all NULL)
  int64_t pending_nulls;
  bool warned;
  bool warned_range;
  bool warned_utf8;
  // Set once an integer has needed 64 bits: like the default path, a data
  // frame keeps the column as integer64 from then on
  bool wide_ints;

  // The value of the current row: its storage class, read before any
  // conversion, and for a utf8 or binary column its bytes, read once for the
  // byte limits and the append
  int value_type;
  const void* value_data;
  int value_size;
  bool value_fetched;

public:
  SqliteArrowColumn(
    sqlite3_stmt* stmt_,
    const int j_,
    const std::string& name_,
    bool with_alt_types_
  );

public:
  bool decided() const;
  ARROW_KIND get_kind() const;
  // Starts a data frame fetch of a new execution from the type and the 64-bit
  // flag of the last one, like the default path; an undecided type keeps the
  // decision from the first row
  void carry_over(ARROW_KIND kind_, bool wide_ints_);
  // Decides the kind from the value of the current row, if there is one
  void decide_from_row(bool has_row);
  // Types the column from the value read by read_row() for a data frame
  // fetch of no rows, like the default path: an undecided column takes the
  // type of a value that is not NULL, integers widen to double
  void peek_value();
  // Decides the kind from the declared type, falling back to the null type
  void decide_from_decltype();
  void freeze();
  // Lets the next data frame fetch decide a column of the null type again
  void reopen();
  // Selects the arrays of a data frame fetch or of an Arrow stream
  void set_data_frame(bool data_frame_);
  // For a data frame fetch: the R class of a column of times or timestamps,
  // which are stored as doubles in seconds, or an empty string
  const char* seconds_class() const;

  void set_schema(struct ArrowSchema* schema) const;
  bool wide_integers() const;

  // Chunk building
  void start_chunk();
  // Reads the storage class of the value of the current row; a row held
  // back from the previous chunk keeps it for the next one
  void read_row();
  // The bytes that the value of the current row adds to the data buffer of a
  // utf8 or binary column, zero for the other types
  int64_t value_bytes();
  // Appends the value of the current row
  void append_row();
  // Completes the chunk of `n` rows: an undecided column takes its declared
  // type, or stays open with a chunk of the null type when `keep_open` is set
  void finish_chunk(int64_t n, bool keep_open);
  // Moves the chunk to `out` and returns its type
  ARROW_KIND move_chunk_to(struct ArrowArray* out);
  // Rebuilds a chunk of this column of type `chunk_kind`, from an earlier
  // chunk of the same data frame fetch, with the column's type: a chunk of the
  // null type becomes all NULL, integers become doubles
  void conform_chunk(struct ArrowArray* chunk, ARROW_KIND chunk_kind) const;
  // The bytes in the data buffer of a utf8 or binary column
  int64_t variable_bytes();

private:
  static ARROW_KIND kind_from_column_type(int column_type);
  void note_integer(int64_t value);
  ARROW_KIND kind_from_decltype() const;

  // The type of the arrays: a time or timestamp is a double in seconds for a
  // data frame
  ARROW_KIND storage_kind() const;
  static void set_type(struct ArrowSchema* schema, ARROW_KIND kind);
  static void init_array(struct ArrowArray* out, ARROW_KIND kind);
  static void append_ints_as_doubles(
    struct ArrowArray* out,
    struct ArrowArray* ints
  );
  void init_array();
  void fetch_bytes();
  void append_value(int column_type);
  void promote_to_double();
  void warn_mixed(int column_type);
  void warn_out_of_range(int column_type);
  void warn_invalid_utf8(int column_type);
  static const char* format_kind(ARROW_KIND kind);
  static const char* format_column_type(int column_type);
};

#endif  // RSQLITE_SQLITEARROWCOLUMN_H
