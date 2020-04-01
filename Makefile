all: help

help:
	@echo "make help   # display this section"
	@echo "make gen    # generate min.sh to be copied in entrypoint.sh"
	@echo "make test   # test timegroup.sh - should print DONE without FAILURE"
	@echo "make check  # analyze the scripts using shellcheck"

gen:
	./helper.sh gen

test:
	./helper.sh test

check:
	shellcheck timegroup.sh
	shellcheck -x helper.sh
	shellcheck -x entrypoint.sh

