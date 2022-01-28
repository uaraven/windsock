import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Math;
import Toybox.Application.Properties;

class ATWView extends WatchUi.DataField {

    private var arrow = [
        new Vector2(0, -1),
        new Vector2(-0.2, 1),
        new Vector2(0, 0.8),
        new Vector2(0.2, 1)
    ];

    hidden var mHeading as Numeric;
    hidden var mWindSpeed as Numeric;
    hidden var mWindSpeedMs as Numeric;
    hidden var mWindBearing as Numeric;
    hidden var mWindValid as Boolean;

    hidden var roseX as Numeric;
    hidden var roseY as Numeric;
    hidden var roseR as Numeric;

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

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc as Dc) as Void {
        View.setLayout(Rez.Layouts.DatafieldLayout(dc));
        var speedView = View.findDrawableById("speed");
        // labelView.locY = labelView.locY - 16;
        var unitView = View.findDrawableById("unit");
        // valueView.locY = valueView.locY + 7;

        speedView.setJustification(Graphics.TEXT_JUSTIFY_CENTER); 
        unitView.setJustification(Graphics.TEXT_JUSTIFY_CENTER); 
        (View.findDrawableById("unit") as Text).setText("m/s");

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
            speedView.locY = (dc.getHeight() / 2 -  speedD[1]);           
            unitView.locX = dc.getWidth()/2 +  (dc.getWidth()/2 - unitView.width)/2;
            unitView.locY = dc.getHeight()/2 + 3;
            roseX = dc.getWidth() / 4;
            roseY = dc.getHeight() / 2;
            roseR = dc.getHeight() / 4 - 2;
        } else {
            speedView.locX = (dc.getWidth() - speedView.width)/2;
            speedView.locY = dc.getHeight() / 2;
            unitView.locX = (dc.getWidth() - unitView.width)/2;
            unitView.locY = 4 * dc.getWidth()/5;
            unitView.width = dc.getWidth();
            roseX = dc.getWidth() / 2;
            roseY = dc.getHeight() / 4;
            roseR = dc.getWidth() / 4 - 5;
        }
    }

    function convertSpeed(speed as Numeric) as Numeric {
        switch (unitsNameId) {
            case 1: 
                return speed * 3.6;
            case 2: 
                return speed * 2.237;
            default:
                return speed;
        }
    }

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info as Activity.Info) as Void {
        // See Activity.Info in the documentation for available information.
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

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc as Dc) as Void {
        // Set the background color
        (View.findDrawableById("Background") as Text).setColor(getBackgroundColor());

        // Set the foreground color and value
        var unit = View.findDrawableById("unit") as Text;
        var wind = View.findDrawableById("speed") as Text;

        unit.setText(getUnitsName());

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
        dc.fillCircle(roseX, roseY, roseR);
        dc.setColor(fg, bg);
        dc.drawCircle(roseX, roseY, roseR);

        var poly = arrowToPoly(roseX, roseY ,roseR, Math.toRadians(mWindBearing + 180) + mHeading);
        var color = Graphics.COLOR_GREEN;
        if (mWindSpeedMs > 3) {
            color = Graphics.COLOR_YELLOW;
        } 
        if (mWindSpeedMs > 6) {
            color = Graphics.COLOR_ORANGE;
        } 
        if (mWindSpeedMs > 9) {
            color = Graphics.COLOR_RED;
        }
        dc.setColor(color, bg);
        dc.fillPolygon(poly);

        // dc.setColor(Graphics.COLOR_BLUE, bg);        
        // poly = arrowToPoly(20, 20 , 20,  -mHeading);
        // dc.fillPolygon(poly);

        // dc.setColor(Graphics.COLOR_GREEN, bg);        
        // poly = arrowToPoly(dc.getWidth()-20, 20 , 20,  Math.toRadians(mWindBearing+180));
        // dc.fillPolygon(poly);
    }

}
