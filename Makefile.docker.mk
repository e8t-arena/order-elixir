PREFIX=docker run --rm -it -v $(PWD):/app peterlau/elixir-dev

build_image:
	docker build . -t peterlau/elixir-dev

boot:
	$(PREFIX) mix deps.get

deps:
	$(PREFIX) mix deps

run:
	$(PREFIX) mix run --no-halt 

# take first 36 orders for quick test
sample: 
	docker run --rm -it -v $(PWD):/app -e MIX_ENV=sample peterlau/elixir-dev mix run --no-halt

# take first 36 orders for quick test, but do not dispatch courier
nodispatch:
	docker run --rm -it -v $(PWD):/app -e MIX_ENV=nodispatch peterlau/elixir-dev mix run --no-halt

test:
	$(PREFIX) mix test --no-start

.PHONY: all boot deps test clean