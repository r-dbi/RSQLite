Hi


This is an automated email to let you know about the upcoming release of {{{my_package}}} (version {{{my_version}}}), which I'm planning to submit to CRAN on {{{ date }}}.

To check for potential problems, I ran `R CMD check` on your package {{{your_package}}} (version {{{your_version}}}).  I have appended the check results to the bottom of this message.  I found {{{your_summary}}}.

{{#you_have_problems}}
{{#you_cant_install}}Looks like I couldn't install your package {{{your_package}}}, I'd recommend you check it yourself. Unfortunately I don't have the resources to manually fix installation failures.

{{/you_cant_install}}
{{^you_cant_install}}Almost all CRAN and Bioconductor packages that I've checked ran their checks without new ERRORs, compared to the CRAN version {{{my_package}}} v1.1-2.  Exceptions mostly concern the `dbGetQuery()` method: please note that in the `NAMESPACE` file you can now use either `importFrom(RSQLite, dbGetQuery)` or `importMethodsFrom(DBI, dbGetQuery)`, but not `importMethodsFrom(RSQLite, dbGetQuery)`, because RSQLite doesn't implement this method anymore.  I've also noticed occasional segmentation faults in a few packages with the CRAN version {{{my_package}}} v1.1-2, but not with the current version.  Please see <https://github.com/rstats-db/RSQLite/commit/e38015fd70e3fab5bff5c5bb2bbca9a1f938a849#diff-9b9ef2f7fd487bc2c0b01dc920e29069> for a before-after comparison of check problems.

Other regressions may arise due to changes in the public API, which have been done to improve compatibility with the upcoming DBI specification.  In particular, the new default value `FALSE` for the `row.names` argument to a few methods may cause problem, but it's easy to revert to the previous default.  Please see the NEWS (link below) for a full list of changes.

Apologies if I have wrongly detected failure because pandoc-citeproc is missing.

Please submit an update of your package {{{your_package}}} to fix any ERRORs or WARNINGs. Please pay attention to the deprecation warnings, they may become errors at some point in the future. Other problems may not be caused by the update to {{{my_package}}}, but it really makes life easier if you also fix any other problems that may have accumulated over time. Please also try to minimise the NOTEs.

{{/you_cant_install}}

To get the development version of {{{my_package}}} so you can run the checks yourself, you can run:

    # install.packages("remotes")
    remotes::install_github("{{my_github}}")

To see what's changed visit <https://github.com/{{{my_github}}}/blob/master/NEWS.md>.

{{/you_have_problems}}
{{^you_have_problems}}It looks like everything is ok, so you don't need to take any action, but you might want to read the NEWS, <https://github.com/{{{my_github}}}/blob/master/NEWS.md>, to see what's changed.
Please note the new default value `FALSE` for the `row.names` argument to a few methods, it's easy to revert to the previous default if necessary,

{{/you_have_problems}}

If you have any questions about this email, please feel free to respond directly.  Thank you for your help with improving {{{my_package}}}.


Regards,

{{{ me }}}




{{{your_results}}}
