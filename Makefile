RED         = $(shell printf "\033[31m")
BOLDRED     = $(shell printf "\033[1;31m")
YELLOW      = $(shell printf "\033[33m")
BOLDYELLOW  = $(shell printf "\033[1;33m")
GREEN       = $(shell printf "\033[32m")
BOLDGREEN   = $(shell printf "\033[1;32m")
BOLD        = $(shell printf "\033[1m")
NORMAL      = $(shell printf "\033[0m")

ifneq ($(shell git rev-parse --git-dir &> /dev/null; echo $$?), 0)
    $(warning $(BOLDYELLOW)Working directory is not a Git repository$(NORMAL))
endif

ifeq ($(shell go env GO111MODULE 2> /dev/null), off)
    $(warning $(BOLDYELLOW)Not using Go Modules$(NORMAL))
    MODULEPATH := .
else
    MODULEPATH := $(shell go mod edit -json 2> /dev/null | jq -r '.Module.Path')
endif

ifeq ($(shell go env GOMOD 2> /dev/null),)
    $(warning $(BOLDYELLOW)go.mod not found$(NORMAL))
endif

QUIET := $(findstring s, $(word 1, $(MAKEFLAGS)))
IGNORE_ERRORS := $(findstring i, $(word 1, $(MAKEFLAGS)))
KEEP_GOING := $(findstring k, $(word 1, $(MAKEFLAGS)))
SPACE := $(subst ,, )
SPACETO := +

BUILD := debug
DEFIMPORTPATH := main
SEMVER := 0.1.0

DEFINITIONS :=  -X=$(DEFIMPORTPATH).GoVersion=$(subst $(SPACE),$(SPACETO),$(shell go version 2> /dev/null))                         \
                -X=$(DEFIMPORTPATH).SysInfo=$(subst $(SPACE),$(SPACETO),$(shell uname -a 2> /dev/null))                             \
                -X=$(DEFIMPORTPATH).LogName=$(shell whoami 2> /dev/null)                                                            \
                -X=$(DEFIMPORTPATH).UserID=$(shell id -u 2> /dev/null)                                                              \
                -X=$(DEFIMPORTPATH).Host=$(shell hostname -f 2> /dev/null)                                                          \
                -X=$(DEFIMPORTPATH).User=$(shell git config user.name 2> /dev/null)                                                 \
                -X=$(DEFIMPORTPATH).Email=$(shell git config user.email 2> /dev/null)                                               \
                -X=$(DEFIMPORTPATH).Repo=$(shell basename $$(git rev-parse --show-toplevel 2> /dev/null))                           \
                -X=$(DEFIMPORTPATH).Branch=$(shell git branch --contain HEAD 2> /dev/null | grep '*' | head -n1 | cut -d' ' -f2-)   \
                -X=$(DEFIMPORTPATH).LatestTag=$(shell git describe --tags --dirty=-dev 2> /dev/null)                                \
                -X=$(DEFIMPORTPATH).LatestCommit=$(shell git rev-parse HEAD 2> /dev/null)                                           \
                -X=$(DEFIMPORTPATH).LatestCommitTimeStamp=$(shell git log -1 --format=%ct 2> /dev/null)                             \
                -X=$(DEFIMPORTPATH).ModulePath=$(MODULEPATH)                                                                        \
                -X=$(DEFIMPORTPATH).GOOS=$(shell echo $${GOOS:-$$(go env GOOS 2> /dev/null)})                                       \
                -X=$(DEFIMPORTPATH).GOARCH=$(shell echo $${GOARCH:-$$(go env GOARCH 2> /dev/null)})                                 \
                -X=$(DEFIMPORTPATH).GOHOSTOS=$(shell echo $${GOHOSTOS:-$$(go env GOHOSTOS 2> /dev/null)})                           \
                -X=$(DEFIMPORTPATH).GOHOSTARCH=$(shell echo $${GOHOSTARCH:-$$(go env GOHOSTARCH 2> /dev/null)})                     \
                -X=$(DEFIMPORTPATH).SemVer=$(SEMVER)                                                                                \
                -X=$(DEFIMPORTPATH).Build=$(BUILD)                                                                                  \
                -X=$(DEFIMPORTPATH).BuildTimeStamp=$(shell date +%s)

GOSUBDIRS := ./cmd ./internal ./pkg
_GOPATH := $(shell echo $${GOPATH:-$$(go env GOPATH 2> /dev/null)})
_GOBIN := $(shell echo $${GOBIN:-$$(go env GOBIN 2> /dev/null)})
GOPACKAGES := $(foreach dir,$(GOSUBDIRS),$(shell go list $(dir)/... 2> /dev/null | grep -v /vendor/))
GOFILES := $(foreach dir,$(GOSUBDIRS),$(shell go list -f '{{ range .GoFiles }}{{ $$.Dir }}/{{ . }} {{ end }}' $(dir)/... 2> /dev/null | grep -v /vendor/))
GOFILES := $(GOFILES) $(foreach dir,$(GOSUBDIRS),$(shell go list -f '{{ range .CgoFiles }}{{ $.Dir }}/{{ . }} {{ end }}' $(dir)/... 2> /dev/null | grep -v /vendor/))
TESTGOFILES := $(foreach dir,$(GOSUBDIRS),$(shell go list -f '{{ range .TestGoFiles }}{{ $$.Dir }}/{{ . }} {{ end }}' $(dir)/... 2> /dev/null | grep -v /vendor/))
TESTGOFILES := $(TESTGOFILES) $(foreach dir,$(GOSUBDIRS),$(shell go list -f '{{ range .XTestGoFiles }}{{ $$.Dir }}/{{ . }} {{ end }}' $(dir)/... 2> /dev/null | grep -v /vendor/))
TESTGOPACKAGES := $(foreach dir,$(GOSUBDIRS),$(shell go list -f '{{ if (or .TestGoFiles .XTestGoFiles) }}{{ .ImportPath }}{{ end }}' $(dir)/... 2> /dev/null | grep -v /vendor/))
CROSSOS := linux windows darwin freebsd openbsd netbsd
CROSSARCH := amd64

BUILDOPTS = $(BUILDOPTS.${BUILD})
BUILDOPTS.debug :=
BUILDOPTS.release := -trimpath
LDFLAGS = $(LDFLAGS.${BUILD})
LDFLAGS.debug := -ldflags="$(DEFINITIONS)"
LDFLAGS.release := -ldflags="-s -w $(DEFINITIONS)"
GCFLAGS = $(GCFLAGS.${BUILD})
GCFLAGS.debug := -gcflags='-N -l'
GCFLAGS.release := -gcflags=-trimpath="$(_GOPATH)/src"
ASMFLAGS = $(ASMFLAGS.${BUILD})
ASMFLAGS.debug :=
ASMFLAGS.release := -asmflags=-trimpath="$(_GOPATH)/src"
TESTOPTS := -timeout 60s -race
GOIMPORTSOPTS := -w
GOFMTOPTS := -s -w
GENERATEOPTS :=
GETOPTS := -u
GOLINTOPTS :=
VETOPTS :=
CLEANOPTS := -cache -testcache -i
BINDIR = $(BINDIR.${BUILD})
BINDIR.debug := dist/debug
BINDIR.release := dist/release
TARGETDIRS = $(TARGETDIRS.${BUILD})
TARGETDIRS.debug := $(BINDIR.debug)/app1 $(BINDIR.debug)/app2
TARGETDIRS.release := $(BINDIR.release)/app1 $(BINDIR.release)/app2
MAINDIRS = cmd/app1 cmd/app2
LOOKUP.app1 := cmd/app1
LOOKUP.app2 := cmd/app2

ifndef QUIET
    BUILDOPTS.debug += -v -x
    BUILDOPTS.release += -v -x
    TESTOPTS += -v
    GOIMPORTSOPTS += -v
    GOFMTOPTS += -l
    GENERATEOPTS += -v -x
    GETOPTS += -v
    CLEANOPTS += -x
endif

GOLINT := golint
ifneq ($(shell command -v golint &> /dev/null; echo $$?), 0)
    ifeq ($(wildcard $(_GOBIN)/golint),)
        $(warning $(BOLDYELLOW)Golint not found$(NORMAL))
    else
        GOLINT := $(_GOBIN)/golint
    endif
endif

GOIMPORTS := goimports
ifneq ($(shell command -v goimports &> /dev/null; echo $$?), 0)
    ifeq ($(wildcard $(_GOBIN)/goimports),)
        $(warning $(BOLDYELLOW)Goimports not found$(NORMAL))
    else
        GOIMPORTS := $(_GOBIN)/goimports
    endif
endif

GOFMT := gofmt
ifneq ($(shell command -v gofmt &> /dev/null; echo $$?), 0)
    ifeq ($(wildcard $(_GOBIN)/gofmt),)
        $(warning $(BOLDYELLOW)Gofmt not found$(NORMAL))
    else
        GOFMT := $(_GOBIN)/gofmt
    endif
endif

.DEFAULT_GOAL := all

all: build
debug: BUILD := debug
debug: $(TARGETDIRS.debug)
release: BUILD := release
release: $(TARGETDIRS.release)

build: $(TARGETDIRS)

.PHONY: build

$(MAINDIRS):
	go build $(BUILDOPTS) $(GCFLAGS) $(ASMFLAGS) $(LDFLAGS) -o $(BINDIR)/$(shell basename $@) $(MODULEPATH)/$@

.PHONY: $(MAINDIRS)

$(TARGETDIRS.debug) $(TARGETDIRS.release): $(GOFILES) go.mod go.sum
	go build $(BUILDOPTS) $(GCFLAGS) $(ASMFLAGS) $(LDFLAGS) -o $@ $(MODULEPATH)/$(LOOKUP.$(shell basename $@))

install:
	for dir in $(MAINDIRS); do                                                          \
		go install $(BUILDOPTS) $(GCFLAGS) $(ASMFLAGS) $(LDFLAGS) $(MODULEPATH)/$$dir;  \
	done

.PHONY: install

test:
	go test $(TESTOPTS) $(TESTGOPACKAGES)

.PHONY: test

get:
	go get $(GETOPTS) $(GOPACKAGES)

.PHONY: get

generate:
	go generate $(GENERATEOPTS) $(GOPACKAGES)

.PHONY: generate

lint:
	$(GOLINT) $(GOLINTOPTS) $(GOPACKAGES)

.PHONY: lint

vet:
	go vet $(VETOPTS) $(GOPACKAGES)

.PHONY: vet

imports:
	$(GOIMPORTS) $(GOIMPORTSOPTS) $(GOFILES) $(TESTGOFILES)

.PHONY: imports

fmt:
	$(GOFMT) $(GOFMTOPTS) $(GOFILES) $(TESTGOFILES)

.PHONY: fmt

clean:
	for dir in $(MAINDIRS); do                                                      \
		go clean $(CLEANOPTS) $(MODULEPATH)/$$dir;                                  \
		rm -f $(BINDIR)/$$(basename $$dir);                                         \
		for os in $(CROSSOS); do                                                    \
			for arch in $(CROSSARCH); do                                            \
				rm -f $(BINDIR)/$$(basename $$dir).$$os.$$arch;                     \
			done                                                                    \
		done                                                                        \
	done

.PHONY: clean

cross:
	for dir in $(MAINDIRS); do                                                      \
		for os in $(CROSSOS); do                                                    \
			for arch in $(CROSSARCH); do                                            \
				env GOOS=$$os GOARCH=$$arch go build $(BUILDOPTS) $(GCFLAGS) $(ASMFLAGS) $(LDFLAGS) -o $(BINDIR)/$$(basename $$dir).$$os.$$arch $(MODULEPATH)/$$dir;    \
			done                                                                    \
		done                                                                        \
	done

.PHONY: cross

list:
	echo '$(BOLDGREEN)Import path:$(NORMAL)'
	-for dir in $(GOSUBDIRS); do                                                    \
		go list $$dir/... 2> /dev/null | grep -v /vendor/;                          \
	done
	echo '$(BOLDGREEN)Import path --> Go files:$(NORMAL)'
	-for dir in $(GOSUBDIRS); do                                                    \
		go list -f '{{ range .GoFiles }}{{ $$.ImportPath }} --> {{ $$.Dir }}/{{ println . }}{{ end }}' $$dir/... 2> /dev/null | grep -v /vendor/;       \
		go list -f '{{ range .CgoFiles }}{{ $$.ImportPath }} --> {{ $$.Dir }}/{{ println . }}{{ end }}' $$dir/... 2> /dev/null | grep -v /vendor/;      \
	done
	echo '$(BOLDGREEN)Import path --> Go test files:$(NORMAL)'
	-for dir in $(GOSUBDIRS); do                                                    \
		go list -f '{{ range .TestGoFiles }}{{ $$.ImportPath }} --> {{ $$.Dir }}/{{ println . }}{{ end }}' $$dir/... 2> /dev/null | grep -v /vendor/;   \
		go list -f '{{ range .XTestGoFiles }}{{ $$.ImportPath }} --> {{ $$.Dir }}/{{ println . }}{{ end }}' $$dir/... 2> /dev/null | grep -v /vendor/;  \
	done
	echo '$(BOLDGREEN)Import path --> Dir --> Go files --> Go test files:$(NORMAL)'
	-for dir in $(GOSUBDIRS); do                                                    \
		go list -f '{{ .ImportPath }} --> {{ .Dir }} --> {{ .GoFiles }}{{ .CgoFiles }} --> {{ .TestGoFiles }}{{ .XTestGoFiles }}' $$dir/... 2> /dev/null | grep -v /vendor/;    \
	done
	echo '$(BOLDGREEN)Import path --> Dependencies:$(NORMAL)'
	-for dir in $(GOSUBDIRS); do                                                    \
		go list -f '{{ .ImportPath }} --> {{ .Imports }}' $$dir/... 2> /dev/null | grep -v /vendor/;    \
	done

.PHONY: list
