import 'dart:convert';
import 'dart:math' as math;
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:phan_loai_rac_qua_hinh_anh/utils/env.dart';

class MapScreen extends StatefulWidget {
  final bool showBackButton;
  const MapScreen({super.key, this.showBackButton = true});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  
  LatLng _userLocation = const LatLng(10.762622, 106.660172);
  LatLng _mapCenter = const LatLng(10.762622, 106.660172);
  
  double _currentRotation = 0.0;
  bool _isLoading = true;
  String _mapStyle = 'voyager'; // 'voyager', 'positron', 'dark', 'satellite'
  bool _showTraffic = false;
  bool _isFetchingWaste = false;
  DateTime? _lastFetchTime;
  List<Marker> _markers = [];
  List<dynamic> _searchResults = [];
  bool _isLoadingSearch = false;
  LatLng? _selectedPinLocation;
  bool _isSelectingLocationOnMap = false;
  String _tempGeocodedAddress = "";
  bool _isLoadingGeocoding = false;

  List<LatLng> _routePoints = [];
  bool _isRouting = false;
  String? _routeDistance;
  String? _routeDuration;

  Future<void> _fetchRouteOSRM(LatLng destination, String pointName) async {
    setState(() {
      _isRouting = true;
    });

    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/${_userLocation.longitude},${_userLocation.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'EcoSortApp_by_Jisy/1.0 (Flutter)',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List?;

        if (routes != null && routes.isNotEmpty) {
          final firstRoute = routes[0];
          final geometry = firstRoute['geometry'] as Map<String, dynamic>?;
          final coords = geometry?['coordinates'] as List?;

          if (coords != null) {
            final List<LatLng> points = coords.map((c) {
              final list = c as List;
              return LatLng((list[1] as num).toDouble(), (list[0] as num).toDouble());
            }).toList();

            final double distMeters = (firstRoute['distance'] as num).toDouble();
            final double durSecs = (firstRoute['duration'] as num).toDouble();

            final String distStr = distMeters >= 1000
                ? '${(distMeters / 1000).toStringAsFixed(1)} km'
                : '${distMeters.round()} m';
            final String durStr = '${(durSecs / 60).round()} phút';

            if (mounted) {
              setState(() {
                _routePoints = points;
                _routeDistance = distStr;
                _routeDuration = durStr;
                _isRouting = false;
              });

              _mapController.move(destination, 15);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã vẽ đường đi OSRM đến $pointName ($distStr - $durStr) 🧭'),
                  backgroundColor: Colors.blueAccent,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('[OSRM] Lỗi tải đường đi: $e');
    }

    if (mounted) {
      setState(() => _isRouting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể lấy đường đi OSRM. Bạn có thể mở Google Maps!'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _launchGoogleMapsDirections(LatLng destination) async {
    final googleMapsAppUrl = Uri.parse(
      'google.navigation:q=${destination.latitude},${destination.longitude}',
    );
    final googleMapsWebUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}',
    );

    try {
      if (await canLaunchUrl(googleMapsAppUrl)) {
        await launchUrl(googleMapsAppUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(googleMapsWebUrl)) {
        await launchUrl(googleMapsWebUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (await canLaunchUrl(googleMapsWebUrl)) {
        await launchUrl(googleMapsWebUrl, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở ứng dụng Google Maps.')),
        );
      }
    }
  }

  String get _voyagerUrl {
    final key = Env.stadiaMapsApiKey;
    return key.isNotEmpty
        ? 'https://tiles.stadiamaps.com/tiles/outdoors/{z}/{x}/{y}.png?api_key=$key'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  String get _positronUrl {
    final key = Env.stadiaMapsApiKey;
    return key.isNotEmpty
        ? 'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}.png?api_key=$key'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  String get _darkMatterUrl {
    final key = Env.stadiaMapsApiKey;
    return key.isNotEmpty
        ? 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}.png?api_key=$key'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  String get _satelliteUrl {
    final key = Env.stadiaMapsApiKey;
    return key.isNotEmpty
        ? 'https://tiles.stadiamaps.com/tiles/alidade_satellite/{z}/{x}/{y}.jpg?api_key=$key'
        : 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
  }

  final String _trafficUrl = 'https://tile.waymarkedtrails.org/cycling/{z}/{x}/{y}.png'; 

  @override
  void initState() {
    super.initState();
    // Tự động chuyển sang bản đồ tối nếu giao diện hệ thống là chế độ tối
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        setState(() {
          _mapStyle = isDark ? 'dark' : 'voyager';
        });
      }
    });
    _determinePosition();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isLoadingSearch = true;
      _searchResults = [];
    });

    final url = Uri.parse("https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1");

    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'EcoSortApp_by_Jisy/1.0 (Flutter)',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _searchResults = data;
          });
        }
      }
    } catch (e) {
      debugPrint("Error searching location: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSearch = false;
        });
      }
    }
  }

  Marker _buildMarkerFromTags(double lat, double lon, Map tags) {
    final String amenity = tags['amenity'] ?? 'recycling';

    IconData markerIcon;
    Color markerColor;
    String title;

    if (amenity == 'waste_disposal') {
      markerIcon = Icons.delete_sweep_rounded;
      markerColor = Colors.blue;
      title = tags['name'] ?? "Trạm thu gom/đổ rác";
    } else if (amenity == 'waste_basket') {
      markerIcon = Icons.delete_outline_rounded;
      markerColor = Colors.orange;
      title = tags['name'] ?? "Thùng rác công cộng";
    } else {
      markerIcon = Icons.recycling_rounded;
      markerColor = Colors.green;
      title = tags['name'] ?? "Điểm thu gom tái chế";
    }

    final Map<String, dynamic> tagsWithPoint = Map<String, dynamic>.from(tags);
    tagsWithPoint['point'] = LatLng(lat, lon);
    if (tagsWithPoint['name'] == null) {
      tagsWithPoint['name_display'] = title;
    }

    return Marker(
      point: LatLng(lat, lon),
      width: 50,
      height: 50,
      child: GestureDetector(
        onTap: () => _showPointDetails(tagsWithPoint),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
            border: Border.all(color: markerColor, width: 2.5),
          ),
          child: Icon(markerIcon, color: markerColor, size: 28),
        ),
      ),
    );
  }

  Future<List<Marker>> _fetchSupabaseCollectionPoints() async {
    final List<Marker> supabaseMarkers = [];
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('collection_points')
          .select('id, name, description, address, point_type, latitude, longitude, location, is_verified')
          .eq('is_verified', true);

      for (final item in response) {
        double? pLat;
        double? pLon;

        if (item['latitude'] != null && item['longitude'] != null) {
          pLat = (item['latitude'] as num).toDouble();
          pLon = (item['longitude'] as num).toDouble();
        } else if (item['location'] != null && item['location'] is String) {
          final locStr = item['location'] as String;
          final match = RegExp(r'POINT\(([-?\d.]+)\s+([-?\d.]+)\)', caseSensitive: false).firstMatch(locStr);
          if (match != null) {
            pLon = double.tryParse(match.group(1)!);
            pLat = double.tryParse(match.group(2)!);
          }
        }

        if (pLat != null && pLon != null) {
          final Map<String, dynamic> tags = {
            'amenity': item['point_type'] ?? 'recycling',
            'name': item['name'] ?? 'Điểm thu gom',
            'name_display': item['name'] ?? 'Điểm thu gom',
            'description': item['address'] != null && (item['address'] as String).isNotEmpty
                ? '${item['description'] ?? ''}\n📍 ${item['address']}'
                : item['description'],
            'recycling_type': item['point_type'] == 'waste_disposal'
                ? 'Rác tổng hợp'
                : (item['point_type'] == 'waste_basket' ? 'Rác công cộng' : 'Rác tái chế ♻️'),
          };
          supabaseMarkers.add(_buildMarkerFromTags(pLat, pLon, tags));
        }
      }
    } catch (e) {
      debugPrint('[SUPABASE] Lỗi tải collection_points từ Supabase: $e');
    }
    return supabaseMarkers;
  }

  Future<void> _fetchWastePoints(double lat, double lon) async {
    if (_isFetchingWaste) return;
    final now = DateTime.now();
    if (_lastFetchTime != null && now.difference(_lastFetchTime!) < const Duration(seconds: 5)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chờ vài giây trước khi tải lại.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    setState(() => _isFetchingWaste = true);
    _lastFetchTime = now;

    // 1. Truy vấn toàn bộ điểm thu gom rác từ Supabase database
    final List<Marker> allMarkers = await _fetchSupabaseCollectionPoints();

    // 2. Truy vấn bổ sung điểm rác cộng đồng từ OpenStreetMap (nếu có)
    final String bbox = "(${lat - 0.05},${lon - 0.05},${lat + 0.05},${lon + 0.05})";
    final url = Uri.parse("https://overpass-api.de/api/interpreter?data=[out:json];node['amenity'~'waste_disposal|recycling|waste_basket']$bbox;out;");

    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'EcoSortApp_by_Jisy/1.0 (Flutter)',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List elements = data['elements'];

        for (final e in elements) {
          final tags = e['tags'] ?? {};
          allMarkers.add(_buildMarkerFromTags((e['lat'] as num).toDouble(), (e['lon'] as num).toDouble(), tags));
        }
      }
    } catch (e) {
      debugPrint("Lỗi tải data OSM: $e");
    }

    if (mounted) {
      setState(() {
        _markers = allMarkers;
      });

      if (allMarkers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chưa có dữ liệu điểm thu gom rác tại khu vực này.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        debugPrint('✅ Đã nạp ${allMarkers.length} điểm thu gom rác từ Supabase & OSM!');
      }
    }

    if (mounted) setState(() => _isFetchingWaste = false);
  }

  void _showPointDetails(Map tags) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1C1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4, 
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300], 
                    borderRadius: BorderRadius.circular(2)
                  )
                )
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: tags['amenity'] == 'waste_disposal' 
                        ? Colors.blue 
                        : (tags['amenity'] == 'waste_basket' ? Colors.orange : Colors.green), 
                    child: Icon(
                      tags['amenity'] == 'waste_disposal' 
                          ? Icons.delete_sweep_rounded 
                          : (tags['amenity'] == 'waste_basket' ? Icons.delete_outline_rounded : Icons.recycling_rounded), 
                      color: Colors.white
                    )
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      tags['name'] ?? tags['name_display'] ?? "Điểm bỏ rác",
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 30),
              _buildInfoRow(
                Icons.category_outlined, 
                "Loại rác chấp nhận", 
                tags['recycling_type'] ?? tags['amenity']?.replaceAll('_', ' ') ?? "Rác tổng hợp",
                isDark
              ),
              _buildInfoRow(
                Icons.access_time, 
                "Giờ hoạt động", 
                tags['opening_hours'] ?? "Chưa có thông tin",
                isDark
              ),
              _buildInfoRow(
                Icons.location_on_outlined, 
                "Mô tả", 
                tags['description'] ?? "Vui lòng giữ vệ sinh chung tại điểm bỏ rác.",
                isDark
              ),
              const SizedBox(height: 30),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (tags['point'] is LatLng) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.navigation_rounded, size: 20),
                        label: Text(
                          _isRouting ? 'Đang tính...' : 'Vẽ đường OSRM',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: _isRouting
                            ? null
                            : () {
                                final LatLng pt = tags['point'] as LatLng;
                                final String name = tags['name'] ?? tags['name_display'] ?? 'Điểm bỏ rác';
                                Navigator.pop(context);
                                _fetchRouteOSRM(pt, name);
                              },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.green, width: 1.5),
                          foregroundColor: Colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.map_rounded, size: 20),
                        label: const Text(
                          'Google Maps',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          final LatLng pt = tags['point'] as LatLng;
                          _launchGoogleMapsDirections(pt);
                        },
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Đã hiểu", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      }
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value, bool isDark) {
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
                Text(
                  title, 
                  style: TextStyle(
                    fontSize: 12, 
                    color: isDark ? Colors.grey[400] : Colors.grey, 
                    fontWeight: FontWeight.bold
                  )
                ),
                Text(
                  value, 
                  style: TextStyle(
                    fontSize: 15, 
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87
                  )
                ),
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

  Widget _buildStyleCard(String styleId, String name, IconData icon, Color previewColor) {
    final isSelected = _mapStyle == styleId;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _mapStyle = styleId;
        });
        Navigator.pop(context);
      },
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: previewColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? theme.primaryColor : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
                width: isSelected ? 3 : 1.5,
              ),
              boxShadow: isSelected 
                  ? [BoxShadow(color: theme.primaryColor.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 1)]
                  : null,
            ),
            child: Icon(
              icon, 
              color: isSelected ? theme.primaryColor : (isDark ? Colors.white70 : Colors.black87), 
              size: 28
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? theme.primaryColor : (isDark ? Colors.white70 : Colors.black87),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _onMapPositionChanged(MapPosition position, bool hasGesture) {
    if (position.center != null) {
      _mapCenter = position.center!;
    }
    final double currentRot = _mapController.camera.rotation;
    if (_currentRotation != currentRot) {
      setState(() {
        _currentRotation = currentRot;
      });
    }

    if (_isSelectingLocationOnMap) {
      setState(() {
        _isLoadingGeocoding = true;
      });
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
        _geocodeSelectionCenter();
      });
    }
  }

  Future<void> _geocodeSelectionCenter() async {
    if (!mounted || !_isSelectingLocationOnMap) return;
    setState(() {
      _isLoadingGeocoding = true;
    });
    try {
      final url = Uri.parse("https://nominatim.openstreetmap.org/reverse?lat=${_mapCenter.latitude}&lon=${_mapCenter.longitude}&format=json");
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'EcoSortApp_by_Jisy/1.0 (Flutter)',
          'Accept': 'application/json',
        },
      );
      if (mounted && _isSelectingLocationOnMap) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            _tempGeocodedAddress = data['display_name'] ?? "Không tìm thấy địa chỉ";
            _isLoadingGeocoding = false;
          });
        } else {
          setState(() {
            _tempGeocodedAddress = "Không tìm thấy địa chỉ (Lỗi API)";
            _isLoadingGeocoding = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error geocoding selection center: $e");
      if (mounted) {
        setState(() {
          _isLoadingGeocoding = false;
        });
      }
    }
  }

  void _confirmSelectedLocation() {
    setState(() {
      _selectedPinLocation = _mapCenter;
      _isSelectingLocationOnMap = false;
    });
    _showAddPointDialog();
  }

  void _cancelMapSelection() {
    setState(() {
      _isSelectingLocationOnMap = false;
    });
  }

  void _onAddPointPressed() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1C1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4, 
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300], 
                    borderRadius: BorderRadius.circular(2)
                  )
                )
              ),
              const SizedBox(height: 20),
              Text(
                "Đóng góp điểm rác mới",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Vui lòng chọn phương thức xác định vị trí cho điểm đóng góp mới:",
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  child: const Icon(Icons.gps_fixed_rounded, color: Colors.blue),
                ),
                title: Text(
                  "Sử dụng vị trí GPS hiện tại",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: const Text("Hệ thống sẽ lấy tọa độ GPS chính xác tại vị trí của bạn"),
                onTap: () async {
                  Navigator.pop(context);
                  _startGpsContribution();
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                  child: const Icon(Icons.pin_drop_rounded, color: Colors.redAccent),
                ),
                title: Text(
                  "Chọn vị trí bất kỳ trên bản đồ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: const Text("Di chuyển bản đồ để ghim vị trí mong muốn"),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _isSelectingLocationOnMap = true;
                    _tempGeocodedAddress = "";
                  });
                  _geocodeSelectionCenter();
                },
              ),
              if (_selectedPinLocation != null) ...[
                const SizedBox(height: 8),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                    child: const Icon(Icons.check_circle_rounded, color: Colors.green),
                  ),
                  title: Text(
                    "Sử dụng vị trí đã ghim trước đó",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    "Tọa độ: (${_selectedPinLocation!.latitude.toStringAsFixed(6)}, ${_selectedPinLocation!.longitude.toStringAsFixed(6)})"
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddPointDialog();
                  },
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _startGpsContribution() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: const Row(
            children: [
              CircularProgressIndicator(color: Colors.green),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  "Đang xác định vị trí GPS...",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        );
      },
    );

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Quyền truy cập vị trí bị từ chối.')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quyền truy cập vị trí bị từ chối vĩnh viễn. Vui lòng bật trong Cài đặt.')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
          _selectedPinLocation = null;
        });
        Navigator.pop(context);
        _showAddPointDialog();
      }
    } catch (e) {
      debugPrint("Error getting GPS position: $e");
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xác định vị trí: $e. Sẽ dùng vị trí mặc định.')),
        );
        _showAddPointDialog();
      }
    }
  }

  Future<void> _showAddPointDialog() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đóng góp điểm thu gom rác!')),
      );
      return;
    }

    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedType = 'recycling';
    File? pickedImage;
    bool isSubmitting = false;

    // Ưu tiên dùng vị trí đã ghim, nếu không thì dùng GPS hiện tại của user
    final LatLng contributionLocation = _selectedPinLocation ?? _userLocation;
    final bool isUsingGps = _selectedPinLocation == null;

    if (!isUsingGps && _tempGeocodedAddress.isNotEmpty) {
      addressController.text = _tempGeocodedAddress;
    } else {
      try {
        final url = Uri.parse("https://nominatim.openstreetmap.org/reverse?lat=${contributionLocation.latitude}&lon=${contributionLocation.longitude}&format=json");
        final response = await http.get(url, headers: {'User-Agent': 'EcoSortApp_by_Jisy/1.0'});
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          addressController.text = data['display_name'] ?? "";
        }
      } catch (_) {}
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1C1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4, 
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[700] : Colors.grey[300], 
                          borderRadius: BorderRadius.circular(2)
                        )
                      )
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(Icons.add_location_alt_rounded, color: theme.primaryColor, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          "Đóng góp điểm rác mới",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          isUsingGps ? Icons.gps_fixed_rounded : Icons.pin_drop_rounded, 
                          color: isUsingGps ? Colors.blue : Colors.redAccent, 
                          size: 14
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isUsingGps 
                                ? "Vị trí: Lấy theo định vị GPS hiện tại của bạn" 
                                : "Vị trí: Đã ghim tùy chọn trên bản đồ",
                            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "Tọa độ: (${contributionLocation.latitude.toStringAsFixed(6)}, ${contributionLocation.longitude.toStringAsFixed(6)})",
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const Divider(height: 30),
                    
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        labelText: "Tên địa điểm (Ví dụ: Thùng rác công viên)*",
                        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: addressController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        labelText: "Địa chỉ cụ thể*",
                        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: descriptionController,
                      maxLines: 2,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        labelText: "Mô tả / Loại rác chấp nhận",
                        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      dropdownColor: isDark ? const Color(0xFF2A2D31) : Colors.white,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        labelText: "Loại điểm bỏ rác*",
                        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                        border: const OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'recycling', child: Text("Điểm thu gom tái chế")),
                        DropdownMenuItem(value: 'waste_disposal', child: Text("Trạm thu gom/đổ rác lớn")),
                        DropdownMenuItem(value: 'waste_basket', child: Text("Thùng rác công cộng")),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.camera_alt_rounded),
                            label: const Text("Chụp ảnh thực tế"),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              final picker = ImagePicker();
                              final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
                              if (image != null) {
                                setDialogState(() {
                                  pickedImage = File(image.path);
                                });
                              }
                            },
                          ),
                        ),
                        if (pickedImage != null) ...[
                          const SizedBox(width: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              pickedImage!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ],
                    ),
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
                        onPressed: isSubmitting 
                            ? null 
                            : () async {
                                final name = nameController.text.trim();
                                final address = addressController.text.trim();
                                
                                if (name.isEmpty || address.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Vui lòng điền đầy đủ Tên và Địa chỉ!')),
                                  );
                                  return;
                                }

                                setDialogState(() => isSubmitting = true);

                                try {
                                  final supabase = Supabase.instance.client;
                                  String? uploadedUrl;

                                  if (pickedImage != null) {
                                    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
                                    final imagePath = 'crowdsourced/${user.id}/$fileName';
                                    
                                    await supabase.storage.from('waste-reports').upload(
                                      imagePath,
                                      pickedImage!,
                                      fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
                                    );
                                    
                                    uploadedUrl = supabase.storage.from('waste-reports').getPublicUrl(imagePath);
                                  }

                                  final String locationGeo = 'POINT(${contributionLocation.longitude} ${contributionLocation.latitude})';

                                  await supabase.from('collection_points').insert({
                                    'name': name,
                                    'description': descriptionController.text.trim(),
                                    'address': address,
                                    'point_type': selectedType,
                                    'location': locationGeo,
                                    'image_url': uploadedUrl,
                                    'is_verified': false,
                                    'created_by': user.id,
                                  });

                                  await supabase.rpc('rpc_award_points', params: {
                                    'p_delta': 20,
                                    'p_reason': 'map_contribution',
                                    'p_ref_type': 'map',
                                    'p_metadata': {'point_name': name},
                                  });

                                  await _updateQuestProgress('map_visit', 1);

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        backgroundColor: Colors.green,
                                        content: Text('Đóng góp thành công! Điểm mới sẽ hiển thị sau khi Admin duyệt.'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  debugPrint("Lỗi đóng góp điểm rác: $e");
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Lỗi gửi đóng góp: $e')),
                                    );
                                  }
                                } finally {
                                  if (context.mounted) {
                                    setDialogState(() => isSubmitting = false);
                                  }
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text("Gửi đóng góp (Thưởng +20 XP)", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  Future<void> _updateQuestProgress(String questType, int increment) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final activeQuests = await supabase
          .from('quests')
          .select()
          .eq('quest_type', questType)
          .eq('is_active', true);

      for (var quest in activeQuests) {
        final questId = quest['id'];
        final targetCount = quest['target_count'] as int;
        final rewardXp = quest['reward_xp'] as int;

        final todayStr = DateTime.now().toIso8601String().substring(0, 10);
        
        final userQuestRecord = await supabase
            .from('user_quests')
            .select()
            .eq('user_id', user.id)
            .eq('quest_id', questId)
            .eq('date', todayStr)
            .maybeSingle();

        int newProgress = increment;
        bool alreadyRewarded = false;

        if (userQuestRecord != null) {
          newProgress = (userQuestRecord['progress_count'] as int) + increment;
          alreadyRewarded = userQuestRecord['is_rewarded'] as bool;
        }

        final bool isCompleted = newProgress >= targetCount;

        await supabase.from('user_quests').upsert({
          'user_id': user.id,
          'quest_id': questId,
          'date': todayStr,
          'progress_count': newProgress,
          'is_completed': isCompleted,
          'is_rewarded': alreadyRewarded || isCompleted,
          'updated_at': DateTime.now().toIso8601String(),
        });

        if (isCompleted && !alreadyRewarded) {
          await supabase.rpc('rpc_award_points', params: {
            'p_delta': rewardXp,
            'p_reason': 'quest_completed',
            'p_ref_type': 'quest',
            'p_metadata': {'quest_title': quest['title_vi']},
          });
        }
      }
    } catch (e) {
      debugPrint('Error updating quest progress on map: $e');
    }
  }

  void _showStyleSelectorSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1C1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Lớp bản đồ",
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Kiểu bản đồ",
                    style: TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black54
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStyleCard('voyager', 'Mặc định', Icons.map_rounded, isDark ? const Color(0xFF1E272C) : const Color(0xFFE8F5E9)),
                      _buildStyleCard('positron', 'Tối giản', Icons.wb_sunny_outlined, isDark ? const Color(0xFF263238) : const Color(0xFFECEFF1)),
                      _buildStyleCard('dark', 'Bản đồ tối', Icons.dark_mode_outlined, isDark ? const Color(0xFF12181B) : const Color(0xFFF5F5F5)),
                      _buildStyleCard('satellite', 'Vệ tinh', Icons.satellite_alt_rounded, isDark ? const Color(0xFF1A237E) : const Color(0xFFE8EAF6)),
                    ],
                  ),
                  const Divider(height: 35),
                  Text(
                    "Tùy chọn lớp phủ",
                    style: TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black54
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    activeThumbColor: theme.primaryColor,
                    contentPadding: EdgeInsets.zero,
                    title: Row(
                      children: [
                        const Icon(Icons.directions_bike_rounded, color: Colors.orange),
                        const SizedBox(width: 12),
                        Text(
                          "Đường đi xe đạp & dạo bộ",
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black87
                          ),
                        ),
                      ],
                    ),
                    value: _showTraffic,
                    onChanged: (bool value) {
                      setSheetState(() {
                        _showTraffic = value;
                      });
                      setState(() {
                        _showTraffic = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String urlTemplate;
    switch (_mapStyle) {
      case 'positron':
        urlTemplate = _positronUrl;
        break;
      case 'dark':
        urlTemplate = _darkMatterUrl;
        break;
      case 'satellite':
        urlTemplate = _satelliteUrl;
        break;
      case 'voyager':
      default:
        urlTemplate = _voyagerUrl;
        break;
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mapCenter,
              initialZoom: 16,
              onLongPress: (tapPosition, point) {
                setState(() {
                  _selectedPinLocation = point;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã ghim vị trí đóng góp mới! Nhấn nút "+" để thêm thông tin.'),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
              onPositionChanged: _onMapPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: urlTemplate,
                userAgentPackageName: 'com.example.phan_loai_rac_qua_hinh_anh',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              if (_showTraffic)
                Opacity(
                  opacity: 0.6,
                  child: TileLayer(
                    urlTemplate: _trafficUrl,
                    userAgentPackageName: 'com.example.phan_loai_rac_qua_hinh_anh',
                  ),
                ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.0,
                      color: Colors.blueAccent,
                    ),
                  ],
                ),
              MarkerLayer(markers: [
                Marker(
                  point: _userLocation,
                  width: 80,
                  height: 80,
                  child: _buildUserLocationMarker(),
                ),
                if (_selectedPinLocation != null)
                  Marker(
                    point: _selectedPinLocation!,
                    width: 60,
                    height: 60,
                    child: const Icon(Icons.pin_drop_rounded, color: Colors.redAccent, size: 45),
                  ),
                ..._markers,
              ]),
            ],
          ),

          // Banner chỉ đường OSRM
          if (_routePoints.isNotEmpty)
            Positioned(
              top: 115,
              left: 20,
              right: 20,
              child: Card(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        radius: 18,
                        child: Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Đường đi OSRM (${_routeDistance ?? ''})',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              'Thời gian: ${_routeDuration ?? ''} • Miễn phí 100%',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _routePoints = [];
                            _routeDistance = null;
                            _routeDuration = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Banner hiển thị ghim vị trí tùy chọn
          if (_selectedPinLocation != null && !_isSelectingLocationOnMap)
            Positioned(
              top: 115,
              left: 20,
              right: 20,
              child: Card(
                color: theme.primaryColor,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.pin_drop_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "Đã ghim vị trí đóng góp mới",
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                        onPressed: () {
                          setState(() {
                            _selectedPinLocation = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Thanh tìm kiếm phía trên
          if (!_isSelectingLocationOnMap)
            Positioned(
              top: 50, left: 20, right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2D31) : Colors.white, 
                  borderRadius: BorderRadius.circular(25), 
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.15), 
                      blurRadius: 15, 
                      offset: const Offset(0, 5)
                    )
                  ]
                ),
              child: Row(
                children: [
                  if (widget.showBackButton)
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: isDark ? Colors.white : Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0, right: 4.0),
                      child: Icon(Icons.search_rounded, color: theme.primaryColor, size: 24),
                    ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        fontSize: 15, 
                        color: isDark ? Colors.white : Colors.black87
                      ),
                      decoration: InputDecoration(
                        hintText: "Tìm kiếm địa điểm...",
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black38,
                          fontSize: 15
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (val) {
                        setState(() {}); // cập nhật nút xóa
                        if (val.isEmpty) {
                          setState(() {
                            _searchResults = [];
                          });
                        }
                      },
                      onSubmitted: _searchLocation,
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.close_rounded, size: 20, color: isDark ? Colors.white70 : Colors.black54),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchResults = [];
                        });
                      },
                    ),
                  if (_isLoadingSearch)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.0),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green)),
                    ),
                  IconButton(
                    icon: Icon(Icons.layers_rounded, color: theme.primaryColor), 
                    onPressed: _showStyleSelectorSheet,
                  ),
                ],
              ),
            ),
          ),

          // Kết quả tìm kiếm địa điểm
          if (_searchResults.isNotEmpty && !_isSelectingLocationOnMap)
            Positioned(
              top: 110,
              left: 20,
              right: 20,
              child: Card(
                elevation: 10,
                color: isDark ? const Color(0xFF2A2D31) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _searchResults.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                    itemBuilder: (context, index) {
                      final item = _searchResults[index];
                      final displayName = item['display_name'] ?? "";
                      final address = item['address'] ?? {};
                      return ListTile(
                        leading: const Icon(Icons.location_on, color: Colors.redAccent),
                        title: Text(
                          displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                        ),
                        onTap: () {
                          final double lat = double.parse(item['lat']);
                          final double lon = double.parse(item['lon']);
                          final point = LatLng(lat, lon);
                          setState(() {
                            _mapCenter = point;
                            _searchResults = [];
                            _searchController.text = address['road'] ?? address['suburb'] ?? address['city'] ?? displayName;
                          });
                          _mapController.move(point, 16);
                          _fetchWastePoints(lat, lon);
                          FocusScope.of(context).unfocus();
                        },
                      );
                    },
                  ),
                ),
              ),
            ),

          if (_isLoading) const Center(child: CircularProgressIndicator(color: Colors.green)),
          
          if (!_isSelectingLocationOnMap)
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
                        backgroundColor: isDark ? const Color(0xFF2A2D31) : Colors.white,
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
                    backgroundColor: isDark ? const Color(0xFF2A2D31) : Colors.white,
                    onPressed: _isFetchingWaste ? null : () => _fetchWastePoints(_mapCenter.latitude, _mapCenter.longitude),
                    child: _isFetchingWaste
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green))
                        : const Icon(Icons.refresh_rounded, color: Colors.green),
                  ),
                  const SizedBox(height: 15),
                  FloatingActionButton(
                    heroTag: "add_point",
                    backgroundColor: Colors.orangeAccent,
                    onPressed: _onAddPointPressed,
                    child: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
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

          // Overlay cho chế độ chọn vị trí trên bản đồ
          if (_isSelectingLocationOnMap) ...[
            // Center pin target dot
            Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            // Floating pin icon
            Center(
              child: Transform.translate(
                offset: const Offset(0, -24),
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, double value, child) {
                    return Transform.translate(
                      offset: Offset(0, -10 * (1 - value)),
                      child: child,
                    );
                  },
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Colors.redAccent,
                    size: 48,
                  ),
                ),
              ),
            ),
            // Bottom confirmation card
            Positioned(
              bottom: widget.showBackButton ? 30 : 120,
              left: 20,
              right: 20,
              child: Card(
                elevation: 8,
                color: isDark ? const Color(0xFF1A1C1E) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.pin_drop_rounded, color: theme.primaryColor, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Chọn vị trí trên bản đồ",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _isLoadingGeocoding
                          ? const Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "Đang tải địa chỉ...",
                                    style: TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              _tempGeocodedAddress.isNotEmpty
                                  ? _tempGeocodedAddress
                                  : "Di chuyển bản đồ để chọn địa chỉ",
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                side: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
                              ),
                              onPressed: _cancelMapSelection,
                              child: Text(
                                "Hủy",
                                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _confirmSelectedLocation,
                              child: const Text(
                                "Xác nhận vị trí",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
