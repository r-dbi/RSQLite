#include "param_binding.h"
#include "Rhelpers.h"
#include <string.h>
#include <stdlib.h>


static int *
init_bindParams(int num_cols)
{
    int i;
    /* FIXME: this could probably move to R_alloc */
    int *used_index = (int *)malloc(sizeof(int) * num_cols);
    if (!used_index) return NULL;

    for (i = 0; i < num_cols; i++){
        used_index[i] = -1;
    }
    return used_index;
}

static int first_not_used(const int *used_index, int len)
{
    int j, current = -1;
    for (j = 0; j < len; j++) {
        if (used_index[j] == -1) {
            current = j;
            break;
        }
    }
    return current;
}

void add_data_to_param_binding(RS_SQLite_bindParams *params, int i, SEXP data)
{
    int did_alloc = 1;
    SEXP col_data;
    if (isFactor(data)) {
        col_data = Rf_asCharacterFactor(data);
    }
    else {
        switch (TYPEOF(data)) {
        case LGLSXP:
            col_data = Rf_coerceVector(data, INTSXP);
            break;
        case INTSXP: case REALSXP: case STRSXP: case VECSXP: /* VECSXP => BLOB */
            did_alloc = 0;
            col_data = data;
            break;
        default:
            col_data = Rf_coerceVector(data, STRSXP);
        }
    }
    /* Since params->data is preserved, this provides protection from
       GC */
    SET_VECTOR_ELT(params->data, i, col_data);
    if (!did_alloc) {
        /* we want to hold on to the data columns and make sure that
           they are duplicated on modification so our copy is
           preserved. */
        SET_NAMED(data, 2);
    }
}

static int find_by_name(const char *paramName, SEXP colNames)
{
    int i = 0, len = length(colNames), ans = -1;
    const char *pname = paramName + 1;    /* skip past initial bind identifier */
    for (i = 0; i < len; i++) {
        const char *s = CHAR(STRING_ELT(colNames, i));
        if (strcmp(pname, s) == 0) {
            ans = i;
            break;
        }
    }
    return ans;
}

RS_SQLite_bindParams *
RS_SQLite_createParameterBinding(int n, SEXP bind_data,
                                 sqlite3_stmt *stmt, char *errorMsg)
{
    RS_SQLite_bindParams *params;
    int i, *used_index, current, num_cols, err = 0;
    SEXP colNames, col_data;

    colNames = Rf_getAttrib(bind_data, R_NamesSymbol);
    num_cols = length(colNames);
    if (num_cols < n) {
        sprintf(errorMsg,
                "incomplete data binding: expected %d parameters, got %d",
                n, num_cols);
        return NULL;
    }

    /* could this move to R_alloc? */
    params = (RS_SQLite_bindParams *)malloc(sizeof(RS_SQLite_bindParams));
    if (!params) {
        sprintf(errorMsg, "could not allocate memory");
        return NULL;
    }
    params->count = n;
    params->row_count = length(VECTOR_ELT(bind_data, 0));
    params->rows_used = 0;
    params->row_complete = 1;
    /* XXX: if the R allocation fails, we leak memory */
    params->data = Rf_allocVector(VECSXP, n);
    R_PreserveObject(params->data);

    used_index = init_bindParams(num_cols);
    if (!used_index) {
        RS_SQLite_freeParameterBinding(&params);
        sprintf(errorMsg, "could not allocate memory");
        return NULL;
    }

    for (i = 0; i < n; i++) {
        const char *paramName = sqlite3_bind_parameter_name(stmt, i + 1);
        current = -1;
        if (paramName == NULL) { 
            /* assume the first non-used column is the one we want */
            current = first_not_used(used_index, num_cols);
            if (current >= 0) {
                used_index[current] = 1;
            } else {
                sprintf(errorMsg,
                        "unable to bind data for positional parameter %d", i+1);
                err = 1;
                break;
            }
        } else {
            current = find_by_name(paramName, colNames);
            if (current >= 0) {
                if (used_index[current] == -1) {
                    used_index[current] = 1;
                } else {
                    sprintf(errorMsg,
                            "attempted to re-bind column [%s] to positional "
                            "parameter %d",
                            CHAR(STRING_ELT(colNames, current)), i+1);
                    err = 1;
                    break;
                }
            } else { /* current < 0 */
                /* FIXME: we should pass in size of errorMsg buffer and use
                   snprint since size of paramName is unknown.
                 */
                sprintf(errorMsg,
                        "unable to bind data for parameter '%s'", paramName);
                err = 1;
                break;
            }
        }
        if (!err) {
            col_data = VECTOR_ELT(bind_data, current);
            add_data_to_param_binding(params, i, col_data);
        }
    }
    free(used_index);
    used_index = NULL;
    if (err) {
        RS_SQLite_freeParameterBinding(&params);
    }
    return params;
}

void
RS_SQLite_freeParameterBinding(RS_SQLite_bindParams **params)
{
    if ((*params)->data) R_ReleaseObject((*params)->data);
    free(*params);
    *params = NULL;
}
