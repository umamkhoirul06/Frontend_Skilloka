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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        children: [
          // Section: Server & Jaringan
          ListTile(
            leading: const Icon(Icons.cloud_sync_outlined, color: AppColors.primary),
            title: const Text(
              'Server & Koneksi API',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              _getEnvironmentTitle(AppConfig.environment),
              style: const TextStyle(color: AppColors.primary, fontSize: 13),
            ),
            trailing: const Icon(Icons.tune_rounded),
            onTap: _showServerConfigDialog,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Target API: ${AppConfig.baseUrl}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          const Divider(),

          // Section: Legal & Kebijakan
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Syarat & Ketentuan'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openUrl(
              'https://skilloka.my.id/terms-and-conditions.html',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Kebijakan Privasi'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openUrl(
              'https://skilloka.my.id/privacy-policy.html',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.phone_outlined),
            title: const Text('Hubungi Kami'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openUrl(
              'https://wa.me/qr/EBV7DJO2S5HEM1',
            ),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Informasi Versi'),
            subtitle: Text('Skilloka v1.0.0'),
          ),
        ],
      ),
    );
  }
}
