pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool available: false
    property bool loading: false
    property var events: []
    property string lastError: ""

    function refresh() {
        if (eventsProcess.running) return
        loading = true
        eventsProcess.running = true
    }

    function checkStatus() {
        if (statusProcess.running) return
        statusProcess.running = true
    }

    function getEventsForDate(date) {
        if (!events || events.length === 0) return []

        const dateStr = Qt.formatDate(date, "yyyy-MM-dd")
        return events.filter(e => {
            const eventDate = e.start.substring(0, 10)
            return eventDate === dateStr
        }).map(e => ({
            id: e.id,
            title: e.title,
            start: new Date(e.start),
            end: new Date(e.end),
            url: e.meetingUrl || "",
            location: "",
            description: "",
            allDay: false,
            hasConflict: e.hasConflict,
            attendeeCount: e.attendeeCount
        }))
    }

    function hasEventsForDate(date) {
        return getEventsForDate(date).length > 0
    }

    function getTodayEvents() {
        return getEventsForDate(new Date())
    }

    Component.onCompleted: {
        console.log("GCalService: initializing...")
        checkStatus()
    }

    Timer {
        interval: 5 * 60 * 1000
        running: root.available
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: statusProcess
        command: ["dms", "gcal", "status"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                console.log("GCalService: status response:", text)
                try {
                    let result = JSON.parse(text)
                    root.available = result.configured && result.authorized
                    console.log("GCalService: available =", root.available)
                    if (root.available) {
                        root.refresh()
                    }
                } catch (e) {
                    console.log("GCalService: status parse error:", e)
                    root.available = false
                }
            }
        }
    }

    Process {
        id: eventsProcess
        command: ["dms", "gcal", "events"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false
                console.log("GCalService: events response length:", text.length)
                try {
                    let result = JSON.parse(text)
                    if (result.success) {
                        root.events = result.events || []
                        console.log("GCalService: loaded", root.events.length, "events")
                        root.lastError = ""
                    } else {
                        root.lastError = result.message || result.error
                        console.log("GCalService: error:", root.lastError)
                    }
                } catch (e) {
                    root.lastError = "Failed to parse events"
                    console.log("GCalService: parse error:", e)
                }
            }
        }
    }
}
