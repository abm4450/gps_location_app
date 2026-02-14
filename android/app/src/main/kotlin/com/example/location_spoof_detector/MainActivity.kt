package com.example.location_spoof_detector

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.net.wifi.WifiManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.telephony.CellInfoGsm
import android.telephony.CellInfoLte
import android.telephony.CellInfoWcdma
import android.telephony.TelephonyManager
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "location_spoof_detector/native"

    private val KNOWN_SPOOFING_PACKAGES = listOf(
        "com.lexa.fakegps",
        "com.dummy.fakegps",
        "com.evildevil.fakegps",
        "org.fakegps",
        "com.incorporate.fakegps",
        "com.lerist.fakelocation",
        "com.lexa.fakegps.free",
        "com.david.fakegps",
        "io.github.project_travel_mocklocation",
        "com.ilyaboguslavsky.fakegps",
        "com.silentlex.fakegps",
        "com.easy.fakegps",
        "ninja.fakegps",
        "com.byecode.fakegps",
        "com.fakegps.go",
        "com.godinsoft.fakegps",
        "com.pspace.fakegps"
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkKnownSpoofingApps" -> {
                    val installed = getInstalledSpoofingApps()
                    result.success(installed)
                }
                "getCellTowerInfo" -> {
                    val cellInfo = getCellTowerData()
                    result.success(cellInfo)
                }
                "getNetworkProviderLocation" -> {
                    getNetworkProviderLocation(result)
                }
                "getWifiSignalStrength" -> {
                    val strength = getWifiSignalStrength()
                    result.success(strength)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getInstalledSpoofingApps(): List<String> {
        val installed = mutableListOf<String>()
        val pm = applicationContext.packageManager
        for (pkg in KNOWN_SPOOFING_PACKAGES) {
            try {
                @Suppress("DEPRECATION")
                pm.getPackageInfo(pkg, 0)
                installed.add(pkg)
            } catch (e: PackageManager.NameNotFoundException) {
                // التطبيق غير مثبت
            }
        }
        return installed
    }

    private fun getCellTowerData(): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>()
        try {
            val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

            // الحصول على MCC و MNC من network operator
            val networkOperator = telephonyManager.networkOperator
            if (networkOperator != null && networkOperator.length >= 5) {
                map["mcc"] = networkOperator.substring(0, 3).toIntOrNull()
                map["mnc"] = networkOperator.substring(3).toIntOrNull()
            }
            map["operatorName"] = telephonyManager.networkOperatorName

            // الحصول على معلومات البرج الخلوي (يتطلب ACCESS_FINE_LOCATION)
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION)
                == PackageManager.PERMISSION_GRANTED) {
                try {
                    val cellInfoList = telephonyManager.allCellInfo
                    if (cellInfoList != null && cellInfoList.isNotEmpty()) {
                        val cellInfo = cellInfoList[0]
                        when (cellInfo) {
                            is CellInfoGsm -> {
                                val identity = cellInfo.cellIdentity
                                map["cellId"] = if (identity.cid != Int.MAX_VALUE) identity.cid else null
                                map["lac"] = if (identity.lac != Int.MAX_VALUE) identity.lac else null
                                map["signalStrength"] = cellInfo.cellSignalStrength.dbm
                                map["type"] = "GSM"
                            }
                            is CellInfoLte -> {
                                val identity = cellInfo.cellIdentity
                                map["cellId"] = if (identity.ci != Int.MAX_VALUE) identity.ci else null
                                map["lac"] = if (identity.tac != Int.MAX_VALUE) identity.tac else null
                                map["signalStrength"] = cellInfo.cellSignalStrength.dbm
                                map["type"] = "LTE"
                            }
                            is CellInfoWcdma -> {
                                val identity = cellInfo.cellIdentity
                                map["cellId"] = if (identity.cid != Int.MAX_VALUE) identity.cid else null
                                map["lac"] = if (identity.lac != Int.MAX_VALUE) identity.lac else null
                                map["signalStrength"] = cellInfo.cellSignalStrength.dbm
                                map["type"] = "WCDMA"
                            }
                            else -> {
                                map["type"] = "UNKNOWN"
                            }
                        }
                    }
                } catch (e: SecurityException) {
                    map["error"] = "صلاحية الموقع مطلوبة: ${e.message}"
                }
            } else {
                map["error"] = "لم يتم منح صلاحية الموقع"
            }
        } catch (e: Exception) {
            map["error"] = e.message
        }
        return map
    }

    private fun getNetworkProviderLocation(result: MethodChannel.Result) {
        try {
            val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager

            if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION)
                != PackageManager.PERMISSION_GRANTED) {
                result.error("PERMISSION_DENIED", "لم يتم منح صلاحية الموقع", null)
                return
            }

            // التحقق من توفر Network Provider
            if (!locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
                result.error("PROVIDER_DISABLED", "Network Provider غير متاح", null)
                return
            }

            var resultSent = false

            val listener = object : LocationListener {
                override fun onLocationChanged(location: Location) {
                    if (!resultSent) {
                        resultSent = true
                        val map = mapOf(
                            "latitude" to location.latitude,
                            "longitude" to location.longitude,
                            "accuracy" to location.accuracy.toDouble(),
                            "isMocked" to location.isFromMockProvider,
                            "provider" to (location.provider ?: "network"),
                            "time" to location.time
                        )
                        result.success(map)
                        locationManager.removeUpdates(this)
                    }
                }

                override fun onProviderDisabled(provider: String) {
                    if (!resultSent) {
                        resultSent = true
                        result.error("PROVIDER_DISABLED", "تم تعطيل Network Provider", null)
                    }
                }

                override fun onProviderEnabled(provider: String) {}

                @Deprecated("Deprecated in API level 29")
                override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
            }

            // طلب موقع واحد من Network Provider
            locationManager.requestSingleUpdate(
                LocationManager.NETWORK_PROVIDER,
                listener,
                Looper.getMainLooper()
            )

            // مهلة 15 ثانية
            Handler(Looper.getMainLooper()).postDelayed({
                if (!resultSent) {
                    resultSent = true
                    locationManager.removeUpdates(listener)
                    result.error("TIMEOUT", "انتهت المهلة - تعذر الحصول على موقع الشبكة", null)
                }
            }, 15000)

        } catch (e: Exception) {
            result.error("ERROR", e.message, null)
        }
    }

    @Suppress("DEPRECATION")
    private fun getWifiSignalStrength(): Int? {
        return try {
            val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            val wifiInfo = wifiManager.connectionInfo
            wifiInfo?.rssi
        } catch (e: Exception) {
            null
        }
    }
}
