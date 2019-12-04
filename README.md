
# backuptools

<!-- badges: start -->
<!-- badges: end -->

The goal of backuptools is to provide a set of bash utilities to do backups. Although the repository contains just a few bash-script, the R-package infrastructure is abused for convenience of documentation and deployment.

The package website is available at: https://pvrqualitasag.github.io/backuptools

## Installation

You can install the latest release of backuptools from [GitHub](https://github.com) with:

``` r
devtools::install_github("pvrqualitasag/backuptools")
```

## Example

The following example runs a basic data backup of `<data_source>` into the target directory `<backup_target>`:

``` bash
backup_data.sh -s <data_source> -t <backup_target>
```

