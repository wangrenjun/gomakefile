package binflag

import (
	"fmt"
	"io"
	"os"
	"strconv"
	"time"
)

var (
	Mode                  string
	GoVersion             string
	SysInfo               string
	LogName               string
	UserID                string
	Host                  string
	User                  string
	Email                 string
	Repo                  string
	Branch                string
	LatestTag             string
	LatestCommit          string
	LatestCommitTimeStamp string
	ModulePath            string
	GOOS                  string
	GOARCH                string
	GOHOSTOS              string
	GOHOSTARCH            string
	SemVer                string
	BuildTimeStamp        string
)

func printJustify(w io.Writer, just int, key, val string) {
	fmt.Fprintf(w, fmt.Sprintf("%%%ds: %%s\n", just), key, val)
}

func FPrettyPrint(w io.Writer, just int) {
	printJustify(w, just, "Mode", Mode)
	printJustify(w, just, "GoVersion", GoVersion)
	printJustify(w, just, "SysInfo", SysInfo)
	printJustify(w, just, "LogName", LogName)
	printJustify(w, just, "UserID", UserID)
	printJustify(w, just, "Host", Host)
	printJustify(w, just, "User", User)
	printJustify(w, just, "Email", Email)
	printJustify(w, just, "Repo", Repo)
	printJustify(w, just, "Branch", Branch)
	printJustify(w, just, "LatestTag", LatestTag)
	printJustify(w, just, "LatestCommit", LatestCommit)
	if ts, err := strconv.ParseInt(LatestCommitTimeStamp, 10, 64); err == nil {
		printJustify(w, just, "LatestCommitTime", time.Unix(ts, 0).Format(time.RFC3339))
	}
	printJustify(w, just, "ModulePath", ModulePath)
	printJustify(w, just, "GOOS", GOOS)
	printJustify(w, just, "GOARCH", GOARCH)
	printJustify(w, just, "GOHOSTOS", GOHOSTOS)
	printJustify(w, just, "GOHOSTARCH", GOHOSTARCH)
	printJustify(w, just, "SemVer", SemVer)
	if ts, err := strconv.ParseInt(BuildTimeStamp, 10, 64); err == nil {
		printJustify(w, just, "BuildTime", time.Unix(ts, 0).Format(time.RFC3339))
	}
}

func PrettyPrint(just int) {
	FPrettyPrint(os.Stdout, just)
}
