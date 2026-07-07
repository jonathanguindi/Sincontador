package com.sincontador.sinapuestas

import android.content.Intent
import android.net.Uri
import android.net.VpnService
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.widget.Button
import android.widget.RadioGroup
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import com.sincontador.sinapuestas.data.CommitmentLock
import com.sincontador.sinapuestas.vpn.DnsBlockerVpnService

class MainActivity : AppCompatActivity() {

    private val vpnPermissionLauncher =
        registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
            if (result.resultCode == RESULT_OK) startProtection()
            else Toast.makeText(this, R.string.vpn_permission_denied, Toast.LENGTH_LONG).show()
        }

    private val notificationPermissionLauncher =
        registerForActivityResult(ActivityResultContracts.RequestPermission()) { }

    private var selectedDays = 7

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        if (Build.VERSION.SDK_INT >= 33) {
            notificationPermissionLauncher.launch(android.Manifest.permission.POST_NOTIFICATIONS)
        }

        findViewById<RadioGroup>(R.id.duration_group).setOnCheckedChangeListener { _, checkedId ->
            selectedDays = when (checkedId) {
                R.id.duration_30 -> 30
                R.id.duration_90 -> 90
                else -> 7
            }
        }

        findViewById<Button>(R.id.btn_toggle).setOnClickListener { onToggleClicked() }
        findViewById<Button>(R.id.btn_accessibility).setOnClickListener {
            startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
            Toast.makeText(this, R.string.accessibility_hint, Toast.LENGTH_LONG).show()
        }
        findViewById<Button>(R.id.btn_help).setOnClickListener {
            startActivity(
                Intent(
                    Intent.ACTION_VIEW,
                    Uri.parse("https://www.jugarbien.es/") // recursos sobre juego responsable
                )
            )
        }
    }

    override fun onResume() {
        super.onResume()
        refreshStatus()
    }

    private fun onToggleClicked() {
        if (CommitmentLock.isProtectionOn(this)) {
            if (CommitmentLock.isLocked(this)) {
                val days = CommitmentLock.remainingDays(this)
                AlertDialog.Builder(this)
                    .setTitle(R.string.locked_dialog_title)
                    .setMessage(getString(R.string.locked_dialog_message, days))
                    .setPositiveButton(R.string.keep_protection, null)
                    .show()
            } else {
                stopProtection()
            }
            return
        }

        AlertDialog.Builder(this)
            .setTitle(R.string.confirm_dialog_title)
            .setMessage(getString(R.string.confirm_dialog_message, selectedDays))
            .setPositiveButton(R.string.confirm_activate) { _, _ -> requestVpnAndStart() }
            .setNegativeButton(android.R.string.cancel, null)
            .show()
    }

    private fun requestVpnAndStart() {
        val prepareIntent = VpnService.prepare(this)
        if (prepareIntent != null) {
            vpnPermissionLauncher.launch(prepareIntent)
        } else {
            startProtection()
        }
    }

    private fun startProtection() {
        CommitmentLock.activate(this, selectedDays)
        startForegroundService(
            Intent(this, DnsBlockerVpnService::class.java)
                .setAction(DnsBlockerVpnService.ACTION_START)
        )
        refreshStatus()
        Toast.makeText(this, R.string.protection_started, Toast.LENGTH_LONG).show()
    }

    private fun stopProtection() {
        CommitmentLock.deactivate(this)
        startService(
            Intent(this, DnsBlockerVpnService::class.java)
                .setAction(DnsBlockerVpnService.ACTION_STOP)
        )
        refreshStatus()
    }

    private fun refreshStatus() {
        val statusView = findViewById<TextView>(R.id.status_text)
        val toggleButton = findViewById<Button>(R.id.btn_toggle)

        if (CommitmentLock.isProtectionOn(this)) {
            val days = CommitmentLock.remainingDays(this)
            statusView.text =
                if (days > 0) getString(R.string.status_on_days, days)
                else getString(R.string.status_on)
            toggleButton.setText(
                if (CommitmentLock.isLocked(this)) R.string.btn_locked else R.string.btn_deactivate
            )
        } else {
            statusView.setText(R.string.status_off)
            toggleButton.setText(R.string.btn_activate)
        }

        // Si la protección debería estar activa pero la VPN se cayó (p. ej. tras
        // revocarla en Ajustes), reintenta levantarla al volver a la app.
        if (CommitmentLock.isProtectionOn(this) && !DnsBlockerVpnService.isRunning) {
            if (VpnService.prepare(this) == null) {
                startForegroundService(
                    Intent(this, DnsBlockerVpnService::class.java)
                        .setAction(DnsBlockerVpnService.ACTION_START)
                )
            }
        }
    }
}
