# MODE-iOSSDK

[![CI Status](http://img.shields.io/travis/Naoki Takano/MODE-iOSSDK.svg?style=flat)](https://travis-ci.org/Naoki Takano/MODE-iOSSDK)
[![Version](https://img.shields.io/cocoapods/v/MODE-iOSSDK.svg?style=flat)](http://cocoapods.org/pods/MODE-iOSSDK)
[![License](https://img.shields.io/cocoapods/l/MODE-iOSSDK.svg?style=flat)](http://cocoapods.org/pods/MODE-iOSSDK)
[![Platform](https://img.shields.io/cocoapods/p/MODE-iOSSDK.svg?style=flat)](http://cocoapods.org/pods/MODE-iOSSDK)

## Overview
MODE-iOSDK provides API call wrapper to [MODE cloud](http://www.tinkermode.com) and handles the data to connect between iOS app and devices and smart modules.

You can write MODE cloud iOS app without this SDK, but it makes developers more easy to use MODE cloud service to communicate each other with IoT devices.

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

You need to use the SDK on at least iOS7 platform. The library depends on [Mantle](https://github.com/Mantle/Mantle) and [SocketRocket](https://github.com/square/SocketRocket). See more detail `MODE-iOSSDK.podspec`.

## Installation

MODE-iOSSDK is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "MODE-iOSSDK"
```

## Classes

All classes start with `MODE` as prefix.

### MODEAppAPI
`MODEAppAPI` is API wrappter class to call MODE cloud service from `App`. Each function is corresponding to [each MODE cloud API](http://dev.tinkermode.com/api/api_reference.html).

All function call is aysnc, so you need to pass callback function as `Objective-C` block and check `NSError` object when the function is called. Whenever an error happens, `NSError` has `nil`. Otherwise it means success to call.

All callback block is called in main GUI thread as default behavior. So you can call other UI related API from callback. If you want to change the behavior, please set `EXECUTE_BLOCK_IN_MAIN_THREAD` macro value to `0` in `ModeApp.m`.

The detail parameter meaning is written in `ModeApp.h` as comments.

### MODEData
`ModeData` is data schema class and each class corresponding to each JSON data at [Data Model Reference](http://dev.tinkermode.com/api/model_reference.html). All JSON data is parsed and stored to each properties as proper type in the class.  But `eventData` in `MODEDeviceEvent` is `NSDictionary`, because it can be defined by developers.

The classes are sub-classes of `MTLModel`, so you can use nifty [Mantle](https://github.com/Mantle/Mantle) functions.

### MODEEventListener
`MODEEventListener` is a class to receive events delivered by `MODE cloud`. So you need to keep connection to `MODE cloud` and don't delete the object while you are waiting for events.


## Simple example

The following is the simple example code to listen the events. The sample code doesn't check errors, so you need more error checks if you want to reuse the code.

You need to define project already on `MODE cloud` console page. Also you need to define `appId` on the page. Here we assume, projectId is `1234` and `appId` is `SampleApp1`

~~~
    // You have to trigger somewhere with button or menu.
    [MODEAppAPI initiateAuthenticationWithSMS:1234 phoneNumber:@"YOUR PHONE NUMBER"
        completion:(void(^)(MODESMSMessageReceipt* obj, NSError* err)){ /* Need to error check */ };
~~~

Then you can get verification code via SMS.

~~~
  MODEEventListener* listener = nil; // Maybe you should define as object property.*
  [MODEAppAPI authenticateWithCode:1234 phoneNumber:@"YOUR PHONE NUMBER" appId:@"SampleApp1" code:@"CODE VIA SMS"
      completion:(void(^)(MODEClientAuthentication* auth, NSError* err)){

        listner = [[MODEEventListener alloc] initWithClientAuthentication:auth]; 

        [listener startListenToEvents:^(MODEDeviceEvent* event, NSError* err){
          if (event) {
            NSLog(@"Event: %@", event);
          }

        }];
      }];
~~~

## Author

Naoki Takano, honten@tinkermode.com

## License

MODE-iOSSDK is available under the MIT license. See the LICENSE file for more info.
