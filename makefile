

clean:
	cd libs/libheif && make clean
	rm -rf libs/libheif/examples/src libs/libheif/examples/pkg libs/libheif/tests/pkg libs/libheif/tests/src libs/x265/build/darwin
	go mod tidy
	go mod edit -droprequire github.com/strukturag/libheif