import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../service/locatie_service.dart';
import '../sabloane/locatie_sablon.dart';
import 'location_details_page.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final LocatieService _locatieService = LocatieService();

  List<SablonLocatie> _locatii = [];
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  String _selectedCategory = 'Toate';

  final List<String> _categorii = [
    'Toate',
    'Castel',
    'Muzeu',
    'Mănăstire',
    'Parc',
    'Traseu',
    'Lac',
  ];

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final locatii = await _locatieService.getAllLocatii();

    if (!mounted) return;

    setState(() {
      _locatii = locatii;
    });

    _buildMarkers();
  }

  void _buildMarkers() {
    final filtered = _locatii.where((locatie) {
      final hasCoordinates =
          locatie.latitudine != 0 && locatie.longitudine != 0;

      final matchesCategory =
          _selectedCategory == 'Toate' ||
          locatie.categorie == _selectedCategory;

      return hasCoordinates && matchesCategory;
    }).toList();

    final markers = filtered.map((locatie) {
      return Marker(
        markerId: MarkerId(locatie.id),
        position: LatLng(locatie.latitudine, locatie.longitudine),
        icon: _getMarkerColor(locatie.categorie),
        infoWindow: InfoWindow(
          title: locatie.nume,
          snippet:
              '${locatie.oras}, ${locatie.judet} • ⭐ ${locatie.rating.toStringAsFixed(1)}',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LocationDetailsPage(locatie: locatie),
              ),
            );
          },
        ),
      );
    }).toSet();

    setState(() {
      _markers = markers;
    });
  }

  BitmapDescriptor _getMarkerColor(String categorie) {
    switch (categorie) {
      case 'Castel':
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueViolet,
        );
      case 'Muzeu':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      case 'Mănăstire':
        return BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueOrange,
        );
      case 'Parc':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'Traseu':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case 'Lac':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  Future<void> _goToMyLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activează locația telefonului.')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permisiunea pentru locație a fost refuzată.'),
        ),
      );
      return;
    }

    final position = await Geolocator.getCurrentPosition();

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hartă atracții turistice')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToMyLocation,
        icon: const Icon(Icons.my_location),
        label: const Text('Locația mea'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 55,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _categorii.length,
              itemBuilder: (context, index) {
                final categorie = _categorii[index];

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(categorie),
                    selected: _selectedCategory == categorie,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = categorie;
                      });

                      _buildMarkers();
                    },
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(45.9432, 24.9668),
                zoom: 6.5,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              markers: _markers,
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
              zoomControlsEnabled: true,
            ),
          ),
        ],
      ),
    );
  }
}
