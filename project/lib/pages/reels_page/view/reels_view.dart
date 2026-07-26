import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:file_picker/file_picker.dart';
import 'package:auralive/routes/app_routes.dart';
import 'package:auralive/utils/database.dart';
import 'package:auralive/utils/utils.dart';

class ReelsViewIOS extends StatefulWidget {
  const ReelsViewIOS({super.key});

  @override
  State<ReelsViewIOS> createState() => _ReelsViewIOSState();
}

class _ReelsViewIOSState extends State<ReelsViewIOS> {
  WebViewController? webViewController;

  @override
  void initState() {
    super.initState();
    initializeWebView();
  }

  Future<void> initializeWebView() async {
    try {
      final storage = GetStorage();
      final userEmail = storage.read('user_email') ?? '';
      final webUserId = Database.loginUserId;
      final webName = Database.fetchLoginUserProfileModel?.user?.name ?? '';

      final url = "https://kulclass.com/live.php?email=$userEmail&uid=$webUserId&name=$webName";
      Utils.showLog("🎯 Loading Full Reels WebView (iOS): $url");

      late final PlatformWebViewControllerCreationParams params;
      if (WebViewPlatform.instance is WebKitWebViewPlatform) {
        params = WebKitWebViewControllerCreationParams(
          allowsInlineMediaPlayback: true,
        );
      } else {
        params = const PlatformWebViewControllerCreationParams();
      }

      webViewController = WebViewController.fromPlatformCreationParams(params)
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..setUserAgent("Mozilla/5.0 (iPhone; CPU iPhone OS 16_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Mobile/15E148 Safari/604.1")
        ..addJavaScriptChannel(
          'ToProfile',
          onMessageReceived: (JavaScriptMessage message) {
            if (message.message.isNotEmpty) {
              Utils.showLog("Opening Profile for User ID: ${message.message}");
              Get.toNamed(AppRoutes.previewUserProfilePage, arguments: message.message);
            }
          },
        )
        ..loadRequest(Uri.parse(url));

      if (webViewController!.platform is AndroidWebViewController) {
        final androidController = webViewController!.platform as AndroidWebViewController;
        androidController.setMediaPlaybackRequiresUserGesture(false);
        
        androidController.setOnShowFileSelector((FileSelectorParams params) async {
          try {
            final FileType type;
            if (params.acceptTypes.any((t) => t.contains('video'))) {
              type = FileType.video;
            } else if (params.acceptTypes.any((t) => t.contains('image'))) {
              type = FileType.image;
            } else {
              type = FileType.any;
            }

            final result = await FilePicker.platform.pickFiles(
              type: type,
              allowMultiple: params.mode == FileSelectorMode.openMultiple,
            );

            if (result != null && result.files.isNotEmpty) {
              return result.files
                  .where((file) => file.path != null)
                  .map((file) => Uri.file(file.path!).toString())
                  .toList();
            }
          } catch (e) {
            Utils.showLog("File Picker Error: $e");
          }
          return [];
        });
      }
    } catch (e) {
      Utils.showLog("Reels WebView Initialization Failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: webViewController != null
          ? WebViewWidget(controller: webViewController!)
          : const SizedBox.shrink(),
    );
  }
} 
