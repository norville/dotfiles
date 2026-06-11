// LoginFormComponent.qml — Tokyo Night Moon SDDM theme
import QtQuick 2.15
import SddmComponents 2.0

Item {
    id:     form
    width:  380
    height: col.height + 64

    // Tab order: 0=user 1=pass 2=session 3=loginBtn
    property int focusedField: 0
    readonly property int tabCount: 6

    function nextTab() {
        focusedField = (focusedField + 1) % tabCount
        applyFocus()
    }
    function prevTab() {
        focusedField = (focusedField - 1 + tabCount) % tabCount
        applyFocus()
    }
    function applyFocus() {
        if      (focusedField === 0) userInput.forceActiveFocus()
        else if (focusedField === 1) passInput.forceActiveFocus()
        else if (focusedField === 2) sessionBox.forceActiveFocus()
        else if (focusedField === 3) loginBtnFocus.forceActiveFocus()
        else if (focusedField === 4) rebootBtn.forceActiveFocus()
        else if (focusedField === 5) poweroffBtn.forceActiveFocus()
    }

    // ── Panel ─────────────────────────────────────────────────
    // Frosted glass: semi-transparent base + lighter overlay
    Rectangle {
        anchors.fill: parent
        color:        "#1c1e2e"
        radius:       14
        opacity:      0.85
    }
    Rectangle {
        anchors.fill: parent
        color:        "#2f334d"
        radius:       14
        opacity:      0.18
    }
    Rectangle {
        anchors.fill: parent
        color:        "transparent"
        border.color: "#444a73"
        border.width: 1
        radius:       14
    }

    Column {
        id:      col
        anchors {
            top:         parent.top
            left:        parent.left
            right:       parent.right
            topMargin:   36
            leftMargin:  36
            rightMargin: 36
        }
        spacing: 14

        // ── Hostname ──────────────────────────────────────────
        Text {
            width:               parent.width
            horizontalAlignment: Text.AlignHCenter
            text:                sddm.hostName
            color:               "#82aaff"
            font { family: "JetBrains Mono"; pixelSize: 18; weight: Font.Bold }
        }

        // Divider
        Rectangle {
            width:  parent.width
            height: 1
            color:  "#444a73"
        }

        // ── Username ──────────────────────────────────────────
        Column {
            width:   parent.width
            spacing: 4

            Text {
                text:  "username"
                color: form.focusedField === 0 ? "#82aaff" : "#636da6"
                font { family: "JetBrains Mono"; pixelSize: 11 }
                Behavior on color { ColorAnimation { duration: 100 } }
            }

            Rectangle {
                width:        parent.width
                height:       44
                color:        "#2a2d45"
                border.color: form.focusedField === 0 ? "#82aaff" : "#444a73"
                border.width: form.focusedField === 0 ? 2 : 1
                radius:       7
                Behavior on border.color { ColorAnimation { duration: 100 } }

                TextInput {
                    id:              userInput
                    anchors {
                        left:           parent.left
                        right:          parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin:     14
                        rightMargin:    14
                    }
                    color:             "#c8d3f5"
                    font { family: "JetBrains Mono"; pixelSize: 15 }
                    clip:              true
                    activeFocusOnTab:  false
                    cursorVisible:     form.focusedField === 0
                    onActiveFocusChanged: if (activeFocus) form.focusedField = 0
                    Keys.onTabPressed:    form.nextTab()
                    Keys.onBacktabPressed: form.prevTab()
                    Keys.onReturnPressed: { form.focusedField = 1; passInput.forceActiveFocus() }
                }
            }
        }

        // ── Password ──────────────────────────────────────────
        Column {
            width:   parent.width
            spacing: 4

            Text {
                text:  "password"
                color: form.focusedField === 1 ? "#82aaff" : "#636da6"
                font { family: "JetBrains Mono"; pixelSize: 11 }
                Behavior on color { ColorAnimation { duration: 100 } }
            }

            Rectangle {
                width:        parent.width
                height:       44
                color:        "#2a2d45"
                border.color: form.focusedField === 1 ? "#82aaff" : "#444a73"
                border.width: form.focusedField === 1 ? 2 : 1
                radius:       7
                Behavior on border.color { ColorAnimation { duration: 100 } }

                TextInput {
                    id:              passInput
                    anchors {
                        left:           parent.left
                        right:          parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin:     14
                        rightMargin:    14
                    }
                    color:             "#c8d3f5"
                    font { family: "JetBrains Mono"; pixelSize: 15 }
                    echoMode:          TextInput.Password
                    passwordCharacter: "•"
                    clip:              true
                    activeFocusOnTab:  false
                    cursorVisible:     form.focusedField === 1
                    onActiveFocusChanged: if (activeFocus) form.focusedField = 1
                    Keys.onTabPressed:    form.nextTab()
                    Keys.onBacktabPressed: form.prevTab()
                    Keys.onReturnPressed: doLogin()
                }
            }
        }

        // ── Session selector ──────────────────────────────────
        Column {
            width:   parent.width
            spacing: 4

            Text {
                text:  "session"
                color: form.focusedField === 2 ? "#82aaff" : "#636da6"
                font { family: "JetBrains Mono"; pixelSize: 11 }
                Behavior on color { ColorAnimation { duration: 100 } }
            }

        Rectangle {
            id:           sessionBox
            width:        parent.width
            height:       36
            color:        "#232538"
            border.color: form.focusedField === 2 ? "#82aaff"
                              : sessionMouse.containsMouse ? "#6270a0" : "#444a73"
            border.width: form.focusedField === 2 ? 2 : 1
            radius:       7
            focus:        false
            Behavior on border.color { ColorAnimation { duration: 100 } }

            property int sessionIndex: sessionModel.lastIndex

            Keys.onTabPressed:     form.nextTab()
            Keys.onBacktabPressed: form.prevTab()
            Keys.onReturnPressed:  sessionIndex = (sessionIndex + 1) % sessionModel.rowCount()
            Keys.onSpacePressed:   sessionIndex = (sessionIndex + 1) % sessionModel.rowCount()
            onActiveFocusChanged:  if (activeFocus) form.focusedField = 2

            Text {
                anchors {
                    left:           parent.left
                    right:          chevron.left
                    verticalCenter: parent.verticalCenter
                    leftMargin:     14
                    rightMargin:    8
                }
                text:  sessionModel.data(sessionModel.index(parent.sessionIndex, 0), Qt.UserRole + 4) || "niri"
                color: "#828bb8"
                font { family: "JetBrains Mono"; pixelSize: 12 }
                elide: Text.ElideRight
            }
            Text {
                id:    chevron
                anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 12 }
                text:  "▾"
                color: "#636da6"
                font { family: "JetBrains Mono"; pixelSize: 11 }
            }
            MouseArea {
                id:           sessionMouse
                anchors.fill: parent
                hoverEnabled: true
                onEntered:    parent.forceActiveFocus()
                onClicked: {
                    parent.forceActiveFocus()
                    parent.sessionIndex = (parent.sessionIndex + 1) % sessionModel.rowCount()
                }
            }
        }
        } // end session Column

        // ── Error message ─────────────────────────────────────
        Rectangle {
            width:  parent.width
            height: 36
            color:        errorMsg.text !== "" ? "#2a1520" : "transparent"
            border.color: errorMsg.text !== "" ? "#ff757f" : "transparent"
            border.width: errorMsg.text !== "" ? 1 : 0
            radius: 7
            Behavior on color        { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Text {
                id:                  errorMsg
                anchors.centerIn:    parent
                width:               parent.width - 24
                horizontalAlignment: Text.AlignHCenter
                text:                ""
                color:               "#ff757f"
                font { family: "JetBrains Mono"; pixelSize: 12 }
                wrapMode:            Text.WordWrap
            }
        }

        // ── Login button ──────────────────────────────────────
        Rectangle {
            id:     loginBtn
            width:  parent.width
            height: 44
            color:  loginMouse.pressed || form.focusedField === 3
                        ? "#5d7ddf"
                        : loginMouse.containsMouse ? "#7090e8" : "#82aaff"
            radius: 7
            Behavior on color { ColorAnimation { duration: 120 } }

            // Invisible FocusScope to receive keyboard focus
            Item {
                id:    loginBtnFocus
                anchors.fill: parent
                focus: false
                onActiveFocusChanged: if (activeFocus) form.focusedField = 3
                Keys.onTabPressed:     form.nextTab()
                Keys.onBacktabPressed: form.prevTab()
                Keys.onReturnPressed:  doLogin()
                Keys.onSpacePressed:   doLogin()
            }

            Text {
                anchors.centerIn: parent
                text:  "login"
                color: "#1e2030"
                font { family: "JetBrains Mono"; pixelSize: 14; weight: Font.Medium }
            }
            MouseArea {
                id:           loginMouse
                anchors.fill: parent
                hoverEnabled: true
                onEntered:    loginBtnFocus.forceActiveFocus()
                onClicked: {
                    loginBtnFocus.forceActiveFocus()
                    doLogin()
                }
            }
        }

        // ── Power row ─────────────────────────────────────────
        Row {
            width:   parent.width
            spacing: 20

            Rectangle {
                id:     rebootBtn
                readonly property bool active: form.focusedField === 4 || rebootMouse.containsMouse
                width:  (parent.width - 20) / 2
                height: 30
                color:        active ? "#ffc777" : "transparent"
                border.color: active ? "transparent" : "#ffc777"
                border.width: 1
                radius:       5
                Behavior on color        { ColorAnimation { duration: 100 } }
                Behavior on border.color { ColorAnimation { duration: 100 } }
                onActiveFocusChanged: if (activeFocus) form.focusedField = 4
                Keys.onTabPressed:     form.nextTab()
                Keys.onBacktabPressed: form.prevTab()
                Keys.onReturnPressed:  confirmOverlay.open("reboot")
                Keys.onSpacePressed:   confirmOverlay.open("reboot")
                Text {
                    anchors.centerIn: parent
                    text:  "reboot"
                    color: rebootBtn.active ? "#1e2030" : "#ffc777"
                    font { family: "JetBrains Mono"; pixelSize: 12
                           weight: rebootBtn.active ? Font.Bold : Font.Normal }
                    Behavior on color { ColorAnimation { duration: 100 } }
                }
                MouseArea {
                    id:           rebootMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered:    rebootBtn.forceActiveFocus()
                    onClicked: { rebootBtn.forceActiveFocus(); confirmOverlay.open("reboot") }
                }
            }

            Rectangle {
                id:     poweroffBtn
                readonly property bool active: form.focusedField === 5 || poweroffMouse.containsMouse
                width:  (parent.width - 20) / 2
                height: 30
                color:        active ? "#ff757f" : "transparent"
                border.color: active ? "transparent" : "#ff757f"
                border.width: 1
                radius:       5
                Behavior on color        { ColorAnimation { duration: 100 } }
                Behavior on border.color { ColorAnimation { duration: 100 } }
                onActiveFocusChanged: if (activeFocus) form.focusedField = 5
                Keys.onTabPressed:     form.nextTab()
                Keys.onBacktabPressed: form.prevTab()
                Keys.onReturnPressed:  confirmOverlay.open("poweroff")
                Keys.onSpacePressed:   confirmOverlay.open("poweroff")
                Text {
                    anchors.centerIn: parent
                    text:  "poweroff"
                    color: poweroffBtn.active ? "#1e2030" : "#ff757f"
                    font { family: "JetBrains Mono"; pixelSize: 12
                           weight: poweroffBtn.active ? Font.Bold : Font.Normal }
                    Behavior on color { ColorAnimation { duration: 100 } }
                }
                MouseArea {
                    id:           poweroffMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered:    poweroffBtn.forceActiveFocus()
                    onClicked: { poweroffBtn.forceActiveFocus(); confirmOverlay.open("poweroff") }
                }
            }
        }

        Item { height: 4 }
    }

    // ── Confirm dialog ───────────────────────────────────────
    // FocusScope keeps keyboard focus inside the overlay while it's open.
    FocusScope {
        id:      confirmOverlay
        anchors.fill: parent
        opacity: 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 140 } }

        property string action: ""
        // Which button is focused: 0 = cancel (default), 1 = yes
        property int    dlgFocus: 0

        function open(act) {
            action   = act
            opacity  = 1.0
            dlgFocus = 0
            confirmNo.forceActiveFocus()
        }
        function close() {
            opacity = 0.0
            applyFocus()
        }
        function confirm() {
            var act = action
            close()
            if (act === "reboot") sddm.reboot()
            else sddm.powerOff()
        }

        Rectangle {
            anchors.fill: parent
            color:  "#1e2030"
            radius: 14
        }

        Column {
            anchors.centerIn: parent
            spacing:          20

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:  confirmOverlay.action === "reboot" ? "reboot system?" : "power off system?"
                color: "#c8d3f5"
                font { family: "JetBrains Mono"; pixelSize: 15; weight: Font.Medium }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16

                // ── Yes button ────────────────────────────────
                Rectangle {
                    id:     confirmYes
                    width:  100
                    height: 34
                    readonly property bool active: confirmOverlay.dlgFocus === 1
                    color:        active || yesMouse.pressed ? "#ff757f" : "transparent"
                    border.color: active || yesMouse.pressed ? "transparent" : "#ff757f"
                    border.width: 1
                    radius: 7
                    focus: false
                    Behavior on color        { ColorAnimation { duration: 100 } }
                    Behavior on border.color { ColorAnimation { duration: 100 } }
                    Keys.onReturnPressed:  confirmOverlay.confirm()
                    Keys.onSpacePressed:   confirmOverlay.confirm()
                    Keys.onEscapePressed:  confirmOverlay.close()
                    Keys.onTabPressed:     { confirmOverlay.dlgFocus = 0; confirmNo.forceActiveFocus() }
                    Keys.onBacktabPressed: { confirmOverlay.dlgFocus = 0; confirmNo.forceActiveFocus() }
                    onActiveFocusChanged:  if (activeFocus) confirmOverlay.dlgFocus = 1
                    Text {
                        anchors.centerIn: parent
                        text:  "yes"
                        color: confirmYes.active || yesMouse.pressed ? "#1e2030" : "#ff757f"
                        font { family: "JetBrains Mono"; pixelSize: 13
                               weight: confirmYes.active || yesMouse.pressed ? Font.Bold : Font.Normal }
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                    MouseArea {
                        id:           yesMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered:    { confirmOverlay.dlgFocus = 1; confirmYes.forceActiveFocus() }
                        onExited:     { if (confirmOverlay.dlgFocus === 1) confirmYes.forceActiveFocus() }
                        onClicked:    confirmOverlay.confirm()
                    }
                }

                // ── Cancel button ─────────────────────────────
                Rectangle {
                    id:     confirmNo
                    width:  100
                    height: 34
                    readonly property bool active: confirmOverlay.dlgFocus === 0
                    color:        active ? "#82aaff" : "transparent"
                    border.color: active ? "transparent" : "#444a73"
                    border.width: 1
                    radius: 7
                    focus: true
                    Behavior on color        { ColorAnimation { duration: 100 } }
                    Behavior on border.color { ColorAnimation { duration: 100 } }
                    Keys.onReturnPressed:  confirmOverlay.close()
                    Keys.onSpacePressed:   confirmOverlay.close()
                    Keys.onEscapePressed:  confirmOverlay.close()
                    Keys.onTabPressed:     { confirmOverlay.dlgFocus = 1; confirmYes.forceActiveFocus() }
                    Keys.onBacktabPressed: { confirmOverlay.dlgFocus = 1; confirmYes.forceActiveFocus() }
                    onActiveFocusChanged:  if (activeFocus) confirmOverlay.dlgFocus = 0
                    Text {
                        anchors.centerIn: parent
                        text:  "cancel"
                        color: confirmNo.active ? "#1e2030" : "#828bb8"
                        font { family: "JetBrains Mono"; pixelSize: 13
                               weight: confirmNo.active ? Font.Bold : Font.Normal }
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                    MouseArea {
                        id:           noMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered:    { confirmOverlay.dlgFocus = 0; confirmNo.forceActiveFocus() }
                        onExited:     { if (confirmOverlay.dlgFocus === 0) confirmNo.forceActiveFocus() }
                        onClicked:    confirmOverlay.close()
                    }
                }
            }
        }
    }

    // ── Session index ─────────────────────────────────────────
    property int currentSessionIndex: sessionBox.sessionIndex

    function doLogin() {
        if (userInput.text === "") {
            errorMsg.text = "username required"
            form.focusedField = 0
            userInput.forceActiveFocus()
            return
        }
        errorMsg.text = ""
        sddm.login(userInput.text, passInput.text, currentSessionIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            errorMsg.text  = "invalid credentials"
            passInput.text = ""
            form.focusedField = 1
            passInput.forceActiveFocus()
        }
    }

    Component.onCompleted: {
        form.focusedField = 0
        userInput.forceActiveFocus()
    }
}
