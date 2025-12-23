package main

import (
	"context"
	"encoding/json"
	"os"
	"strings"

	"github.com/AvengeMedia/DankMaterialShell/core/internal/gcal"
	"github.com/spf13/cobra"
)

var gcalCmd = &cobra.Command{
	Use:   "gcal",
	Short: "Google Calendar integration",
	Long:  "Manage Google Calendar authorization and fetch calendar events",
}

var gcalAuthCmd = &cobra.Command{
	Use:   "auth",
	Short: "Authorize with Google Calendar",
	Long:  "Open browser to authorize access to Google Calendar. Run once to set up.",
	Run:   runGcalAuth,
}

var gcalStatusCmd = &cobra.Command{
	Use:   "status",
	Short: "Check authorization status",
	Long:  "Check if Google Calendar is configured and authorized",
	Run:   runGcalStatus,
}

var gcalEventsCmd = &cobra.Command{
	Use:   "events",
	Short: "Get calendar events",
	Long:  "Fetch today's calendar events or upcoming events within specified hours",
	Run:   runGcalEvents,
}

var gcalCalendarsCmd = &cobra.Command{
	Use:   "calendars",
	Short: "List available calendars",
	Long:  "List all calendars you have access to",
	Run:   runGcalCalendars,
}

var gcalLogoutCmd = &cobra.Command{
	Use:   "logout",
	Short: "Remove authorization",
	Long:  "Remove saved OAuth token (you'll need to re-authorize)",
	Run:   runGcalLogout,
}

var (
	gcalEventsHours     int
	gcalEventsCalendars string
)

func init() {
	gcalEventsCmd.Flags().IntVarP(&gcalEventsHours, "hours", "H", 48, "Fetch events within next N hours (default: 48)")
	gcalEventsCmd.Flags().StringVar(&gcalEventsCalendars, "calendars", "", "Comma-separated calendar IDs (default: primary)")

	gcalCmd.AddCommand(gcalAuthCmd, gcalStatusCmd, gcalEventsCmd, gcalCalendarsCmd, gcalLogoutCmd)
}

func runGcalAuth(cmd *cobra.Command, args []string) {
	creds, err := gcal.LoadCredentials()
	if err != nil {
		outputJSON(gcal.NewErrorResponse(gcal.ErrNotConfigured, err.Error()))
		os.Exit(1)
	}

	if err := gcal.RunAuthFlow(creds); err != nil {
		outputJSON(gcal.NewErrorResponse(gcal.ErrAPIError, err.Error()))
		os.Exit(1)
	}
}

func runGcalStatus(cmd *cobra.Command, args []string) {
	type StatusResponse struct {
		Success      bool   `json:"success"`
		Configured   bool   `json:"configured"`
		Authorized   bool   `json:"authorized"`
		Message      string `json:"message,omitempty"`
		Error        string `json:"error,omitempty"`
		CredPath     string `json:"credentialsPath,omitempty"`
		TokenPath    string `json:"tokenPath,omitempty"`
	}

	resp := StatusResponse{Success: true}

	// Check credentials
	creds, credErr := gcal.LoadCredentials()
	resp.Configured = credErr == nil && creds != nil

	// Check token
	token, tokenErr := gcal.LoadToken()
	resp.Authorized = tokenErr == nil && token != nil

	if resp.Configured && resp.Authorized {
		resp.Message = "Google Calendar is configured and authorized"
	} else if resp.Configured && !resp.Authorized {
		resp.Message = "Credentials found but not authorized - run 'dms gcal auth'"
	} else {
		resp.Message = "Not configured - add credentials to gcal-credentials.json"
		if credErr != nil {
			resp.Error = credErr.Error()
		}
	}

	outputJSON(resp)
}

func runGcalEvents(cmd *cobra.Command, args []string) {
	ctx := context.Background()

	var calendarIDs []string
	if gcalEventsCalendars != "" {
		calendarIDs = strings.Split(gcalEventsCalendars, ",")
		for i := range calendarIDs {
			calendarIDs[i] = strings.TrimSpace(calendarIDs[i])
		}
	}

	var resp gcal.Response
	if gcalEventsHours > 0 {
		resp = gcal.FetchUpcomingEvents(ctx, calendarIDs, gcalEventsHours)
	} else {
		resp = gcal.FetchTodayEvents(ctx, calendarIDs)
	}

	outputJSON(resp)
	if !resp.Success {
		os.Exit(1)
	}
}

func runGcalCalendars(cmd *cobra.Command, args []string) {
	ctx := context.Background()
	resp := gcal.ListCalendars(ctx)
	outputJSON(resp)
	if !resp.Success {
		os.Exit(1)
	}
}

func runGcalLogout(cmd *cobra.Command, args []string) {
	dataHome := os.Getenv("XDG_DATA_HOME")
	if dataHome == "" {
		home, err := os.UserHomeDir()
		if err != nil {
			outputJSON(gcal.NewErrorResponse(gcal.ErrAPIError, "cannot find home directory"))
			os.Exit(1)
		}
		dataHome = home + "/.local/share"
	}

	tokenPath := dataHome + "/DankMaterialShell/gcal-tokens.json"

	if _, err := os.Stat(tokenPath); os.IsNotExist(err) {
		outputJSON(map[string]any{
			"success": true,
			"message": "No token found - already logged out",
		})
		return
	}

	if err := os.Remove(tokenPath); err != nil {
		outputJSON(gcal.NewErrorResponse(gcal.ErrAPIError, "failed to remove token: "+err.Error()))
		os.Exit(1)
	}

	outputJSON(map[string]any{
		"success": true,
		"message": "Token removed - you are now logged out",
	})
}

func outputJSON(v any) {
	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", "  ")
	enc.Encode(v)
}
