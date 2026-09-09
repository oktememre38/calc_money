import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../state/app_state.dart';
import '../utils/dates.dart';
import '../widgets/common.dart';

/// Ayarlar: hesap kesim günü + veri yedeği (dışa/içe aktarma).
class AyarlarPage extends StatelessWidget {
  const AyarlarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final tema = Theme.of(context);
    final kesim = state.hesapKesimGunu;
    final bugun = DateTime.now();
    final kayma = (kesim > 0 && bugun.day > kesim) ? 1 : 0;
    final donemAyNo = ((bugun.month - 1 + kayma) % 12) + 1;
    final donemYil = bugun.year + ((bugun.month + kayma) > 12 ? 1 : 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _KesimKarti(
            kesim: kesim,
            donemMetni: 'Bugün ${bugun.day} ${monthName(bugun.month)} '
                'olduğundan ${kesim == 0 ? 'takvim ayına' : 'kesim gününe'} '
                'göre ${monthName(donemAyNo)} $donemYil dönemine işlenir.',
            onSec: (gun) => context.read<AppState>().kesimGunuAyarla(gun),
          ),
          const SizedBox(height: 12),
          Text(
            'Kesim gününü değiştirirseniz mevcut tüm kayıtlar yeni dönem '
            'kuralına göre yeniden gruplanır.',
            style: tema.textTheme.bodySmall?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.backup_outlined, color: tema.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Veri yedeği',
                          style: tema.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tüm verini (kategoriler, kayıtlar, sabit kayıtlar, ayarlar) '
                    'tek bir .db dosyası olarak dışa aktarabilir ya da bu '
                    'dosyadan geri yükleyebilirsin. Yedeği güvende tut '
                    '(Drive/e-posta/bilgisayar).',
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () => _disariAktar(context),
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Yedek al'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _geriYukle(context),
                          icon: const Icon(Icons.settings_backup_restore),
                          label: const Text('Geri yükle'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Geri yükleme mevcut verinin üzerine yazar. Telefon/yeni kurulum '
            'değişikliklerinde önce "Yedek al" ile dosyayı sakla.',
            style: tema.textTheme.bodySmall?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _disariAktar(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final kopya = await context.read<AppState>().yedekOlustur();
      if (!context.mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(kopya, mimeType: 'application/octet-stream')],
          subject: 'CalcMoney yedeği',
          text: 'CalcMoney veritabanı yedeği (.db).',
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Yedek alınamadı: $e')),
      );
    }
  }

  Future<void> _geriYukle(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final dosya = await FilePicker.pickFile(type: FileType.any);
      if (dosya == null) return;
      final yol = dosya.path;
      if (yol == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Dosya seçilemedi.')),
        );
        return;
      }
      if (!context.mounted) return;
      final onay = await onayIste(
        context,
        baslik: 'Yedek geri yüklensin mi?',
        mesaj: 'Mevcut veriler bu yedekle değiştirilecek. Onaylıyor musun?',
        onayMetni: 'Geri yükle',
      );
      if (!onay || !context.mounted) return;
      await context.read<AppState>().yedekGeriYukle(yol);
      messenger.showSnackBar(
        const SnackBar(content: Text('Yedek başarıyla geri yüklendi.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Geri yükleme başarısız: $e')),
      );
    }
  }
}

class _KesimKarti extends StatelessWidget {
  final int kesim;
  final String donemMetni;
  final ValueChanged<int> onSec;

  const _KesimKarti({
    required this.kesim,
    required this.donemMetni,
    required this.onSec,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_repeat),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hesap kesim günü',
                    style: tema.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Kredi kartı ekstrenizin kesildiği günü seçin. Kesim gününe '
              'kadar (dahil) eklenen gelir/giderler o ayın dönemine, '
              'kesimden SONRAKİ günler ise bir sonraki ayın dönemine işlenir.\n\n'
              'Örnek: kesim günü 10 iken 20\'sinde girdiğiniz bir gider '
              'gelecek ayın döneminde görünür. "Kapalı" seçiliyken dönem '
              'takvim ayıyla aynıdır.',
              style: tema.textTheme.bodySmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Kapalı'),
                  avatar: const Icon(Icons.block, size: 16),
                  selected: kesim == 0,
                  onSelected: (_) => onSec(0),
                ),
                for (var gun = 1; gun <= 28; gun++)
                  ChoiceChip(
                    label: Text('$gun'),
                    selected: kesim == gun,
                    onSelected: (_) => onSec(gun),
                  ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(
                  Icons.today,
                  size: 20,
                  color: tema.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(donemMetni, style: tema.textTheme.bodyMedium),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
