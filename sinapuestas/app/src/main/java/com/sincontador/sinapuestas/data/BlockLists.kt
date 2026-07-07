package com.sincontador.sinapuestas.data

import android.content.Context
import com.sincontador.sinapuestas.R

/**
 * Carga y consulta las listas de bloqueo empaquetadas en res/raw:
 *  - blocked_domains.txt: dominios de casas de apuestas (se bloquean también todos sus subdominios)
 *  - blocked_packages.txt: tokens que identifican apps de apuestas por su nombre de paquete
 */
object BlockLists {

    @Volatile private var domains: Set<String>? = null
    @Volatile private var packageTokens: List<String>? = null

    fun blockedDomains(context: Context): Set<String> {
        return domains ?: synchronized(this) {
            domains ?: loadLines(context, R.raw.blocked_domains)
                .map { it.lowercase().trim().trimEnd('.') }
                .toSet()
                .also { domains = it }
        }
    }

    fun blockedPackageTokens(context: Context): List<String> {
        return packageTokens ?: synchronized(this) {
            packageTokens ?: loadLines(context, R.raw.blocked_packages)
                .map { it.lowercase().trim() }
                .also { packageTokens = it }
        }
    }

    /** true si [domain] es exactamente un dominio bloqueado o un subdominio de uno. */
    fun isDomainBlocked(context: Context, domain: String): Boolean {
        val d = domain.lowercase().trimEnd('.')
        if (d.isEmpty()) return false
        val list = blockedDomains(context)
        if (d in list) return true
        // Recorre los sufijos: sub.bet365.com -> bet365.com -> com
        var idx = d.indexOf('.')
        while (idx in 0 until d.length - 1) {
            if (d.substring(idx + 1) in list) return true
            idx = d.indexOf('.', idx + 1)
        }
        return false
    }

    /** true si el nombre de paquete de una app coincide con algún token bloqueado. */
    fun isPackageBlocked(context: Context, packageName: String): Boolean {
        val p = packageName.lowercase()
        return blockedPackageTokens(context).any { it.isNotEmpty() && p.contains(it) }
    }

    private fun loadLines(context: Context, resId: Int): List<String> =
        context.resources.openRawResource(resId).bufferedReader().useLines { lines ->
            lines.map { it.substringBefore('#').trim() }
                .filter { it.isNotEmpty() }
                .toList()
        }
}
