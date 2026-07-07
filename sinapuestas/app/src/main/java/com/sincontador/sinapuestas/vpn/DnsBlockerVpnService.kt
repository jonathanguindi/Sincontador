package com.sincontador.sinapuestas.vpn

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.ParcelFileDescriptor
import android.util.Log
import com.sincontador.sinapuestas.MainActivity
import com.sincontador.sinapuestas.R
import com.sincontador.sinapuestas.data.BlockLists
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetSocketAddress

/**
 * VPN local que actúa como filtro DNS:
 *
 *  - Se declara como servidor DNS del dispositivo una IP virtual (10.111.222.53)
 *    y la VPN solo enruta esa IP, así que únicamente las consultas DNS pasan
 *    por aquí; el resto del tráfico sigue su camino normal.
 *  - Si el dominio consultado está en la lista de apuestas, se responde
 *    NXDOMAIN (el dominio "no existe") y el sitio nunca carga.
 *  - Si no está bloqueado, la consulta se reenvía a un DNS real (1.1.1.1)
 *    y la respuesta se devuelve al dispositivo.
 */
class DnsBlockerVpnService : VpnService() {

    companion object {
        const val ACTION_START = "com.sincontador.sinapuestas.START_VPN"
        const val ACTION_STOP = "com.sincontador.sinapuestas.STOP_VPN"

        private const val TAG = "DnsBlockerVpn"
        private const val VPN_ADDRESS = "10.111.222.1"
        private const val VIRTUAL_DNS = "10.111.222.53"
        private const val UPSTREAM_DNS = "1.1.1.1"
        private const val NOTIFICATION_CHANNEL = "proteccion"
        private const val NOTIFICATION_ID = 1

        @Volatile
        var isRunning: Boolean = false
            private set
    }

    private var tunInterface: ParcelFileDescriptor? = null
    private var workerThread: Thread? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopVpn()
            stopSelf()
            return START_NOT_STICKY
        }
        if (isRunning) return START_STICKY

        startForeground(NOTIFICATION_ID, buildNotification())
        establishVpn()
        return START_STICKY
    }

    private fun establishVpn() {
        val builder = Builder()
            .setSession(getString(R.string.app_name))
            .addAddress(VPN_ADDRESS, 24)
            .addDnsServer(VIRTUAL_DNS)
            .addRoute(VIRTUAL_DNS, 32)
            .setBlocking(true)

        val tun = builder.establish()
        if (tun == null) {
            Log.w(TAG, "No se pudo establecer la VPN (falta permiso)")
            stopSelf()
            return
        }
        tunInterface = tun
        isRunning = true

        workerThread = Thread({ runLoop(tun) }, "sinapuestas-dns").also { it.start() }
    }

    private fun runLoop(tun: ParcelFileDescriptor) {
        val input = FileInputStream(tun.fileDescriptor)
        val output = FileOutputStream(tun.fileDescriptor)
        val buffer = ByteArray(32767)

        try {
            while (!Thread.currentThread().isInterrupted) {
                val length = input.read(buffer)
                if (length <= 0) continue

                val query = DnsPackets.parse(buffer, length) ?: continue

                if (BlockLists.isDomainBlocked(this, query.qname)) {
                    Log.i(TAG, "Bloqueado: ${query.qname}")
                    val payload = DnsPackets.buildNxDomainPayload(query.dnsPayload)
                    writePacket(output, DnsPackets.buildUdpResponsePacket(query, payload))
                } else {
                    // Reenvío en un hilo corto para no frenar el bucle de lectura
                    Thread { forwardQuery(query, output) }.start()
                }
            }
        } catch (e: Exception) {
            if (isRunning) Log.e(TAG, "Bucle VPN terminado: ${e.message}")
        }
    }

    private fun forwardQuery(query: DnsPackets.ParsedQuery, output: FileOutputStream) {
        try {
            DatagramSocket().use { socket ->
                protect(socket)
                socket.soTimeout = 5000
                socket.send(
                    DatagramPacket(
                        query.dnsPayload, query.dnsPayload.size,
                        InetSocketAddress(UPSTREAM_DNS, 53)
                    )
                )
                val responseBuffer = ByteArray(4096)
                val response = DatagramPacket(responseBuffer, responseBuffer.size)
                socket.receive(response)
                val payload = responseBuffer.copyOf(response.length)
                writePacket(output, DnsPackets.buildUdpResponsePacket(query, payload))
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error reenviando consulta DNS: ${e.message}")
        }
    }

    private val writeLock = Any()

    private fun writePacket(output: FileOutputStream, packet: ByteArray) {
        synchronized(writeLock) {
            try {
                output.write(packet)
            } catch (e: Exception) {
                Log.w(TAG, "Error escribiendo a TUN: ${e.message}")
            }
        }
    }

    private fun stopVpn() {
        isRunning = false
        workerThread?.interrupt()
        workerThread = null
        try {
            tunInterface?.close()
        } catch (_: Exception) {
        }
        tunInterface = null
        stopForeground(STOP_FOREGROUND_REMOVE)
    }

    override fun onDestroy() {
        stopVpn()
        super.onDestroy()
    }

    override fun onRevoke() {
        // El usuario desconectó la VPN desde Ajustes del sistema
        stopVpn()
        stopSelf()
    }

    private fun buildNotification(): Notification {
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(
                NOTIFICATION_CHANNEL,
                getString(R.string.notification_channel_name),
                NotificationManager.IMPORTANCE_LOW
            )
        )
        val contentIntent = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )
        return Notification.Builder(this, NOTIFICATION_CHANNEL)
            .setSmallIcon(R.drawable.ic_shield)
            .setContentTitle(getString(R.string.notification_title))
            .setContentText(getString(R.string.notification_text))
            .setContentIntent(contentIntent)
            .setOngoing(true)
            .build()
    }
}
