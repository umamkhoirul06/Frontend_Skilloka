import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka halaman')),
        );
      }
    }
  }

  String _getEnvironmentTitle(AppEnvironment env) {
    switch (env) {
      case AppEnvironment.prod:
      case AppEnvironment.dev:
        return 'Server Online (skilloka.my.id)';
      case AppEnvironment.devLocal:
        return 'Server Lokal (Emulator / Desktop)';
      case AppEnvironment.devDevice:
        return 'Server Lokal WiFi (${AppConfig.deviceIp}:8000)';
      case AppEnvironment.custom:
        return 'Custom URL (${AppConfig.customOrigin})';
      case AppEnvironment.staging:
        return 'Server Staging (staging.skilloka.my.id)';
    }
  }

  void _showServerConfigDialog() {
    AppEnvironment selectedEnv = AppConfig.environment;
    final ipController = TextEditingController(text: AppConfig.deviceIp);
    final customUrlController =
        TextEditingController(text: AppConfig.customOrigin);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.dns_rounded, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Pilih Server API'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<AppEnvironment>(
                      value: AppEnvironment.prod,
                      groupValue: selectedEnv,
                      title: const Text('Server Online (Production)'),
                      subtitle: const Text('https://skilloka.my.id (Rekomendasi)'),
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedEnv = val);
                        }
                      },
                    ),
                    RadioListTile<AppEnvironment>(
                      value: AppEnvironment.devLocal,
                      groupValue: selectedEnv,
                      title: const Text('Server Lokal (Emulator / PC)'),
                      subtitle: const Text('10.0.2.2:8000 / localhost:8000'),
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedEnv = val);
                        }
                      },
                    ),
                    RadioListTile<AppEnvironment>(
                      value: AppEnvironment.devDevice,
                      groupValue: selectedEnv,
                      title: const Text('Server HP Fisik (WiFi Lokal)'),
                      subtitle: const Text('Koneksi via IP WiFi PC lokal'),
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedEnv = val);
                        }
                      },
                    ),
                    if (selectedEnv == AppEnvironment.devDevice) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: ipController,
                          decoration: const InputDecoration(
                            labelText: 'IP PC (contoh: 192.168.0.107)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    RadioListTile<AppEnvironment>(
                      value: AppEnvironment.custom,
                      groupValue: selectedEnv,
                      title: const Text('Custom URL Server'),
                      subtitle: const Text('Masukkan origin URL manual'),
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedEnv = val);
                        }
                      },
                    ),
                    if (selectedEnv == AppEnvironment.custom) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: customUrlController,
                          decoration: const InputDecoration(
                            labelText: 'URL (contoh: https://myserver.com)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final prefs = sl<SharedPreferences>();
                    await AppConfig.setEnvironment(
                      selectedEnv,
                      newDeviceIp: ipController.text.trim().isNotEmpty
                          ? ipController.text.trim()
                          : null,
                      newCustomOrigin:
                          customUrlController.text.trim().isNotEmpty
                              ? customUrlController.text.trim()
                              : null,
                      prefs: prefs,
                    );

                    sl<ApiClient>().updateBaseUrl();

                    if (!context.mounted) return;
                    Navigator.pop(ctx);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Server aktif: ${AppConfig.baseOrigin}',
                        ),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Pengaturan'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Section 1: Server & Jaringan
          _buildSettingsGroup(
            title: 'Koneksi & Server',
            isDark: isDark,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.cloud_sync_rounded, color: AppColors.primary, size: 22),
                ),
                title: const Text(
                  'Server & Koneksi API',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      _getEnvironmentTitle(AppConfig.environment),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Target: ${AppConfig.baseUrl}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                trailing: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.tune_rounded, size: 16, color: AppColors.primary),
                ),
                onTap: _showServerConfigDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Section 2: Legal & Kebijakan
          _buildSettingsGroup(
            title: 'Bantuan & Kebijakan',
            isDark: isDark,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_outlined, color: Color(0xFF2563EB), size: 20),
                ),
                title: const Text('Syarat & Ketentuan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
                onTap: () => _openUrl('https://skilloka.my.id/terms-and-conditions.html'),
              ),
              Divider(height: 1, indent: 64, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF10B981), size: 20),
                ),
                title: const Text('Kebijakan Privasi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
                onTap: () => _openUrl('https://skilloka.my.id/privacy-policy.html'),
              ),
              Divider(height: 1, indent: 64, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.support_agent_rounded, color: Color(0xFF0D9488), size: 20),
                ),
                title: const Text('Hubungi Layanan WhatsApp', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
                onTap: () => _openUrl('https://wa.me/qr/EBV7DJO2S5HEM1'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Section 3: Informasi Aplikasi
          _buildSettingsGroup(
            title: 'Tentang Aplikasi',
            isDark: isDark,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.verified_rounded, color: Color(0xFFF59E0B), size: 20),
                ),
                title: const Text('Versi Aplikasi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                subtitle: const Text('Skilloka Mobile v4.3.0 (Official Build)', style: TextStyle(fontSize: 12)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Terbaru',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup({
    required String title,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}
