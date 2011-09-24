/* $Id$
 *
 *
 * Copyright (C) 1999-2003 The Omega Project for Statistical Computing.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#include "RS-SQLite.h"
#include "param_binding.h"

/* size_t getline(char**, size_t*, FILE*); */
char *compiledVarsion = SQLITE_VERSION;

int RS_sqlite_import(sqlite3 *db, const char *zTable,
                     const char *zFile, const char *separator, const char *eol, int skip);

void RSQLite_closeResultSet0(RS_DBI_resultSet *result, RS_DBI_connection *con);

/* The macro NA_STRING is a CHRSXP in R but a char * in Splus */
#define RS_NA_STRING CHAR(NA_STRING)

/* R and S Database Interface to the SQLite embedded SQL engine
 *
 * C Function library which can be used to run SQL queries from
 * inside of Splus5.x, or R.
 * This driver hooks R/S and SQLite and implements the proposed S-DBI
 * generic R/S-database interface 0.2.
 *
 * We need to simulate (fake) exception objects. We do this piggy-
 * backing on the member "drvData" of the RS_DBI_connection structure.
 * The exception is a 2-member struct with errorNum and erroMsg
 * (this should be extended to allow multiple errors in the structure,
 * like in the ODBC API.)
 *
 * For details on SQLite see http://www.sqlite.org.
 * TODO:
 *    1. Make sure the code is thread-safe, in particular,
 *       we need to remove the PROBLEM ... ERROR macros
 *       in RS_DBI_errorMessage() because it's definetely not
 *       thread-safe.  But see RS_DBI_setException().
 *     2. Use proper types instead of getting everything as character
 */


Mgr_Handle
RS_SQLite_init(SEXP config_params, SEXP reload, SEXP cache)
{
    /* Currently we can specify the 2 defaults max conns and records per
     * fetch (this last one can be over-ridden explicitly in the S call to fetch).
     */
    RS_DBI_manager *mgr;
    Mgr_Handle mgrHandle;
    Sint  fetch_default_rec, force_reload;
    Sint  *shared_cache;
    const char *drvName = "SQLite";
    const char *clientVersion = sqlite3_libversion();

    /* make sure we're running with the "right" version of the SQLite library */
    if(strcmp(clientVersion, compiledVarsion)){
        char  buf[256];
        (void) sprintf(buf,
                       "%s mismatch between compiled version %s and runtime version %s",
                       drvName, compiledVarsion, clientVersion);
        RS_DBI_errorMessage(buf, RS_DBI_WARNING);
    }
    if(GET_LENGTH(config_params)!=2){
        RS_DBI_errorMessage(
            "initialization error: must specify max num of conenctions and default number of rows per fetch",
            RS_DBI_ERROR);
    }
    /* max_con is now IGNORED as connections are not tracked by the
     * manager; instead they are held in external pointers with
     * finalizers. */
    /* max_con = INT_EL(config_params, 0); */
    fetch_default_rec = INT_EL(config_params,1);
    force_reload = LGL_EL(reload,0);

    /* The manager does not keep track of connections, so there is no
       pre-set max connections.  We set this to 1 for now until more
       of the code is refactored.
     */
    mgrHandle = RS_DBI_allocManager(drvName, 1, fetch_default_rec,
                                    force_reload);

    mgr = RS_DBI_getManager(mgrHandle);

    shared_cache = (Sint *)malloc(sizeof(Sint));
    if(!shared_cache){
        RS_DBI_errorMessage(
            "could not malloc space for driver data", RS_DBI_ERROR);
    }

    *shared_cache = LGL_EL(cache,0);
    mgr->drvData = (void *)shared_cache;

    if(*shared_cache)
        sqlite3_enable_shared_cache(1);

    return mgrHandle;
}

SEXP 
RS_SQLite_closeManager(Mgr_Handle mgrHandle)
{
    RS_DBI_manager *mgr;
    SEXP status;
    Sint *shared_cache;

    mgr = RS_DBI_getManager(mgrHandle);
    if(mgr->num_con)
        RS_DBI_errorMessage("there are opened connections -- close them first",
                            RS_DBI_ERROR);

    sqlite3_enable_shared_cache(0);
    shared_cache = (Sint *)mgr->drvData;
    if(shared_cache){
        free(shared_cache);
        mgr->drvData = NULL;
    }

    RS_DBI_freeManager(mgrHandle);

    PROTECT(status = NEW_LOGICAL((Sint) 1));
    LGL_EL(status,0) = TRUE;
    UNPROTECT(1);
    return status;
}

/* open a connection with the same parameters used for in conHandle */
Con_Handle
RS_SQLite_cloneConnection(Con_Handle conHandle)
{
    Mgr_Handle mgrHandle;
    RS_DBI_connection  *con;
    RS_SQLite_conParams *conParams;
    SEXP dbname, allow_ext, vfs, flags;
    Con_Handle ans;

    /* get connection params used to open existing connection */
    con = RS_DBI_getConnection(conHandle);
    conParams = (RS_SQLite_conParams *) con->conParams;

    mgrHandle = RS_DBI_asMgrHandle(MGR_ID(conHandle));

    /* copy dbname and loadable_extensions into a 2-element character
     * vector to be passed to the RS_SQLite_newConnection() function.
     */
    PROTECT(dbname = mkString(conParams->dbname));
    PROTECT(allow_ext = ScalarLogical(conParams->loadable_extensions));
    PROTECT(vfs = mkString(conParams->vfs));
    PROTECT(flags = ScalarInteger(conParams->flags));
    ans = RS_SQLite_newConnection(mgrHandle, dbname, allow_ext, flags, vfs);
    UNPROTECT(4);
    return ans;
}

RS_SQLite_conParams *
RS_SQLite_allocConParams(const char *dbname, int loadable_extensions,
                         int flags, const char *vfs)
{
    RS_SQLite_conParams *conParams;

    conParams = (RS_SQLite_conParams *) malloc(sizeof(RS_SQLite_conParams));
    if(!conParams){
        RS_DBI_errorMessage("could not malloc space for connection params",
                            RS_DBI_ERROR);
    }
    conParams->dbname = RS_DBI_copyString(dbname);
    if (vfs)
        conParams->vfs = RS_DBI_copyString(vfs);
    else
        conParams->vfs = RS_DBI_copyString("");
    conParams->loadable_extensions = loadable_extensions;
    conParams->flags = flags;
    return conParams;
}

void
RS_SQLite_freeConParams(RS_SQLite_conParams *conParams)
{
    if (conParams->dbname) free(conParams->dbname);
    if (conParams->vfs) free(conParams->vfs);
    /* conParams->loadable_extensions is an int, thus needs no free */
    free(conParams);
    conParams = (RS_SQLite_conParams *)NULL;
    return;
}

/* set exception object (allocate memory if needed) */
void
RS_SQLite_setException(RS_DBI_connection *con, int err_no, const char *err_msg)
{
    RS_SQLite_exception *ex;

    ex = (RS_SQLite_exception *) con->drvData;
    if(!ex){    /* brand new exception object */
        ex = (RS_SQLite_exception *) malloc(sizeof(RS_SQLite_exception));
        if(!ex)
            RS_DBI_errorMessage("could not allocate SQLite exception object",
                                RS_DBI_ERROR);
    }
    else
        free(ex->errorMsg);      /* re-use existing object */

    ex->errorNum = err_no;
    if(err_msg)
        ex->errorMsg = RS_DBI_copyString(err_msg);
    else
        ex->errorMsg = (char *) NULL;

    con->drvData = (void *) ex;
    return;
}

void
RS_SQLite_freeException(RS_DBI_connection *con)
{
    RS_SQLite_exception *ex = (RS_SQLite_exception *) con->drvData;

    if(!ex) return;
    if(ex->errorMsg) free(ex->errorMsg);
    free(ex);
    return;
}

SEXP
RS_SQLite_newConnection(Mgr_Handle mgrHandle, SEXP dbfile, SEXP allow_ext,
                        SEXP s_flags, SEXP s_vfs)
{
    RS_DBI_connection   *con;
    RS_SQLite_conParams *conParams;
    Con_Handle conHandle;
    sqlite3     *db_connection;
    const char  *dbname = NULL, *vfs = NULL;
    int         rc, loadable_extensions, open_flags = 0;

    if(!is_validHandle(mgrHandle, MGR_HANDLE_TYPE))
        RS_DBI_errorMessage("invalid SQLiteManager", RS_DBI_ERROR);

    if (TYPEOF(dbfile) != STRSXP || length(dbfile) != 1
        || STRING_ELT(dbfile, 0) == NA_STRING)
        error("'dbname' must be a length one character vector and not NA");
    dbname = CHAR(STRING_ELT(dbfile, 0));

    if (!isLogical(allow_ext))
        error("'allow_ext' must be TRUE or FALSE");
    loadable_extensions = LOGICAL(allow_ext)[0];
    if (loadable_extensions == NA_LOGICAL)
        error("'allow_ext' must be TRUE or FALSE, not NA");

    if (!isNull(s_vfs)) {
        if (!isString(s_vfs) || length(s_vfs) != 1
            || STRING_ELT(s_vfs, 0) == NA_STRING) {
            error("invalid argument 'vfs'");
        }
        vfs = CHAR(STRING_ELT(s_vfs, 0));
        /* "" is not valid, NULL gives default value */
        if (strlen(vfs) == 0) vfs = NULL;
    }
  
    if (!isInteger(s_flags) || length(s_flags) != 1)
        error("argument 'mode' must be length 1 integer, got %s, length: %d",
              type2char(TYPEOF(s_flags)), length(s_flags));
    open_flags = INTEGER(s_flags)[0];
  
    rc = sqlite3_open_v2(dbname, &db_connection, open_flags, vfs);
    if(rc != SQLITE_OK){
        char buf[256];
        sprintf(buf, "could not connect to dbname:\n%s\n",
                sqlite3_errmsg(db_connection));

        RS_DBI_errorMessage(buf, RS_DBI_ERROR);
    }

    /* SQLite connections can only have 1 result set open at a time */
    conHandle = RS_DBI_allocConnection(mgrHandle, (Sint) 1);
    con = RS_DBI_getConnection(conHandle);
    if(!con){
        (void) sqlite3_close(db_connection);
        RS_DBI_freeConnection(conHandle);
        RS_DBI_errorMessage("could not alloc space for connection object",
                            RS_DBI_ERROR);
    }
    /* save connection parameters in the connection object */
    conParams = RS_SQLite_allocConParams(dbname, loadable_extensions,
                                         open_flags, vfs);
    con->drvConnection = (void *) db_connection;
    con->conParams = (void *) conParams;
    RS_SQLite_setException(con, SQLITE_OK, "OK");

    /* enable loadable extensions if required */
    if(loadable_extensions != 0)
        sqlite3_enable_load_extension(db_connection, 1);

    return conHandle;
}

SEXP 
RS_SQLite_closeConnection(Con_Handle conHandle)
{
    RS_DBI_connection *con;
    sqlite3 *db_connection;
    int      rc;

    con = RS_DBI_getConnection(conHandle);
    if(con->num_res>0){
        /* we used to error out here telling the user to
           close pending result sets.  Now we warn and close the set ourself.
         */
        RS_DBI_errorMessage("closing pending result sets before closing "
                            "this connection", RS_DBI_WARNING);
        RSQLite_closeResultSet0(con->resultSets[0], con);
    }

    db_connection = (sqlite3 *) con->drvConnection;
    rc = sqlite3_close(db_connection);  /* it also frees db_connection */
    if (rc == SQLITE_BUSY) {
        /* This will happen if there is an unfinalized prepared statement or
           an unfinalized BLOB reference.  Should not happen under normal
           operation -- even if user is doing things out of order.
         */
        RS_DBI_errorMessage(
            "unfinalized prepared statements before closing this connection",
            RS_DBI_WARNING);
    }
    else if(rc!=SQLITE_OK){
        RS_DBI_errorMessage("internal error: "
                            "SQLite could not close the connection",
                            RS_DBI_WARNING);
    }

    /* make sure we first free the conParams and SQLite connection from
     * the RS-RBI connection object.
     */
    if(con->conParams){
        RS_SQLite_freeConParams(con->conParams);
        /* we must set con->conParms to NULL (not just free it) to signal
         * RS_DBI_freeConnection that it is okay to free the connection itself.
         */
        con->conParams = NULL;
    }
    con->drvConnection = NULL;
    RS_SQLite_freeException(con);
    con->drvData = NULL;
    RS_DBI_freeConnection(conHandle);
    return ScalarLogical(1);
}

int SQLite_decltype_to_type(const char* decltype)
{
    unsigned int h = 0;
    if (!decltype)
        return SQLITE_TEXT;
    int len = strlen(decltype);
    const unsigned char *zIn = (unsigned char*)decltype;
    const unsigned char *zEnd = (unsigned char*)&(decltype[len]);
    int col_type = SQLITE_FLOAT;

    while( zIn!=zEnd ){
        h = (h<<8) + tolower(*zIn);
        zIn++;
        if( h==(('c'<<24)+('h'<<16)+('a'<<8)+'r') ){             /* CHAR */
            col_type = SQLITE_TEXT;
        }else if( h==(('c'<<24)+('l'<<16)+('o'<<8)+'b') ){       /* CLOB */
            col_type = SQLITE_TEXT;
        }else if( h==(('t'<<24)+('e'<<16)+('x'<<8)+'t') ){       /* TEXT */
            col_type = SQLITE_TEXT;
        }else if( h==(('b'<<24)+('l'<<16)+('o'<<8)+'b')          /* BLOB */
                  && col_type==SQLITE_FLOAT ){
            col_type = SQLITE_BLOB;
#ifndef SQLITE_OMIT_FLOATING_POINT
        }else if( h==(('r'<<24)+('e'<<16)+('a'<<8)+'l')          /* REAL */
                  && col_type==SQLITE_FLOAT ){
            col_type = SQLITE_FLOAT;
        }else if( h==(('f'<<24)+('l'<<16)+('o'<<8)+'a')          /* FLOA */
                  && col_type==SQLITE_FLOAT ){
            col_type = SQLITE_FLOAT;
        }else if( h==(('d'<<24)+('o'<<16)+('u'<<8)+'b')          /* DOUB */
                  && col_type==SQLITE_FLOAT ){
            col_type = SQLITE_FLOAT;
#endif
        }else if( (h&0x00FFFFFF)==(('i'<<16)+('n'<<8)+'t') ){    /* INT */
            col_type = SQLITE_INTEGER;
            break;
        }
    }
    return col_type;
}


int RS_SQLite_get_row_count(sqlite3* db, const char* tname) {
    char* sqlQuery;
    const char* sqlFmt = "select rowid from %s order by rowid desc limit 1";
    int qrylen = strlen(sqlFmt);
    int rc = 0;
    int ans;
    sqlite3_stmt* stmt;
    const char* tail;

    qrylen += strlen(tname) + 1;
    sqlQuery = (char*)  R_alloc(qrylen, sizeof(char));
    snprintf(sqlQuery, qrylen, sqlFmt, tname);
    rc = sqlite3_prepare_v2(db, sqlQuery, -1, &stmt, &tail);
    if (rc != SQLITE_OK) {
        sqlite3_finalize(stmt);
        error("SQL error: %s\n", sqlite3_errmsg(db));
    }
    rc = sqlite3_step(stmt);
    if (rc != SQLITE_ROW && rc != SQLITE_DONE) {
        sqlite3_finalize(stmt);
        error("SQL error: %s\n", sqlite3_errmsg(db));
    }
    ans = sqlite3_column_int(stmt, 0);
    sqlite3_finalize(stmt);
    return ans;
}


SEXP RS_SQLite_quick_column(Con_Handle conHandle, SEXP table, SEXP column)
{
    SEXP ans = R_NilValue, rawv;
    RS_DBI_connection *con = NULL;
    sqlite3 *db_connection = NULL;
    sqlite3_stmt *stmt = NULL;
    int numrows, rc, i = 0, col_type, *intans = NULL, blob_len;
    char sqlQuery[500];
    const char *table_name = NULL, *column_name = NULL, *tail = NULL;
    double *doubleans = NULL;
    const Rbyte *blob_data;

    con = RS_DBI_getConnection(conHandle);
    db_connection = (sqlite3 *) con->drvConnection;
    table_name = CHAR(STRING_ELT(table, 0));
    column_name = CHAR(STRING_ELT(column, 0));
    numrows = RS_SQLite_get_row_count(db_connection, table_name);
    snprintf(sqlQuery, sizeof(sqlQuery), "select %s from %s",
             column_name, table_name);

    rc = sqlite3_prepare_v2(db_connection, sqlQuery, strlen(sqlQuery), &stmt, &tail);
    /* FIXME: how should we be handling errors?
       Could either follow the pattern in the rest of the package or
       start to use the condition system and raise specific conditions.
    */
    if(rc != SQLITE_OK) {
        error("SQL error: %s\n", sqlite3_errmsg(db_connection));
    }

    rc = sqlite3_step(stmt);
    if (rc != SQLITE_ROW) {
        error("SQL error: %s\n", sqlite3_errmsg(db_connection));
    }
    col_type = sqlite3_column_type(stmt, 0);
    switch(col_type) {
    case SQLITE_INTEGER:
        PROTECT(ans = allocVector(INTSXP, numrows));
        intans = INTEGER(ans);
        break;
    case SQLITE_FLOAT:
        PROTECT(ans = allocVector(REALSXP, numrows));
        doubleans = REAL(ans);
        break;
    case SQLITE_TEXT:
        PROTECT(ans = allocVector(STRSXP, numrows));
        break;
    case SQLITE_NULL:
        error("RS_SQLite_quick_column: encountered NULL column");
        break;
    case SQLITE_BLOB:
        PROTECT(ans = allocVector(VECSXP, numrows));
        break;
    default:
        error("RS_SQLite_quick_column: unknown column type %d", col_type);
    }

    i = 0;
    while (rc == SQLITE_ROW && i < numrows) {
        switch (col_type) {
        case SQLITE_INTEGER:
            intans[i] = sqlite3_column_int(stmt, 0);
            break;
        case SQLITE_FLOAT:
            doubleans[i] = sqlite3_column_double(stmt, 0);
            break;
        case SQLITE_TEXT:
            SET_STRING_ELT(ans, i, /* cast for -Wall */
                           mkChar((char*)sqlite3_column_text(stmt, 0)));
            break;
        case SQLITE_BLOB:
            blob_data = (const Rbyte *) sqlite3_column_blob(stmt, 0);
            blob_len = sqlite3_column_bytes(stmt, 0);
            PROTECT(rawv = allocVector(RAWSXP, blob_len));
            memcpy(RAW(rawv), blob_data, blob_len * sizeof(Rbyte));;
            SET_VECTOR_ELT(ans, i, rawv);
            UNPROTECT(1);
            break;
        }
        i++;
        rc = sqlite3_step(stmt);
    }
    sqlite3_finalize(stmt);
    UNPROTECT(1);
    return ans;
}

static void RSQLite_freeResultSet0(RS_DBI_resultSet *result, RS_DBI_connection *con)
{
    if (result->drvResultSet) {
        sqlite3_finalize((sqlite3_stmt *)result->drvResultSet);
        result->drvResultSet = NULL;
    }
    if (result->drvData) {
        RS_SQLite_bindParams *params = (RS_SQLite_bindParams *)result->drvData;
        R_ReleaseObject(params->data);
        RS_SQLite_freeParameterBinding(&params);
        result->drvData = NULL;
    }
    RS_DBI_freeResultSet0(result, con);
}

/* Helper function to clean up and report an error during a call to
   RS_SQLite_exec */
static void
exec_error(const char *msg,
           RS_DBI_connection *con,
           int bind_count,
           RS_SQLite_bindParams *params,
           Res_Handle rsHandle)
{
    sqlite3 *db = (sqlite3 *) con->drvConnection;
    int errcode = db ? sqlite3_errcode(db) : -1;
    char buf[2048];
    const char *db_msg = "";
    const char *sep = "";
    if (db && errcode != SQLITE_OK) {
        db_msg = sqlite3_errmsg(db);
        sep = ": ";
    }
    snprintf(buf, sizeof(buf), "%s%s%s", msg, sep, db_msg);
    RS_SQLite_setException(con, errcode, buf);
    if (rsHandle) {
        RSQLite_freeResultSet0(RS_DBI_getResultSet(rsHandle), con);
        rsHandle = NULL;
    }
    if (params) {
        RS_SQLite_freeParameterBinding(&params);
        params = NULL;
    }
    RS_DBI_errorMessage(buf, RS_DBI_ERROR);
}

static void
select_prepared_query(sqlite3_stmt *db_statement,
                      SEXP bind_data,
                      int bind_count,
                      int rows,
                      RS_DBI_connection *con,
                      SEXP rsHandle)
{
    RS_DBI_resultSet *res;
    char bindingErrorMsg[2048]; bindingErrorMsg[0] = '\0';
    RS_SQLite_bindParams *params =
        RS_SQLite_createParameterBinding(bind_count, bind_data,
                                         db_statement, bindingErrorMsg);
    if (params == NULL) {
        /* FIXME: this UNPROTECT is ugly, paired to caller */
        UNPROTECT(1);
        exec_error(bindingErrorMsg, con, 0, NULL, rsHandle);
    }
    res = RS_DBI_getResultSet(rsHandle);
    res->drvData = params;
}

static int
bind_params_to_stmt(RS_SQLite_bindParams *params,
                    sqlite3_stmt *db_statement, int row)
{
    int state = SQLITE_OK, j;
    for (j = 0; j < params->count; j++) {
        SEXP pdata = VECTOR_ELT(params->data, j), v_elt;
        int integer;
        double number;
        Rbyte *raw;
        const char *string;

        switch(TYPEOF(pdata)){
        case INTSXP:
            integer = INTEGER(pdata)[row];
            if (IS_NA(&integer, INTSXP))
                state = sqlite3_bind_null(db_statement, j+1);
            else
                state = sqlite3_bind_int(db_statement, j+1, integer);
            break;
        case REALSXP:
            number = NUM_EL(pdata, row);
            if (IS_NA(&number, REALSXP))
                state = sqlite3_bind_null(db_statement, j+1);
            else
                state = sqlite3_bind_double(db_statement, j+1, number);
            break;
        case VECSXP:            /* BLOB */
            v_elt = VECTOR_ELT(pdata, row);
            if (v_elt == R_NilValue) {
                state = sqlite3_bind_null(db_statement, j+1);
            } else {
                raw = RAW(v_elt);
                state = sqlite3_bind_blob(db_statement, j+1,
                                          raw, LENGTH(v_elt), SQLITE_STATIC);
            }
            break;
        case STRSXP:
            /* falls through */
        default:
            v_elt = STRING_ELT(pdata, row);
            if (NA_STRING == v_elt)
                state = sqlite3_bind_null(db_statement, j+1);
            else
                state = sqlite3_bind_text(db_statement, j+1,
                                          CHAR(v_elt), -1, SQLITE_STATIC);
            break;
        }
        if (state != SQLITE_OK) break;
    }
    return state;
}

static void
non_select_prepared_query(sqlite3_stmt *db_statement,
                          SEXP bind_data,
                          int bind_count,
                          int rows,
                          RS_DBI_connection *con,
                          SEXP rsHandle)
{
    int state, i;
    char bindingErrorMsg[2048]; bindingErrorMsg[0] = '\0';
    RS_SQLite_bindParams *params =
        RS_SQLite_createParameterBinding(bind_count, bind_data,
                                         db_statement, bindingErrorMsg);
    if (params == NULL) {
        /* FIXME: this UNPROTECT is ugly, paired to caller */
        UNPROTECT(1);
        exec_error(bindingErrorMsg, con, 0, NULL, rsHandle);
    }

    /* we need to step through the query for each row */
    for (i=0; i<rows; i++) {
        state = bind_params_to_stmt(params, db_statement, i);
        if (state != SQLITE_OK) {
            UNPROTECT(1);
            /* FIXME: add errmsg from sqlite */
            exec_error("RS_SQLite_exec: could not bind data",
                       con, 0, NULL, rsHandle);
        }
        state = sqlite3_step(db_statement);
        if (state != SQLITE_DONE) {
            UNPROTECT(1);
            /* FIXME: add errmsg from sqlite */
            exec_error("RS_SQLite_exec: could not execute",
                       con, 0, NULL, rsHandle);
        }
        state = sqlite3_reset(db_statement);
        sqlite3_clear_bindings(db_statement);
        if (state != SQLITE_OK) {
            UNPROTECT(1);
            exec_error("RS_SQLite_exec: could not reset statement",
                       con, 0, NULL, rsHandle);
        }
    }
    RS_SQLite_freeParameterBinding(&params);
}


Res_Handle RS_SQLite_exec(Con_Handle conHandle, SEXP statement, SEXP bind_data)
{
    RS_DBI_connection *con;
    Res_Handle rsHandle;
    RS_DBI_resultSet *res;
    sqlite3 *db_connection;
    sqlite3_stmt *db_statement = NULL;
    int state, bind_count;
    int rows = 0, cols = 0;
    char *dyn_statement;

    con = RS_DBI_getConnection(conHandle);
    db_connection = (sqlite3 *) con->drvConnection;
    dyn_statement = RS_DBI_copyString(CHR_EL(statement,0));

    /* Do we have a pending resultSet in the current connection?
     * SQLite only allows  one resultSet per connection.
     */
    if (con->num_res>0) {
        Sint res_id = (Sint) con->resultSetIds[0]; /* SQLite has only 1 res */
        rsHandle = RS_DBI_asResHandle(MGR_ID(conHandle),
                                      CON_ID(conHandle), res_id, conHandle);
        res = RS_DBI_getResultSet(rsHandle);
        if (res->completed != 1) {
            free(dyn_statement);
            RS_DBI_errorMessage(
                "connection with pending rows, close resultSet before continuing",
                RS_DBI_ERROR);
        } else
            RS_SQLite_closeResultSet(rsHandle);
    }

    /* allocate and init a new result set */
    PROTECT(rsHandle = RS_DBI_allocResultSet(conHandle));
    res = RS_DBI_getResultSet(rsHandle);
    res->completed = (Sint) 0;
    res->statement = dyn_statement;
    res->drvResultSet = db_statement;
    state = sqlite3_prepare_v2(db_connection, dyn_statement, -1,
                               &db_statement, NULL);
    if (state != SQLITE_OK) {
        UNPROTECT(1);
        exec_error("error in statement", con, 0, NULL, rsHandle);
    }

    if (db_statement == NULL) {
        UNPROTECT(1);
        exec_error("nothing to execute", con, 0, NULL, rsHandle);
    }
    res->drvResultSet = (void *) db_statement;
    bind_count = sqlite3_bind_parameter_count(db_statement);
    if (bind_count > 0 && bind_data != R_NilValue) {
        rows = GET_LENGTH(GET_ROWNAMES(bind_data));
        cols = GET_LENGTH(bind_data);
    }


    res->isSelect = sqlite3_column_count(db_statement) > 0;
    res->rowCount = 0;      /* fake's cursor's row count */
    res->rowsAffected = -1; /* no rows affected */
    RS_SQLite_setException(con, state, "OK");

    if (res->isSelect) {
        if (bind_count > 0) {
            select_prepared_query(db_statement, bind_data, bind_count,
                                  rows, con, rsHandle);
        }
    } else {
        if (bind_count > 0) {
            non_select_prepared_query(db_statement, bind_data, bind_count,
                                      rows, con, rsHandle);
        }
        else {
            state = sqlite3_step(db_statement);
            if (state != SQLITE_DONE) {
                UNPROTECT(1);
                exec_error("RS_SQLite_exec: could not execute1",
                           con, 0, NULL, rsHandle);
            }
        }
        res->completed = (Sint) 1;          /* BUG: what if query is async?*/
        res->rowsAffected = (Sint) sqlite3_changes(db_connection);
    }
    UNPROTECT(1);
    return rsHandle;
}

RS_DBI_fields *
RS_SQLite_createDataMappings(Res_Handle rsHandle)
{
    sqlite3_stmt  *db_statement;
    RS_DBI_resultSet   *result;
    RS_DBI_fields      *flds;
    int     j, ncol, col_type;
    const char *col_decltype = NULL;
    char *col_name;

    result = RS_DBI_getResultSet(rsHandle);
    db_statement = (sqlite3_stmt *) result->drvResultSet;

    ncol = sqlite3_column_count(db_statement);
    flds = RS_DBI_allocFields(ncol); /* BUG: mem leak if this fails? */
    flds->num_fields = (Sint) ncol;

    for(j=0; j<ncol; j++){
        col_name = (char*)sqlite3_column_name(db_statement, j); /* -Wall */
        if (col_name)
            flds->name[j] = RS_DBI_copyString(col_name);
        else {                   /* weird failure */
            RS_DBI_freeFields(flds);
            flds = NULL;
            return NULL;
        }
        /* XXX: We do our best to determine the type of the column.  When
           the first row retrieved contains a NULL and does not reference
           a table column, we give up.
        */
        col_type = sqlite3_column_type(db_statement, j);
        if (col_type == SQLITE_NULL) {
            /* try to get type from origin column */
            col_decltype = sqlite3_column_decltype(db_statement, j);
            col_type = SQLite_decltype_to_type(col_decltype);
        }
        switch(col_type) {
        case SQLITE_INTEGER:
            flds->type[j] = SQL92_TYPE_INTEGER;
            flds->Sclass[j] = INTSXP;
            flds->length[j] = (Sint) sizeof(int);
            flds->isVarLength[j] = (Sint) 0;
            break;
        case SQLITE_FLOAT:
            flds->type[j] = SQL92_TYPE_DOUBLE;
            flds->Sclass[j] = REALSXP;
            flds->length[j] = (Sint) sizeof(double);
            flds->isVarLength[j] = (Sint) 0;
            break;
        case SQLITE_TEXT:
            flds->type[j] = SQL92_TYPE_CHAR_VAR;
            flds->Sclass[j] = STRSXP;
            flds->length[j] = (Sint) -1;   /* unknown */
            flds->isVarLength[j] = (Sint) 1;
            break;
        case SQLITE_NULL:
            error("NULL column handling not implemented");
            break;
        case SQLITE_BLOB:
            flds->type[j] = SQLns_TYPE_BLOB;
            flds->Sclass[j] = VECSXP;
            flds->length[j] = (Sint) -1;   /* unknown */
            flds->isVarLength[j] = (Sint) 1;
            break;
        default:
            error("unknown column type %d", col_type);
        }
        flds->precision[j] = (Sint) -1;
        flds->scale[j] = (Sint) -1;
        /* For nullOk, could use sqlite3_column_origin_name and
           sqlite3_table_column_metadata to determine this.  It
           won't always be possible as the query column may not
           refer to a table column.
        */
        flds->nullOk[j] = (Sint) -1;
    }
    return flds;
}


/* Fills the output VECSXP with one row of data from the resultset
 */
static void fill_one_row(sqlite3_stmt *db_statement, SEXP output, int row_idx,
                         RS_DBI_fields *flds)
{
    int j, null_item, blob_len;
    SEXP rawv;
    const Rbyte *blob_data;

    for (j = 0; j < flds->num_fields; j++) {
        null_item = (sqlite3_column_type(db_statement, j) == SQLITE_NULL);
        switch (flds->Sclass[j]) {
        case INTSXP:
            if (null_item)
                NA_SET(&(LST_INT_EL(output, j, row_idx)), INTSXP);
            else
                LST_INT_EL(output, j, row_idx) =
                    sqlite3_column_int(db_statement, j);
            break;
        case REALSXP:
            if (null_item)
                NA_SET(&(LST_NUM_EL(output,j,row_idx)), REALSXP);
            else
                LST_NUM_EL(output,j,row_idx) =
                    sqlite3_column_double(db_statement, j);
            break;
        case VECSXP:            /* BLOB */
            if (null_item) {
                rawv = R_NilValue;
            } else {
                blob_data = (const Rbyte *)sqlite3_column_blob(db_statement, j);
                blob_len = sqlite3_column_bytes(db_statement, j);
                PROTECT(rawv = allocVector(RAWSXP, blob_len));
                memcpy(RAW(rawv), blob_data, blob_len * sizeof(Rbyte));
            }
            SET_VECTOR_ELT(VECTOR_ELT(output, j), row_idx, rawv);
            if (rawv != R_NilValue) UNPROTECT(1);
            break;
        case STRSXP:
            /* falls through */
        default:
            if (null_item)
                SET_LST_CHR_EL(output,j,row_idx, NA_STRING);
            else
                SET_LST_CHR_EL(output,j,row_idx, /* cast for -Wall */
                               C_S_CPY((char*)sqlite3_column_text(db_statement, j)));
            break;
        }
    }
}

static int do_select_step(RS_DBI_resultSet *res, int row_idx)
{
    int state;
    RS_SQLite_bindParams * params = NULL;
    sqlite3_stmt *stmt = (sqlite3_stmt *)res->drvResultSet;
    if (res->drvData) {         /* we have parameters to bind */
        params = (RS_SQLite_bindParams *)res->drvData;
        if (params->row_complete) {
            params->row_complete = 0;
            sqlite3_clear_bindings(stmt);
            state = bind_params_to_stmt(params,
                                        stmt,
                                        params->rows_used);
            if (state != SQLITE_OK) return state;
            params->rows_used++;
        }
    }
    state = sqlite3_step(stmt);
    if (params && state == SQLITE_DONE) {
        params->row_complete = 1;
        if (params->rows_used < params->row_count) {
            state = sqlite3_reset(stmt);
            if (state != SQLITE_OK) return state;
            return do_select_step(res, row_idx);
        }
    }
    return state;
}

/* Return a data.frame containing the requested number of rows from
   the resultset.

   We try to determine the correct R type for each column in the
   result.  Currently, type detection happens only for the first fetch
   on a given resultset and the first row of the resultset is used for
   type interpolation.  If a NULL value appears in the first row of
   the resultset and the column corresponds to a DB table column, we
   guess the type based on the DB schema definition for the column.
   If the NULL value does not correspond to a table column, then we
   force character.

   TODO: consider making this smarter by keeping track of unknown
   columns and setting the type based on the first non-NULL.

   TODO: consider adding ability for users to specify desired types
   for result columns.  This could happen either via coercion in R or
   at the SQLite level (which would be more efficient, but less
   flexible).

*/
SEXP RS_SQLite_fetch(SEXP rsHandle, SEXP max_rec)
{
    RS_DBI_resultSet *res;
    RS_DBI_fields *flds;
    sqlite3_stmt *db_statement;
    SEXP output, s_tmp;
    int j, state, expand;
    Sint num_rec;
    int num_fields, row_idx = 0;

    res = RS_DBI_getResultSet(rsHandle);
    if (res->isSelect != 1) {
        RSQLITE_MSG("resultSet does not correspond to a SELECT statement",
                    RS_DBI_WARNING);
        return R_NilValue;
    }
    if (res->completed == 1)
        return R_NilValue;

    /* We need to step once to be able to create the data mappings */
    state = do_select_step(res, row_idx);
    db_statement = (sqlite3_stmt *)res->drvResultSet;
    if (state != SQLITE_ROW && state != SQLITE_DONE) {
        char errMsg[2048];
        (void)sprintf(errMsg, "RS_SQLite_fetch: failed first step: %s",
                      sqlite3_errmsg(sqlite3_db_handle(db_statement)));
        RSQLITE_MSG(errMsg, RS_DBI_ERROR);
    }
    if (!res->fields) {
        if (!(res->fields = RS_SQLite_createDataMappings(rsHandle))) {
            RSQLITE_MSG("corrupt SQLite resultSet, missing fieldDescription",
                        RS_DBI_ERROR);
        }
    }
    flds = res->fields;
    num_fields = flds->num_fields;
    num_rec = INT_EL(max_rec, 0);
    expand = (num_rec < 0);   /* dyn expand output to accommodate all rows*/
    if (expand || num_rec == 0) {
        num_rec = RS_DBI_getManager(rsHandle)->fetch_default_rec;
    }

    PROTECT(output = NEW_LIST((Sint) num_fields));
    RS_DBI_allocOutput(output, flds, num_rec, 0);
    while (state != SQLITE_DONE) {
        fill_one_row(db_statement, output, row_idx, flds);
        row_idx++;
        if (row_idx == num_rec) {  /* request satisfied or exhausted allocated space */
            if (expand) {    /* do we extend or return the records fetched so far*/
                num_rec = 2 * num_rec;
                RS_DBI_allocOutput(output, flds, num_rec, expand);
            }
            else
                break;       /* okay, no more fetching for now */
        }
        state = do_select_step(res, row_idx);
        if (state != SQLITE_ROW && state != SQLITE_DONE) {
            char errMsg[2048];
            (void)sprintf(errMsg, "RS_SQLite_fetch: failed: %s",
                          sqlite3_errmsg(sqlite3_db_handle(db_statement)));
            RSQLITE_MSG(errMsg, RS_DBI_ERROR);
        }
    } /* end row loop */
    if (state == SQLITE_DONE) {
        res->completed = (Sint) 1;
    }
    /* size to actual number of records fetched */
    if (row_idx < num_rec) {
        num_rec = row_idx;
        /* adjust the length of each of the members in the output_list */
        for (j = 0; j<num_fields; j++) {
            s_tmp = LST_EL(output, j);
            PROTECT(SET_LENGTH(s_tmp, num_rec));
            SET_VECTOR_ELT(output, j, s_tmp);
            UNPROTECT(1);
        }
    }
    res->rowCount += num_rec;
    UNPROTECT(1);
    return output;
}

/* The following mget-like function is EXPERIMENTAL

   The purpose is to return a compact list structure directly instead
   of, for example, pulling across a two-column table and calling
   split.

*/
#if 0
/* declare function that needs to be added to R API */
SEXP R_NewHashedEnv(SEXP);

SEXP       /* data.frame */
RS_SQLite_mget(SEXP rsHandle, SEXP max_rec)
{
    RS_DBI_resultSet *res;
    RS_DBI_fields    *flds;
    sqlite3_stmt     *db_statement;
    SEXP output, *s_tmp;
    int    i, j, state, expand, vlen;
    Sint   num_rec;
    int    num_fields, row_idx;
    int *key_breaks;
    int breaks_idx;
    const char *cur_key = NULL;
    char *prev_key = NULL;
    SEXP env, vect;


    res = RS_DBI_getResultSet(rsHandle);
    if(res->isSelect != 1){
        RS_DBI_errorMessage("resultSet does not correspond to a SELECT statement",
                            RS_DBI_WARNING);
        return S_NULL_ENTRY;
    }

    if(res->completed == 1)
        return R_NilValue;

    db_statement = (sqlite3_stmt *)res->drvResultSet;
    if(db_statement == NULL){
        RS_DBI_errorMessage("corrupt SQLite resultSet, missing statement handle",
                            RS_DBI_ERROR);
    }

    state = sqlite3_step(db_statement);
    row_idx = 0;
    if(state!=SQLITE_ROW && state!=SQLITE_DONE){
        char errMsg[2048];
        (void)sprintf(errMsg, "RS_SQLite_fetch: failed first step: %s",
                      sqlite3_errmsg(sqlite3_db_handle(db_statement)));
        RS_DBI_errorMessage(errMsg, RS_DBI_ERROR);
    }
    if (!res->fields) {
        if (!(res->fields = RS_SQLite_createDataMappings(rsHandle))) {
            RS_DBI_errorMessage("corrupt SQLite resultSet, missing fieldDescription",
                                RS_DBI_ERROR);
        }
    }
    flds = res->fields;
    /* force first column to character */
    flds->Sclass[0] = STRSXP;

    num_fields = flds->num_fields;
    num_rec = INT_EL(max_rec,0);
    expand = (num_rec < 0);   /* dyn expand output to accommodate all rows*/
    if(expand || num_rec == 0){
        num_rec = RS_DBI_getManager(rsHandle)->fetch_default_rec;
    }

    PROTECT(output = NEW_LIST((Sint) num_fields));
    RS_DBI_allocOutput(output, flds, num_rec, 0);
    key_breaks = (int *)R_alloc(num_rec, sizeof(int));
    key_breaks[0] = 0;
    breaks_idx++;
    while (state != SQLITE_DONE) {
        if (sqlite3_column_type(db_statement, 0) == SQLITE_NULL)
            error("RS_SQLite_mget: encounted NULL key");
        cur_key = sqlite3_column_text(db_statement, 0);
        if (prev_key == NULL || strcmp(prev_key, cur_key) != 0) {
            if (prev_key != NULL) {
                Free(prev_key);
                key_breaks[breaks_idx++] = row_idx;
            }
            prev_key = Calloc(strlen(cur_key) + 1, char);
            strcpy(prev_key, cur_key);
        }

        for (j = 0; j < num_fields; j++) {
            int null_item = (sqlite3_column_type(db_statement, j) == SQLITE_NULL);
            switch(flds->Sclass[j]){
            case INTSXP:
                if(null_item)
                    NA_SET(&(LST_INT_EL(output,j,row_idx)), INTSXP);
                else
                    LST_INT_EL(output,j,row_idx) =
                        sqlite3_column_int(db_statement, j);
                break;
            case REALSXP:
                if(null_item)
                    NA_SET(&(LST_NUM_EL(output,j,row_idx)), REALSXP);
                else
                    LST_NUM_EL(output,j,row_idx) =
                        sqlite3_column_double(db_statement, j);
                break;
            case STRSXP:
                /* falls through */
            default:
                if(null_item)
                    SET_LST_CHR_EL(output,j,row_idx, NA_STRING);
                else
                    SET_LST_CHR_EL(output,j,row_idx,
                                   C_S_CPY(sqlite3_column_text(db_statement, j)));
                break;
            }
        } /* end column loop */
        row_idx++;
        if (row_idx == num_rec) {  /* request satisfied or exhausted allocated space */
            if (expand) {    /* do we extend or return the records fetched so far*/
                key_breaks = (int *)S_realloc((char *)key_breaks, 2 * num_rec, num_rec,
                                              sizeof(int));
                num_rec = 2 * num_rec;
                RS_DBI_allocOutput(output, flds, num_rec, expand);
            }
            else
                break;       /* okay, no more fetching for now */
        }
        state = sqlite3_step(db_statement);
        if (state != SQLITE_ROW && state != SQLITE_DONE) {
            char errMsg[2048];
            (void)sprintf(errMsg, "RS_SQLite_fetch: failed: %s",
                          sqlite3_errmsg(sqlite3_db_handle(db_statement)));
            RS_DBI_errorMessage(errMsg, RS_DBI_ERROR);
        }
    } /* end row loop */
    if (state == SQLITE_DONE) {
        res->completed = (Sint) 1;
    }
    /* size to actual number of records fetched */
    if(row_idx < num_rec){
        num_rec = row_idx;
        /* adjust the length of each of the members in the output_list */
        for(j = 0; j<num_fields; j++){
            s_tmp = LST_EL(output,j);
            PROTECT(SET_LENGTH(s_tmp, num_rec));
            SET_VECTOR_ELT(output, j, s_tmp);
            UNPROTECT(1);
        }
    }
    res->rowCount += num_rec;
    key_breaks[breaks_idx++] = num_rec;
    PROTECT(env = R_NewHashedEnv(R_NilValue));
    for (j = 1; j < breaks_idx; j++) {
        vlen = key_breaks[j] - key_breaks[j - 1];
        s_tmp = LST_EL(output, 1);
        PROTECT(vect = allocVector(TYPEOF(s_tmp), vlen));
        for (i = 0; i < vlen; i++) {
            switch (TYPEOF(vect)) {
            case INTSXP:
                INTEGER(vect)[i] = INTEGER(s_tmp)[key_breaks[j-1]+i];
                break;
            case REALSXP:
                REAL(vect)[i] = REAL(s_tmp)[key_breaks[j-1]+i];
                break;
            case STRSXP:
                SET_STRING_ELT(vect, i, STRING_ELT(s_tmp, key_breaks[j-1]+i));
                break;
            default:
                error("unknown type");
                break;
            }
        }
        s_tmp = STRING_ELT(LST_EL(output, 0), key_breaks[j]-1);
        defineVar(install(CHAR(s_tmp)), vect, env);
        UNPROTECT(1);
    }

    if (prev_key)
        Free(prev_key);
    UNPROTECT(2);
    return env;
}
#endif

/* return a 2-elem list with the last exception number and exception message on a given connection.
 * NOTE: RS_SQLite_getException() is meant to be used mostly directory R.
 */
SEXP 
RS_SQLite_getException(SEXP conHandle)
{
    SEXP output;
    RS_DBI_connection   *con;
    RS_SQLite_exception *err;
    Sint  n = 2;
    char *exDesc[] = {"errorNum", "errorMsg"};
    Stype exType[] = {INTSXP, STRSXP};
    Sint  exLen[]  = {1, 1};

    con = RS_DBI_getConnection(conHandle);
    if(!con->drvConnection)
        RS_DBI_errorMessage("internal error: corrupt connection handle",
                            RS_DBI_ERROR);
    PROTECT(output = RS_DBI_createNamedList(exDesc, exType, exLen, n));
    err = (RS_SQLite_exception *) con->drvData;
    LST_INT_EL(output,0,0) = (Sint) err->errorNum;
    SET_LST_CHR_EL(output,1,0,C_S_CPY(err->errorMsg));
    UNPROTECT(1);
    return output;
}

void RSQLite_closeResultSet0(RS_DBI_resultSet *result, RS_DBI_connection *con)
{
   if(result->drvResultSet == NULL)
       RS_DBI_errorMessage("corrupt SQLite resultSet, missing statement handle",
                           RS_DBI_ERROR);
    RSQLite_freeResultSet0(result, con);
}

SEXP 
RS_SQLite_closeResultSet(SEXP resHandle)
{
    RSQLite_closeResultSet0(RS_DBI_getResultSet(resHandle),
                            RS_DBI_getConnection(resHandle));
    /* The connection external ptr is stored within the result handle
       so that an active result keeps the connection protected.  When
       we close the result set, we remove the reference to the
       connection so that the connection can be gc'd.
     */
    SET_VECTOR_ELT(R_ExternalPtrProtected(resHandle), 1, R_NilValue);
    RES_ID(resHandle) = -1;
    return ScalarLogical(1);
}

SEXP 
RS_SQLite_managerInfo(Mgr_Handle mgrHandle)
{
    RS_DBI_manager *mgr;
    SEXP output;
    Sint i, num_con, max_con, *cons, ncon, *shared_cache;
    Sint j, n = 9;
    char *mgrDesc[] = {"drvName",   "connectionIds", "fetch_default_rec",
                       "managerId", "length",        "num_con",
                       "counter",   "clientVersion", "shared_cache"};
    Stype mgrType[] = {STRSXP, INTSXP, INTSXP,
                       INTSXP,   INTSXP, INTSXP,
                       INTSXP,   STRSXP, STRSXP };
    Sint  mgrLen[]  = {1, 1, 1, 1, 1, 1, 1, 1, 1};

    mgr = RS_DBI_getManager(mgrHandle);
    if(!mgr)
        RS_DBI_errorMessage("driver not loaded yet", RS_DBI_ERROR);
    num_con = (Sint) mgr->num_con;
    max_con = (Sint) mgr->length;
    shared_cache = (Sint *) mgr->drvData;
    mgrLen[1] = num_con;

    PROTECT(output = RS_DBI_createNamedList(mgrDesc, mgrType, mgrLen, n));
    j = (Sint) 0;
    if(mgr->drvName)
        SET_LST_CHR_EL(output,j++,0,C_S_CPY(mgr->drvName));
    else
        SET_LST_CHR_EL(output,j++,0,C_S_CPY(""));

    cons = (Sint *) S_alloc((long)max_con, (int)sizeof(Sint));
    ncon = RS_DBI_listEntries(mgr->connectionIds, mgr->length, cons);
    /* expecting ncon == 0 alwasy */
    if(ncon != 0){
        RS_DBI_errorMessage(
            "internal error: corrupt RS_DBI connection table",
            RS_DBI_ERROR);
    }
    for(i = 0; i < num_con; i++)
        LST_INT_EL(output, j, i) = cons[i];
    j++;
    LST_INT_EL(output,j++,0) = mgr->fetch_default_rec;
    LST_INT_EL(output,j++,0) = mgr->managerId;
    LST_INT_EL(output,j++,0) = mgr->length;
    LST_INT_EL(output,j++,0) = mgr->num_con;
    LST_INT_EL(output,j++,0) = mgr->counter;
    SET_LST_CHR_EL(output,j++,0,C_S_CPY(SQLITE_VERSION));
    if(*shared_cache)
        SET_LST_CHR_EL(output,j++,0,C_S_CPY("on"));
    else
        SET_LST_CHR_EL(output,j++,0,C_S_CPY("off"));
    UNPROTECT(1);
    return output;
}

SEXP 
RSQLite_connectionInfo(Con_Handle conHandle)
{
    int info_count = 6, i = 0, nres;
    RS_DBI_connection *con = RS_DBI_getConnection(conHandle);
    RS_SQLite_conParams *params = (RS_SQLite_conParams *) con->conParams;
    SEXP rsIds;

    SEXP info = PROTECT(NEW_LIST(info_count));
    SEXP info_nms = PROTECT(NEW_CHARACTER(info_count));
    SET_NAMES(info, info_nms);
    UNPROTECT(1);

    SET_STRING_ELT(info_nms, i, mkChar("dbname"));
    SET_VECTOR_ELT(info, i++, mkString(params->dbname));

    SET_STRING_ELT(info_nms, i, mkChar("serverVersion"));
    SET_VECTOR_ELT(info, i++, mkString(SQLITE_VERSION));

    SET_STRING_ELT(info_nms, i, mkChar("rsId"));
    rsIds = PROTECT(NEW_INTEGER(con->length));
    nres = RS_DBI_listEntries(con->resultSetIds, con->length, INTEGER(rsIds));
    SET_LENGTH(rsIds, nres);
    SET_VECTOR_ELT(info, i++, rsIds);
    UNPROTECT(1);

    SET_STRING_ELT(info_nms, i, mkChar("loadableExtensions"));
    SET_VECTOR_ELT(info, i++,
                   mkString(params->loadable_extensions ? "on" : "off"));

    SET_STRING_ELT(info_nms, i, mkChar("flags"));
    SET_VECTOR_ELT(info, i++, ScalarInteger(params->flags));

    SET_STRING_ELT(info_nms, i, mkChar("vfs"));
    SET_VECTOR_ELT(info, i++, mkString(params->vfs));

    UNPROTECT(1);
    return info;
}

SEXP 
RS_SQLite_resultSetInfo(Res_Handle rsHandle)
{
    RS_DBI_resultSet   *result;
    SEXP output, flds;
    Sint  n = 6;
    char  *rsDesc[] = {"statement", "isSelect", "rowsAffected",
                       "rowCount", "completed", "fieldDescription"};
    Stype rsType[]  = {STRSXP, INTSXP, INTSXP,
                       INTSXP,   INTSXP, LIST_TYPE};
    Sint  rsLen[]   = {1, 1, 1, 1, 1, 1};

    result = RS_DBI_getResultSet(rsHandle);
    if(result->fields)
        PROTECT(flds = RS_DBI_getFieldDescriptions(result->fields));
    else
        PROTECT(flds = S_NULL_ENTRY);

    PROTECT(output = RS_DBI_createNamedList(rsDesc, rsType, rsLen, n));
    SET_LST_CHR_EL(output,0,0,C_S_CPY(result->statement));
    LST_INT_EL(output,1,0) = result->isSelect;
    LST_INT_EL(output,2,0) = result->rowsAffected;
    LST_INT_EL(output,3,0) = result->rowCount;
    LST_INT_EL(output,4,0) = result->completed;
    if(flds != S_NULL_ENTRY)
        SET_VECTOR_ELT(LST_EL(output, 5), (Sint) 0, flds);

    UNPROTECT(2);
    return output;
}

SEXP 
RS_SQLite_typeNames(SEXP typeIds)
{
    SEXP typeNames;
    Sint n;
    Sint *typeCodes;
    int i;
    char *s;

    n = LENGTH(typeIds);
    typeCodes = INTEGER_DATA(typeIds);
    PROTECT(typeNames = NEW_CHARACTER(n));
    for(i = 0; i < n; i++) {
        s = RS_DBI_getTypeName(typeCodes[i], RS_SQLite_fieldTypes);
        SET_CHR_EL(typeNames, i, C_S_CPY(s));
    }
    UNPROTECT(1);
    return typeNames;
}

SEXP     /* returns TRUE/FALSE */
RS_SQLite_importFile(
    Con_Handle conHandle,
    SEXP s_tablename,
    SEXP s_filename,
    SEXP s_separator,
    SEXP s_eol,
    SEXP s_skip
    )
{
    RS_DBI_connection *con;
    sqlite3           *db_connection;
    char              *zFile, *zTable, *zSep, *zEol;
    const char *s, *s1;
    Sint              rc, skip;
    SEXP output;


    s = CHR_EL(s_tablename, 0);
    zTable = (char *) malloc( strlen(s)+1);
    if(!zTable){
        RS_DBI_errorMessage("could not allocate memory", RS_DBI_ERROR);
    }
    (void) strcpy(zTable, s);

    s = CHR_EL(s_filename, 0);
    zFile = (char *) malloc( strlen(s)+1);
    if(!zFile){
        free(zTable);
        RS_DBI_errorMessage("could not allocate memory", RS_DBI_ERROR);
    }
    (void) strcpy(zFile, s);

    s = CHR_EL(s_separator, 0);
    s1 = CHR_EL(s_eol, 0);
    zSep = (char *) malloc( strlen(s)+1);
    zEol = (char *) malloc(strlen(s1)+1);
    if(!zSep || !zEol){
        free(zTable);
        free(zFile);
        if(zSep) free(zSep);
        if(zEol) free(zEol);
        RS_DBI_errorMessage("could not allocate memory", RS_DBI_ERROR);
    }
    (void) strcpy(zSep, s);
    (void) strcpy(zEol, s1);

    skip = (Sint) INT_EL(s_skip, 0);

    con = RS_DBI_getConnection(conHandle);
    db_connection = (sqlite3 *) con->drvConnection;

    rc = RS_sqlite_import(db_connection, zTable, zFile, zSep, zEol, skip);

    free(zTable);
    free(zFile);
    free(zSep);

    PROTECT(output = NEW_LOGICAL((Sint) 1));
    LOGICAL_POINTER(output)[0] = rc;
    UNPROTECT(1);
    return output;
}

/* The following code comes directly from SQLite's shell.c, with
 * obvious minor changes.
 */
int
RS_sqlite_import(
    sqlite3 *db,
    const char *zTable,          /* table must already exist */
    const char *zFile,
    const char *separator,
    const char *eol,
    Sint skip
    )
{
    sqlite3_stmt *pStmt;        /* A statement */
    int rc;                     /* Result code */
    int nCol;                   /* Number of columns in the table */
    int nByte;                  /* Number of bytes in an SQL string */
    int i, j;                   /* Loop counters */
    int nSep;                   /* Number of bytes in separator[] */
    char *zSql;                 /* An SQL statement */
    char *zLine = NULL;         /* A single line of input from the file */
    char **azCol;               /* zLine[] broken up into columns */
    char *zCommit;              /* How to commit changes */
    FILE *in;                   /* The input file */
    int lineno = 0;             /* Line number of input file */
    char errMsg[512];
    char *z;

    nSep = strlen(separator);
    if( nSep==0 ){
        RS_DBI_errorMessage(
            "RS_sqlite_import: non-null separator required for import",
            RS_DBI_ERROR);
    }
    zSql = sqlite3_mprintf("SELECT * FROM '%q'", zTable);
    if( zSql==0 ) return 0;
    nByte = strlen(zSql);
    rc = sqlite3_prepare_v2(db, zSql, -1, &pStmt, 0);
    sqlite3_free(zSql);
    if (rc != SQLITE_OK) {
        sqlite3_finalize(pStmt);
        (void) sprintf(errMsg, "RS_sqlite_import: %s", sqlite3_errmsg(db));
        RS_DBI_errorMessage(errMsg, RS_DBI_ERROR);
        nCol = 0;
    }else{
        nCol = sqlite3_column_count(pStmt);
    }
    sqlite3_finalize(pStmt);
    if( nCol==0 ) return 0;
    zSql = malloc( nByte + 20 + nCol*2 );
    if( zSql==0 ) return 0;
    sqlite3_snprintf(nByte+20, zSql, "INSERT INTO '%q' VALUES(?", zTable);
    j = strlen(zSql);
    for(i=1; i<nCol; i++){
        zSql[j++] = ',';
        zSql[j++] = '?';
    }
    zSql[j++] = ')';
    zSql[j] = 0;
    rc = sqlite3_prepare_v2(db, zSql, -1, &pStmt, 0);
    free(zSql);
    if (rc != SQLITE_OK) {
        sqlite3_finalize(pStmt);
        (void) sprintf(errMsg, "RS_sqlite_import: %s", sqlite3_errmsg(db));
        RS_DBI_errorMessage(errMsg, RS_DBI_ERROR);
    }
    in = fopen(zFile, "rb");
    if( in==0 ){
        (void) sprintf(errMsg, "RS_sqlite_import: cannot open file %s", zFile);
        sqlite3_finalize(pStmt);
        RS_DBI_errorMessage(errMsg, RS_DBI_ERROR);
    }
    azCol = malloc( sizeof(azCol[0])*(nCol+1) );
    if( azCol==0 ) return 0;
    sqlite3_exec(db, "BEGIN", 0, 0, 0);
    zCommit = "COMMIT";
    while( (zLine = RS_sqlite_getline(in, eol)) != NULL){
        lineno++;
        if(lineno <= skip) continue;
        i = 0;
        azCol[0] = zLine;
        for(i=0, z=zLine; *z && *z!='\n' && *z!='\r'; z++){
            if( *z==separator[0] && strncmp(z, separator, nSep)==0 ){
                *z = 0;
                i++;
                if( i<nCol ){
                    azCol[i] = &z[nSep];
                    z += nSep-1;
                }
            }
        }
        if( i+1!=nCol ){
            (void) sprintf(errMsg,
                           "RS_sqlite_import: %s line %d expected %d columns of data but found %d",
                           zFile, lineno, nCol, i+1);
            zCommit = "ROLLBACK";
            break;
        }

        for(i=0; i<nCol; i++){
            if(azCol[i][0]=='\\' && azCol[i][1]=='N'){   /* insert NULL for NA */
                sqlite3_bind_null(pStmt, i+1);
            }
            else {
                sqlite3_bind_text(pStmt, i+1, azCol[i], -1, SQLITE_STATIC);
            }
        }

        rc = sqlite3_step(pStmt);
        if (rc != SQLITE_DONE && rc != SQLITE_SCHEMA) {
            sqlite3_finalize(pStmt);
            (void) sprintf(errMsg, "RS_sqlite_import: %s", sqlite3_errmsg(db));
            RS_DBI_errorMessage(errMsg, RS_DBI_ERROR);
        }
        rc = sqlite3_reset(pStmt);
        free(zLine);
        zLine = NULL;
        if (rc != SQLITE_OK) {
            sqlite3_finalize(pStmt);
            (void) sprintf(errMsg,"RS_sqlite_import: %s", sqlite3_errmsg(db));
            zCommit = "ROLLBACK";
            break;
        }
    }
    free(azCol);
    fclose(in);
    sqlite3_finalize(pStmt);
    sqlite3_exec(db, zCommit, 0, 0, 0);
    if (strcmp(zCommit, "ROLLBACK") == 0) {
        RS_DBI_errorMessage(errMsg, RS_DBI_ERROR);
    }
    return 1;
}

/* the following is only needed (?) on windows (getline is a GNU extension
 * and it gave me problems with minGW).  Note that we drop the (UNIX)
 * new line character.  The R function safe.write() explicitly uses
 * eol = '\n' even on Windows.
 */

char *
RS_sqlite_getline(FILE *in, const char *eol)
{
    /* caller must free memory */
    char *buf, ceol;
    size_t nc, i;
    int c, j, neol;
    int found_eol = 0;

    nc = 1024; i = 0;
    buf = (char *) malloc(nc);
    if(!buf)
        RS_DBI_errorMessage("RS_sqlite_getline could not malloc", RS_DBI_ERROR);

    neol = strlen(eol);  /* num of eol chars */
    ceol = eol[neol-1];  /* last char in eol */
    while(TRUE){
        c=fgetc(in);
        if(i==nc){
            nc = 2 * nc;
            buf = (char *) realloc((void *) buf, nc);
            if(!buf)
                RS_DBI_errorMessage(
                    "RS_sqlite_getline could not realloc", RS_DBI_ERROR);
        }
        if(c==EOF)
            break;
        buf[i++] = c;
        if (c == ceol) {
            /* see if we've got eol */
            found_eol = 1;
            for (j = neol - 1; j > 0; j--) {
                if (buf[(i - 1) - j] != eol[neol - 1 - j]) {
                    found_eol = 0;
                    break;
                }
            }
            if (found_eol) {
                buf[i-neol] = '\0';   /* drop the newline char(s) */
                break;
            }
        }
    }

    if (i == 0 || strlen(buf) == 0) {    /* empty line */
        free(buf);
        buf = (char *) NULL;
    }

    return buf;
}

SEXP RS_SQLite_copy_database(Con_Handle fromConHandle, Con_Handle toConHandle)
{
    sqlite3_backup *backup = NULL;
    RS_DBI_connection *fromCon = RS_DBI_getConnection(fromConHandle);
    RS_DBI_connection *toCon = RS_DBI_getConnection(toConHandle);
    sqlite3 *dbFrom = (sqlite3 *)fromCon->drvConnection;
    sqlite3 *dbTo = (sqlite3 *)toCon->drvConnection;
    int rc = 0;

    backup = sqlite3_backup_init(dbTo, "main", dbFrom, "main");
    if (backup) {
        sqlite3_backup_step(backup, -1);
        sqlite3_backup_finish(backup);
    }
    rc = sqlite3_errcode(dbTo);
    if (rc != SQLITE_OK) {
        RS_SQLite_setException(toCon, rc, sqlite3_errmsg(dbTo));
        RS_DBI_errorMessage(sqlite3_errmsg(dbTo), RS_DBI_ERROR);
    }
    return R_NilValue;
}
