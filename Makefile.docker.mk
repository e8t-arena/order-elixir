PREFIX=docker run --rm -it -v $(PWD):/app peterlau/elixir-dev

build_image:
	docker build . -t peterlau/elixir-dev

boot:
	$(PREFIX) mix deps.get

deps:
	$(PREFIX) mix deps

test:
	$(PREFIX) mix test --no-start

.PHONY: all boot deps test clean