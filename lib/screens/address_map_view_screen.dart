import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class AddressMapViewScreen extends StatefulWidget {
  final Map<String, dynamic> address;

  const AddressMapViewScreen({super.key, required this.address});

  @override
  State<AddressMapViewScreen> createState() => _AddressMapViewScreenState();
}

class _AddressMapViewScreenState extends State<AddressMapViewScreen> {
  late GoogleMapController _mapController;
  late LatLng _addressLocation;
  final Set<Marker> _markers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    // Try to extract coordinates from address if available
    double? latitude = widget.address['latitude'];
    double? longitude = widget.address['longitude'];

    // If no coordinates, try to get user's current location
    if (latitude == null || longitude == null) {
      try {
        // Check if location services are enabled
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          // Fallback to pharmacy location if location services disabled
          latitude = 7.1844;
          longitude = 125.6844;
        } else {
          // Check permission
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }

          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            // Get current location
            try {
              Position position = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.high,
                timeLimit: const Duration(seconds: 10),
              );
              latitude = position.latitude;
              longitude = position.longitude;
            } catch (e) {
              // Fallback to pharmacy location if getting position fails
              latitude = 7.1844;
              longitude = 125.6844;
            }
          } else {
            // Fallback to pharmacy location if permission denied
            latitude = 7.1844;
            longitude = 125.6844;
          }
        }
      } catch (e) {
        // Fallback to pharmacy location on any error
        latitude = 7.1844;
        longitude = 125.6844;
      }
    }

    _addressLocation = LatLng(latitude, longitude);

    // Create marker for the address
    _markers.add(
      Marker(
        markerId: MarkerId(widget.address['id'] ?? 'address'),
        position: _addressLocation,
        infoWindow: InfoWindow(
          title: widget.address['type'] ?? 'Address',
          snippet: widget.address['address'] ?? '',
        ),
      ),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(_addressLocation, 16),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied.')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission denied forever. '
              'Please enable it in app settings.',
            ),
          ),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final userLocation = LatLng(position.latitude, position.longitude);

      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(userLocation, 16),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navigated to your current location')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.address['type'] ?? 'Address'} Location'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _addressLocation,
                zoom: 16,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              compassEnabled: true,
              mapToolbarEnabled: true,
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'current_location',
            onPressed: _getCurrentLocation,
            tooltip: 'Go to current location',
            mini: true,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'address_location',
            onPressed: () {
              _mapController.animateCamera(
                CameraUpdate.newLatLngZoom(_addressLocation, 16),
              );
            },
            tooltip: 'Go to address',
            mini: true,
            child: const Icon(Icons.location_on),
          ),
        ],
      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.address['type'] ?? 'Address',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.address['address'] ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              widget.address['city'] ?? '',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            if (widget.address['phone'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      widget.address['phone'],
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
