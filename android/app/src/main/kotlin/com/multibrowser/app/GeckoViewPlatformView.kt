package com.multibrowser.app

import android.content.Context
import android.view.View
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import org.mozilla.geckoview.GeckoRuntime
import org.mozilla.geckoview.GeckoSession
import org.mozilla.geckoview.GeckoSessionSettings
import org.mozilla.geckoview.GeckoView

class GeckoViewPlatformView(
    context: Context,
    messenger: BinaryMessenger,
    id: Int,
    params: Map<String, Any?>
) : PlatformView {

    private val geckoView: GeckoView = GeckoView(context)
    private val session: GeckoSession
    private val channel: MethodChannel = MethodChannel(messenger, "com.multibrowser/geckoview_$id")

    private var currentZoom: Float = 1.0f

    init {
        val runtime = GeckoRuntime.getDefault(context)

        val ua = params["userAgent"] as? String
        val zoom = (params["zoom"] as? Number)?.toFloat() ?: 0.7f
        val desktop = params["desktopMode"] as? Boolean ?: true
        currentZoom = zoom

        val builder = GeckoSessionSettings.Builder()
        builder.usePrivateMode(false)
        if (desktop) {
            builder.userAgentMode(GeckoSessionSettings.USER_AGENT_MODE_DESKTOP)
            builder.viewportMode(GeckoSessionSettings.VIEWPORT_MODE_DESKTOP)
        } else {
            builder.userAgentMode(GeckoSessionSettings.USER_AGENT_MODE_MOBILE)
            builder.viewportMode(GeckoSessionSettings.VIEWPORT_MODE_MOBILE)
        }
        if (!ua.isNullOrBlank()) {
            builder.userAgentOverride(ua)
        }

        session = GeckoSession(builder.build())
        session.open(runtime)
        geckoView.setSession(session)

        session.contentDelegate = object : GeckoSession.ContentDelegate {
            override fun onPageStop(s: GeckoSession, success: Boolean) {
                applyZoom()
            }
        }

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "load" -> {
                    val url = call.argument<String>("url") ?: ""
                    if (url.isNotBlank()) session.loadUri(url)
                    result.success(null)
                }
                "reload" -> {
                    session.reload()
                    result.success(null)
                }
                "back" -> {
                    session.goBack()
                    result.success(null)
                }
                "forward" -> {
                    session.goForward()
                    result.success(null)
                }
                "setUserAgent" -> {
                    val newUa = call.argument<String>("ua") ?: ""
                    session.settings.userAgentOverride = newUa
                    session.reload()
                    result.success(null)
                }
                "setZoom" -> {
                    currentZoom = (call.argument<Number>("zoom") ?: 1.0).toFloat()
                    applyZoom()
                    result.success(null)
                }
                "evaluateJS" -> {
                    val js = call.argument<String>("js") ?: ""
                    session.loadUri("javascript:(function() { $js })();")
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        val url = params["url"] as? String
        if (!url.isNullOrBlank()) session.loadUri(url)
    }

    private fun applyZoom() {
        val z = currentZoom.coerceIn(0.25f, 1.5f)
        val js = """
            (function() {
                try {
                    var meta = document.querySelector('meta[name="viewport"]');
                    if (!meta) {
                        meta = document.createElement('meta');
                        meta.name = 'viewport';
                        document.head.appendChild(meta);
                    }
                    meta.setAttribute('content', 'width=device-width, initial-scale=$z, minimum-scale=0.25, maximum-scale=5');
                    document.documentElement.style.zoom = '$z';
                    document.documentElement.style.MozTransformOrigin = 'top left';
                } catch (e) {}
            })();
        """.trimIndent()
        session.loadUri("javascript:$js")
    }

    override fun getView(): View = geckoView

    override fun dispose() {
        channel.setMethodCallHandler(null)
        session.close()
    }
}
