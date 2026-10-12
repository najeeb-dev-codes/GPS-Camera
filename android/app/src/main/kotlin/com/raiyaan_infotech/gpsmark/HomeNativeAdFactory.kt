package com.raiyaan_infotech.gpsmark

import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.NativeAdFactory

/** Native layout used by the full-width Home advertisement. */
class HomeNativeAdFactory(
    private val context: Context
) : NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val backgroundColor = customOptions.color("backgroundColor", Color.WHITE)
        val textColor = customOptions.color("textColor", Color.rgb(45, 45, 45))
        val secondaryTextColor = customOptions.color(
            "secondaryTextColor",
            Color.rgb(100, 100, 100)
        )
        val primaryColor = customOptions.color("primaryColor", Color.rgb(109, 40, 217))

        val adView = NativeAdView(context).apply {
            setBackgroundColor(backgroundColor)
        }

        val content = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(10), dp(8), dp(10), dp(8))
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        }

        val upperRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                0,
                1f
            )
        }

        val icon = ImageView(context).apply {
            scaleType = ImageView.ScaleType.CENTER_CROP
            contentDescription = null
            layoutParams = LinearLayout.LayoutParams(dp(72), dp(72)).apply {
                marginEnd = dp(10)
            }
        }

        val textColumn = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_VERTICAL
            layoutParams = LinearLayout.LayoutParams(
                0,
                ViewGroup.LayoutParams.WRAP_CONTENT,
                1f
            )
        }

        val attribution = TextView(context).apply {
            text = "Ad"
            setTextColor(primaryColor)
            textSize = 11f
            setTypeface(typeface, Typeface.BOLD)
        }

        val headline = TextView(context).apply {
            text = nativeAd.headline
            setTextColor(textColor)
            textSize = 15f
            maxLines = 1
            ellipsize = android.text.TextUtils.TruncateAt.END
            setTypeface(typeface, Typeface.BOLD)
        }

        val advertiser = TextView(context).apply {
            text = nativeAd.advertiser.orEmpty()
            setTextColor(secondaryTextColor)
            textSize = 12f
            maxLines = 1
            ellipsize = android.text.TextUtils.TruncateAt.END
            visibility = if (nativeAd.advertiser.isNullOrBlank()) View.GONE else View.VISIBLE
        }

        val body = TextView(context).apply {
            text = nativeAd.body.orEmpty()
            setTextColor(secondaryTextColor)
            textSize = 12f
            maxLines = 2
            ellipsize = android.text.TextUtils.TruncateAt.END
            visibility = if (nativeAd.body.isNullOrBlank()) View.GONE else View.VISIBLE
        }

        val callToAction = Button(context).apply {
            text = nativeAd.callToAction.orEmpty()
            isAllCaps = true
            setTextColor(Color.WHITE)
            textSize = 13f
            setTypeface(typeface, Typeface.BOLD)
            isEnabled = nativeAd.callToAction != null
            visibility = if (nativeAd.callToAction == null) View.INVISIBLE else View.VISIBLE
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dp(6).toFloat()
                setColor(primaryColor)
            }
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                dp(40)
            ).apply {
                topMargin = dp(6)
            }
        }

        textColumn.addView(attribution)
        textColumn.addView(headline)
        textColumn.addView(advertiser)
        textColumn.addView(body)
        upperRow.addView(icon)
        upperRow.addView(textColumn)
        content.addView(upperRow)
        content.addView(callToAction)
        adView.addView(content)

        adView.iconView = icon
        adView.headlineView = headline
        adView.advertiserView = advertiser
        adView.bodyView = body
        adView.callToActionView = callToAction

        val nativeIcon = nativeAd.icon
        if (nativeIcon == null) {
            icon.visibility = View.GONE
        } else {
            icon.setImageDrawable(nativeIcon.drawable)
            icon.visibility = View.VISIBLE
        }

        adView.setNativeAd(nativeAd)
        return adView
    }

    private fun dp(value: Int): Int =
        (value * context.resources.displayMetrics.density).toInt()

    private fun MutableMap<String, Any>?.color(key: String, fallback: Int): Int =
        (this?.get(key) as? Number)?.toInt() ?: fallback
}
