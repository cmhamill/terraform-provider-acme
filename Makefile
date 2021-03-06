ALL_TARGETS += darwin_amd64 \
	linux_amd64 \
	windows_amd64

VERSION ?= dev

export ACME_SERVER_URL ?= https://acme-staging-v02.api.letsencrypt.org/directory

.PHONY: test
test:
	go test . ./acme

.PHONY: testacc
testacc:
	TF_ACC=1 go test -v ./acme $(TESTARGS) -timeout 240m

.PHONY: debugacc
debugacc:
	TF_ACC=1 dlv test ./acme -- -test.v $(TESTARGS) -test.timeout 240m

pkg/darwin_amd64/terraform-provider-acme:
	@echo "==> Building $@..."
	@CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 \
		go build -o "$@"

pkg/linux_amd64/terraform-provider-acme:
	@echo "==> Building $@..."
	@CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
		go build -o "$@"

pkg/windows_amd64/terraform-provider-acme:
	@echo "==> Building $@..."
	@CGO_ENABLED=0 GOOS=windows GOARCH=amd64 \
		go build -o "$@.exe"

# Define package targets for each of the build targets we actually have on this system
define makePackageTarget

pkg/$(1).zip: pkg/$(1)/terraform-provider-acme
	@echo "==> Packaging for $(1)..."
	@mkdir -p pkg/dist
	@zip -j pkg/dist/terraform-provider-acme_$(VERSION)_$(1).zip pkg/$(1)/*

endef

# Reify the package targets
$(foreach t,$(ALL_TARGETS),$(eval $(call makePackageTarget,$(t))))

.PHONY: release
release: clean $(foreach t,$(ALL_TARGETS),pkg/$(t).zip) ## Build all release packages which can be built on this platform.
	@echo "==> Results:"
	@tree --dirsfirst pkg

.PHONY: build
build: release

.PHONY: clean
clean:
	rm -rf pkg/
