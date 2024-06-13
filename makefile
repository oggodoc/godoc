################################################################################
#### INSTALLATION VARS
################################################################################
PREFIX=$(HOME)

################################################################################
#### BUILD VARS
################################################################################
BIN=godoc
BINDIR=bin
CMDDIR=cmd
HEAD=$(shell git describe --dirty --long --tags 2> /dev/null  || git rev-parse --short HEAD)
TIMESTAMP=$(shell TZ=UTC date '+%FT%T %Z')
# TIMESTAMP=$(shell date '+%Y-%m-%dT%H:%M:%S %z %Z')

LDFLAGS="-X 'main.binName=$(BIN)' -X 'main.buildVersion=$(HEAD)' -X 'main.buildTimestamp=$(TIMESTAMP)' -X 'main.compiledBy=$(shell go version)'" # `-s -w` removes some debugging info that might not be necessary in production (smaller binaries)

all: local

################################################################################
#### HOUSE CLEANING
################################################################################
.PHONY: _setup
_setup:
	mkdir -p $(BINDIR)

clean:
	rm -f $(BIN) $(BIN)-* $(BINDIR)/$(BIN) $(BINDIR)/$(BIN)-*

.PHONY: dep
dep:
	go mod tidy
	go mod vendor

.PHONY: version
version:
	@printf "\n\n%s\n\n" $(HEAD)

.PHONY: check
check: _setup
	golint
	goimports -w ./
	gofmt -w ./
	go vet

################################################################################
#### INSTALL
################################################################################

.PHONY: install
install: local
	mkdir -p $(PREFIX)/$(BINDIR)
	mv $(BINDIR)/$(BIN) $(PREFIX)/$(BINDIR)/$(BIN)
	@echo "\ninstalled $(BIN) to $(PREFIX)/$(BINDIR)\n"


.PHONY: uninstall
uninstall:
	rm -f $(PREFIX)/$(BINDIR)/$(BIN)

################################################################################
#### ENV BUILDS
################################################################################

.PHONY: local
local:
	go build -ldflags $(LDFLAGS) -o $(BINDIR)/$(BIN) ./$(CMDDIR)

.PHONY: localv
localv: check
	go build -mod=vendor -ldflags $(LDFLAGS) -o $(BINDIR)/$(BIN) ./$(CMDDIR)

.PHONY: test
test:
	go mod vendor
	go mod tidy
	go test -mod=vendor -coverprofile=coverage.out -covermode=count ./...

.PHONY: prod
prod: check
	GOWORK=off go build -ldflags $(LDFLAGS) -o $(BINDIR)/$(BIN) ./$(CMDDIR)
