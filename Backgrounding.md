## Backgrounding ##
Users have requested the ability to continue running transfers in the background, while using other applications or having the device locked. While this is not a native feature in iTransmission (yet), it can be quite easily accomplished by installing and configuring a few iOS add-ons (which users should have already; if not, they're useful for other applications as well.)

  * **Applications/Tweaks needed** - install these from Cydia:
    * [Backgrounder](http://cydia.saurik.com/package/backgrounder)
    * [LastApp](http://cydia.saurik.com/package/jp.ashikase.lastapp)
      * _Other applications/tweaks may need to be installed as a dependency, such as [Activator](http://cydia.saurik.com/package/libactivator); Cydia will install these automatically if needed._

## How to enable backgrounding for iTransmission ##
  1. Once installed from Cydia, go into the iOS Settings app, choose the entry for [LastApp](http://cydia.saurik.com/package/jp.ashikase.lastapp), and make sure the option "Backgrounding" is set to **ON**.
  1. Close the Settings app.
  1. Open the Backgrounder app configuration, and select "Overrides".
  1. Click the "Add" button in the upper right-hand side, and scroll to the entry for iTransmission.
    * Selecting the entry for iTransmission automatically returns the user to the Overrides section.
  1. Click the new iTransmission entry.
  1. Change the entry for "Backgrounding method" to "Backgrounder".
  1. Change the entry for "Backgrounding state" - "Enable at Launch" to **ON**.
  1. Change the entry for "Backgrounding state" - "Stay Enabled" to **ON**.
  1. Press the Home button on the device to exit. The device will respring to load the new Backgrounder settings.
iTransmission will now run in the background, even at the lock screen, and won't automatically pause any downloads when the user closes it and either starts a different application or locks the device.

To **exit** iTransmission completely when it's backgrounded, go to the app, then press and **hold** the Home button until the screen flashes "Backgrounding Disabled". iTransmission will exit, Backgrounder will not keep it running memory, and any transfers will enter a paused state.
## <font color='red'>This has been tested and verified working under iOS 4.3.3 and lower.</font> ##