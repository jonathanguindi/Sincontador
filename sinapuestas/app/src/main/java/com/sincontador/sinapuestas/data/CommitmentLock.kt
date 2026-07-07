package com.sincontador.sinapuestas.data

import android.content.Context

/**
 * "Candado de compromiso": cuando la persona activa la protección elige un
 * período (7, 30 o 90 días) durante el cual la app no permite desactivarla
 * desde su propia interfaz. Es una barrera de fricción, no un candado
 * absoluto (Android siempre permite desconectar una VPN desde Ajustes).
 */
object CommitmentLock {

    private const val PREFS = "sinapuestas_prefs"
    private const val KEY_LOCK_UNTIL = "lock_until_millis"
    private const val KEY_PROTECTION_ON = "protection_on"

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun activate(context: Context, days: Int) {
        val until = System.currentTimeMillis() + days * 24L * 60L * 60L * 1000L
        prefs(context).edit()
            .putLong(KEY_LOCK_UNTIL, until)
            .putBoolean(KEY_PROTECTION_ON, true)
            .apply()
    }

    fun deactivate(context: Context) {
        prefs(context).edit().putBoolean(KEY_PROTECTION_ON, false).apply()
    }

    fun isProtectionOn(context: Context): Boolean =
        prefs(context).getBoolean(KEY_PROTECTION_ON, false)

    fun isLocked(context: Context): Boolean =
        isProtectionOn(context) && System.currentTimeMillis() < lockUntil(context)

    fun lockUntil(context: Context): Long =
        prefs(context).getLong(KEY_LOCK_UNTIL, 0L)

    fun remainingDays(context: Context): Long {
        val remaining = lockUntil(context) - System.currentTimeMillis()
        if (remaining <= 0) return 0
        return (remaining + 24L * 60L * 60L * 1000L - 1) / (24L * 60L * 60L * 1000L)
    }
}
