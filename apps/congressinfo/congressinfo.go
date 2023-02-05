// Package congressinfo provides details for the Congress Info applet.
package congressinfo

import (
	_ "embed"

	"tidbyt.dev/community/apps/manifest"
)

//go:embed congress_info.star
var source []byte

// New creates a new instance of the Congress Info applet.
func New() manifest.Manifest {
	return manifest.Manifest{
		ID:          "congress-info",
		Name:        "Congress Info",
		Author:      "Anders Heie",
		Summary:     "Show Congress Information",
		Desc:        "This app will show the latest information from congress using congress.gov. This includes new bills, actions on bills, etc.",
		FileName:    "congress_info.star",
		PackageName: "congressinfo",
		Source:  source,
	}
}
