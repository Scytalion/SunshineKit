# SunshineKit

SunshineKit is a framework which calculates various Sun related data, such as:
 * sunrise, sunset and transit
 * Ascension
 * Zenith
 * Incidence
 * Azimuth
 * height
 * shadow length and direction

 SunshineKit supports two Sun Position Algorithms (SPA). One is from the german  [Wikipedia](https://de.wikipedia.org/wiki/Sonnenstand), the other is from   [NREL](http://rredc.nrel.gov/solar/codesandalgorithms/spa/). The NREL SPA is far more complex but also more accurate.

 You can use SunshineKit to calculate the data above for one point in time or if you use the NREL SPA, you can let SunshineKit calculate data points for every hour, every minute or every second of a day. SunshineKit is then using the Apple Accelerate framework for faster processing.

 If you do not need all data points, you can choose the needed data points with the Fragments-Enums.
