import 'package:flutter/material.dart';



BoxDecoration loginBackgroundDecoration =
const BoxDecoration(
  // border: Border.all(color: Colors.black),
    gradient: LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
        colors: [
          Colors.white,
          Color(0xFF066cff),
        ],
      stops: [0.5,0.9]
    )
);

BoxDecoration homeBackgroundDecoration =
BoxDecoration(
  // border: Border.all(color: Colors.black),
    gradient: LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Colors.lightBlue.shade500,
          Color(0xFF066cff),
        ],
    )
);

BoxDecoration whiteBackgroundDecoration =
BoxDecoration(
  // border: Border.all(color: Colors.black),
    gradient: LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        Colors.white,
        Colors.white
      ],
    ),
);

// BoxDecoration homeBackgroundDecoration =
// const BoxDecoration(
//     gradient: LinearGradient(
//         begin: Alignment.bottomCenter,
//         end: Alignment.topCenter,
//         colors: [
//           Color(0xFF066cff),
//           Color(0xFF066cff),
//         ],
//         stops: [0.0,0.5]
//     )
// );

BoxDecoration myClassAppBarBackgroundDecoration =
BoxDecoration(
  // border: Border.all(color: Colors.black),
    gradient: LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [
          Color(0xFF066cff),
          Colors.blue.shade900,
          Color(0xFF066cff),
        ],
    )
);

