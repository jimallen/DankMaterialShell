import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

Item {
    id: root

    implicitHeight: Math.max(410, contentColumn.implicitHeight)

    readonly property color meetingColor: "#a6c8ff"
    readonly property color oneOnOneColor: "#c3e88d"
    readonly property color conflictColor: "#ffb4ab"

    property int expandedIndex: -1

    readonly property var nextMeeting: {
        if (!GCalService.available || !GCalService.events) return null
        let now = new Date()
        for (let e of GCalService.events) {
            let end = new Date(e.end)
            if (end > now) return e
        }
        return null
    }

    function getEventColor(event) {
        if (!event) return meetingColor
        if (event.hasConflict) return conflictColor
        if (event.attendeeCount === 1) return oneOnOneColor
        return meetingColor
    }

    function formatTime(isoTime) {
        let d = new Date(isoTime)
        return Qt.formatTime(d, SettingsData.use24HourClock ? "HH:mm" : "h:mm AP")
    }

    function formatDate(isoTime) {
        let d = new Date(isoTime)
        return Qt.formatDate(d, "ddd, MMM d")
    }

    function getTimeUntil(startTime) {
        let start = new Date(startTime)
        let now = new Date()
        let diff = start - now

        if (diff < 0) return "now"

        let hours = Math.floor(diff / (1000 * 60 * 60))
        let minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60))

        if (hours > 0) return hours + "h " + minutes + "m"
        return minutes + "m"
    }

    function getDuration(startTime, endTime) {
        let start = new Date(startTime)
        let end = new Date(endTime)
        let diff = end - start
        let minutes = Math.floor(diff / (1000 * 60))
        if (minutes >= 60) {
            let hours = Math.floor(minutes / 60)
            let mins = minutes % 60
            return mins > 0 ? hours + "h " + mins + "m" : hours + "h"
        }
        return minutes + "m"
    }

    function isEventPast(event) {
        if (!event || !event.end) return false
        return new Date(event.end) < new Date()
    }

    function isNextMeeting(event) {
        return nextMeeting && event && nextMeeting.id === event.id
    }

    Column {
        id: contentColumn
        anchors.fill: parent
        spacing: Theme.spacingM

        Row {
            width: parent.width
            spacing: Theme.spacingM

            Column {
                width: parent.width
                spacing: Theme.spacingXS

                StyledText {
                    text: I18n.tr("Meetings")
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Bold
                    color: Theme.surfaceText
                }

                StyledText {
                    text: GCalService.available ?
                        (GCalService.events.length + " " + I18n.tr("meetings in next 48h")) :
                        I18n.tr("Calendar not configured")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
            }
        }

        Rectangle {
            width: parent.width
            height: Math.max(320, meetingsList.contentHeight + Theme.spacingS * 2)
            radius: Theme.cornerRadius
            color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
            clip: true

            DankListView {
                id: meetingsList
                anchors.fill: parent
                anchors.margins: Theme.spacingS
                model: GCalService.available ? GCalService.events : []
                spacing: Theme.spacingXS

                delegate: Rectangle {
                    id: meetingDelegate

                    required property var modelData
                    required property int index

                    readonly property bool isPast: root.isEventPast(modelData)
                    readonly property bool isNext: root.isNextMeeting(modelData)
                    readonly property bool isExpanded: root.expandedIndex === index

                    width: meetingsList.width
                    height: delegateContent.implicitHeight + Theme.spacingS * 2
                    radius: Theme.cornerRadius
                    opacity: isPast ? 0.5 : 1.0
                    color: isNext ?
                        Qt.rgba(root.getEventColor(modelData).r, root.getEventColor(modelData).g, root.getEventColor(modelData).b, 0.15) :
                        Theme.withAlpha(Theme.surfaceContainer, 0.5)
                    border.color: isNext ? root.getEventColor(modelData) : "transparent"
                    border.width: isNext ? 1 : 0

                    Behavior on height {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }

                    Rectangle {
                        width: 4
                        height: parent.height - Theme.spacingS
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingXS
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 2
                        color: isPast ? Theme.surfaceVariantText : root.getEventColor(modelData)
                    }

                    Column {
                        id: delegateContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.leftMargin: Theme.spacingS + 8
                        anchors.rightMargin: Theme.spacingS
                        anchors.topMargin: Theme.spacingS
                        spacing: Theme.spacingS

                        Row {
                            width: parent.width
                            spacing: Theme.spacingS

                            Column {
                                width: parent.width - rightControls.width - Theme.spacingS
                                spacing: 2

                                StyledText {
                                    text: modelData.title || "Untitled"
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Font.Medium
                                    color: isPast ? Theme.surfaceVariantText : Theme.surfaceText
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Row {
                                    spacing: Theme.spacingS

                                    StyledText {
                                        text: root.formatTime(modelData.start) + " – " + root.formatTime(modelData.end)
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceVariantText
                                    }

                                    StyledText {
                                        visible: modelData.attendeeCount > 0
                                        text: "•"
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceVariantText
                                    }

                                    StyledText {
                                        visible: modelData.attendeeCount > 0
                                        text: modelData.attendeeCount === 1 ?
                                            I18n.tr("1:1") :
                                            (modelData.attendeeCount + " " + I18n.tr("attendees"))
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: modelData.attendeeCount === 1 ? root.oneOnOneColor : Theme.surfaceVariantText
                                    }
                                }
                            }

                            Row {
                                id: rightControls
                                spacing: Theme.spacingS
                                anchors.verticalCenter: parent.verticalCenter

                                StyledText {
                                    id: timeUntilText
                                    text: {
                                        if (isPast) return I18n.tr("ended")
                                        let timeUntil = root.getTimeUntil(modelData.start)
                                        return timeUntil === "now" ? I18n.tr("Now") : ("in " + timeUntil)
                                    }
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: isNext ? root.getEventColor(modelData) : Theme.surfaceVariantText
                                    font.weight: isNext ? Font.Medium : Font.Normal
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Rectangle {
                                    id: joinButton
                                    visible: isNext && modelData.meetingUrl && modelData.meetingUrl !== ""
                                    width: visible ? 70 : 0
                                    height: 32
                                    radius: Theme.cornerRadius
                                    color: joinArea.containsMouse ?
                                        Qt.lighter(root.getEventColor(modelData), 1.2) :
                                        root.getEventColor(modelData)

                                    StyledText {
                                        anchors.centerIn: parent
                                        text: I18n.tr("Join")
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: Font.Medium
                                        color: Theme.surfaceContainerLowest
                                    }

                                    MouseArea {
                                        id: joinArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: function(mouse) {
                                            mouse.accepted = true
                                            Qt.openUrlExternally(modelData.meetingUrl)
                                        }
                                    }
                                }

                                DankIcon {
                                    id: expandIcon
                                    name: isExpanded ? "expand_less" : "expand_more"
                                    size: 20
                                    color: Theme.surfaceVariantText
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }

                        Column {
                            id: expandedContent
                            width: parent.width
                            spacing: Theme.spacingS
                            visible: isExpanded
                            opacity: isExpanded ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation { duration: 150 }
                            }

                            Rectangle {
                                width: parent.width
                                height: 1
                                color: Theme.outlineVariant
                                opacity: 0.3
                            }

                            Row {
                                spacing: Theme.spacingM
                                width: parent.width

                                Column {
                                    spacing: Theme.spacingXS
                                    width: (parent.width - Theme.spacingM) / 2

                                    Row {
                                        spacing: Theme.spacingXS

                                        DankIcon {
                                            name: "schedule"
                                            size: 16
                                            color: Theme.surfaceVariantText
                                        }

                                        StyledText {
                                            text: root.formatDate(modelData.start)
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: Theme.surfaceVariantText
                                        }
                                    }

                                    Row {
                                        spacing: Theme.spacingXS

                                        DankIcon {
                                            name: "timelapse"
                                            size: 16
                                            color: Theme.surfaceVariantText
                                        }

                                        StyledText {
                                            text: root.getDuration(modelData.start, modelData.end)
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: Theme.surfaceVariantText
                                        }
                                    }
                                }

                                Column {
                                    spacing: Theme.spacingXS
                                    width: (parent.width - Theme.spacingM) / 2

                                    Row {
                                        spacing: Theme.spacingXS
                                        visible: modelData.hasConflict

                                        DankIcon {
                                            name: "warning"
                                            size: 16
                                            color: root.conflictColor
                                        }

                                        StyledText {
                                            text: I18n.tr("Has conflict")
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: root.conflictColor
                                        }
                                    }

                                    Row {
                                        spacing: Theme.spacingXS
                                        visible: modelData.meetingUrl && modelData.meetingUrl !== ""

                                        DankIcon {
                                            name: "videocam"
                                            size: 16
                                            color: Theme.surfaceVariantText
                                        }

                                        StyledText {
                                            text: I18n.tr("Video meeting")
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: Theme.surfaceVariantText
                                        }
                                    }
                                }
                            }

                            Column {
                                width: parent.width
                                spacing: Theme.spacingXS
                                visible: modelData.attendees && modelData.attendees.length > 0

                                Row {
                                    spacing: Theme.spacingXS

                                    DankIcon {
                                        name: "group"
                                        size: 16
                                        color: Theme.surfaceVariantText
                                    }

                                    StyledText {
                                        text: I18n.tr("Attendees")
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: Font.Medium
                                        color: Theme.surfaceVariantText
                                    }
                                }

                                StyledText {
                                    width: parent.width
                                    text: modelData.attendees ? modelData.attendees.join(", ") : ""
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceText
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                }
                            }

                            Rectangle {
                                id: joinButtonExpanded
                                visible: !isNext && modelData.meetingUrl && modelData.meetingUrl !== ""
                                width: 100
                                height: 36
                                radius: Theme.cornerRadius
                                color: joinAreaExpanded.containsMouse ?
                                    Qt.lighter(root.getEventColor(modelData), 1.2) :
                                    root.getEventColor(modelData)

                                Row {
                                    anchors.centerIn: parent
                                    spacing: Theme.spacingXS

                                    DankIcon {
                                        name: "videocam"
                                        size: 16
                                        color: Theme.surfaceContainerLowest
                                    }

                                    StyledText {
                                        text: I18n.tr("Join")
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: Font.Medium
                                        color: Theme.surfaceContainerLowest
                                    }
                                }

                                MouseArea {
                                    id: joinAreaExpanded
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: function(mouse) {
                                        mouse.accepted = true
                                        Qt.openUrlExternally(modelData.meetingUrl)
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        z: -1
                        onClicked: {
                            if (root.expandedIndex === index) {
                                root.expandedIndex = -1
                            } else {
                                root.expandedIndex = index
                            }
                        }
                    }
                }

                StyledText {
                    visible: !GCalService.available
                    anchors.centerIn: parent
                    text: I18n.tr("Google Calendar not configured")
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceVariantText
                }

                StyledText {
                    visible: GCalService.available && GCalService.events.length === 0
                    anchors.centerIn: parent
                    text: I18n.tr("No upcoming meetings")
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceVariantText
                }
            }
        }
    }
}
