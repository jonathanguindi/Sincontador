package com.sincontador.sinapuestas

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.VpnService
import com.sincontador.sinapuestas.data.CommitmentLock
import com.sincontador.sinapuestas.vpn.DnsBlockerVpnService

/**
 * Al reiniciar el teléfono, vuelve a levantar el filtro DNS si la
 * protección estaba activa y el permiso de VPN sigue concedido.
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        if (!CommitmentLock.isProtectionOn(context)) return
        // prepare() devuelve null cuando el permiso de VPN ya está concedido
        if (VpnService.prepare(context) != null) return

        context.startForegroundService(
            Intent(context, DnsBlockerVpnService::class.java)
                .setAction(DnsBlockerVpnService.ACTION_START)
        )
    }
}
