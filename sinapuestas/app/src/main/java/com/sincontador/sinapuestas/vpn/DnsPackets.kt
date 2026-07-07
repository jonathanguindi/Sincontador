package com.sincontador.sinapuestas.vpn

/**
 * Utilidades mínimas para leer/escribir paquetes IPv4 + UDP + DNS crudos
 * tal como llegan por la interfaz TUN de la VPN.
 *
 * La VPN se configura para enrutar únicamente el servidor DNS virtual,
 * así que por aquí solo pasan consultas DNS (tráfico muy liviano).
 */
object DnsPackets {

    class ParsedQuery(
        val ipHeaderLength: Int,
        val srcAddress: ByteArray,   // 4 bytes
        val dstAddress: ByteArray,   // 4 bytes
        val srcPort: Int,
        val dstPort: Int,
        val dnsPayload: ByteArray,
        val qname: String
    )

    /** Devuelve null si el paquete no es una consulta DNS IPv4/UDP válida. */
    fun parse(packet: ByteArray, length: Int): ParsedQuery? {
        if (length < 20) return null
        val version = (packet[0].toInt() shr 4) and 0xF
        if (version != 4) return null
        val ihl = (packet[0].toInt() and 0xF) * 4
        if (ihl < 20 || length < ihl + 8) return null
        val protocol = packet[9].toInt() and 0xFF
        if (protocol != 17) return null // solo UDP

        val srcPort = readU16(packet, ihl)
        val dstPort = readU16(packet, ihl + 2)
        if (dstPort != 53) return null

        val udpLength = readU16(packet, ihl + 4)
        val dnsOffset = ihl + 8
        val dnsLength = minOf(udpLength - 8, length - dnsOffset)
        if (dnsLength < 12) return null

        val dnsPayload = packet.copyOfRange(dnsOffset, dnsOffset + dnsLength)
        val qname = readQName(dnsPayload) ?: return null

        return ParsedQuery(
            ipHeaderLength = ihl,
            srcAddress = packet.copyOfRange(12, 16),
            dstAddress = packet.copyOfRange(16, 20),
            srcPort = srcPort,
            dstPort = dstPort,
            dnsPayload = dnsPayload,
            qname = qname
        )
    }

    /** Extrae el nombre consultado (QNAME) de un mensaje DNS. */
    private fun readQName(dns: ByteArray): String? {
        val qdCount = readU16(dns, 4)
        if (qdCount < 1) return null
        val sb = StringBuilder()
        var pos = 12
        while (pos < dns.size) {
            val len = dns[pos].toInt() and 0xFF
            if (len == 0) break
            // Las consultas no usan compresión de nombres
            if (len and 0xC0 != 0) return null
            if (pos + 1 + len > dns.size) return null
            if (sb.isNotEmpty()) sb.append('.')
            for (i in 1..len) sb.append((dns[pos + i].toInt() and 0xFF).toChar())
            pos += 1 + len
        }
        return sb.toString()
    }

    /**
     * Construye la respuesta DNS "NXDOMAIN" (dominio inexistente) para una
     * consulta bloqueada: se copia la consulta y se marcan los bits de
     * respuesta (QR, RA) con código de error 3.
     */
    fun buildNxDomainPayload(query: ByteArray): ByteArray {
        val response = query.copyOf()
        // Flags: QR=1 (respuesta), conserva RD, RA=1, RCODE=3 (NXDOMAIN)
        response[2] = (0x80 or (response[2].toInt() and 0x01)).toByte()
        response[3] = (0x80 or 0x03).toByte()
        // ANCOUNT / NSCOUNT / ARCOUNT = 0
        for (i in 6..11) response[i] = 0
        return response
    }

    /**
     * Envuelve [dnsPayload] en un paquete IPv4+UDP dirigido de vuelta al
     * origen de [query] (direcciones y puertos intercambiados).
     */
    fun buildUdpResponsePacket(query: ParsedQuery, dnsPayload: ByteArray): ByteArray {
        val udpLength = 8 + dnsPayload.size
        val totalLength = 20 + udpLength
        val packet = ByteArray(totalLength)

        // --- Encabezado IPv4 (20 bytes, sin opciones) ---
        packet[0] = 0x45                     // versión 4, IHL 5
        writeU16(packet, 2, totalLength)
        packet[8] = 64                       // TTL
        packet[9] = 17                       // UDP
        System.arraycopy(query.dstAddress, 0, packet, 12, 4) // origen = DNS virtual
        System.arraycopy(query.srcAddress, 0, packet, 16, 4) // destino = cliente
        writeU16(packet, 10, ipChecksum(packet))

        // --- Encabezado UDP ---
        writeU16(packet, 20, query.dstPort)  // puerto origen = 53
        writeU16(packet, 22, query.srcPort)
        writeU16(packet, 24, udpLength)
        // checksum UDP = 0 (opcional en IPv4)

        System.arraycopy(dnsPayload, 0, packet, 28, dnsPayload.size)
        return packet
    }

    private fun ipChecksum(packet: ByteArray): Int {
        var sum = 0L
        var i = 0
        while (i < 20) {
            if (i != 10) sum += readU16(packet, i).toLong()
            i += 2
        }
        while (sum shr 16 != 0L) sum = (sum and 0xFFFF) + (sum shr 16)
        return sum.inv().toInt() and 0xFFFF
    }

    private fun readU16(bytes: ByteArray, offset: Int): Int =
        ((bytes[offset].toInt() and 0xFF) shl 8) or (bytes[offset + 1].toInt() and 0xFF)

    private fun writeU16(bytes: ByteArray, offset: Int, value: Int) {
        bytes[offset] = ((value shr 8) and 0xFF).toByte()
        bytes[offset + 1] = (value and 0xFF).toByte()
    }
}
