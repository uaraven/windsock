import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class ATWView extends WatchUi.DataField {

    hidden var mSpeed as Numeric;
    hidden var mHeading as Numeric;
    hidden var mWindSpeed as Numeric;
    hidden var mWindBearing as Numeric;
    hidden var mWindValid as Boolean;

    function initialize() {
        DataField.initialize();
        mSpeed = 0.0f;
        mHeading = 0.0f;
        mWindSpeed = 0.0f;
        mWindBearing = 0.0f;
        mWindValid = false;
    }

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc as Dc) as Void {
        View.setLayout(Rez.Layouts.MainLayout(dc));
        var labelView = View.findDrawableById("label");
        labelView.locY = labelView.locY - 16;
        var valueView = View.findDrawableById("value");
        valueView.locY = valueView.locY + 7;
        var windView = View.findDrawableById("wind_speed");
        windView.locY = windView.locY + 26;
 
        (View.findDrawableById("label") as Text).setText(Rez.Strings.label);
    }

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info as Activity.Info) as Void {
        // See Activity.Info in the documentation for available information.
        if(info has :currentHeartRate){
            if (info.currentHeading != null) {
                mValue = info.currentHeading as Number;
            } else {
                mValue = -500;
            }
        }
        var w = Weather.getCurrentConditions();
        if (w != null) {
            mWindSpeed = w.windSpeed;
        } else {
            mWindSpeed = 0;
        }
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc as Dc) as Void {
        // Set the background color
        (View.findDrawableById("Background") as Text).setColor(getBackgroundColor());

        // Set the foreground color and value
        var value = View.findDrawableById("value") as Text;
        var wind = View.findDrawableById("wind_speed") as Text;
        if (getBackgroundColor() == Graphics.COLOR_BLACK) {
            value.setColor(Graphics.COLOR_WHITE);
        } else {
            value.setColor(Graphics.COLOR_BLACK);
        }
        if (mValue != -500) {
            value.setText(mValue.format("%.2f"));
        } else {
            value.setText(mValue);
        }
           if (mWindSpeed != 0) {
            wind.setText(mWindSpeed.format("%.2f"));
        } else {
            wind.setText(mWindSpeed);
        }

        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
    }

}
