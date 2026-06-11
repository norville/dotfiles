// Main.qml — Tokyo Night Moon SDDM theme
// Qt Quick primitives only. No QtQuick.Controls.
// Dual-monitor: clock centered on left monitor, login form on DP-1.

import QtQuick 2.15
import SddmComponents 2.0

Repeater {
    model: screenModel

    Rectangle {
        id: root

        x:      geometry.x
        y:      geometry.y
        width:  geometry.width
        height: geometry.height

        readonly property bool isLeft: geometry.width === 1080 && geometry.height === 1920
        readonly property bool isMain: geometry.width === 2560 && geometry.height === 1440

        readonly property string bannerText: "ミナト・ドット・チキュウ・ドット・ラン"

        // Wallpaper
        Image {
            anchors.fill: parent
            source:       "background.jpg"
            fillMode:     Image.PreserveAspectCrop
            smooth:       true
            asynchronous: true
        }

        // Dark scrim
        Rectangle {
            anchors.fill: parent
            color:        "#1e2030"
            opacity:      0.60
        }

        // Login form — DP-1 only (2560x1440)
        Loader {
            anchors.centerIn: parent
            active:           root.isMain
            sourceComponent:  loginFormComponent
        }

        // Clock — centered on left monitor, bottom on main
        Column {
            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter:   root.isLeft ? parent.verticalCenter : undefined
                bottom:           root.isLeft ? undefined : parent.bottom
                bottomMargin:     root.isLeft ? 0 : 48
            }
            spacing: 6

            Text {
                id:    clockTime
                anchors.horizontalCenter: parent.horizontalCenter
                text:  Qt.formatTime(new Date(), "HH:mm")
                color: "#c8d3f5"
                font { family: "JetBrains Mono"; pixelSize: root.height * 0.044; weight: Font.Light }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:  Qt.formatDate(new Date(), "dddd, dd MMMM yyyy")
                color: "#828bb8"
                font { family: "JetBrains Mono"; pixelSize: root.height * 0.017 }
            }
            Timer {
                interval:    1000
                running:     true
                repeat:      true
                onTriggered: clockTime.text = Qt.formatTime(new Date(), "HH:mm")
            }
        }

        // ── Banner — horizontal, top, left monitor ────────────────
        // Text width  = monitor width - 2×margin = 1080 - 72 = 1008px
        // Banner height = fontSize + 2×margin
        // fontSize fills the text width: computed as a fraction of monitor width
        Item {
            visible: root.isLeft
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: bannerTextLeft.font.pixelSize + 72

            Rectangle { anchors.fill: parent; color: "#1e2030"; opacity: 0.55 }
            Rectangle { anchors.fill: parent; color: "#2f334d"; opacity: 0.18 }

            Text {
                id:               bannerTextLeft
                anchors.centerIn: parent
                width:            parent.width - 72      // 36px margin each side
                text:             root.bannerText
                color:            "#c8d3f5"
                font { family: "JetBrains Mono"; pixelSize: 72; weight: Font.Bold }
                horizontalAlignment: Text.AlignHCenter
                wrapMode:         Text.NoWrap
                minimumPixelSize: 10
                fontSizeMode:     Text.HorizontalFit
            }
        }

        // ── Banner — vertical, right side, main monitor ───────────
        // Anchored strip on the right edge. Text rotated 90° inside.
        // Strip is anchored (never outside parent bounds → no clipping).
        // Text width (pre-rotation) = parent.height - 2×margin.
        // After +90° rotation around TopLeft at (0, fontSize/2 + 36):
        //   text runs top-to-bottom, centered in the strip.
        Item {
            visible: root.isMain
            anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
            width: 72 + 72   // charFontSize + 2×margin

            Rectangle { anchors.fill: parent; color: "#1e2030"; opacity: 0.55 }
            Rectangle { anchors.fill: parent; color: "#2f334d"; opacity: 0.18 }

            // Characters laid out top-to-bottom in a Column,
            // each rotated -90° around its own center.
            Column {
                id:     bannerTextRight
                readonly property real charFontSize: 72
                readonly property real charSize: charFontSize

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top:              parent.top
                    topMargin:        36
                    bottom:           parent.bottom
                    bottomMargin:     36
                }
                width: charSize

                Repeater {
                    model: root.bannerText.split("")
                    Text {
                        width:           bannerTextRight.charSize
                        height:          bannerTextRight.charSize
                        text:            modelData
                        color:           "#c8d3f5"
                        font { family: "JetBrains Mono"
                               pixelSize: bannerTextRight.charFontSize
                               weight: Font.Bold }
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment:   Text.AlignVCenter
                        rotation:        0
                        transformOrigin: Item.Center
                    }
                }
            }
        }
    }

    // ── Login form ───────────────────────────────────────────────
    property Component loginFormComponent: Qt.createComponent("LoginFormComponent.qml")
}
