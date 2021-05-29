package com.example.websocket

/*import androidx.annotation.NonNull
import android.webkit.CookieManager
import android.util.Log
import io.flutter.plugin.common.MethodChannel*/
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    /*private val CHANNEL = "com.example.websocket/cookies"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            // Note: this method is invoked on the main thread.
            call, result ->
            if (call.method == "getCookies") {
                val url : String? = call.argument("url")
                val cookies: String? = getCookies(url)
                result.success(cookies)
            } else {
                result.notImplemented()
            }
        }

    }

    private fun getCookies(url: String?): String? {
        val cookies: String? = CookieManager.getInstance().getCookie(url)

        return cookies
    }*/

}
