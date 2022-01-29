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

    private var sidewindColors = [
        [0, Graphics.COLOR_GREEN],
        [6, Graphics.COLOR_YELLOW],
        [9, Graphics.COLOR_ORANGE],
        [12, Graphics.COLOR_RED]
    ];

    private var tailwindColors = [
        [0, Graphics.COLOR_GREEN]
    ];

    // mapping between relative wind bearing and the wind speed color mapping
    // i.e. if the wind bearing is between ±60º from the front it is treated as a headwind
    // if the wind comes from anywhere from the back, it is treated as a tailwind (even if it is side-ish tailwind)

    private var headingColors = [
        [-180, -120, headwindColors],
        [120, 180, headwindColors],
        [90, 120, sidewindColors],
        [-120, -90, sidewindColors],
        [-90, 90, tailwindColors]
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

    hidden var indicatorX as Numeric;
    hidden var indicatorY as Numeric;
    hidden var indicatorR as Numeric;

    private var units as String;

    function initialize() {
        DataField.initialize();
        mHeading = 0.0f;
        mWindSpeed = 0.0f;
        mWindSpeedMs = -1;
        mWindBearing = 0.0f;
        mWindValid = false;
    }

    private function arrowToPoly( dx as Numeric, dy as Numeric, sz as Numeric, rot as Numeric) {
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
                mHeading = info.currentHeading as Number;
            } else {
                mHeading = 0;
            }
        }
        var w = Weather.getCurrentConditions();
        if (w != null) {
            mWindSpeedMs = w.windSpeed;
            mWindSpeed = convertSpeed(w.windSpeed);
            mWindBearing = w.windBearing;
        } else {
            mWindSpeed = -1;
            mWindSpeedMs = -1;
            mWindBearing = 0;
        }
    }

    function getArrowColor() {
        var heading = (mWindBearing + 180 + Math.toDegrees(mHeading)).toLong();
        if (heading > 180) {
            heading = heading - 360;
        }
        // chose color mapping based on heading
        var colorMap = headwindColors;
        for (var i = 0; i < headingColors.size(); i++) {
            if (heading >= headingColors[i][0] && heading <= headingColors[i][1]) {
                colorMap = headingColors[i][2];
                break;
            }
        }
        for (var i = colorMap.size()-1 ; i >= 0; i--) {
            if (mWindSpeedMs > colorMap[i][0]) {
                return colorMap[i][1];
            }
        }
        return colorMap[0][1];
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc as Dc) as Void {
        // Set the background color
        (View.findDrawableById("Background") as Text).setColor(getBackgroundColor());

        // Set the foreground color and value
        var unit = View.findDrawableById("unit") as Text;
        var wind = View.findDrawableById("speed") as Text;

        unit.setText(System.getDeviceSettings().paceUnits == System.UNIT_STATUTE ? 
            Application.loadResource(Rez.Strings.unitMph) : Application.loadResource(Rez.Strings.unitKph) );

        var fg = Graphics.COLOR_BLACK;
        var bg = Graphics.COLOR_TRANSPARENT;
        if (getBackgroundColor() == Graphics.COLOR_BLACK) {
            unit.setColor(Graphics.COLOR_WHITE);
            wind.setColor(Graphics.COLOR_WHITE);
            fg = Graphics.COLOR_DK_GRAY;
        } else {
            unit.setColor(Graphics.COLOR_BLACK);
            wind.setColor(Graphics.COLOR_BLACK);
            fg = Graphics.COLOR_LT_GRAY;
        }
        if (mWindSpeedMs >= 0) {
            wind.setText(mWindSpeed.format("%.1f"));
        } else {
            wind.setText("N/A");
        }

        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);

        dc.setPenWidth(2);
        dc.setAntiAlias(true);
        dc.setColor(0xFF101040, bg);
        dc.fillCircle(indicatorX, indicatorY, indicatorR);
        dc.setColor(fg, bg);
        dc.drawCircle(indicatorX, indicatorY, indicatorR);

        var poly = arrowToPoly(indicatorX, indicatorY ,indicatorR, Math.toRadians(mWindBearing + 180) + mHeading);
        var color = getArrowColor();
        dc.setColor(color, bg);
        dc.fillPolygon(poly);
    }

}
