#include "param_binding.h"
#include "Rhelpers.h"
#include <string.h>
#include <stdlib.h>


static int *
init_bindParams(RS_SQLite_bindParam *params,
                int num_params,
                int num_cols)
{
    int i;
    /* FIXME: this could probably move to R_alloc */
    int *used_index = (int *)malloc(sizeof(int) * num_cols);
    if (!used_index) return NULL;

    for (i = 0; i < num_cols; i++){
        used_index[i] = -1;
        if (i < num_params) {
            params[i].is_protected = 0;
            params[i].data = NULL;
        }
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

void add_data_to_param_binding(RS_SQLite_bindParam *param, SEXP data)
{
    if (isFactor(data)) {
        param->type = STRSXP;
        param->data = Rf_asCharacterFactor(data);
        R_PreserveObject(param->data);
        param->is_protected = 1;
    }
    else {
        switch (TYPEOF(data)) {
        case LGLSXP:
            param->type = INTSXP;
            param->data = Rf_coerceVector(data, INTSXP);
            R_PreserveObject(param->data);
            param->is_protected = 1;
            break;
        case INTSXP: case REALSXP: case STRSXP:
            param->type = TYPEOF(data);
            param->data = data;
            break;
        default:
            param->type = STRSXP;
            param->data = Rf_coerceVector(data, STRSXP);
            R_PreserveObject(param->data);
            param->is_protected = 1;
        }
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

RS_SQLite_bindParam *
RS_SQLite_createParameterBinding(int n, SEXP bind_data,
                                 sqlite3_stmt *stmt, char *errorMsg)
{
    RS_SQLite_bindParam *params;
    int i, *used_index, current, num_cols, err = 0;
    SEXP colNames, data;

    colNames = Rf_getAttrib(bind_data, R_NamesSymbol);
    num_cols = length(colNames);
    if (num_cols < n) {
        sprintf(errorMsg,
                "incomplete data binding: expected %d parameters, got %d",
                n, num_cols);
        return NULL;
    }

    /* could this move to R_alloc? */
    params = (RS_SQLite_bindParam *)malloc(sizeof(RS_SQLite_bindParam) * n);
    if (!params) {
        sprintf(errorMsg, "could not allocate memory");
        return NULL;
    }

    used_index = init_bindParams(params, n, num_cols);
    if (!used_index) {
        free(params);
        sprintf(errorMsg, "could not allocate memory");
        return NULL;
    }

    for (i = 0; i < n; i++) {
        const char *paramName = sqlite3_bind_parameter_name(stmt, i + 1);
        current = -1;
        if (paramName == NULL) { 
            /* assume the first non-used column is the one we want */
            current = first_not_used(used_index, num_cols);
            if (current >= 0) used_index[current] = 1;
        }
        else {
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
                }
            }
        }

        if (!err && current == -1) {
            sprintf(errorMsg,
                    "unable to bind data for positional parameter %d", i+1);
            err = 1;
        }

        if (!err) {
            data = VECTOR_ELT(bind_data, current);
            add_data_to_param_binding(&(params[i]), data);
        }
    }
    free(used_index);
    used_index = NULL;
    if (err) {
        free(params);
        params = NULL;
    }
    return params;
}

void
RS_SQLite_freeParameterBinding(int n, RS_SQLite_bindParam *params)
{
    int i;

    for(i=0; i<n; i++){
        if(params[i].is_protected)
            R_ReleaseObject(params[i].data);
    }
    free(params);
}
