# Minimal, targeted R8 keep rules for PPPlayer Android release builds.

# Referenced reflectively by Google Cast Framework via AndroidManifest meta-data.
-keep class com.ppplayer.app.PPPlayerCastOptionsProvider {
    public <init>();
    public *** getCastOptions(android.content.Context);
    public *** getAdditionalSessionProviders(android.content.Context);
}

# Methods invoked via JavaScript bridge on Android WebView.
-keepclassmembers class com.ppplayer.app.CustomWebViewService$WebViewInterface {
    @android.webkit.JavascriptInterface <methods>;
}
