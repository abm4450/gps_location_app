import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location_data.dart';
import '../models/network_data.dart';
import '../models/spoof_result.dart';
import '../services/spoof_detection_service.dart';
import '../services/gps_service.dart';
import '../services/wifi_service.dart';
import '../services/cellular_service.dart';
import '../widgets/app_logo.dart';
import '../widgets/location_card.dart';
import '../widgets/location_map.dart';
import '../widgets/spoof_result_card.dart';
import 'about_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final SpoofDetectionService _spoofService = SpoofDetectionService();
  final GpsLocationService _gpsService = GpsLocationService();
  final WifiLocationService _wifiService = WifiLocationService();
  final CellularLocationService _cellularService = CellularLocationService();

  LocationData? _gpsLocation;
  LocationData? _wifiLocation;
  LocationData? _cellularLocation;
  WifiData? _wifiData;
  CellTowerData? _cellData;
  SpoofDetectionResult? _spoofResult;

  bool _isLoadingGps = false;
  bool _isLoadingWifi = false;
  bool _isLoadingCellular = false;
  bool _isCheckingSpoof = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _fetchGpsLocation() async {
    setState(() {
      _isLoadingGps = true;
      _gpsLocation = null;
    });

    final location = await _gpsService.getGpsOnlyLocation();

    if (mounted) {
      setState(() {
        _gpsLocation = location;
        _isLoadingGps = false;
      });
    }
  }

  Future<void> _fetchWifiLocation() async {
    setState(() {
      _isLoadingWifi = true;
      _wifiLocation = null;
      _wifiData = null;
    });

    final wifiData = await _wifiService.getWifiInfo();
    final wifiLocation = await _wifiService.getWifiBasedLocation();

    if (mounted) {
      setState(() {
        _wifiData = wifiData;
        _wifiLocation = wifiLocation;
        _isLoadingWifi = false;
      });
    }
  }

  Future<void> _fetchCellularLocation() async {
    setState(() {
      _isLoadingCellular = true;
      _cellularLocation = null;
      _cellData = null;
    });

    final cellData = await _cellularService.getCellTowerInfo();
    final cellularLocation = await _cellularService.getCellularBasedLocation();

    if (mounted) {
      setState(() {
        _cellData = cellData;
        _cellularLocation = cellularLocation;
        _isLoadingCellular = false;
      });
    }
  }

  Future<void> _checkSpoofing() async {
    setState(() {
      _isCheckingSpoof = true;
      _spoofResult = null;
    });

    final result = await _spoofService.performFullCheck();

    if (mounted) {
      setState(() {
        _spoofResult = result;
        _gpsLocation = result.gpsLocation;
        _wifiLocation = result.wifiLocation;
        _cellularLocation = result.cellularLocation;
        _wifiData = result.wifiData;
        _cellData = result.cellData;
        _isCheckingSpoof = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLogo(size: 32),
              const SizedBox(width: 12),
              Text(
                'كفشة كبشة',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 56,
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline_rounded, size: 22),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                );
              },
              tooltip: 'حول',
              style: IconButton.styleFrom(
                minimumSize: const Size(44, 44),
                padding: EdgeInsets.zero,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings_rounded, size: 22),
              onPressed: () => Geolocator.openAppSettings(),
              tooltip: 'الإعدادات',
              style: IconButton.styleFrom(
                minimumSize: const Size(44, 44),
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildSpoofCheckTab(),
            _buildGpsTab(),
            _buildWifiTab(),
            _buildCellularTab(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.shield_rounded, 'فحص التزوير', colorScheme.primary),
                  _buildNavItem(1, Icons.satellite_alt_rounded, 'GPS', const Color(0xFF0EA5E9)),
                  _buildNavItem(2, Icons.wifi_rounded, 'WiFi', const Color(0xFF10B981)),
                  _buildNavItem(3, Icons.cell_tower_rounded, 'الخلوي', const Color(0xFFF59E0B)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, Color activeColor) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _currentIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _currentIndex = index),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected ? activeColor : colorScheme.onSurface.withValues(alpha: 0.45),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? activeColor : colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpoofCheckTab() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withOpacity(0.12),
                  colorScheme.primary.withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.security_rounded,
                    color: colorScheme.primary,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'فحص شامل لكشف تزوير الموقع',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.primary,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'يقارن بين موقع GPS، WiFi، الشبكة الخلوية، وعنوان IP للكشف عن أي تلاعب',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.75),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isCheckingSpoof ? null : _checkSpoofing,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isCheckingSpoof
                        ? [colorScheme.primary.withOpacity(0.5), colorScheme.primary.withOpacity(0.4)]
                        : [colorScheme.primary, colorScheme.primary.withOpacity(0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isCheckingSpoof)
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    else
                      Icon(Icons.search_rounded, size: 28, color: Colors.white),
                    const SizedBox(width: 14),
                    Text(
                      _isCheckingSpoof ? 'جاري الفحص...' : 'بدء فحص التزوير',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          _buildSpoofDisclaimer(theme, colorScheme),
          if (_spoofResult != null) ...[
            const SizedBox(height: 20),
            SpoofResultCard(result: _spoofResult!),
          ],
        ],
      ),
    );
  }

  Widget _buildSpoofDisclaimer(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'ملاحظة: التطبيق يكتشف التزوير العادي (وضع المطور). تطبيقات تغيير الموقع التي تعمل بروت أو على مستوى النظام قد لا تُكتشف.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.75),
                height: 1.4,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(
            icon: Icons.satellite_alt_rounded,
            color: const Color(0xFF0EA5E9),
            title: 'موقع GPS الأصلي',
            description: 'يستخدم الأقمار الصناعية مباشرة بدون تدخل الشبكة',
          ),
          const SizedBox(height: 24),
          _buildActionButton(
            onPressed: _isLoadingGps ? null : _fetchGpsLocation,
            isLoading: _isLoadingGps,
            icon: Icons.my_location_rounded,
            label: _isLoadingGps ? 'جاري التحديد...' : 'تحديد موقع GPS',
            color: const Color(0xFF0EA5E9),
          ),
          const SizedBox(height: 24),
          if (_gpsLocation != null) ...[
            LocationCard(
              location: _gpsLocation!,
              title: 'موقع GPS',
              color: const Color(0xFF0EA5E9),
            ),
            if (_gpsLocation!.hasLocation) ...[
              const SizedBox(height: 24),
              LocationMapWidget(
                latitude: _gpsLocation!.latitude!,
                longitude: _gpsLocation!.longitude!,
                title: 'الموقع على الخريطة - GPS',
                markerColor: const Color(0xFF0EA5E9),
              ),
            ],
          ],
          const SizedBox(height: 24),
          _buildSignalAnalysisActive(_isLoadingGps),
        ],
      ),
    );
  }

  Widget _buildWifiTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(
            icon: Icons.wifi_rounded,
            color: const Color(0xFF10B981),
            title: 'موقع الواي فاي',
            description: 'يستخدم شبكة WiFi المتصلة لتقدير الموقع',
          ),
          const SizedBox(height: 24),
          _buildActionButton(
            onPressed: _isLoadingWifi ? null : _fetchWifiLocation,
            isLoading: _isLoadingWifi,
            icon: Icons.wifi_find_rounded,
            label: _isLoadingWifi ? 'جاري الجلب...' : 'تحديد موقع WiFi',
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 24),
          if (_wifiData != null && _wifiData!.hasData) _buildWifiInfoCard(),
          if (_wifiLocation != null) ...[
            const SizedBox(height: 16),
            LocationCard(
              location: _wifiLocation!,
              title: 'موقع WiFi',
              color: const Color(0xFF10B981),
            ),
            if (_wifiLocation!.hasLocation) ...[
              const SizedBox(height: 24),
              LocationMapWidget(
                latitude: _wifiLocation!.latitude!,
                longitude: _wifiLocation!.longitude!,
                title: 'الموقع على الخريطة - WiFi',
                markerColor: const Color(0xFF10B981),
              ),
            ],
          ],
          const SizedBox(height: 24),
          _buildSignalAnalysisActive(_isLoadingWifi),
        ],
      ),
    );
  }

  Widget _buildCellularTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(
            icon: Icons.cell_tower_rounded,
            color: const Color(0xFFF59E0B),
            title: 'موقع الشبكة الخلوية',
            description: 'يستخدم أبراج الاتصالات لتقدير الموقع (أقل دقة)',
          ),
          const SizedBox(height: 24),
          _buildActionButton(
            onPressed: _isLoadingCellular ? null : _fetchCellularLocation,
            isLoading: _isLoadingCellular,
            icon: Icons.cell_tower_rounded,
            label: _isLoadingCellular ? 'جاري الجلب...' : 'تحديد موقع الخلوي',
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 24),
          if (_cellData != null && _cellData!.hasData) _buildCellInfoCard(),
          if (_cellularLocation != null) ...[
            const SizedBox(height: 16),
            LocationCard(
              location: _cellularLocation!,
              title: 'موقع الخلوي',
              color: const Color(0xFFF59E0B),
            ),
            if (_cellularLocation!.hasLocation) ...[
              const SizedBox(height: 24),
              LocationMapWidget(
                latitude: _cellularLocation!.latitude!,
                longitude: _cellularLocation!.longitude!,
                title: 'الموقع على الخريطة - الخلوي',
                markerColor: const Color(0xFFF59E0B),
              ),
            ],
          ],
          const SizedBox(height: 24),
          _buildSignalAnalysisActive(_isLoadingCellular),
        ],
      ),
    );
  }

  Widget _buildSignalAnalysisActive(bool isActive) {
    if (!isActive) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.green.shade500,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'تحليل الإشارة نشط الآن',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required bool isLoading,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWifiInfoCard() {
    final theme = Theme.of(context);
    const color = Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.wifi_rounded, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'معلومات الشبكة',
                style: theme.textTheme.titleMedium?.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...[
            if (_wifiData!.ssid != null) _buildInfoRow('اسم الشبكة', _wifiData!.ssid!),
            if (_wifiData!.bssid != null) _buildInfoRow('BSSID', _wifiData!.bssid!),
            if (_wifiData!.ipAddress != null) _buildInfoRow('عنوان IP', _wifiData!.ipAddress!),
            if (_wifiData!.gateway != null) _buildInfoRow('البوابة', _wifiData!.gateway!),
          ],
        ],
      ),
    );
  }

  Widget _buildCellInfoCard() {
    final theme = Theme.of(context);
    const color = Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.cell_tower_rounded, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'معلومات الشبكة الخلوية',
                style: theme.textTheme.titleMedium?.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...[
            if (_cellData!.networkOperator != null)
              _buildInfoRow('المشغل', _cellData!.networkOperator!),
            if (_cellData!.networkType != null)
              _buildInfoRow('نوع الشبكة', _cellData!.networkType!),
            if (_cellData!.cellId != null)
              _buildInfoRow('Cell ID', _cellData!.cellId.toString()),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}
