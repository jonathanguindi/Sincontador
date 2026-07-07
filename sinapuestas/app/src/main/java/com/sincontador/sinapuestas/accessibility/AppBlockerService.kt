package com.sincontador.sinapuestas.accessibility

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import com.sincontador.sinapuestas.BlockedActivity
import com.sincontador.sinapuestas.data.BlockLists
import com.sincontador.sinapuestas.data.CommitmentLock

/**
 * Servicio de accesibilidad que detecta cuándo pasa a primer plano una app
 * de apuestas instalada y la cubre inmediatamente con la pantalla de bloqueo.
 */
class AppBlockerService : AccessibilityService() {

    private var lastBlockedAt = 0L

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        if (!CommitmentLock.isProtectionOn(this)) return

        val packageName = event.packageName?.toString() ?: return
        if (packageName == this.packageName) return
        if (!BlockLists.isPackageBlocked(this, packageName)) return

        // Evita relanzar la pantalla de bloqueo en ráfaga
        val now = System.currentTimeMillis()
        if (now - lastBlockedAt < 1500) return
        lastBlockedAt = now

        performGlobalAction(GLOBAL_ACTION_HOME)
        startActivity(
            Intent(this, BlockedActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                .putExtra(BlockedActivity.EXTRA_BLOCKED_PACKAGE, packageName)
        )
    }

    override fun onInterrupt() = Unit
}
