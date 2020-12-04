boot:
	mix deps.get

deps:
	mix deps

test:
	mix test --no-start

.PHONY: all boot deps test clean