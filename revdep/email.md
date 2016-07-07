Hi


This is an automated email to let you know about the upcoming release of {{{ my_package }}}, which will be submitted to CRAN on {{{ date }}}. To check for potential problems, I ran `R CMD check` on your package {{{your_package}}} ({{{your_version}}}). 

I found: {{{your_summary}}}.

{{#you_have_problems}}
{{{your_results}}}

If I got an ERROR because I couldn't install your package (or one of its dependencies), my apologies. You'll have to run the checks yourself (unfortunately I don't have the time to diagnose installation failures).

Regressions may arise due to changes in the public API. In particular, the `dbGetQuery()` and `summary()` methods are not exported anymore.  Instead, use `DBI::dbGetQuery()` and `show()`, respectively. Furthermore, `dbSendPreparedQuery()`, `dbGetPreparedQuery()` and `dbListResults()` have been deprecated, these functions now raise an error. Use `dbBind()` for parametrized queries, listing the results of a connection is not supported anymore.

Otherwise, please carefully look at the results, and let me know if I've introduced a bug in {{{ my_package }}}.

To get the development version of {{{ my_package }}} so you can run the checks yourself, you can run:

    # install.packages("devtools")
    devtools::install_github("{{my_github}}")
    
To see what's changed visit <https://github.com/{{{my_github}}}/blob/master/NEWS.md>.

{{/you_have_problems}}
{{^you_have_problems}}
It looks like everything is ok, so you don't need to take any action, but you might want to read the NEWS, <https://github.com/{{{my_github}}}/blob/master/NEWS.md>, to see what's changed.
{{/you_have_problems}}

If you have any questions about this email, please feel free to respond directly.


Regards

{{{ me }}}
