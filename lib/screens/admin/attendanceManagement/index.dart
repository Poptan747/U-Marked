import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class googeMapTest extends StatefulWidget {
  const googeMapTest({Key? key}) : super(key: key);

  @override
  State<googeMapTest> createState() => _googeMapTestState();
}

class _googeMapTestState extends State<googeMapTest> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Highlighted Area on Google Maps'),
      ),
      body: GoogleMap(
        onMapCreated: (controller) {
          setState(() {
            // mapController = controller;
          });
        },
        initialCameraPosition: CameraPosition(
          target: LatLng(37.7749, -122.4194), // Initial map center
          zoom: 12.0, // Initial zoom level
        ),
        polygons: Set.from([
          Polygon(
            polygonId: PolygonId('highlightedArea'),
            points: [
              LatLng(1.5331988034221635, 103.6828984846777),
              LatLng(1.533319427323412, 103.68277217892413),
              LatLng(1.533744429243514, 103.68315899029903),
              LatLng(1.5336283146701633, 103.68329657335201),
            ],
            strokeWidth: 2,
            strokeColor: Colors.red,
            fillColor: Colors.red.withOpacity(0.3),
          ),
        ]),
      ),
    );
  }
}
