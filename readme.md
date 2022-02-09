# Windsock

![](windsock.png) 

Connect IQ data field which displays wind direction relative to the direction you're moving. Designed for the Edge head units.

Requires Connect IQ 3.2 and higher and works* on following devices:
 
  - Edge 530
  - Edge 830
  - Edge 1030
  - Edge 1030+

Data field displays direction the wind is coming at you and wind speed (units depend on your device settings).

![](data_field.png)

Arrow will change the color from green to red depending on the wind strength and direction, i.e. tailwind is always good(green) and light headwind is not a big deal either (green), but stronger headwind will be shown in orange or red.

The windsock data field uses Garmin provided weather data, make sure it is enabled in the Garmin Connect Mobile for your Edge device. 

## Note about correctness

Sometimes there is no wind data in the current weather conditions reported by Garmin, in this case Windsock will try to use closest forecast value. If that's happening, wind direction indicator will display additional orange band.
![](data_field_forecast.png)

Garmin devices update the weather every 15-30 minutes, so the wind strength and direction shown by Windsock can become stale. Treat it as approximate suggestion, not like definite truth.

## License

Windsock is an open source project and distributed under GPLv3 license. You can find the license in the [license.md](license.md) file

-----
\* should work, at least
