version = $(shell cat ../DESCRIPTION|grep Version:|awk '{print $$2}')
pkg_name = RSQLite
pkg = $(pkg_name)_$(version).tar.gz

cran_ftp = ftp://cran.R-project.org/incoming/
cran_email = CRAN@R-project.org
cran_subject = "CRAN submission $(pkg_name) $(version)"

all: prepare_upload

$(pkg):
	R CMD build ../../$(pkg_name)

build: $(pkg)

check: $(pkg)
	R CMD check --as-cran $(pkg)

install: $(pkg)
	R CMD INSTALL $(pkg)

clean:
	-rm -rf $(pkg) RSQLite.Rcheck

prepare_upload: clean check
	@echo "Submit $(pkg) $(version) to CRAN as follows:"
	@echo ""
	@echo "curl --disable-epsv -T $(pkg)_$(version) $(cran_ftp)"
	@echo
	@echo "After uploading, send an email:"
	@echo ""
	@echo "To: $(cran_email)"
	@echo "Subject: $(cran_subject)"
	@echo ""
	@echo "Did you:"
	@echo "    - update NEWS?"
	@echo "    - write and verify tests?"
	@echo "    - use latest R?"
	@echo ""


.PHONY: build check install clean prepare_upload
