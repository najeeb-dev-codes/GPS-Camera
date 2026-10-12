package com.raiyaan_infotech.gpsmark

import android.Manifest
import android.app.Activity
import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.Settings
import android.view.KeyEvent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin
import java.io.File
import kotlin.math.atan2

class MainActivity : FlutterActivity(), SensorEventListener {
    private var volumeAction = "Capture"
    private var volumeSink: EventChannel.EventSink? = null
    private var levelSink: EventChannel.EventSink? = null
    private var sensorManager: SensorManager? = null
    private var pendingCoverResult: MethodChannel.Result? = null
    private var pendingCameraCoverFile: File? = null

    companion object {
        private const val PICK_PROJECT_COVER_REQUEST = 4102
        private const val CAPTURE_PROJECT_COVER_REQUEST = 4103
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "gpsMarkHomeNative",
            HomeNativeAdFactory(this)
        )

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "gps_camera/hardware_commands"
        ).setMethodCallHandler { call, result ->
            if (call.method == "setVolumeAction") {
                volumeAction = call.arguments as? String ?: "Capture"
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "gps_camera/project_cover"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickProjectCover" -> openProjectCoverPicker(result)
                "captureProjectCover" -> openProjectCoverCamera(result)
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "gps_camera/permission_settings"
        ).setMethodCallHandler { call, result ->
            if (call.method != "openPermissionSettings") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val permission = call.argument<String>("permission")
            result.success(openPermissionSettings(permission))
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "gps_camera/internet_settings"
        ).setMethodCallHandler { call, result ->
            if (call.method == "openInternetSettings") {
                result.success(openInternetSettings())
            } else {
                result.notImplemented()
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "gps_camera/volume_buttons"
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                volumeSink = events
            }
            override fun onCancel(arguments: Any?) {
                volumeSink = null
            }
        })

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "gps_camera/level_sensor"
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                levelSink = events
                startLevelSensor()
            }
            override fun onCancel(arguments: Any?) {
                levelSink = null
                sensorManager?.unregisterListener(this@MainActivity)
            }
        })
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        val isVolumeKey = event.keyCode == KeyEvent.KEYCODE_VOLUME_UP ||
            event.keyCode == KeyEvent.KEYCODE_VOLUME_DOWN
        if (isVolumeKey && event.action == KeyEvent.ACTION_DOWN && volumeAction != "Volume") {
            volumeSink?.success(
                if (event.keyCode == KeyEvent.KEYCODE_VOLUME_UP) "up" else "down"
            )
            return true
        }
        return super.dispatchKeyEvent(event)
    }

    private fun openProjectCoverPicker(result: MethodChannel.Result) {
        if (pendingCoverResult != null) {
            result.error("picker_busy", "The image picker is already open.", null)
            return
        }
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "image/*"
        }
        try {
            pendingCoverResult = result
            startActivityForResult(intent, PICK_PROJECT_COVER_REQUEST)
        } catch (error: Exception) {
            pendingCoverResult = null
            result.error("picker_unavailable", error.message, null)
        }
    }

    private fun openProjectCoverCamera(result: MethodChannel.Result) {
        if (pendingCoverResult != null) {
            result.error("picker_busy", "The image picker is already open.", null)
            return
        }

        try {
            val coverDirectory = File(filesDir, "project_covers").apply { mkdirs() }
            val outputFile = File(
                coverDirectory,
                "project_cover_${System.currentTimeMillis()}.jpg"
            )
            val outputUri = FileProvider.getUriForFile(
                this,
                "$packageName.fileprovider",
                outputFile
            )
            val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
                putExtra(MediaStore.EXTRA_OUTPUT, outputUri)
                clipData = ClipData.newRawUri("Project cover", outputUri)
                addFlags(
                    Intent.FLAG_GRANT_READ_URI_PERMISSION or
                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                )
            }

            if (intent.resolveActivity(packageManager) == null) {
                result.error("camera_unavailable", "No camera app is available.", null)
                return
            }

            pendingCoverResult = result
            pendingCameraCoverFile = outputFile
            startActivityForResult(intent, CAPTURE_PROJECT_COVER_REQUEST)
        } catch (error: Exception) {
            pendingCoverResult = null
            pendingCameraCoverFile?.delete()
            pendingCameraCoverFile = null
            result.error("camera_open_failed", error.message, null)
        }
    }

    private fun openPermissionSettings(permission: String?): Boolean {
        val androidPermission = when (permission) {
            "camera" -> Manifest.permission.CAMERA
            "location" -> Manifest.permission.ACCESS_FINE_LOCATION
            "gallery" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                Manifest.permission.READ_MEDIA_IMAGES
            } else {
                Manifest.permission.READ_EXTERNAL_STORAGE
            }
            "notifications" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                Manifest.permission.POST_NOTIFICATIONS
            } else {
                return openNotificationSettings()
            }
            else -> return openAppPermissionList()
        }

        val exactPermissionIntent = Intent(
            "android.intent.action.MANAGE_APP_PERMISSION"
        ).apply {
            putExtra(Intent.EXTRA_PACKAGE_NAME, packageName)
            putExtra("android.intent.extra.PERMISSION_NAME", androidPermission)
        }

        return startSettingsIntent(exactPermissionIntent) ||
            openAppPermissionList()
    }

    private fun openInternetSettings(): Boolean {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            Intent(Settings.Panel.ACTION_INTERNET_CONNECTIVITY)
        } else {
            Intent(Settings.ACTION_WIRELESS_SETTINGS)
        }

        return startSettingsIntent(intent) ||
            startSettingsIntent(Intent(Settings.ACTION_SETTINGS))
    }

    private fun openNotificationSettings(): Boolean {
        val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
            putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        }
        return startSettingsIntent(intent) || openAppPermissionList()
    }

    private fun openAppPermissionList(): Boolean {
        val permissionsIntent = Intent(
            "android.intent.action.MANAGE_APP_PERMISSIONS"
        ).apply {
            putExtra(Intent.EXTRA_PACKAGE_NAME, packageName)
        }
        if (startSettingsIntent(permissionsIntent)) return true

        return startSettingsIntent(
            Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.parse("package:$packageName")
            )
        )
    }

    private fun startSettingsIntent(intent: Intent): Boolean {
        return try {
            startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    @Deprecated("Deprecated in Android, retained for FlutterActivity compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        when (requestCode) {
            PICK_PROJECT_COVER_REQUEST -> finishGalleryCoverPick(resultCode, data)
            CAPTURE_PROJECT_COVER_REQUEST -> finishCameraCoverCapture(resultCode)
            else -> super.onActivityResult(requestCode, resultCode, data)
        }
    }

    private fun finishGalleryCoverPick(resultCode: Int, data: Intent?) {
        val result = pendingCoverResult
        pendingCoverResult = null
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result?.success(null)
            return
        }

        try {
            val uri = data.data!!
            val mimeType = contentResolver.getType(uri).orEmpty()
            val extension = when {
                mimeType.contains("png") -> "png"
                mimeType.contains("webp") -> "webp"
                else -> "jpg"
            }
            val coverDirectory = File(filesDir, "project_covers").apply { mkdirs() }
            val outputFile = File(
                coverDirectory,
                "project_cover_${System.currentTimeMillis()}.$extension"
            )
            contentResolver.openInputStream(uri).use { input ->
                requireNotNull(input) { "Unable to open the selected image." }
                outputFile.outputStream().use { output -> input.copyTo(output) }
            }
            result?.success(outputFile.absolutePath)
        } catch (error: Exception) {
            result?.error("cover_copy_failed", error.message, null)
        }
    }

    private fun finishCameraCoverCapture(resultCode: Int) {
        val result = pendingCoverResult
        val outputFile = pendingCameraCoverFile
        pendingCoverResult = null
        pendingCameraCoverFile = null

        if (resultCode != Activity.RESULT_OK) {
            outputFile?.delete()
            result?.success(null)
            return
        }

        if (outputFile == null || !outputFile.exists() || outputFile.length() == 0L) {
            outputFile?.delete()
            result?.error("capture_failed", "The camera did not return an image.", null)
            return
        }

        result?.success(outputFile.absolutePath)
    }

    private fun startLevelSensor() {
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val accelerometer = sensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        sensorManager?.registerListener(this, accelerometer, SensorManager.SENSOR_DELAY_UI)
    }

    override fun onSensorChanged(event: SensorEvent) {
        val degrees = Math.toDegrees(atan2(event.values[0].toDouble(), event.values[1].toDouble()))
        levelSink?.success(degrees)
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

    override fun onDestroy() {
        sensorManager?.unregisterListener(this)
        super.onDestroy()
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(
            flutterEngine,
            "gpsMarkHomeNative"
        )
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
