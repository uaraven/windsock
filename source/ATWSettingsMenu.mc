using Toybox.WatchUi;
using Toybox.Application.Storage;


class SettingsMenu extends WatchUi.Menu2 {
    
    function initialize() {
        Menu2.initialize(null);        
        Menu2.setTitle(Application.loadResource(Rez.Strings.SettingsMenuTitle) as String);
    }
}

class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(menuItem) {
        unitsNameId += 1;
        if (unitsNameId > 2) {
            unitsNameId = 0;
        }
        Storage.setValue("units", unitsNameId);
        menuItem.setSubLabel(getUnitsName());
    }
}