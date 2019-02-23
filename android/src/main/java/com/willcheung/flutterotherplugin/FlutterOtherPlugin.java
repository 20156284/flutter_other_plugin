package com.willcheung.flutterotherplugin;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import android.Manifest;
import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.Settings;
import android.util.Log;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;

/** FlutterOtherPlugin */
public class FlutterOtherPlugin implements MethodCallHandler {
  private static final String STREAM_CHANNEL_NAME = "flutter_other_plugin/locationstream";
  private static final String METHOD_CHANNEL_NAME = "flutter_other_plugin";

  private static final int REQUEST_PERMISSIONS_REQUEST_CODE = 34;
  private static final int REQUEST_CHECK_SETTINGS = 0x1;
  private static final long UPDATE_INTERVAL_IN_MILLISECONDS = 10000;
  private static final long FASTEST_UPDATE_INTERVAL_IN_MILLISECONDS = UPDATE_INTERVAL_IN_MILLISECONDS / 2;


  /** Plugin registration. */

  private Activity activity;

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
        showDialogTipUserRequestPermission();
      }
    } else {
      result.notImplemented();
    }
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

  private void showDialogTipUserRequestPermission() {

    new AlertDialog.Builder(activity)
            .setTitle("存储权限不可用")
            .setMessage("保存图片需先将存储权限开启；否则，您将无法正常使用该功能.\n请在-应用设置-权限-中，允许使用存储权限来保存用户数据")
            .setPositiveButton("立即开启", new DialogInterface.OnClickListener() {
              @Override
              public void onClick(DialogInterface dialog, int which) {
                dialog.dismiss();
                goToAppSetting();
              }
            })
            .setNegativeButton("取消", new DialogInterface.OnClickListener() {
              @Override
              public void onClick(DialogInterface dialog, int which) {
                dialog.dismiss();
              }
            }).setCancelable(false).show();
  }
  // 跳转到当前应用的设置界面
  private void goToAppSetting() {
    Intent intent = new Intent();

    intent.setAction(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
    Uri uri = Uri.fromParts("package", activity.getPackageName(), null);
    intent.setData(uri);

    activity.startActivityForResult(intent, 11);
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


}
