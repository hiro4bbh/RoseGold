#  RoseGold - An Example Ray-Tracing Implementation on macOS and iOS

Copyright 2019- Tatsuhiro Aoshima (hiro4bbh@gmail.com).

## Introduction

RoseGold is an example ray-tracing implementation on macOS and iOS.
The several features are implemented:

- SmallPT-based simple ray-tracing __(Beason 2010)__ running on Metal Compute Pipeline __(Yi 2018)__.
- Joystick implementation for moving the camera and sliding to rotating the camera (iOS).
- An well-known cute mascot _kixby_.

If you are interested in ray-tracing, I will recommend you to refer __Pharr+ (2018)__.
I have no plan to maintain RoseGold ...

There are too many problems, for example:

- Support more object primitives other than the simple balls __(Pharr+ 2018, chapter 3)__.
- Ensure the errors of the floating number operations __(Pharr+ 2018, section 3.9)__.
- Implement acceleration structures for testing object intersections faster __(Pharr+ 2018, chapter 4)__.
- Implement upsampling for reducing the noise especially in a specular reflecting balls __(Pharr+ 2018, chapter 7)__.
- Implement volume rendering and more efficient bidirectional methods __(Pharr+ 2018, chapter 15 and 16)__.


## Screenshots

### macOS Mojave 10.14.3 (MacBook Early 2016)

![MacBook (Early 2016)](Resources/RoseGold-MacBookEarly2016-1519.png "MacBook (Early 2016)")

- Total 1519 frames (about 20 fps)

### iOS 12.1.2 (iPhone XR 2018)

![iPhone XR (2018)](Resources/RoseGold-iPhoneXR-about1500.png "iPhone XR (2018)")

- About 1500 frames (about 50 fps)

## References
- __Beason__, K. __(2010)__ _"smallpt: Global Illumination in 99 lines of C++."_ Retrieved on 2019/2/12, [http://www.kevinbeason.com/smallpt/](http://www.kevinbeason.com/smallpt/).
- __Pharr__, M., W. Jakob, and G. Humphreys. __(2018)__ _Physically Based Rendering From Theory to Implementation Third Edition._ (online version at [http://www.pbr-book.org/3ed-2018](http://www.pbr-book.org/3ed-2018) retrieved on 2019/2/12)
- __Yi__, X. __(2018)__ _"imxieyi/SmallPT-Metal: SmallPT port to iOS in Metal."_ Retrieved on 2019/2/12. [https://github.com/imxieyi/SmallPT-Metal](https://github.com/imxieyi/SmallPT-Metal).
