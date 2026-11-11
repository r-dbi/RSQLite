#ifndef RSQLITE_SQLITEARROWCOLUMN_H
#define RSQLITE_SQLITEARROWCOLUMN_H

#include <string>

#include "sqlite3-cpp.h"
#include "CoercionLog.h"
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
// A type requested up front, see ArrowTarget, skips the decision and is final
// for streams and data frame fetches alike: a data frame fetch builds arrays
// of that type, also for times and timestamps, and carries no type over to it
// from an earlier execution.
enum ARROW_KIND {
  AK_UNDECIDED,
  AK_NA,
  AK_BOOL,
  AK_INT8,
  AK_INT16,
  AK_INT32,
  AK_INT64,
  AK_UINT8,
  AK_UINT16,
  AK_UINT32,
  AK_UINT64,
  AK_FLOAT,
  AK_DOUBLE,
  AK_STRING,
  AK_LARGE_STRING,
  AK_BINARY,
  AK_LARGE_BINARY,
  AK_DATE32,
  AK_DATE64,
  AK_TIME32,
  AK_TIME64,
  AK_TIMESTAMP
};

// An Arrow type requested for a column: the kind, and for the time types the
// unit and the time zone
struct ArrowTarget {
  bool set;
  ARROW_KIND kind;
  enum ArrowTimeUnit unit;
  std::string timezone;

  ArrowTarget()
      : set(false), kind(AK_UNDECIDED), unit(NANOARROW_TIME_UNIT_MICRO) {}

  // Reads the target from a schema, throws for a type that can't be filled
  static ArrowTarget from_schema(
    const struct ArrowSchema* schema,
    const std::string& name
  );
};

class SqliteArrowColumn {
  sqlite3_stmt* stmt;
  const int j;
  const std::string name;
  const bool with_alt_types;
  SqliteColumnDataSource source;

  ARROW_KIND kind;
  enum ArrowTimeUnit unit;
  std::string timezone;
  // Set when the schema has been handed out or the type was requested:
  // the kind is final from then on
  bool frozen;
  // Set when the type was requested
  bool requested;
  // Set while the column builds arrays for a data frame fetch
  bool data_frame;

  // Child array of the chunk under construction, and its type: the null type
  // for an undecided column whose chunk ends while it is open
  nanoarrow::UniqueArray array;
  ARROW_KIND array_kind;
  // Rows of the current chunk seen while undecided (all NULL)
  int64_t pending_nulls;
  // Set once an integer has needed 64 bits: like the default path, a data
  // frame keeps the column as integer64 from then on
  bool wide_ints;
  // Set once a data frame fetch has seen a uint64 beyond 2^63 - 1, which
  // integer64 can't hold: the column is a double in data frames from then on
  bool unsigned_doubles;

  // The value of the current row: its storage class, read before any
  // conversion, and for a column of a string or binary type its bytes, read
  // once for the byte limits and the append
  int value_type;
  const void* value_data;
  int value_size;
  bool value_fetched;

  // Values that were not of the column's type, since the last call to
  // coercions()
  CoercionLog log;

public:
  SqliteArrowColumn(
    sqlite3_stmt* stmt_,
    const int j_,
    const std::string& name_,
    bool with_alt_types_,
    const ArrowTarget& target
  );

public:
  bool decided() const;
  bool is_frozen() const;
  ARROW_KIND get_kind() const;
  // Starts a data frame fetch of a new execution from the type and the 64-bit
  // flag of the last one, like the default path; an undecided type keeps the
  // decision from the first row, a requested type is kept
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
  // For a data frame fetch of a uint64 column: rebuilds the chunks, child `j`
  // of each, as doubles if a value of them or of an earlier fetch is beyond
  // 2^63 - 1; returns whether the column is a double in this fetch
  bool conform_unsigned(std::vector<nanoarrow::UniqueArray>& chunks, size_t j);

  // Chunk building
  void start_chunk();
  // Reads the storage class of the value of the current row; a row held
  // back from the previous chunk keeps it for the next one
  void read_row();
  // The bytes that the value of the current row adds to the data buffer of a
  // utf8 or binary column, zero for the other types: the 64-bit offsets of
  // large_utf8 and large_binary need no byte limits
  int64_t value_bytes();
  // Appends the value of the current row, `row` is its 1-based row number in
  // the result for the coercion log
  void append_row(int64_t row);
  // Completes the chunk of `n` rows: an undecided column takes its declared
  // type, or stays open with a chunk of the null type when `keep_open` is set
  void finish_chunk(int64_t n, bool keep_open);
  // Moves the chunk to `out` and returns its type
  ARROW_KIND move_chunk_to(struct ArrowArray* out);
  // Rebuilds a chunk of this column of type `chunk_kind`, from an earlier
  // chunk of the same data frame fetch, with the column's type: a chunk of the
  // null type becomes all NULL, integers become doubles
  void conform_chunk(struct ArrowArray* chunk, ARROW_KIND chunk_kind) const;
  // The bytes in the data buffer of a utf8 or binary column, zero for the
  // other types, see value_bytes()
  int64_t variable_bytes();

  // The values logged since the last call that were not of the column's type,
  // as an R list with the column name, its current type and the entries of
  // the log, which is cleared; NULL if there were none
  cpp11::sexp coercions();
  // The same as a line of the warning's text, empty if there were none,
  // for a thread that can't call R; the log is cleared
  std::string coercions_text();
  // Clears the log without reporting it
  void discard_coercions();

private:
  static ARROW_KIND kind_from_column_type(int column_type);
  // A uint64 comes in the bits of `value`
  void note_integer(int64_t value);
  ARROW_KIND kind_from_decltype() const;

  // The type of the arrays: a time or timestamp is a double in seconds for a
  // data frame, unless the type was requested
  ARROW_KIND storage_kind() const;
  // The time types take the column's unit and time zone
  void set_type(struct ArrowSchema* schema, ARROW_KIND kind) const;
  void init_array(struct ArrowArray* out, ARROW_KIND kind) const;
  static void append_ints_as_doubles(
    struct ArrowArray* out,
    struct ArrowArray* ints,
    bool is_unsigned = false
  );
  void init_array();
  void fetch_bytes();
  void append_value(int column_type, int64_t row);
  void append_integer(int column_type, int64_t row);
  void append_string(int column_type, int64_t row);
  void append_binary(int column_type, int64_t row);
  void append_date(int column_type, int64_t row);
  void append_time(int column_type, int64_t row);
  // Parses text into whole microseconds, since 1970-01-01 for a timestamp,
  // like SqliteColumnDataSource parses it into seconds; false if it can't
  bool parse_micros(int column_type, int64_t& micros) const;
  void append_null();
  // The value of the current row for an integer type other than bool, as
  // SQLite converts it but without saturating at 64 bits; false if it is out
  // of the range of the type. A uint64 comes back in the bits of `value`.
  bool integer_value(int column_type, int64_t& value);
  bool in_range(int64_t value) const;
  void promote_to_double();
  static const char* format_kind(ARROW_KIND kind);
};

#endif  // RSQLITE_SQLITEARROWCOLUMN_H
