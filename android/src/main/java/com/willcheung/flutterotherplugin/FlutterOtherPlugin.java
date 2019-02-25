package com.willcheung.flutterotherplugin;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import android.Manifest;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentSender;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.location.Location;
import android.location.LocationListener;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.os.Looper;
import android.provider.Settings;
import android.util.Log;
import android.content.Context;
import android.location.LocationManager;
import android.os.Bundle;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.HashMap;
import java.util.List;


import android.Manifest;
import android.app.Activity;
import android.content.IntentSender;
import android.content.pm.PackageManager;
import android.location.Location;
import android.os.Build;
import android.os.Looper;
import androidx.annotation.MainThread;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;






/** FlutterOtherPlugin */
public class FlutterOtherPlugin implements MethodCallHandler,StreamHandler {
  private static final String STREAM_CHANNEL_NAME = "flutter_other_plugin/locationstream";
  private static final String METHOD_CHANNEL_NAME = "flutter_other_plugin";

  private static final int REQUEST_PERMISSIONS_REQUEST_CODE = 34;
  private static final int REQUEST_CHECK_SETTINGS = 0x1;
  private static final long UPDATE_INTERVAL_IN_MILLISECONDS = 10000;
  private static final long FASTEST_UPDATE_INTERVAL_IN_MILLISECONDS = UPDATE_INTERVAL_IN_MILLISECONDS / 2;

//  private final FusedLocationProviderClient mFusedLocationClient;
//  private final SettingsClient mSettingsClient;
//  private LocationRequest mLocationRequest;
//  private LocationSettingsRequest mLocationSettingsRequest;
//  private LocationCallback mLocationCallback;
  private PluginRegistry.RequestPermissionsResultListener mPermissionsResultListener;

  private EventSink events;
  private Result result;

  /** Plugin registration. */

  private final Activity activity;

  private FlutterOtherPlugin(Activity activity) {
    this.activity = activity;
  }

  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    FlutterOtherPlugin flutterPlugin = new FlutterOtherPlugin(registrar.activity());
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "flutter_other_plugin");
    channel.setMethodCallHandler(flutterPlugin);
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (call.method.equals("saveImageToGallery")) {
      if (hasPermission()){
        Bitmap image = BytesBimap((byte[]) call.arguments);
        result.success(savePhotoToSDCard(image));
      }else{
        showDialogTipUserRequestPermission(false);
      }
    }
    else  if (call.method.equals("getLocation")) {
      if (hasPermission()){
        getLngAndLat(result);
      }else{
        showDialogTipUserRequestPermission(false);
      }
    }
    else if(call.method.equals("hasPermission")) {
      if(hasPermission()) {
        result.success(1);
      } else {
        result.error("PERMISSION_DENIED", "The user explicitly denied the use of location services for this app or location services are currently disabled in Settings.", null);
      }
    }
    else {
      result.notImplemented();
    }
  }

  @Override
  public void onListen(Object o, EventSink eventsSink) {
    events = eventsSink;

    getLngAndLat(null);
    /**
     * Requests location updates from the FusedLocationApi. Note: we don't call this unless location
     * runtime permission has been granted.
     */
    mSettingsClient.checkLocationSettings(mLocationSettingsRequest)
            .addOnSuccessListener(activity, new OnSuccessListener<LocationSettingsResponse>() {
              @Override
              public void onSuccess(LocationSettingsResponse locationSettingsResponse) {
                mFusedLocationClient.requestLocationUpdates(mLocationRequest, mLocationCallback,
                        Looper.myLooper());
              }
            }).addOnFailureListener(activity, new OnFailureListener() {
      @Override
      public void onFailure(@NonNull Exception e) {
        int statusCode = ((ApiException) e).getStatusCode();
        switch (statusCode) {
          case LocationSettingsStatusCodes.RESOLUTION_REQUIRED:
            try {
              // Show the dialog by calling startResolutionForResult(), and check the
              // result in onActivityResult().
              ResolvableApiException rae = (ResolvableApiException) e;
              rae.startResolutionForResult(activity, REQUEST_CHECK_SETTINGS);
            } catch (IntentSender.SendIntentException sie) {
              Log.i(METHOD_CHANNEL_NAME, "PendingIntent unable to execute request.");
            }
            break;
          case LocationSettingsStatusCodes.SETTINGS_CHANGE_UNAVAILABLE:
            String errorMessage = "Location settings are inadequate, and cannot be "
                    + "fixed here. Fix in Settings.";
            Log.e(METHOD_CHANNEL_NAME, errorMessage);
        }
      }
    });
  }

  @Override
  public void onCancel(Object o) {
    events = null;
  }

  private void reqPermission() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      String[] PERMISSIONS_STORAGE = {Manifest.permission.WRITE_EXTERNAL_STORAGE};
      if (activity.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
        activity.requestPermissions(PERMISSIONS_STORAGE, 123);
      }
    }
  }

  private boolean hasPermission(){
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      return (activity.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED) ;
    }
    return true;
  }

  private Bitmap BytesBimap(byte[] b){
    try{
      if (b.length != 0) {
        BitmapFactory.Options op = new BitmapFactory.Options();
        op.inSampleSize = 2;
        return BitmapFactory.decodeByteArray(b, 0, b.length);
      } else {
        return null;
      }
    }catch (Exception e){
      Log.i("","==============================");
      Log.i("",e.getMessage());
    }
    return null;
  }

  private void showDialogTipUserRequestPermission(final boolean isLocation)  {
    if (isLocation){
      new AlertDialog.Builder(activity)
              .setTitle("")
              .setMessage("请先开启网络连接或者开启GPS")
              .setPositiveButton("立即开启", new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialog, int which) {
                  dialog.dismiss();
                  goToAppSetting(isLocation);
                }
              })
              .setNegativeButton("取消", new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialog, int which) {
                  dialog.dismiss();
                }
              }).setCancelable(false).show();
    }
    else {
      new AlertDialog.Builder(activity)
              .setTitle("存储权限不可用")
              .setMessage("保存图片需先将存储权限开启；否则，您将无法正常使用该功能.\n请在-应用设置-权限-中，允许使用存储权限来保存用户数据")
              .setPositiveButton("立即开启", new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialog, int which) {
                  dialog.dismiss();
                  goToAppSetting(isLocation);
                }
              })
              .setNegativeButton("取消", new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialog, int which) {
                  dialog.dismiss();
                }
              }).setCancelable(false).show();
    }


  }

  // 跳转到当前应用的设置界面
  private void goToAppSetting(boolean isLocation) {
    Intent intent = new Intent();
    intent.setAction(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
    Uri uri = Uri.fromParts("package", activity.getPackageName(), null);
    intent.setData(uri);
    if (isLocation){
      activity.startActivityForResult(intent, 19);
    }
    else {
      activity.startActivityForResult(intent, 11);
    }
  }

  private int savePhotoToSDCard(Bitmap photoBitmap) {
    int result = 0;
    //系统相册目录
    String photoName = "paopao"+System.currentTimeMillis()+".png";

    String path = Environment.getExternalStorageDirectory()
            + File.separator + Environment.DIRECTORY_DCIM
            +File.separator+"Camera"+File.separator;

    File photoFile = new File(path, photoName);
    FileOutputStream fileOutputStream = null;
    try {
      fileOutputStream = new FileOutputStream(photoFile);
      if (photoBitmap != null) {
        if (photoBitmap.compress(Bitmap.CompressFormat.PNG, 100,
                fileOutputStream)) {
          fileOutputStream.flush();
          result = 1;
        }
      }
    } catch (FileNotFoundException e) {
      Log.i("","==============================");
      Log.i("",e.getMessage());
    } catch (IOException e) {
      Log.i("","==============================");
      Log.i("",e.getMessage());
    } finally {
      try {
        if (fileOutputStream!=null){
          fileOutputStream.close();
        }
      } catch (IOException e) {
        Log.i("","==============================");
        Log.i("",e.getMessage());
      }
    }
    return result;
  }

  /**
   * 获取经纬度
   *
   * @return
   */
  LocationManager locationManager;
  public void getLngAndLat(final Result res) {
    String result = "";
    String locationProvider = null;
    locationManager = (LocationManager) activity.getSystemService(Context.LOCATION_SERVICE);
    //获取所有可用的位置提供器
    List<String> providers = locationManager.getProviders(true);

    if (providers.contains(LocationManager.GPS_PROVIDER)) {
      //如果是GPS
      locationProvider = LocationManager.GPS_PROVIDER;
    } else if (providers.contains(LocationManager.NETWORK_PROVIDER)) {
      //如果是Network
      locationProvider = LocationManager.NETWORK_PROVIDER;
    } else {
      showDialogTipUserRequestPermission(true);
      return;
    }
    //获取Location
    Location location = locationManager.getLastKnownLocation(locationProvider);
    if (location != null) {
      Log.i("===","====================");
      //纬度
      Log.i("getLatitude",location.getLatitude()+"");
      //经度
      Log.i("getLongitude",location.getLongitude()+"");

      result = location.getLatitude()+";"+location.getLongitude();
      //监视地理位置变化
      locationManager.requestLocationUpdates(locationProvider, 3000, 1, locationListener);

      HashMap<String, Double> loc = new HashMap<String, Double>();
      loc.put("latitude", location.getLatitude());
      loc.put("longitude", location.getLongitude());
      loc.put("accuracy", (double) location.getAccuracy());
      loc.put("altitude", location.getAltitude());
      loc.put("speed", (double) location.getSpeed());
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        loc.put("speed_accuracy", (double) location.getSpeedAccuracyMetersPerSecond());
      }
      loc.put("heading", (double) location.getBearing());

      if (result != null) {
        result.success(loc);
        return;
      }
      if (events != null) {
        events.success(loc);
      }
    } else {
      if (result != null) {
        result.error("ERROR", "Failed to get location.", null);
        return;
      }
      // Do not send error on events otherwise it will produce an error
    }
  }


  /**
   * 监听类
   */
  private LocationListener locationListener = new LocationListener() {

    // Provider的状态在可用、暂时不可用和无服务三个状态直接切换时触发此函数
    @Override
    public void onStatusChanged(String provider, int status, Bundle extras) {

    }

    // Provider被enable时触发此函数，比如GPS被打开
    @Override
    public void onProviderEnabled(String provider) {

    }

    // Provider被disable时触发此函数，比如GPS被关闭
    @Override
    public void onProviderDisabled(String provider) {

    }

    //当坐标改变时触发此函数，如果Provider传进相同的坐标，它就不会被触发
    @Override
    public void onLocationChanged(Location location) {
      if (mOnLocationListener != null) {
        mOnLocationListener.OnLocationChange(location);
      }
    }
  };

  public void removeListener() {
    locationManager.removeUpdates(locationListener);
  }

  private OnLocationResultListener mOnLocationListener;

  public interface OnLocationResultListener {
    void onLocationResult(Location location);
    void OnLocationChange(Location location);
  }

}
