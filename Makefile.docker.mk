PREFIX=docker run --rm -it -v $(PWD):/app schemerace/elixir-dev

pull:
	docker pull schemerace/elixir-dev

build_image:
	# docker build --build-arg http_proxy=http://host.docker.internal:8001 . -t schemerace/elixir-dev
	docker build . -t schemerace/elixir-dev

boot:
	$(PREFIX) mix deps.get

deps:
	$(PREFIX) mix deps

run:
	$(PREFIX) mix run --no-halt 

# take first 36 orders for quick test
sample: 
	docker run --rm -it -v $(PWD):/app -e MIX_ENV=sample schemerace/elixir-dev mix run --no-halt

# take first 36 orders for quick test, but do not dispatch courier
nodispatch:
	docker run --rm -it -v $(PWD):/app -e MIX_ENV=nodispatch schemerace/elixir-dev mix run --no-halt

test:
	$(PREFIX) mix test --no-start

readme:
	cat README.md 

.PHONY: all boot deps test clean