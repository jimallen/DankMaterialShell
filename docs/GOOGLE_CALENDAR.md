# Google Calendar Integration

DMS integrates with Google Calendar to display upcoming meetings in the bar and DankDash.

## Setup

### 1. Authenticate with Google

```bash
dms gcal auth
```

This opens a browser for Google OAuth authentication. Grant access to your calendar and copy the authorization code back to the terminal.

### 2. Verify Authentication

```bash
dms gcal status
```

Should show `"authenticated": true` with your email address.

### 3. Enable the MeetingWidget Plugin

1. Open Settings → Plugins
2. Click "Scan for Plugins"
3. Enable MeetingWidget
4. Add `MeetingWidget` to your DankBar widget list (Settings → Appearance → DankBar Layout)

## Features

### Bar Widget (MeetingWidget)

Shows your next meeting in the bar with:
- Meeting title (truncated if long)
- Time countdown ("in 45m", "in 2h 15m", "Now")
- Color-coded by meeting type

Click to open the Meetings tab in DankDash.

### Meetings Tab (DankDash)

Full meeting list with accordion view:

**Collapsed View:**
- Meeting title and countdown
- Time range (e.g., "9:00 AM – 10:00 AM")
- Attendee indicator ("1:1" or "5 attendees")
- Join button for next meeting

**Expanded View (click to toggle):**
- Date (e.g., "Mon, Dec 23")
- Duration (e.g., "1h 30m")
- Conflict warning (if overlapping meetings)
- Video meeting indicator
- Full attendee list
- Join button (for all meetings with video links)

### Calendar Overview Card

The calendar widget in the Overview tab shows event indicators on days with meetings.

## Color Coding

| Color | Meaning |
|-------|---------|
| Blue (#a6c8ff) | Regular meetings (2+ attendees) |
| Green (#c3e88d) | 1:1 meetings (1 attendee) |
| Red (#ffb4ab) | Conflicting meetings (overlapping times) |

## Event Filtering

DMS automatically filters events to show only relevant meetings:

- **Attendee filter**: Only shows meetings with at least one attendee (excludes focus time, personal events, etc.)
- **Response filter**: Only shows meetings you've accepted (excludes declined/tentative)

## CLI Commands

```bash
# Authentication
dms gcal auth           # Start OAuth flow
dms gcal status         # Check auth status
dms gcal logout         # Remove credentials

# Calendar data
dms gcal events                 # Get next 48 hours (default)
dms gcal events --hours 24      # Custom time range
dms gcal calendars              # List available calendars
```

## Configuration

### MeetingWidget Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `refreshMinutes` | 5 | Calendar refresh interval |
| `meetingColor` | #a6c8ff | Regular meeting color |
| `oneOnOneColor` | #c3e88d | 1:1 meeting color |
| `conflictColor` | #ffb4ab | Conflict color |

### GCalService

The QML service (`Services/GCalService.qml`) automatically:
- Refreshes events every 5 minutes
- Detects conflicts between overlapping meetings
- Provides events to all calendar-related components

## Troubleshooting

### "Calendar not configured"

Run `dms gcal auth` to authenticate with Google.

### No meetings showing

1. Check `dms gcal status` is authenticated
2. Verify you have meetings in the next 48 hours
3. Ensure meetings have attendees (solo events are filtered out)
4. Confirm you've accepted the meetings

### Wrong calendar

By default, DMS uses your primary calendar. To use a different calendar:

```bash
dms gcal calendars              # List calendar IDs
dms gcal events --calendars ID  # Test specific calendar
```

### Refresh not working

The MeetingWidget refreshes every 5 minutes by default. To force a refresh, restart quickshell:

```bash
dms restart
```

## Privacy

- Credentials are stored locally in `~/.config/dms/gcal/`
- Only calendar event data is fetched (titles, times, attendees)
- No data is sent to any server other than Google's API
- Use `dms gcal logout` to remove all stored credentials
