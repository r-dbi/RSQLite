RSQLite 2.3.4

## R CMD check results

- [x] Checked locally, R 4.3.2
- [x] Checked on CI system, R 4.3.2
- [x] Checked on win-builder, R devel

## Current CRAN check results

- [x] Checked on 2023-12-07, problems found: https://cran.r-project.org/web/checks/check_results_RSQLite.html
- [ ] WARN: r-devel-linux-x86_64-debian-clang
     Found the following significant warnings:
     connection.cpp:62:7: warning: format specifies type 'int' but the argument has type 'long' [-Wformat]
     See ‘/home/hornik/tmp/R.check/r-devel-clang/Work/PKGS/RSQLite.Rcheck/00install.out’ for details.
     * used C compiler: ‘Debian clang version 17.0.5 (1)’
     * used C++ compiler: ‘Debian clang version 17.0.5 (1)’
- [ ] WARN: r-devel-linux-x86_64-debian-gcc
     Found the following significant warnings:
     connection.cpp:61:19: warning: format ‘%i’ expects argument of type ‘int’, but argument 2 has type ‘long int’ [-Wformat=]
     See ‘/home/hornik/tmp/R.check/r-devel-gcc/Work/PKGS/RSQLite.Rcheck/00install.out’ for details.
     * used C compiler: ‘gcc-13 (Debian 13.2.0-7) 13.2.0’
     * used C++ compiler: ‘g++-13 (Debian 13.2.0-7) 13.2.0’
- [ ] WARN: r-devel-linux-x86_64-fedora-clang
     Found the following significant warnings:
     connection.cpp:62:7: warning: format specifies type 'int' but the argument has type 'long' [-Wformat]
     See ‘/data/gannet/ripley/R/packages/tests-clang/RSQLite.Rcheck/00install.out’ for details.
     * used C compiler: ‘clang version 17.0.5’
     * used C++ compiler: ‘clang version 17.0.5’
- [ ] WARN: r-devel-linux-x86_64-fedora-gcc
     Found the following significant warnings:
     connection.cpp:61:19: warning: format '%i' expects argument of type 'int', but argument 2 has type 'long int' [-Wformat=]
     See ‘/data/gannet/ripley/R/packages/tests-devel/RSQLite.Rcheck/00install.out’ for details.
     * used C compiler: ‘gcc-13 (GCC) 13.2.0’
     * used C++ compiler: ‘g++-13 (GCC) 13.2.0’
- [ ] WARN: r-devel-windows-x86_64
     Found the following significant warnings:
     connection.cpp:61:19: warning: format '%i' expects argument of type 'int', but argument 2 has type 'long int' [-Wformat=]
     See 'd:/Rcompile/CRANpkg/local/4.4/RSQLite.Rcheck/00install.out' for details.
     * used C compiler: 'gcc.exe (GCC) 12.3.0'
     * used C++ compiler: 'g++.exe (GCC) 12.3.0'

Check results at: https://cran.r-project.org/web/checks/check_results_RSQLite.html
