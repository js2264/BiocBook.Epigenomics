ARG BIOC_VERSION

FROM bioconductor/bioconductor_docker:devel

COPY . /opt/BiocBook

## Install Quarto
RUN apt-get update && apt-get install gdebi-core -y
RUN curl -LO https://quarto.org/download/latest/quarto-linux-amd64.deb && gdebi --non-interactive quarto-linux-amd64.deb

## Install pak
RUN Rscript -e 'install.packages("pak", repos = "https://r-lib.github.io/p/pak/devel/")'

## Set repositories 
RUN Rscript -e 'write(paste0("R_BIOC_VERSION=", gsub(".[0-9]*$$", "", as.character(packageVersion("BiocVersion")))), paste0(Sys.getenv("R_HOME"), "/etc/Renviron.site"), append = TRUE)'
RUN Rscript -e 'write(paste0("BIOCBOOK_PACKAGE=", gsub(".*: ", "", grep("Package: ", readLines("/opt/BiocBook/DESCRIPTION"), value = TRUE))), paste0(Sys.getenv("R_HOME"), "/etc/Renviron.site"), append = TRUE)'
RUN Rscript -e 'write(paste0("BIOCBOOK_IMAGE=", tolower(Sys.getenv("BIOCBOOK_PACKAGE"))), paste0(Sys.getenv("R_HOME"), "/etc/Renviron.site"), append = TRUE)'

## Install BiocBook repo
RUN Rscript -e 'pak::pkg_install("/opt/BiocBook/", ask = FALSE, dependencies = c("Depends", "Imports", "Suggests"))'

## Install conda and required files
RUN curl -L micro.mamba.pm/install.sh | bash
RUN /root/.local/bin/micromamba create --file /opt/BiocBook/requirements.yml --yes

## Check installed BiocBook
RUN Rscript -e 'devtools::check("/opt/BiocBook/", error_on = "error")'
