# SunKit

SunKit is a framework which calculates various Sun related data, such as:
 * sunrise, sunset and transit
 * Ascension
 * Zenith
 * Incidence
 * Azimuth
 * height
 * shadow length and direction

 SunKit supports two Sun Position Algorithms (SPA). One is from the german  [Wikipedia](https://de.wikipedia.org/wiki/Sonnenstand), the other is from   [NREL](http://rredc.nrel.gov/solar/codesandalgorithms/spa/). It is far more complex and more accurate.

 You can use SunKit to calculate the data above for one point in time or if you use the NREL SPA, you can let SunKit calculate data points for every hour, every minute or every second of a day. SunKit is then using the Apple Accelerate framework for faster processing.

 If you do not need all data points, you can choose the needed data points with the Fragments-Enums.
