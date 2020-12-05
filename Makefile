boot:
	mix deps.get

deps:
	mix deps

run:
	mix run --no-halt 

# take first 36 orders for quick test
sample: 
	MIX_ENV=sample mix run --no-halt

# take first 36 orders for quick test, but do not dispatch courier
nodispatch:
	MIX_ENV=nodispatch mix run --no-halt 

test:
	mix test --no-start

readme:
	cat README.md 

.PHONY: all boot deps test clean