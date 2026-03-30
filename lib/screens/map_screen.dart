import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  
  LatLng _userLocation = const LatLng(10.762622, 106.660172);
  LatLng _mapCenter = const LatLng(10.762622, 106.660172);
  
  double _currentRotation = 0.0;
  bool _isLoading = true;
  bool _isSatellite = false;
  bool _showTraffic = false;
  List<Marker> _markers = [];

  final String _osmUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  final String _satelliteUrl = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
  final String _trafficUrl = 'https://tile.waymarkedtrails.org/cycling/{z}/{x}/{y}.png'; 

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _fetchWastePoints(double lat, double lon) async {
    // 1. Mở rộng bán kính quét lên 0.05 độ (khoảng 5km) để dễ tìm thấy điểm hơn
    final String bbox = "(${lat - 0.05},${lon - 0.05},${lat + 0.05},${lon + 0.05})";
    final url = Uri.parse("https://overpass-api.de/api/interpreter?data=[out:json];node['amenity'~'waste_disposal|recycling|waste_basket']$bbox;out;");

    try {
      // 2. THÊM HEADER: "Giấy thông hành" bắt buộc để Overpass API không chặn
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'EcoSortApp_by_Jisy/1.0 (Flutter)', // Tên App của bạn
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List elements = data['elements'];

        // 3. Xử lý trường hợp API chạy thành công nhưng khu vực đó không có dữ liệu
        if (elements.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không tìm thấy điểm thu gom rác nào trong bán kính 5km.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        if (mounted) {
          setState(() {
            _markers = elements.map((e) {
              final tags = e['tags'] ?? {};
              return Marker(
                point: LatLng(e['lat'], e['lon']),
                width: 50,
                height: 50,
                child: GestureDetector(
                  onTap: () => _showPointDetails(tags),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.26), blurRadius: 8, offset: const Offset(0, 2))],
                      border: Border.all(color: Colors.green, width: 2.5),
                    ),
                    child: const Icon(Icons.recycling_rounded, color: Colors.green, size: 28),
                  ),
                ),
              );
            }).toList();
          });
        }
      } else {
        debugPrint("Lỗi API Overpass: Mã ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Lỗi tải data (Mất mạng hoặc API sập): $e");
    }
  }

  void _showPointDetails(Map tags) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(
              children: [
                const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.restore_from_trash, color: Colors.white)),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    tags['name'] ?? "Điểm bỏ rác cộng cộng",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            _buildInfoRow(Icons.category_outlined, "Loại rác chấp nhận", tags['recycling_type'] ?? tags['amenity']?.replaceAll('_', ' ') ?? "Rác tổng hợp"),
            _buildInfoRow(Icons.access_time, "Giờ hoạt động", tags['opening_hours'] ?? "Chưa có thông tin"),
            _buildInfoRow(Icons.location_on_outlined, "Mô tả", tags['description'] ?? "Vui lòng giữ vệ sinh chung tại điểm bỏ rác."),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Đã hiểu", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _determinePosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    if (mounted) {
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _mapCenter = _userLocation;
        _isLoading = false;
      });
      _mapController.move(_userLocation, 16);
      _fetchWastePoints(position.latitude, position.longitude);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mapCenter,
              initialZoom: 16,
              onPositionChanged: (MapPosition position, bool hasGesture) {
                if (position.center != null) {
                  _mapCenter = position.center!; // Lấy center từ MapPosition
                }
                final double currentRot = _mapController.camera.rotation;
                if (_currentRotation != currentRot) {
                  setState(() {
                    _currentRotation = currentRot;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: _isSatellite ? _satelliteUrl : _osmUrl,
                userAgentPackageName: 'com.example.phan_loai_rac_qua_hinh_anh',
              ),
              if (_showTraffic)
                Opacity(
                  opacity: 0.6,
                  child: TileLayer(
                    urlTemplate: _trafficUrl,
                    userAgentPackageName: 'com.example.phan_loai_rac_qua_hinh_anh',
                  ),
                ),
              MarkerLayer(markers: [
                Marker(
                  point: _userLocation,
                  width: 80,
                  height: 80,
                  child: _buildUserLocationMarker(),
                ),
                ..._markers,
              ]),
            ],
          ),
          
          Positioned(
            top: 50, left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(20), 
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(0, 5))]
              ),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
                  const Expanded(child: Text("EcoSort Maps", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.green))),
                  IconButton(
                    icon: Icon(_isSatellite ? Icons.map_rounded : Icons.satellite_alt_rounded, color: theme.primaryColor), 
                    onPressed: () => setState(() => _isSatellite = !_isSatellite)
                  ),
                  IconButton(
                    icon: Icon(Icons.traffic_rounded, color: _showTraffic ? Colors.orange : Colors.grey), 
                    onPressed: () => setState(() => _showTraffic = !_showTraffic)
                  ),
                ],
              ),
            ),
          ),

          if (_isLoading) const Center(child: CircularProgressIndicator(color: Colors.green)),
          
          Positioned(
            bottom: 100, right: 20,
            child: Column(
              children: [
                if (_currentRotation != 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: FloatingActionButton(
                      mini: true,
                      heroTag: "compass",
                      backgroundColor: Colors.white,
                      onPressed: () => _mapController.rotate(0),
                      child: Transform.rotate(
                        angle: -_currentRotation * (math.pi / 180),
                        child: const Icon(Icons.explore, color: Colors.redAccent, size: 28),
                      ),
                    ),
                  ),
                FloatingActionButton(
                  mini: true,
                  heroTag: "refresh",
                  backgroundColor: Colors.white,
                  onPressed: () => _fetchWastePoints(_mapCenter.latitude, _mapCenter.longitude),
                  child: const Icon(Icons.refresh_rounded, color: Colors.green),
                ),
                const SizedBox(height: 15),
                FloatingActionButton(
                  heroTag: "location",
                  backgroundColor: theme.primaryColor,
                  onPressed: _determinePosition,
                  child: const Icon(Icons.my_location_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserLocationMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        TweenAnimationBuilder(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(seconds: 2),
          builder: (context, value, child) => Container(
            width: 45 * (1 + value),
            height: 45 * (1 + value),
            decoration: BoxDecoration(
              shape: BoxShape.circle, 
              color: Colors.blue.withValues(alpha: 0.3 * (1 - value))
            ),
          ),
          onEnd: () => setState(() {}),
        ),
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            color: Colors.white, 
            shape: BoxShape.circle, 
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.26), blurRadius: 5)]
          ),
          child: Center(
            child: Container(
              width: 12, height: 12, 
              decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)
            ),
          ),
        ),
      ],
    );
  }
}
