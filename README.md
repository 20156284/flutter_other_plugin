# flutter_other_plugin

Use this plugin to save images locally
Geolocation in China does not use Google services
Call the ringtone if the user is mute the case directly call the vibrator otherwise use the ringtone you set

使用这个插件 可以将图片 保存到本地
在中国地区获取地理位置 不使用Google 服务
调用铃声 如果用户是 静音的情况下 直接调用震动 否则使用 您设定的铃声

## Getting Started
##IOS 调用铃声
请将 文件下的 example 下的 detection.aiff 拷贝到您的ios 项目中
##Android 调用铃声 请在 AndroidManifest.xml 添加
<uses-permission android:name="android.permission.VIBRATE" />
获取震动的权限

##IOS call ring
Please copy the detection. Aiff file under example to your ios project
##Android calling ring
Please add the in the androidmanifest.xml
< USES - the permission of the android: name = "android. Permission. VIBRATE" / >
Get permission to vibrate

See code example