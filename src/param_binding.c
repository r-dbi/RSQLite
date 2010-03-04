#include "param_binding.h"
#include "Rhelpers.h"
#include <string.h>
#include <stdlib.h>

RS_SQLite_bindParam *
RS_SQLite_createParameterBinding(int n, SEXP bind_data,
                                 sqlite3_stmt *stmt, char *errorMsg)
{
    RS_SQLite_bindParam *params;
    int i, j, *used_index, current, num_cols;
    SEXP colNames, data, levels;

    /* check that we have enough columns in the data frame */
    colNames = Rf_getAttrib(bind_data, R_NamesSymbol);
    num_cols = length(colNames);
    if(num_cols < n){
        sprintf(errorMsg,
                "incomplete data binding: expected %d parameters, got %d",
                n, num_cols);
        return NULL;
    }

    /* allocate and initalize the structures*/
    params = (RS_SQLite_bindParam *)malloc(sizeof(RS_SQLite_bindParam) * n);
    if(params==NULL){
        sprintf(errorMsg, "could not allocate memory");
        return NULL;
    }

    /* If too many columns are provided in the bind data, need to
       allocate enough space for the used_index
    */
    used_index = (int *)malloc(sizeof(int)*num_cols);
    if(used_index==NULL){
        free(params);
        sprintf(errorMsg, "could not allocate memory");
        return NULL;
    }

    for(i=0; i<num_cols; i++){
        used_index[i] = -1;
        if (i < n) {
            params[i].is_protected = 0;
            params[i].data = NULL;
        }
    }

    for(i=0; i<n; i++){
        const char *paramName = sqlite3_bind_parameter_name(stmt, i+1);

        current = -1;
        if(paramName == NULL){
            /* assume the first non-used column is the one we want */
            for(j=0; j<n; j++){
                if(used_index[j] == -1){
                    current = j;
                    used_index[j] = 1;
                    break;
                }
            }
        }
        else {
            for(j=0; j<num_cols; j++){
                /* skip past initial bind identifier */
                if(strcmp(paramName+1, CHR_EL(colNames, j)) == 0){
                    if(used_index[j] == -1){
                        current = j;
                        used_index[j] = 1;
                        break;
                    }
                    /* it's already in use! throw an error */
                    sprintf(errorMsg,
                            "attempted to re-bind column [%s] to positional "
                            "parameter %d",
                            CHR_EL(colNames, j), i+1);
                    free(params);
                    free(used_index);
                    return NULL;
                }
            }
        }

        if(current == -1){
            sprintf(errorMsg,
                    "unable to bind data for positional parameter %d", i+1);
            free(params);
            free(used_index);
            return NULL;
        }

        data = LST_EL(bind_data, current);

        params[i].is_protected = 0;

        if(isInteger(data) || isLogical(data)){
            params[i].type = INTSXP;
            params[i].data = data;
        }
        else if(isReal(data)){
            params[i].type = REALSXP;
            params[i].data = data;
        }
        else if(isString(data)){
            params[i].type = STRSXP;
            params[i].data = data;
        }
        else if(isFactor(data)){
            int factor_code, data_len = length(data);
            /* need to convert to a string vector */
            params[i].type = STRSXP;
            levels = Rf_getAttrib(data, R_LevelsSymbol);

            R_PreserveObject(params[i].data = Rf_allocVector(STRSXP, data_len));
            params[i].is_protected = 1;
            for (j = 0; j < data_len; j++) {
                factor_code = INT_EL(data, j);
                if (factor_code == NA_INTEGER)
                    SET_CHR_EL(params[i].data, j, NA_STRING);
                else
                    SET_CHR_EL(params[i].data, j,
                               STRING_ELT(levels, factor_code - 1));
            }
        }
        else{
            params[i].type = STRSXP;
            R_PreserveObject(params[i].data = Rf_coerceVector(data, STRSXP));
            params[i].is_protected = 1;
        }
    }
    free(used_index);
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
