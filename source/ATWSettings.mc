import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application.Properties;

var unitsNameId = -1;

function getUnitsName() as String {
    if (unitsNameId < 0) {
        unitsNameId = Properties.getValue("units");
    }
    switch (unitsNameId) {
        case 1:
            return Rez.Strings.unitKph;
        case 2:
            return Rez.Strings.unitMph;
        default:
            return Rez.Strings.unitMps;
    }
}

class SettingsView extends WatchUi.View {

    private var title;

    function initialize() {
        View.initialize();

        title = Application.loadResource(Rez.Strings.pressMenu) as String;
    }

    function onUpdate(dc) {
        dc.clearClip();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2 - 30, Graphics.FONT_SMALL, title, Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class SettingsDelegate extends WatchUi.BehaviorDelegate {

    private var menuLabel as String;

    function initialize() {
        BehaviorDelegate.initialize();

        menuLabel = Application.loadResource(Rez.Strings.UnitsMenuLabel) as String;
    }

    function onMenu() {
        var menu = new SettingsMenu();
        var sublabel = getUnitsName();
        menu.addItem(new MenuItem(
            menuLabel,
            sublabel,
            "menuItemId",
            {}
        ));

        WatchUi.pushView(menu, new SettingsMenuDelegate(), WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

}
