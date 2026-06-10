import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:calculator/features/calculator/data/models/calculation_model.dart';

class PdfService {
  static Future<void> generateAndPrint(CalculationModel calculation) async {
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(calculation.title,
              style: pw.TextStyle(font: fontBold, fontSize: 22)),
          pw.SizedBox(height: 4),
          pw.Text(dateFormat.format(calculation.createdAt),
              style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey600)),
          pw.Divider(height: 24),

          pw.Text('Заказчик', style: pw.TextStyle(font: fontBold, fontSize: 13)),
          pw.SizedBox(height: 6),
          pw.Text(calculation.clientName, style: pw.TextStyle(font: font, fontSize: 12)),
          if (calculation.clientPhone != null)
            pw.Text('Тел: ${calculation.clientPhone}', style: pw.TextStyle(font: font, fontSize: 12)),
          if (calculation.clientAddress != null)
            pw.Text('Адрес: ${calculation.clientAddress}', style: pw.TextStyle(font: font, fontSize: 12)),
          if (calculation.comment != null)
            pw.Text('Комментарий: ${calculation.comment}',
                style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey700)),
          pw.Divider(height: 24),

          pw.Text('Изделия', style: pw.TextStyle(font: fontBold, fontSize: 13)),
          pw.SizedBox(height: 8),
          ...calculation.products.asMap().entries.map((e) {
            final p = e.value;
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Изделие #${e.key + 1}: ${p.name}',
                          style: pw.TextStyle(font: fontBold, fontSize: 12)),
                      pw.Text('${p.totalPrice.toStringAsFixed(2)} руб.',
                          style: pw.TextStyle(font: fontBold, fontSize: 12)),
                    ],
                  ),
                ),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(children: [
                      _cell('${p.width.toStringAsFixed(0)} x ${p.height.toStringAsFixed(0)} мм', font: font),
                      _cell('Площадь: ${p.area.toStringAsFixed(3)} м2', font: font),
                      _cell('${p.pricePerSqm.toStringAsFixed(0)} руб/м2', font: font),
                      _cell('${(p.area * p.pricePerSqm).toStringAsFixed(2)} руб.', font: font, right: true),
                    ]),
                    ...p.processings.map((proc) => pw.TableRow(children: [
                      _cell(proc.name, font: font),
                      _cell('Периметр: ${p.perimeter.toStringAsFixed(2)} м', font: font),
                      _cell('${proc.pricePerMeter.toStringAsFixed(0)} руб/м', font: font),
                      _cell('${proc.totalPrice.toStringAsFixed(2)} руб.', font: font, right: true),
                    ])),
                    ...p.pieceWorks.map((pw2) => pw.TableRow(children: [
                      _cell(pw2.name, font: font),
                      _cell('${pw2.quantity} шт', font: font),
                      _cell('${pw2.unitPrice.toStringAsFixed(0)} руб/шт', font: font),
                      _cell('${pw2.totalPrice.toStringAsFixed(2)} руб.', font: font, right: true),
                    ])),
                  ],
                ),
                pw.SizedBox(height: 12),
              ],
            );
          }),

          if (calculation.servicesTotal > 0) ...[
            pw.Text('Дополнительные услуги', style: pw.TextStyle(font: fontBold, fontSize: 13)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                if (calculation.delivery > 0)
                  pw.TableRow(children: [_cell('Доставка', font: font), _cell('${calculation.delivery.toStringAsFixed(2)} руб.', font: font, right: true)]),
                if (calculation.lifting > 0)
                  pw.TableRow(children: [_cell('Подъём', font: font), _cell('${calculation.lifting.toStringAsFixed(2)} руб.', font: font, right: true)]),
                if (calculation.consumables > 0)
                  pw.TableRow(children: [_cell('Расходники', font: font), _cell('${calculation.consumables.toStringAsFixed(2)} руб.', font: font, right: true)]),
                if (calculation.measurement > 0)
                  pw.TableRow(children: [_cell('Замер', font: font), _cell('${calculation.measurement.toStringAsFixed(2)} руб.', font: font, right: true)]),
                if (calculation.installation > 0)
                  pw.TableRow(children: [_cell('Монтаж', font: font), _cell('${calculation.installation.toStringAsFixed(2)} руб.', font: font, right: true)]),
              ],
            ),
            pw.SizedBox(height: 12),
          ],

          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Изделия: ${calculation.productsTotal.toStringAsFixed(2)} руб.',
                      style: pw.TextStyle(font: font, fontSize: 12)),
                  pw.Text('Услуги: ${calculation.servicesTotal.toStringAsFixed(2)} руб.',
                      style: pw.TextStyle(font: font, fontSize: 12)),
                  pw.SizedBox(height: 4),
                  pw.Text('ИТОГО: ${calculation.totalPrice.toStringAsFixed(2)} руб.',
                      style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.blue700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${calculation.title}.pdf',
    );
  }

  static pw.Widget _cell(String text, {required pw.Font font, bool right = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text,
          textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
          style: pw.TextStyle(font: font, fontSize: 10)),
    );
  }
}