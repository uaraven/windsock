import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Math;
import Toybox.System;
import Toybox.Weather;

class ATWView extends WatchUi.DataField {

    // following 3 arrays contains color mappings for the wind indicator
    // if the wind speed in m/s is higher than the number in the first array element, 
    // then the color from the second array element is chosen
    // there are three arrays, for headwind, sidewinds and the tailwind

    private var headwindColors = [
        [0, Graphics.COLOR_GREEN],
        [3, Graphics.COLOR_YELLOW],
        [6, Graphics.COLOR_ORANGE],
        [9, Graphics.COLOR_RED]
    ];

    private var arrow = [
        new Vector2(0, -0.9),
        new Vector2(-0.33, 0.8),
        new Vector2(0, 0.6),
        new Vector2(0.33, 0.8)
    ];

    hidden var mHeading as Numeric;
    hidden var mWindSpeed as Numeric;
    hidden var mWindSpeedMs as Numeric;
    hidden var mWindBearing as Numeric;
    hidden var mWindValid as Boolean;
    hidden var mWindForecast as Boolean;

    hidden var indicatorX as Numeric;
    hidden var indicatorY as Numeric;
    hidden var indicatorR as Numeric;

    private var mph as String;
    private var kmh as String;
    private var noWeather as String;

    function initialize() {
        DataField.initialize();
        mHeading = 0.0f;
        mWindSpeed = 0.0f;
        mWindSpeedMs = -1;
        mWindBearing = 0.0f;
        mWindValid = false;
        mWindForecast = false;

        mph = Application.loadResource(Rez.Strings.unitMph);
        kmh = Application.loadResource(Rez.Strings.unitKph);
        noWeather = Application.loadResource(Rez.Strings.NoWeather);
    }

    private function arrowToPoly( dx as Numeric, dy as Numeric, sz as Numeric, rotD as Numeric) {
        var rot = Math.toRadians(rotD);
        var result = new [arrow.size()];
        for (var i = 0; i < arrow.size(); i++) {
            result[i] = arrow[i].scaleRotateTranslate(sz, rot, dx, dy).asArray();
        }
        return result;
    }

    private function min(a as Numeric, b as Numeric) as Numeric {
        return (a > b) ? b : a;
    }

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc as Dc) as Void {
        View.setLayout(Rez.Layouts.DatafieldLayout(dc));
        var speedView = View.findDrawableById("speed");
        var unitView = View.findDrawableById("unit");

        speedView.setJustification(Graphics.TEXT_JUSTIFY_CENTER); 
        unitView.setJustification(Graphics.TEXT_JUSTIFY_CENTER); 

        var speedD = dc.getTextDimensions("180.0", Graphics.FONT_NUMBER_MEDIUM);
        var unitD = dc.getTextDimensions("km/h", Graphics.FONT_TINY);

        if (speedD[1] > dc.getHeight()/2) {
            speedD = dc.getTextDimensions("180.0", Graphics.FONT_MEDIUM);
            speedView.setFont(Graphics.FONT_MEDIUM);
            unitD = dc.getTextDimensions("km/h", Graphics.FONT_TINY);
            unitView.setFont(Graphics.FONT_XTINY);
        }

        if (dc.getWidth() > dc.getHeight()) {
            speedView.locX = dc.getWidth()/2 + (dc.getWidth()/2 - speedView.width)/2;
            speedView.locY = (dc.getHeight() / 2 -  speedD[1]+8);           
            unitView.locX = dc.getWidth()/2 +  (dc.getWidth()/2 - unitView.width)/2;
            unitView.locY = dc.getHeight()/2 + 3;
            indicatorX = dc.getWidth() / 4;
            indicatorY = dc.getHeight() / 2;
            var hw = dc.getWidth() / 3;
            var hh = dc.getHeight() / 3;
            indicatorR = min(hw, hh);
        } else {
            speedView.locX = (dc.getWidth() - speedView.width)/2;
            speedView.locY =  20 + dc.getHeight() / 2;
            unitView.locX = (dc.getWidth() - unitView.width)/2;
            unitView.locY = speedView.locY + speedD[1];
            unitView.width = dc.getWidth();
            indicatorX = dc.getWidth() / 2;
            indicatorY = dc.getHeight() / 4;
            indicatorR = dc.getWidth() / 3 - 3;
        }
    }

    function convertSpeed(speed as Numeric) as Numeric {
        switch (System.getDeviceSettings().paceUnits) {
            case System.UNIT_METRIC: 
                return speed * 3.6;
            case System.UNIT_STATUTE: 
                return speed * 2.237;
            default:
                return speed;
        }
    }

    function compute(info as Activity.Info) as Void {
        if(info has :currentHeading){
            if (info.currentHeading != null) {
                mHeading = Math.toDegrees(info.currentHeading as Number);
            } else {
                mHeading = 0;
            }
        }
        System.println("Heading: " + mHeading);
        mWindForecast = false;
        var w = Weather.getCurrentConditions();
        if (w != null) {
            mWindSpeedMs = w.windSpeed;
            mWindSpeed = convertSpeed(w.windSpeed);
            mWindBearing = w.windBearing;
            mWindValid = true;
        } else {
            mWindSpeed = -1;
            mWindSpeedMs = -1;
            mWindBearing = 0;
            mWindValid = false;
        }

        if (mWindBearing == null) {
            setForecastWeather();
        }
    }

    function setForecastWeather() {
        mWindBearing = 0;
        mWindValid = false;
        var hf = Weather.getHourlyForecast();
        if (hf == null || hf.size() < 1) {
            return;
        }
        mWindBearing = hf[0].windBearing;
        mWindSpeedMs = hf[0].windSpeed;
        mWindSpeed = convertSpeed(hf[0].windSpeed);
        mWindValid = true;
        mWindForecast = true;
    }

    function getArrowColor() {
        var heading = (mHeading - mWindBearing).toLong() % 360;
        var vy = 0;
        if (heading >=125 && heading <= 235) {
            vy = mWindSpeedMs;
        } else {
            vy = -mWindSpeedMs * Math.cos(Math.toRadians(heading)) * 1.5;
        }
        // chose color mapping based on heading
        var colorMap = headwindColors;
        for (var i = colorMap.size()-1 ; i >= 0; i--) {
            if (vy > colorMap[i][0]) {
                return colorMap[i][1];
            }
        }
        return colorMap[0][1];
    }

    function drawPoly(dc as DC, points) {
        for (var i = 1; i < points.size(); i++) {
            dc.drawLine(points[i-1][0], points[i-1][1], points[i][0], points[i][1]);
        }
        var last = points.size()-1;
        dc.drawLine(points[0][0], points[0][1], points[last][0], points[last][1]);
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc as Dc) as Void {
        // Set the background color
        (View.findDrawableById("Background") as Text).setColor(getBackgroundColor());

        // Set the foreground color and value
        var unit = View.findDrawableById("unit") as Text;
        var wind = View.findDrawableById("speed") as Text;

        unit.setText(System.getDeviceSettings().paceUnits == System.UNIT_STATUTE ? mph : kmh );

        var fg = Graphics.COLOR_BLACK;
        var bg = Graphics.COLOR_TRANSPARENT;
        if (getBackgroundColor() == Graphics.COLOR_BLACK) {
            unit.setColor(Graphics.COLOR_WHITE);
            wind.setColor(Graphics.COLOR_WHITE);
            fg = Graphics.COLOR_BLACK;
            bg = Graphics.COLOR_WHITE;
        } else {
            unit.setColor(Graphics.COLOR_BLACK);
            wind.setColor(Graphics.COLOR_BLACK);
            fg = Graphics.COLOR_WHITE;
            bg = Graphics.COLOR_BLACK;
        }
        if (mWindValid) {
            wind.setText(mWindSpeed.format("%.1f"));

            // Call parent's onUpdate(dc) to redraw the layout
            View.onUpdate(dc);

            dc.setPenWidth(3);
            dc.setAntiAlias(true);
            dc.setColor(fg, bg);
            dc.fillCircle(indicatorX, indicatorY, indicatorR);
            dc.setColor(bg, bg);
            dc.drawCircle(indicatorX, indicatorY, indicatorR);
            dc.setPenWidth(2);

            if (mWindForecast) {
                dc.setColor(Graphics.COLOR_ORANGE, bg);
                dc.drawCircle(indicatorX, indicatorY, indicatorR-2);
            }
            dc.setPenWidth(1);

            var heading = (mHeading - mWindBearing).toLong() % 360;

            var poly = arrowToPoly(indicatorX, indicatorY ,indicatorR, heading);
            var color = getArrowColor();
            dc.setColor(color, bg);
            dc.fillPolygon(poly);
            dc.setColor(bg, fg);
            drawPoly(dc, poly);
        } else {
            showErrorMsg(dc, noWeather, bg);
        }
    }

    function showErrorMsg(dc, text, color) {
        var unit = View.findDrawableById("unit") as Text;
        var wind = View.findDrawableById("speed") as Text;
        wind.setText("");
        unit.setText("");

        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        var td = dc.getTextDimensions(text, Graphics.FONT_SMALL);
        var font = Graphics.FONT_SMALL;
        if (td[0] > dc.getWidth() || td[1] > dc.getHeight()) { // mostly for Edge 130, others do just fine
            font = Graphics.FONT_XTINY;
        }
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, font, text, Graphics.TEXT_JUSTIFY_CENTER + Graphics.TEXT_JUSTIFY_VCENTER);
    }

}
