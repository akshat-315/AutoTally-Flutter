import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _themeMode = 'System Default';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          _SectionHeader(title: 'App', theme: theme),
          _SettingsTile(
            icon: Icons.palette_outlined,
            title: 'Theme',
            subtitle: _themeMode,
            onTap: () => _showThemePicker(context),
            theme: theme,
          ),
          _SettingsTile(
            icon: Icons.view_list_outlined,
            title: 'Default Transaction View',
            subtitle: 'Monthly',
            onTap: () {},
            theme: theme,
          ),
          const SizedBox(height: 8),
          _SectionHeader(title: 'Data', theme: theme),
          _SettingsTile(
            icon: Icons.account_balance_outlined,
            title: 'Supported Banks',
            subtitle: '12 banks',
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: () {},
            theme: theme,
          ),
          _SettingsTile(
            icon: Icons.warning_amber_rounded,
            title: 'Unsupported Messages',
            subtitle: '6 messages',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '6',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFFF59E0B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            onTap: () {},
            theme: theme,
          ),
          _SettingsTile(
            icon: Icons.refresh_rounded,
            title: 'Re-scan SMS',
            subtitle: 'Re-process all messages',
            onTap: () => _showRescanDialog(context),
            theme: theme,
          ),
          _SettingsTile(
            icon: Icons.category_outlined,
            title: 'Categories',
            subtitle: '10 categories',
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: () {},
            theme: theme,
          ),
          const SizedBox(height: 8),
          _SectionHeader(title: 'Cloud', theme: theme),
          _SettingsTile(
            icon: Icons.cloud_outlined,
            title: 'Cloud Sync',
            subtitle: 'Coming Soon',
            enabled: false,
            onTap: () {},
            theme: theme,
          ),
          _SettingsTile(
            icon: Icons.family_restroom_outlined,
            title: 'Family Dashboard',
            subtitle: 'Coming Soon',
            enabled: false,
            onTap: () {},
            theme: theme,
          ),
          const SizedBox(height: 8),
          _SectionHeader(title: 'About', theme: theme),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {},
            theme: theme,
          ),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'How It Works',
            onTap: () => _showHowItWorks(context),
            theme: theme,
          ),
          _SettingsTile(
            icon: Icons.smartphone_outlined,
            title: 'App Version',
            subtitle: '1.0.0',
            enabled: false,
            onTap: () {},
            theme: theme,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton(
              onPressed: () => _showClearDataDialog(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Clear All Data'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Theme',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              for (final option in ['System Default', 'Light', 'Dark'])
                RadioListTile<String>(
                  value: option,
                  groupValue: _themeMode,
                  onChanged: (v) {
                    setState(() => _themeMode = v!);
                    Navigator.pop(context);
                  },
                  title: Text(option),
                  controlAffinity: ListTileControlAffinity.trailing,
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
        );
      },
    );
  }

  void _showRescanDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Re-scan SMS?'),
        content: const Text(
          'This will re-process all your SMS. Existing transactions won\'t be duplicated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Re-scan'),
          ),
        ],
      ),
    );
  }

  void _showHowItWorks(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How AutoTally Works',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              _HowItWorksRow(
                icon: Icons.sms_outlined,
                title: 'Reads bank SMS',
                subtitle: 'Scans your messages for financial transactions',
                theme: theme,
              ),
              _HowItWorksRow(
                icon: Icons.code_rounded,
                title: 'Parses locally',
                subtitle: 'Uses pattern matching to extract transaction details',
                theme: theme,
              ),
              _HowItWorksRow(
                icon: Icons.lock_outline_rounded,
                title: 'Never sends data',
                subtitle: 'Everything stays on your phone. Zero network calls.',
                theme: theme,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all your transaction data, merchants, and categories. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final ThemeData theme;

  const _SectionHeader({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool enabled;
  final ThemeData theme;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
    this.enabled = true,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = enabled ? 1.0 : 0.4;

    return Opacity(
      opacity: opacity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18,
                      color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HowItWorksRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ThemeData theme;

  const _HowItWorksRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
