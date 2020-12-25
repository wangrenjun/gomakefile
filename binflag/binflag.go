package binflag

import (
	"fmt"
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

func printJustify(just int, key, val string) {
	fmt.Printf(fmt.Sprintf("%%%ds: %%s\n", just), key, val)
}

func PrettyPrint(just int) {
	printJustify(just, "Mode", Mode)
	printJustify(just, "GoVersion", GoVersion)
	printJustify(just, "SysInfo", SysInfo)
	printJustify(just, "LogName", LogName)
	printJustify(just, "UserID", UserID)
	printJustify(just, "Host", Host)
	printJustify(just, "User", User)
	printJustify(just, "Email", Email)
	printJustify(just, "Repo", Repo)
	printJustify(just, "Branch", Branch)
	printJustify(just, "LatestTag", LatestTag)
	printJustify(just, "LatestCommit", LatestCommit)
	if ts, err := strconv.ParseInt(LatestCommitTimeStamp, 10, 64); err == nil {
		printJustify(just, "LatestCommitTime", time.Unix(ts, 0).Format(time.RFC3339))
	}
	printJustify(just, "ModulePath", ModulePath)
	printJustify(just, "GOOS", GOOS)
	printJustify(just, "GOARCH", GOARCH)
	printJustify(just, "GOHOSTOS", GOHOSTOS)
	printJustify(just, "GOHOSTARCH", GOHOSTARCH)
	printJustify(just, "SemVer", SemVer)
	if ts, err := strconv.ParseInt(BuildTimeStamp, 10, 64); err == nil {
		printJustify(just, "BuildTime", time.Unix(ts, 0).Format(time.RFC3339))
	}
}
