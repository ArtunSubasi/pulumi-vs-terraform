# Demo helpers. Run `make` for the list.
# Filter showcases with ONLY, e.g.  make check ONLY="02 05"

SHELL := bash
export ONLY

.PHONY: help prep reset reset-live check diff

help:
	@echo "make prep        Pre-cache providers, npm deps, Pulumi plugins + template (needs network once)"
	@echo "make reset       Wipe all state, .terraform/, workspaces, stacks, generated files"
	@echo "make reset-live  reset + restore every live/ dir to its committed version"
	@echo "make check       Run every final/ end to end (apply, tests, destroy). Needs a clean state"
	@echo "make diff        Show what will be typed live: diff -r final live per showcase"
	@echo ""
	@echo "Filter with ONLY, e.g.  make check ONLY=\"02 05\""

prep:
	@scripts/prep.sh

reset:
	@scripts/reset.sh

reset-live:
	@scripts/reset.sh --live

check:
	@scripts/check.sh

diff:
	@scripts/diff.sh
