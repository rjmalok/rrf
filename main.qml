import QtQuick
import QtQuick.Controls 6.2
import QtQuick.LocalStorage

Window {
    id: window
    title: qsTr("qtify")
    width: 640
    height: 480
    visible: true
    property alias button: button

    Component {
        id: mainView

        Row {
            spacing: 10

            Text {
                text: stack.depth
            }
        }
    }

    StackView {
        id: stackView
        y: 0
        // responsywnosc
        anchors.fill: parent
        anchors.horizontalCenter: parent.horizontalCenter

        // zmienne pomocnicze
        property string access_token: ""
        property string refresh_token: ""

        // dane do autoryzacji aplikacji na stronie spotify
        property string client_secret: "SPOTIFY_CLIENT_SECRET"
        property string client_id: "SPOTIFY_CLIENT_ID"
        property var db

        // funkcja do odnawiania tokena autoryzacji
        function autoRenew() {
            // definiowanie funkcji do wykonywania zapytan http
            var xhr3 = new XMLHttpRequest()

            // ustawienie odpowiedzi na json
            xhr3.responseType = 'json'

            xhr3.onreadystatechange = function () {
                // wykonaj gdy funkcja jest w stanie gotowosci
                if (xhr3.readyState == XMLHttpRequest.DONE) {
                    // wykonaj jezeli istnieje odpowiedz w formie json z API
                    if (xhr3.response) {
                        var response2 = xhr3.response
                        stackView.access_token = response2.access_token
                    }
                }
            }

            // wykonaj zapytanie POST do spotify aby pobrac access token do autoryzacji
            xhr3.open("POST",
                      "https://accounts.spotify.com/api/token?grant_type=refresh_token&refresh_token="
                      + stackView.refresh_token + "&client_secret="
                      + stackView.client_secret + "&client_id=" + stackView.client_id,
                      true)

            // ustaw encoding
            xhr3.setRequestHeader("Content-Type",
                                  "application/x-www-form-urlencoded")

            // wyslij zapytanie
            xhr3.send()
        }

        // funkcja do odnawiania access tokena za pomoca refresh tokena co godzine
        function refreshAccessToken() {
            // pobierz kod otrzymany w url
            var code = textInput.text

            // definiowanie funkcji do wykonywania zapytan http
            var xhr = new XMLHttpRequest()

            // ustawienie odpowiedzi na json
            xhr.responseType = 'json'

            xhr.onreadystatechange = function () {
                // wykonaj jezeli stan jest na ready
                if (xhr.readyState == XMLHttpRequest.DONE) {
                    // wykonaj jezeli istnieje odpowiedz z API
                    if (xhr.response) {
                        var response2 = xhr.response
                        stackView.refresh_token = response2.refresh_token
                        stackView.access_token = response2.access_token
                    }
                }
            }

            // wykonaj zapytanie POST do spotify aby pobrac refresh token z kodu uzyskanego w URL po zalogowaniu
            xhr.open("POST",
                     "https://accounts.spotify.com/api/token?grant_type=authorization_code&client_id="
                     + stackView.client_id + "&client_secret=" + stackView.client_secret
                     + "&code=" + code + "&redirect_uri=https://kunszg.com/resolved",
                     true)
            xhr.send()
        }

        // laczenie z baza danych
        function getDatabase() {
            return LocalStorage.openDatabaseSync("baza", "1.0",
                                                 "StorageDatabase", 1000000)
        }

        // tworzenie tabeli jezeli nie istnieje
        function createTables() {
            var db = stackView.getDatabase()
            db.transaction(function (tx) {
                tx.executeSql(
                            'CREATE TABLE IF NOT EXISTS configuration(id INTEGER PRIMARY KEY AUTOINCREMENT,
param_name TEXT, param_value TEXT)')
            })
        }

        // pierwsze uruchomienie
        function setToken() {
            if (stackView.access_token) {
                var xhr2 = new XMLHttpRequest()
                xhr2.responseType = 'json'

                xhr2.onreadystatechange = function () {
                    if (xhr2.readyState == XMLHttpRequest.DONE) {
                        var response = xhr2.response

                        // ustaw nickname spotify uzytkownika w aplikacji z API
                        label1.text = response.display_name

                        // ustaw obrazek spotify uzytkownika w aplikacji z API
                        image1.source = response.images[0].url.replace("\\n",
                                                                       "")

                        var xhr3 = new XMLHttpRequest()
                        xhr3.responseType = 'json'

                        xhr3.onreadystatechange = function () {
                            if (xhr3.readyState == XMLHttpRequest.DONE) {
                                if (xhr3.response) {
                                    var response2 = xhr3.response

                                    // ustaw nazwe artysty i piosenki z API
                                    label.text = response2.item.artists[0].name
                                            + " - " + response2.item.name

                                    // ustaw obrazek piosenki z API
                                    image.source = response2.item.album.images[0].url

                                    // ustawienie zakresu slidera
                                    from = 0
                                    slider.to = 100

                                    // ustawienie wartosci slidera z API
                                    slider.value = ~~(((response2.progress_ms / 1000)
                                                       / (response2.item.duration_ms / 1000)) * 100)

                                    // ustawienie wartosci kroku slidera
                                    slider.stepSize = 1
                                }
                            }
                        }

                        // wykonaj zapytanie w celu pobrania danych o obecnie grajacej piosence na spotify uzytkownika
                        xhr3.open("GET",
                                  "https://api.spotify.com/v1/me/player/currently-playing",
                                  true)

                        // ustaw token autoryzacji uzytkownika do wyslania w tym samym zapytaniu
                        xhr3.setRequestHeader(
                                    "Authorization",
                                    "Bearer " + stackView.access_token)

                        // wyslij zapytanie
                        xhr3.send()
                    }
                }

                // wykonaj zapytanie do spotify aby otrzymac informacje o koncie uzytkownika
                xhr2.open("GET", "https://api.spotify.com/v1/me", true)

                // ustaw token autoryzacji uzytkownika do wyslania w tym samym zapytaniu
                xhr2.setRequestHeader("Authorization",
                                      "Bearer " + stackView.access_token)

                // wyslij zapytanie
                xhr2.send()
            }
        }

        Image {
            id: image
            y: 10
            height: 200
            anchors.left: parent.left

            anchors.right: parent.right
            source: ""
            anchors.leftMargin: 0
            anchors.rightMargin: 87
            fillMode: Image.PreserveAspectFit
        }

        Label {
            id: label
            y: 217
            width: 200
            wrapMode: Text.WordWrap
            anchors.horizontalCenterOffset: -27
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("Nic nie gra na twoim Spotify")
            font.pointSize: 14
            scale: 1
        }

        Slider {
            id: slider
            y: 364
            width: 603
            height: 13
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.horizontalCenterOffset: -11
            anchors.leftMargin: 18
            anchors.rightMargin: 30
            anchors.horizontalCenter: parent.horizontalCenter
            wheelEnabled: false
            orientation: Qt.Horizontal
            stepSize: 1
            value: 0
        }

        Label {
            id: label1
            x: 44
            y: 17
            width: 221
            height: 25
            text: qsTr("")
            z: 1
        }

        Popup {
            id: popup
            x: 100
            y: 100
            width: 400
            height: 100
            modal: true
            focus: true
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

            Rectangle {
                x: -15
                y: -15
                width: 420
                height: 120
                color: "#1a1a1a"
                border.color: "black"
                border.width: 2
                radius: 8

                Button {
                    id: button123
                    text: qsTr("Zapisz")
                    x: 170
                    y: 70
                    onClicked: {

                        var code = textInput.text

                        var http5 = new XMLHttpRequest()

                        // wykonaj zapytanie do strony przetwarzajacej przekierowanie ze spotify
                        var url = "https://kunszg.com/resolvedProjekt?code=" + code.split(
                                    " ")[1]

                        http5.responseType = "json"
                        http5.onreadystatechange = function () {
                            if (http5.readyState == XMLHttpRequest.DONE) {
                                if (http5.response) {
                                    var response = http5.response

                                    stackView.refresh_token = response.refresh_token
                                    stackView.access_token = response.access_token
                                    stackView.setToken()

                                    // wlacz timer
                                    refresh.running = true

                                    var db = stackView.getDatabase()
                                    db.transaction(function (tx) {

                                        // sprawdz czy w bazie danych istnieje token
                                        var q = tx.executeSql(
                                                    'SELECT * FROM configuration WHERE param_name=?',
                                                    ["refresh"])
                                        if (typeof q.rows.item(
                                                    0) === "undefined") {
                                            // jezeli nie istnieje token w bazie, dodaj rekord z pobranym wczesniej tokenem
                                            tx.executeSql(
                                                        'INSERT INTO configuration (param_name, param_value) VALUES (?, ?)',
                                                        ["refresh", response.refresh_token])
                                        }
                                    })

                                    popup.close()
                                }
                            }
                        }

                        // wyslij zapytanie
                        http5.open("GET", url, true)

                        http5.send()
                    }
                }

                Rectangle {
                    x: 115
                    y: 30
                    width: 200
                    height: 20
                    color: "white"
                    border.color: "gray"
                    border.width: 2
                }

                Label {
                    id: label123
                    text: "Wklej tutaj token wyswietlony na stronie"
                    x: 85
                    y: 7
                    color: "white"
                }

                TextInput {
                    id: textInput
                    x: 115
                    y: 34
                    width: 200
                    height: 20
                    font.pixelSize: 12
                }
            }
        }

        Image {
            id: image1
            y: 10
            width: 38
            height: 34
            anchors.left: parent.left
            source: ""
            anchors.leftMargin: 0
            z: 1
            scale: 1
            sourceSize.height: 100
            sourceSize.width: 100
            fillMode: Image.PreserveAspectCrop
        }

        Slider {
            id: slider1
            y: 415
            width: 100
            anchors.horizontalCenterOffset: -27
            anchors.horizontalCenter: parent.horizontalCenter
            value: 0
        }

        Button {
            id: button5
            width: 100
            text: qsTr("zaloguj")
            anchors.right: parent.right
            anchors.rightMargin: 1
            property bool loggedIn: false
            y: 16

            Timer {
                id: timerToken
                interval: 3600000
                running: false
                repeat: true
                onTriggered: stackView.setToken()
                triggeredOnStart: false
            }

            Timer {
                id: refresh
                interval: 1000
                running: false
                repeat: true
                onTriggered: button5.refresh()
                triggeredOnStart: true
            }

            Timer {
                id: renewToken
                interval: 4000
                running: true
                repeat: true
                onTriggered: stackView.autoRenew()
                triggeredOnStart: true
            }

            function refresh() {
                if (stackView.access_token) {
                    var http = new XMLHttpRequest()
                    var http2 = new XMLHttpRequest()
                    http.responseType = 'json'

                    http2.responseType = 'json'
                    http2.onreadystatechange = function () {
                        if (http2.readyState == XMLHttpRequest.DONE) {
                            if (http2.response) {
                                var response2 = http2.response

                                // uaktualnij artyste i nazwe piosenki
                                label.text = response2.item.artists[0].name
                                        + " - " + response2.item.name

                                // uaktualnij obrazek piosenki
                                image.source = response2.item.album.images[0].url

                                // przypisz zakres slidera
                                slider.from = 0
                                slider.to = 100

                                // uaktualnij wartosc slidera
                                slider.value = ~~(((response2.progress_ms / 1000)
                                                   / (response2.item.duration_ms / 1000)) * 100)

                                // przypisz wartosc kroku slidera
                                slider.stepSize = 1

                                // funkcje zamieniajace milisekundy na minuty i sekundy
                                var mins = Math.floor(
                                            response2.progress_ms / 1000 / 60)
                                var secs = Math.floor(
                                            response2.progress_ms / 1000) - mins * 60

                                var mins2 = Math.floor(
                                            response2.item.duration_ms / 1000 / 60)
                                var secs2 = Math.floor(
                                            response2.item.duration_ms / 1000) - mins2 * 60

                                // funkcja dodajaca zero na poczatku liczb np.: 2:12 => 02:12
                                function addZero(arg) {
                                    if (arg.toString().split("").length === 1) {
                                        return "0" + arg
                                    } else {
                                        return arg
                                    }
                                }

                                // ustaw wartosc postepu piosenki pod sliderem
                                label5.text = `${addZero(mins)}:${addZero(
                                            secs)} / ${addZero(
                                            mins2)}:${addZero(secs2)}`
                            }
                        }
                    }

                    // zapytanie do spotify w celu uzyskania jsona z obecnie grajaca piosenka
                    http2.open("GET",
                               "https://api.spotify.com/v1/me/player/currently-playing",
                               true)

                    // autoryzacja zapytania
                    http2.setRequestHeader("Authorization",
                                           "Bearer " + stackView.access_token)
                    // wysylanie zapytania
                    http2.send()

                    http.onreadystatechange = function () {
                        if (http.readyState == XMLHttpRequest.DONE) {
                            if (http.response) {
                                var response = http.response

                                button.playing = response.is_playing
                                if (typeof response.display_name != "undefined") {
                                    label1.text = response.display_name
                                    image1.source = response.images[0].url.replace(
                                                "\\n", "")
                                }

                                // ustawienie znaczka na przycisku play zaleznie od tego czy piosenka jest zapauzowana
                                if (response.is_playing) {
                                    button.text = qsTr("||")
                                } else {
                                    button.text = qsTr("▷")
                                }

                                button4.text = "repeat " + response.repeat_state
                                button4.state = response.repeat_state

                                // ustaw napis na przycisku zaleznie od stanu na spotify
                                if (response.shuffle_state) {
                                    button3.text = "shuffle on"
                                } else {
                                    button3.text = "shuffle off"
                                }

                                button3.state = response.shuffle_state

                                // slider do glosnosci
                                slider1.from = 0
                                slider1.to = 100
                                slider1.stepSize = 1
                                slider1.value = response.device.volume_percent
                                label6.text = "vol " + response.device.volume_percent + "%"

                                if (button5.text === "zaloguj") {
                                    button5.text = "wyloguj"
                                }
                            }
                        }
                    }

                    // wykonaj zapytanie pobierajace informacje o koncie uzytkownika
                    http.open("GET",
                              "https://api.spotify.com/v1/me/player", true)

                    // autoryzacja zapytania
                    http.setRequestHeader("Authorization",
                                          "Bearer " + stackView.access_token)

                    // wyslij zapytanie
                    http.send()
                } else {
                    button5.renewToken.running = true
                }
            }

            onClicked: {
                if (button5.text === "wyloguj") {
                    // kiedy uzytkownik jest zalogowany i kliknie w przycisk "wyloguj"
                    // aplikacja sie terminuje a dane uzytkownika sa usuwane z bazy danych
                    var db4 = stackView.getDatabase()
                    db4.transaction(function (tx) {
                        button5.text = "zaloguj"
                        var q = tx.executeSql(
                                    'DELETE FROM configuration WHERE param_name=?',
                                    ["refresh"])

                        stackView.refresh_token = ""
                        stackView.access_token = ""
                        Qt.quit()
                    })
                } else {
                    // jezeli uzytkownik kliknie w przycisk zaloguj
                    // zostaja zainicjowane funkcje pierwszego uruchomienia
                    timerToken.running = true
                    stackView.setToken()
                    button5.text = "wyloguj"

                    stackView.createTables()
                    var db = stackView.getDatabase()

                    db.transaction(function (tx) {
                        // znajdz token w bazie
                        var q = tx.executeSql(
                                    'SELECT * FROM configuration WHERE param_name=? ORDER BY ID DESC',
                                    ["refresh"])

                        refresh.running = true

                        // jezeli token nie istnieje w bazie...
                        if (typeof q.rows.item(0) === "undefined") {
                            // otwarcie strony do autoryzacji spotify w przegladarce
                            Qt.openUrlExternally(
                                        "https://kunszg.com/connections")
                            popup.open()
                        } else {
                            // przypisanie tokena z bazy do zmiennej
                            stackView.refresh_token = q.rows.item(0).param_value
                            button5.renewToken.running = true
                        }
                    })
                }
            }
        }

        Label {
            id: label6
            y: 415
            text: qsTr("vol 0%")
            anchors.horizontalCenterOffset: 53
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            id: label5
            y: 383
            width: 30
            height: 18
            text: qsTr("00:00 / 00:00")
            anchors.horizontalCenterOffset: -27
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Flow {
            id: grid
            y: 282
            height: 67
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 0
            flow: Flow.LeftToRight
            layoutDirection: Qt.LeftToRight
            anchors.rightMargin: 1
            anchors.leftMargin: 5

            Button {
                id: button3
                width: 130
                height: 26
                text: qsTr("shuffle off")
                property bool state: false
                onClicked: {
                    var url = "https://api.spotify.com/v1/me/player/shuffle?state="
                    if (button3.state) {
                        var http = new XMLHttpRequest()

                        // wyslanie zapytania PUT do spotify w celu zmienienia wartosci shuffle
                        http.open("PUT", url + "false", true)

                        // autoryzacja zapytania
                        http.setRequestHeader(
                                    "Authorization",
                                    "Bearer " + stackView.access_token)

                        // wyslanie zapytania
                        http.send()
                    } else {
                        // wyslanie zapytania PUT do spotify w celu zmienienia wartosci shuffle
                        var http = new XMLHttpRequest()
                        http.open("PUT", url + "true", true)

                        // autoryzacja zapytania
                        http.setRequestHeader(
                                    "Authorization",
                                    "Bearer " + stackView.access_token)

                        // wyslanie zapytania
                        http.send()
                    }
                }
            }

            Button {
                id: button1
                width: 80
                height: 26
                text: qsTr("previous")
                onClicked: {
                    // wyslanie zapytania w celu cofniecia do ostatniej piosenki
                    var http = new XMLHttpRequest()
                    var url = "https://api.spotify.com/v1/me/player/previous"
                    http.open("POST", url, true)
                    http.setRequestHeader("Authorization",
                                          "Bearer " + stackView.access_token)
                    http.send()
                }
            }

            Button {
                id: button
                width: 49
                height: 26
                text: qsTr("▷")
                property bool playing: false
                onClicked: {
                    if (button.playing) {
                        // wyslanie zapytania w celu zatrzymania obecnie grajacej piosenki
                        var http = new XMLHttpRequest()
                        var url = "https://api.spotify.com/v1/me/player/pause"

                        http.open("PUT", url, true)

                        // autoryzacja zapytania
                        http.setRequestHeader(
                                    "Authorization",
                                    "Bearer " + stackView.access_token)
                        http.send()

                        button.playing = false
                        button.text = "▷"
                    } else {
                        // wyslanie zapytania w celu wznowienia obecnie grajacej piosenki
                        var http = new XMLHttpRequest()
                        var url = "https://api.spotify.com/v1/me/player/play"

                        http.open("PUT", url, true)

                        // autoryzacja zapytania
                        http.setRequestHeader(
                                    "Authorization",
                                    "Bearer " + stackView.access_token)
                        http.send()

                        button.playing = true
                        button.text = "||"
                    }
                }
            }

            Button {
                id: button2
                width: 80
                height: 26
                text: qsTr("skip")
                onClicked: {
                    var http = new XMLHttpRequest()
                    var url = "https://api.spotify.com/v1/me/player/next"

                    http.open("POST", url, true)
                    http.setRequestHeader("Authorization",
                                          "Bearer " + stackView.access_token)
                    http.send()
                }
            }

            Button {
                id: button4
                width: 130
                height: 26
                text: qsTr("repeat off")
                property string state: ""
                onClicked: {
                    // wyslanie zapytan PUT zmieniajacych stan zapetlenia piosenki
                    var url = "https://api.spotify.com/v1/me/player/repeat?state="
                    if (button4.state === "off") {
                        var http = new XMLHttpRequest()
                        http.open("PUT", url + "track", true)
                        http.setRequestHeader(
                                    "Authorization",
                                    "Bearer " + stackView.access_token)
                        http.send()
                        button4.text = "repeat track"
                        button4.state = "track"
                    } else if (button4.state === "track") {
                        var http = new XMLHttpRequest()
                        http.open("PUT", url + "context", true)
                        http.setRequestHeader(
                                    "Authorization",
                                    "Bearer " + stackView.access_token)
                        http.send()
                        button4.text = "repeat context"
                        button4.state = "context"
                    } else if (button4.state === "context") {
                        var http = new XMLHttpRequest()
                        http.open("PUT", url + "off", true)
                        http.setRequestHeader(
                                    "Authorization",
                                    "Bearer " + stackView.access_token)
                        http.send()
                        button4.text = "repeat off"
                        button4.state = "off"
                    }
                }
            }
        }
    }
}

/*##^##
Designer {
    D{i:0;formeditorZoom:1.33;width:300}D{i:1}D{i:5}D{i:6}D{i:7}D{i:8}D{i:9}D{i:15}D{i:16}
D{i:18}D{i:19}D{i:20}D{i:17}D{i:21}D{i:22}D{i:24}D{i:25}D{i:26}D{i:27}D{i:28}D{i:23}
D{i:4}
}
##^##*/

