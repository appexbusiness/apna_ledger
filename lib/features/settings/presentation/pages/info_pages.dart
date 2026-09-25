import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/powered_by.dart';
import '../../../../l10n/app_localizations.dart';

/// Shows any of the info pages (Privacy/Terms/About/How-to-use) as a bottom
/// sheet instead of a full pushed page — used across Settings.
Future<void> showInfoSheet(
  BuildContext context, {
  required String title,
  required List<Widget> children,
  FinGlyph glyph = FinGlyph.info,
}) {
  return showAppSheet<void>(
    context,
    title: title,
    glyph: glyph,
    builder: (context, setSheet) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++)
          Entrance(index: i, offset: 10, child: children[i]),
      ],
    ),
  );
}

/// A simple scrollable content page used for Privacy / Terms / About.
class InfoScaffold extends StatelessWidget {
  const InfoScaffold({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 40),
                children: [
                  ScreenHeader(
                    title: title,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Surface3D(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < children.length; i++)
                            Entrance(index: i, offset: 10, child: children[i]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Para extends StatelessWidget {
  const Para(this.heading, this.body, {super.key});
  final String heading;
  final String body;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 18,
            margin: const EdgeInsets.only(top: 2, right: 12),
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(heading, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    color: context.semantic.muted,
                    height: 1.55,
                    fontSize: 14,
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

class _Effective extends StatelessWidget {
  const _Effective();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text('Last updated: 22 September 2026',
            style: TextStyle(
                color: context.semantic.muted,
                fontSize: 12,
                fontStyle: FontStyle.italic,),),
      );
}

List<Widget> privacyPolicyChildren() => const [
        _Effective(),
        Para('Overview',
            'Apna Ledger ("the App"), a product of Appex Business ("we", "us", "our"), is a personal and small-business bookkeeping tool. This Privacy Policy explains what information the App handles and how. By using the App you agree to this Policy.',),
        Para('No bank details. No documents.',
            'We never ask for, collect, or store bank logins, card numbers, UPI PINs, bank OTPs, SMS access, statements, bills, or identity documents. Every entry is typed by you. The App cannot move money.',),
        Para('Information you provide',
            'Account details you enter (name, phone number, optional email, date of birth, state) and the ledger entries you create (amounts, categories, notes, and the names you type for people). "People" are just labels you type — the App does not read your contacts unless you explicitly choose one.',),
        Para('How your data is stored',
            'Data is stored on your device and, where cloud sync is enabled for your build, in your private account space on Google Firebase (Cloud Firestore) hosted in the Mumbai (asia-south1) region. Access is restricted to authenticated sessions.',),
        Para('Third-party services',
            'We use Google Firebase for authentication, database, analytics, crash reporting and push notifications, and Google Sign-In where you choose it. Their processing is governed by Google\'s privacy policy. We share only what those services need to function; we never sell your data.',),
        Para('Analytics & crash reports',
            'We use privacy-respecting, aggregate analytics and crash logs (screen views, feature usage, errors) to improve stability. These do not include the specific amounts you record.',),
        Para('Data retention & deletion',
            'You can export your data (CSV/PDF) or delete it at any time. Deleting your account from Settings removes your account and its data from this device. You control your data.',),
        Para('Data loss disclaimer',
            'While we take reasonable measures to keep your data available, we do NOT guarantee it against device loss, uninstalls, OS/app updates, sync interruptions, or accidental deletion. You are responsible for keeping your own backups via export. We are not liable for any loss of data. Use the App at your own risk.',),
        Para('Children',
            'The App is not directed at children under 13, and we do not knowingly collect data from them.',),
        Para('Changes & contact',
            'We may update this Policy as the App evolves; continued use means acceptance. Questions: support@appexbusiness.com · www.appexbusiness.com',),
      ];

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InfoScaffold(
        title: l10n.privacyPolicy, children: privacyPolicyChildren(),);
  }
}

List<Widget> termsChildren() => const [
        _Effective(),
        Para('1. Acceptance of terms',
            'These Terms & Conditions govern your use of Apna Ledger, a product of Appex Business. By downloading, accessing or using the App you agree to these Terms. If you do not agree, do not use the App.',),
        Para('2. What the App is',
            'Apna Ledger is a self-entry bookkeeping and money-tracking tool. All records — income, spending, money given/taken, investments, goals — are entered by you. The App does not connect to your bank and cannot transfer money.',),
        Para('3. Not professional advice',
            'Any calculations, estimates, projections or reminders (e.g. interest, "what if I pay extra", savings goals) are informational only, are based on the values you enter, and are not financial, investment, tax or legal advice. Verify important decisions with a qualified professional.',),
        Para('4. Your responsibilities',
            'You are responsible for the accuracy of what you enter, for keeping your login and device secure, and for maintaining your own backups by exporting your data regularly.',),
        Para('5. No warranty',
            'The App is provided "AS IS" and "AS AVAILABLE" without warranties of any kind, express or implied, including fitness for a particular purpose, accuracy, or uninterrupted or error-free operation.',),
        Para('6. No guarantee of data — use at your own risk',
            'We make reasonable efforts to keep your data safe and available, but we do NOT and CANNOT guarantee against loss, corruption or deletion caused by device failure, uninstalls, updates, sync issues, or user action. If your data is lost or deleted, we are not responsible. You accept full responsibility for backups and use the App entirely at your own risk.',),
        Para('7. Limitation of liability',
            'To the maximum extent permitted by law, Appex Business and its team shall not be liable for any indirect, incidental, special, consequential or exemplary damages, or for any loss of data, profits, goodwill or revenue, arising from or related to your use of (or inability to use) the App — even if advised of the possibility of such damages.',),
        Para('8. Acceptable use',
            'You agree not to misuse the App, attempt to breach its security, reverse-engineer it, or use it for any unlawful purpose.',),
        Para('9. Service changes & availability',
            'We may add, change, suspend or discontinue features at any time. We do not guarantee uninterrupted availability of any cloud services.',),
        Para('10. Termination',
            'You may stop using the App and delete your account at any time. We may suspend or terminate access if these Terms are violated.',),
        Para('11. Governing law',
            'These Terms are governed by the laws of India, without regard to conflict-of-law principles. Courts at the registered location of Appex Business shall have jurisdiction.',),
        Para('12. Changes to these terms',
            'We may revise these Terms as the App evolves. Continued use after an update constitutes acceptance of the revised Terms. Contact: support@appexbusiness.com',),
      ];

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InfoScaffold(title: l10n.termsConditions, children: termsChildren());
  }
}

List<Widget> aboutChildren(BuildContext context, AppLocalizations l10n) => [
      Center(
        child: Column(
          children: [
            const SizedBox(height: 4),
            SizedBox(
              width: 150,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Floating(
                    amplitude: 5,
                    child: Image.asset(
                      'assets/branding/logo_512.png',
                      height: 88,
                      width: 88,
                    ),
                  ),
                  const Positioned(
                    right: 6,
                    top: 4,
                    child: SpinningCoin(size: 36),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(l10n.appName, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Rakhe Pai Pai Ka Hisaab',
              style: TextStyle(color: context.semantic.muted),
            ),
            const SizedBox(height: 4),
            Text('v1.0.0', style: TextStyle(color: context.semantic.muted)),
            const SizedBox(height: 18),
            const PoweredByAppex(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      const Para(
        'Made for India',
        'Simple, private bookkeeping in your language — English, हिन्दी, ગુજરાતી, বাংলা, తెలుగు and தமிழ். No bank details, no documents, only your hisaab.',
      ),
    ];

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InfoScaffold(
        title: l10n.aboutApp, children: aboutChildren(context, l10n),);
  }
}
