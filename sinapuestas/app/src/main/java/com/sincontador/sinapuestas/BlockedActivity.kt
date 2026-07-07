package com.sincontador.sinapuestas

import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.sincontador.sinapuestas.data.CommitmentLock

/**
 * Pantalla que cubre una app de apuestas cuando se intenta abrir.
 * Mensaje de apoyo + botón para volver al inicio.
 */
class BlockedActivity : AppCompatActivity() {

    companion object {
        const val EXTRA_BLOCKED_PACKAGE = "blocked_package"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_blocked)

        val days = CommitmentLock.remainingDays(this)
        findViewById<TextView>(R.id.blocked_subtitle).text =
            if (days > 0) getString(R.string.blocked_subtitle_days, days)
            else getString(R.string.blocked_subtitle)

        findViewById<Button>(R.id.btn_go_home).setOnClickListener {
            startActivity(
                Intent(Intent.ACTION_MAIN)
                    .addCategory(Intent.CATEGORY_HOME)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
            finish()
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // Volver atrás regresaría a la app bloqueada: mejor al inicio
        startActivity(
            Intent(Intent.ACTION_MAIN)
                .addCategory(Intent.CATEGORY_HOME)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        )
        finish()
    }
}
