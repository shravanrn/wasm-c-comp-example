.DEFAULT_GOAL := build

SHELL := /bin/bash

CURRPATH=$(shell realpath .)

wasm-tools-1.0.40-x86_64-linux.tar.gz:
	wget https://github.com/bytecodealliance/wasm-tools/releases/download/wasm-tools-1.0.40/wasm-tools-1.0.40-x86_64-linux.tar.gz

wasm-tools-1.0.40-x86_64-linux: wasm-tools-1.0.40-x86_64-linux.tar.gz
	tar -zxf ./wasm-tools-1.0.40-x86_64-linux.tar.gz

wit-bindgen-v0.11.0-x86_64-linux.tar.gz:
	wget https://github.com/bytecodealliance/wit-bindgen/releases/download/wit-bindgen-cli-0.11.0/wit-bindgen-v0.11.0-x86_64-linux.tar.gz

wit-bindgen-v0.11.0-x86_64-linux: wit-bindgen-v0.11.0-x86_64-linux.tar.gz
	tar -zxf ./wit-bindgen-v0.11.0-x86_64-linux.tar.gz

wasi-sdk-20.0-linux.tar.gz:
	wget https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-20/wasi-sdk-20.0-linux.tar.gz

wasi-sdk-20.0: wasi-sdk-20.0-linux.tar.gz
	tar -zxf ./wasi-sdk-20.0-linux.tar.gz

wasmcon2023:
	git clone https://github.com/Kylebrown9/wasmcon2023

gen:
	mkdir -p ./gen

bootstrap: wasm-tools-1.0.40-x86_64-linux wit-bindgen-v0.11.0-x86_64-linux wasi-sdk-20.0 wasmcon2023 gen
	if [ ! -x "$(shell command -v rustc)" ] ; then \
		curl https://sh.rustup.rs -sSf | sh -s -- -y; \
		source ~/.cargo/env; \
	fi
	rustup update
	cargo install wasmtime-cli --features=component-model --git https://github.com/bytecodealliance/wasmtime
	touch ./bootstrap


gen/proxy_greeter.componment.wasm: ./wasmcon2023/wit/greeter.wit
	cd gen && \
	../wit-bindgen-v0.11.0-x86_64-linux/wit-bindgen c ../wasmcon2023/wit/greeter.wit --world proxy-greeter && \
	../wasi-sdk-20.0/bin/clang \
			proxy_greeter.c ../wasmcon2023/components/c/component.c \
			proxy_greeter_component_type.o \
			-o proxy_greeter.c.wasm -mexec-model=reactor && \
	../wasm-tools-1.0.40-x86_64-linux/wasm-tools component new proxy_greeter.c.wasm -o ./proxy_greeter.componment.wasm


gen/greeter.componment.wasm: ./wasmcon2023/wit/greeter.wit
	cd gen && \
	../wit-bindgen-v0.11.0-x86_64-linux/wit-bindgen c ../wasmcon2023/wit/greeter.wit --world greeter && \
	../wasi-sdk-20.0/bin/clang \
			greeter.c ../component-endpoint.c \
			greeter_component_type.o \
			-I $(CURRPATH)/gen \
			-o greeter-module.c.wasm -mexec-model=reactor && \
	../wasm-tools-1.0.40-x86_64-linux/wasm-tools component new greeter-module.c.wasm -o ./greeter.componment.wasm

gen/combined.wasm: gen/proxy_greeter.componment.wasm gen/greeter.componment.wasm
	cd gen && \
	../wasm-tools-1.0.40-x86_64-linux/wasm-tools compose -o combined.wasm ./proxy_greeter.componment.wasm -d ./greeter.componment.wasm

gen/combined2.wasm: gen/combined.wasm
	cd gen && \
	../wasm-tools-1.0.40-x86_64-linux/wasm-tools compose -o combined2.wasm ./proxy_greeter.componment.wasm -d ./combined.wasm

.PHONY: build
build: gen/combined2.wasm

.PHONY: run
run:
	cd ./wasmcon2023/runner/ && \
	cargo run -- --component ../../gen/combined2.wasm