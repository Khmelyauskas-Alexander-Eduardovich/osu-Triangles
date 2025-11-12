/*
 * Copyright (C) 2020-2025  JasonWalt Bab@
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * osu! Triangles is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
//We don't use Lomiri Components Library, because it brokens app

Window {
    id: win
    width: 1440
    height: 720
    visible: true
    color: transparentWindow ? "transparent" : "#0b0f18"
    title: "osu!Triangles — Intro + Outro + Speed + Colors"

    // ---------------- Настройки ----------------
    property real introDurationMs: 1000
    property real introSpeedFactor: 3.0
    property real baseSpeedFactor: 1.0       // свитч скорости
    property real baseSpawnIntervalMs: 30
    property real baseSpawnChance: 0.25
    property real minSize: 20
    property real maxSize: 600
    property real minDuration: 3500
    property real maxDuration: 8000
    property var colorPalette: ["#66ccff","#33aaff","#55ddff","#99eeff"]
    property int targetTriCount: 200
    property bool showSettings: true
    property bool transparentWindow: true
    property bool isClosing: false            // для аутро

    // ---------------- Внутренние ----------------
    property real intensity: 0.0
    property real burstFactor: 0.0
    property int triCount: 0
    property real currentIntroFactor: introSpeedFactor
    property bool fullscreen: false

    onTransparentWindowChanged: {
        if(transparentWindow){
            color = "transparent"
        } else {
            color = "#0b0f18"
        }
    }

    // ---------------- Треугольник ----------------
    Component {
        id: triangleComp
        Item {
            id: tri
            property real size: minSize + Math.random()*(maxSize-minSize)
            width: size
            height: size
            property real dur: minDuration + Math.random()*(maxDuration-minDuration)
            property color triColor: colorPalette[Math.floor(Math.random()*colorPalette.length)]
            property real depth: Math.random() // 0 = задний, 1 = передний

            x: (Math.random()*(win.width+width*2))-width
            y: win.height + height
            //rotation: (Math.random()*4 - 2)
            opacity: 1.0
            z: 1 + depth*4

            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    ctx.beginPath();
                    ctx.moveTo(width/2,0);
                    ctx.lineTo(0,height);
                    ctx.lineTo(width,height);
                    ctx.closePath();
                    ctx.fillStyle = triColor;
                    ctx.fill();
                }
            }

            NumberAnimation on y {
                from: tri.y
                to: -tri.height
                duration: tri.dur*(0.7 + (1.0 - tri.depth)*0.6)/(currentIntroFactor*baseSpeedFactor)
                easing.type: Easing.Linear
                running: true
                onStopped: { tri.destroy(); triCount-- }
            }

            Component.onCompleted: triCount++
        }
    }

    // ---------------- Таймер спавна ----------------
    Timer {
        id: spawnTimer
        interval: baseSpawnIntervalMs
        repeat: true
        running: true
        onTriggered: {
            if(isClosing) return // не спавним при аутро
            var density = triCount/targetTriCount
            var needMore = 1.0 - Math.min(1.0,density)
            var effIntensity = Math.max(0.3,intensity)*(1.0 + burstFactor + needMore*1.5)
            var chance = baseSpawnChance*(0.5 + effIntensity*2.0)
            var batch = Math.round(3 + effIntensity*10)
            for(var i=0;i<batch;i++){
                if(Math.random()<chance){
                    var t = triangleComp.createObject(win)
                    if(t){
                        var speedFactor = 1.0 + needMore*1.2
                        t.dur = t.dur/speedFactor/currentIntroFactor/baseSpeedFactor
                    }
                }
            }
            if(burstFactor>0.001) burstFactor *= 0.92
            else burstFactor=0.0
        }
    }

    // ---------------- Интро-анимация ----------------
    SequentialAnimation {
        running: true
        NumberAnimation { target: win; property: "currentIntroFactor"; from: introSpeedFactor; to: 1.0; duration: introDurationMs; easing.type: Easing.OutQuad }
    }
    SequentialAnimation on intensity {
        running: true
        NumberAnimation { from: 0; to: 1; duration: introDurationMs; easing.type: Easing.InOutQuad }
    }

    // ---------------- Обработка клавиш ----------------
    Item {
        anchors.fill: parent
        focus: true
        Keys.onPressed: {
            if(event.key === Qt.Key_Space){
                triggerKick()
                event.accepted=true
            }
        }
    }

    // ---------------- Всплеск ----------------
    function triggerKick(mult=1.0){
        burstFactor=Math.min(1.0,burstFactor+0.4*mult)
        var count=25+Math.round(15*mult)
        for(var i=0;i<count;i++){
            var t = triangleComp.createObject(win)
            if(t){
                t.dur = Math.max(300,t.dur*0.4)/currentIntroFactor/baseSpeedFactor
                t.x = (Math.random()*(win.width + t.width*2)) - t.width
                t.triColor = colorPalette[Math.floor(Math.random()*colorPalette.length)]
                t.rotation = (Math.random()*4 - 2)
            }
        }
    }
    MouseArea {
    anchors.fill: parent
    onPressAndHold: {
    fullscreen = !fullscreen
        if (fullscreen) win.showFullScreen()
        if (!fullscreen) win.showNormal()
    }
    onDoubleClicked: {
    // ---------------- Аутро при закрытии ----------------
     function seeYou () {
        accepted = true          // отменяем мгновенное закрытие
        isClosing = true               // сигнал для таймера спавна
        currentIntroFactor = 0.2       // ускоряем все треугольники
        spawnTimer.stop()              // больше не спавним

        // Через 0.8 сек закрываем приложение после аутро
        Qt.createQmlObject('import QtQuick 2.0; Timer { interval:800; running:true; repeat:false; onTriggered: Qt.quit() }', win)
    }
        seeYou.call()
        Qt.quit()
    }
    }
    // ---------------- Настройки UI ----------------
    Rectangle {
        visible: showSettings
        width: 280
        anchors { left: parent.left; top: parent.top; leftMargin: 10; topMargin: 10 }
        color: "#111CCCCC"
        radius: 6
        border.color: "#666"
        z: 1000
        Column {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 6

            Row { spacing:6; Text { text:"Target Tri Count:"; color:"white"; font.pixelSize:14 } Slider { from:50; to:500; value:targetTriCount; onValueChanged: targetTriCount=value } }
            Row { spacing:6; Text { text:"Spawn Chance:"; color:"white"; font.pixelSize:14 } Slider { from:0.05; to:1; stepSize:0.01; value:baseSpawnChance; onValueChanged: baseSpawnChance=value } }
            Row { spacing:6; Text { text:"Intro Factor:"; color:"white"; font.pixelSize:14 } Slider { from:1; to:5; stepSize:0.1; value:introSpeedFactor; onValueChanged: introSpeedFactor=value } }
            Row { spacing:6; Text { text:"Intro Duration:"; color:"white"; font.pixelSize:14 } Slider { from:200; to:3000; stepSize:50; value:introDurationMs; onValueChanged: introDurationMs=value } }
            Row { spacing:6; Text { text:"Base Speed:"; color:"white"; font.pixelSize:14 } Slider { from:0.2; to:5; stepSize:0.05; value:baseSpeedFactor; onValueChanged: baseSpeedFactor=value } }
            Row { spacing:6; Text { text:"Transparent:"; color:"white"; font.pixelSize:14 } CheckBox { checked: transparentWindow; onCheckedChanged: transparentWindow=checked } }

            // Цвета
            Row { spacing:6; Text { text:"Color 1:"; color:"white"; font.pixelSize:14 } Rectangle { width:20;height:20;color:colorPalette[0]; border.color:"white"; MouseArea { anchors.fill: parent; onClicked: { colorPalette[0] = Qt.rgba(Math.random(),Math.random(),Math.random(),1) } } } }
            Row { spacing:6; Text { text:"Color 2:"; color:"white"; font.pixelSize:14 } Rectangle { width:20;height:20;color:colorPalette[1]; border.color:"white"; MouseArea { anchors.fill: parent; onClicked: { colorPalette[1] = Qt.rgba(Math.random(),Math.random(),Math.random(),1) } } } }
            Row { spacing:6; Text { text:"Color 3:"; color:"white"; font.pixelSize:14 } Rectangle { width:20;height:20;color:colorPalette[2]; border.color:"white"; MouseArea { anchors.fill: parent; onClicked: { colorPalette[2] = Qt.rgba(Math.random(),Math.random(),Math.random(),1) } } } }
            Row { spacing:6; Text { text:"Color 4:"; color:"white"; font.pixelSize:14 } Rectangle { width:20;height:20;color:colorPalette[3]; border.color:"white"; MouseArea { anchors.fill: parent; onClicked: { colorPalette[3] = Qt.rgba(Math.random(),Math.random(),Math.random(),1) } } } }
        }
    }

}
