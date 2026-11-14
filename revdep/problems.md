# GitStats (2.5.2)

* GitHub: <https://github.com/r-world-devs/GitStats>
* Email: <mailto:banasmaciek@gmail.com>
* GitHub mirror: <https://github.com/cran/GitStats>

Run `revdepcheck::revdep_details(, "GitStats")` for more info

## Newly broken

*   checking tests ... ERROR
     ```
     ...
       Expected `gl_repos_urls_with_code_in_files` to have type "character".
       Actual type: "NULL"
       ── Failure ('test-get_urls_repos-GitLab.R:190:3'): get_repos_urls_with_code_from_repos returns repositories URLS ──
       Expected `length(gl_repos_urls_with_code_in_files)` > 0.
       Actual comparison: 0.0 <= 0.0
       Difference: 0.0 <= 0
       ── Failure ('test-get_urls_repos-GitStats.R:36:3'): get_repos_urls_from_hosts gets data with_code in_files from the hosts ──
       Expected `any(grepl("gitlab.com", repos_urls_from_hosts_with_code_in_files))` to be TRUE.
       Differences:
       `actual`:   FALSE
       `expected`: TRUE 
       
       ── Failure ('test-get_urls_repos-GitStats.R:108:3'): get_repos_urls gets vector of repository URLS ──
       Expected `length(repos_urls)` > 1.
       Actual comparison: 1.0 <= 1.0
       Difference: 0.0 <= 0
       ── Failure ('test-get_urls_repos-GitStats.R:132:3'): get_repos_urls gets vector of repository URLS ──
       Expected `length(repos_urls)` > 1.
       Actual comparison: 1.0 <= 1.0
       Difference: 0.0 <= 0
       
       [ FAIL 13 | WARN 0 | SKIP 160 | PASS 1374 ]
       Error:
       ! Test failures.
       Execution halted
     ```

