import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/order.dart';
import '../models/invoice.dart';
import '../models/refund.dart';

/// InvoiceService - Genera facturas PDF de pedidos
/// Diseño replicado de la factura electrónica de la web JGMarket
class InvoiceService {
  /// Carga las fuentes que soportan el símbolo €
  static Future<Map<String, pw.Font>> _loadFonts() async {
    final regular = await PdfGoogleFonts.nunitoSansRegular();
    final bold = await PdfGoogleFonts.nunitoSansBold();
    return {'regular': regular, 'bold': bold};
  }

  /// Formatea precio con € correctamente
  static String _formatPrice(int cents) {
    return '${(cents / 100).toStringAsFixed(2)}\u20AC';
  }
  /// Genera y abre el diálogo de compartir/descargar la factura
  static Future<void> shareInvoice(Order order) async {
    final pdf = await _buildInvoicePdf(order);
    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'factura-${order.orderNumber}.pdf',
      subject: 'Factura JGMarket - Pedido #${order.orderNumber}',
    );
  }

  static Future<pw.Document> _buildInvoicePdf(Order order) async {
    final pdf = pw.Document();
    final fonts = await _loadFonts();
    final ttfRegular = fonts['regular']!;
    final ttfBold = fonts['bold']!;

    // Calcular subtotal desde items
    final subtotal = order.items.fold<int>(
      0,
      (sum, item) => sum + (item.priceCents * item.quantity),
    );

    // Número de factura: FAC-YYYY-XXXXX
    final year = order.createdAt.year;
    final shortId = order.orderNumber.replaceAll('JGM-', '');
    final invoiceNumber = 'FAC-$year-$shortId';

    // Fecha formateada
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    final dateStr =
        '${order.createdAt.day} de ${months[order.createdAt.month - 1]} de ${order.createdAt.year}';

    // Colores
    final darkNavy = PdfColor.fromHex('#1e293b');
    final accentRed = PdfColor.fromHex('#e53e3e');
    final lightBg = PdfColor.fromHex('#f8fafc');
    final borderColor = PdfColor.fromHex('#e2e8f0');
    final textGray = PdfColor.fromHex('#64748b');
    final darkText = PdfColor.fromHex('#1a202c');

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      theme: pw.ThemeData.withFont(base: ttfRegular, bold: ttfBold),
    );

    pdf.addPage(
      pw.Page(
        pageTheme: pageTheme,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ── CABECERA ──────────────────────────────────────────────
              pw.Container(
                color: darkNavy,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 28,
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Logo + subtítulo
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(
                                text: 'JG',
                                style: pw.TextStyle(
                                  color: accentRed,
                                  fontSize: 30,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.TextSpan(
                                text: 'MARKET',
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 30,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'FACTURA ELECTRÓNICA',
                          style: pw.TextStyle(
                            color: PdfColors.grey400,
                            fontSize: 9,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    // Número de factura + fechas
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          invoiceNumber,
                          style: pw.TextStyle(
                            color: accentRed,
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          'Fecha: $dateStr',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Pedido: #${order.orderNumber}',
                          style: pw.TextStyle(
                            color: PdfColors.grey400,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── CUERPO ───────────────────────────────────────────────
              pw.Expanded(
                child: pw.Container(
                  color: PdfColors.white,
                  padding: const pw.EdgeInsets.all(40),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Cliente + Empresa
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: _infoBox(
                              title: 'DATOS DEL CLIENTE',
                              lines: [
                                pw.Text(
                                  order.shippingAddress?.name ??
                                      order.userEmail ??
                                      'Cliente',
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 13,
                                    color: darkText,
                                  ),
                                ),
                                if (order.userEmail != null)
                                  pw.Text(
                                    order.userEmail!,
                                    style: pw.TextStyle(
                                      fontSize: 11,
                                      color: textGray,
                                    ),
                                  ),
                                if (order.shippingAddress != null) ...[
                                  pw.SizedBox(height: 4),
                                  pw.Text(
                                    order.shippingAddress!.street,
                                    style: pw.TextStyle(
                                        fontSize: 10, color: textGray),
                                  ),
                                  pw.Text(
                                    '${order.shippingAddress!.postalCode} ${order.shippingAddress!.city}, ${order.shippingAddress!.country}',
                                    style: pw.TextStyle(
                                        fontSize: 10, color: textGray),
                                  ),
                                ],
                              ],
                              lightBg: lightBg,
                              textGray: textGray,
                            ),
                          ),
                          pw.SizedBox(width: 16),
                          pw.Expanded(
                            child: _infoBox(
                              title: 'DATOS DE LA EMPRESA',
                              lines: [
                                pw.Text(
                                  'JGMarket',
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 13,
                                    color: darkText,
                                  ),
                                ),
                                pw.Text(
                                  'CIF: B-12345678',
                                  style: pw.TextStyle(
                                      fontSize: 11, color: textGray),
                                ),
                                pw.Text(
                                  'info@jgmarket.com',
                                  style: pw.TextStyle(
                                      fontSize: 11, color: textGray),
                                ),
                              ],
                              lightBg: lightBg,
                              textGray: textGray,
                            ),
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 32),

                      // Tabla de productos
                      pw.Table(
                        columnWidths: {
                          0: const pw.FlexColumnWidth(4),
                          1: const pw.FixedColumnWidth(65),
                          2: const pw.FixedColumnWidth(90),
                          3: const pw.FixedColumnWidth(90),
                        },
                        border: pw.TableBorder(
                          bottom: pw.BorderSide(color: borderColor),
                          horizontalInside: pw.BorderSide(color: borderColor, width: 0.5),
                        ),
                        children: [
                          // Cabecera tabla
                          pw.TableRow(
                            decoration: pw.BoxDecoration(
                              border: pw.Border(
                                bottom: pw.BorderSide(color: borderColor, width: 1.5),
                              ),
                            ),
                            children:
                                ['PRODUCTO', 'CANTIDAD', 'PRECIO UNIT.', 'SUBTOTAL']
                                    .map(
                                      (h) => pw.Padding(
                                        padding: const pw.EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 8),
                                        child: pw.Text(
                                          h,
                                          style: pw.TextStyle(
                                            fontSize: 9,
                                            color: textGray,
                                            fontWeight: pw.FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                          // Filas de productos
                          if (order.items.isEmpty)
                            pw.TableRow(
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(12),
                                  child: pw.Text(
                                    'Sin productos',
                                    style: pw.TextStyle(color: textGray, fontSize: 11),
                                  ),
                                ),
                                pw.SizedBox(),
                                pw.SizedBox(),
                                pw.SizedBox(),
                              ],
                            ),
                          ...order.items.map(
                            (item) => pw.TableRow(
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 8),
                                  child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(item.productName,
                                          style: pw.TextStyle(fontSize: 11, color: darkText)),
                                      if (item.size != null)
                                        pw.Text(
                                          'Talla: ${item.size}',
                                          style: pw.TextStyle(fontSize: 9, color: textGray),
                                        ),
                                    ],
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 8),
                                  child: pw.Text(
                                    '${item.quantity}',
                                    style: pw.TextStyle(fontSize: 11, color: darkText),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 8),
                                  child: pw.Text(
                                    '\u20AC${(item.priceCents / 100).toStringAsFixed(2)}',
                                    style: pw.TextStyle(fontSize: 11, color: darkText),
                                    textAlign: pw.TextAlign.right,
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 8),
                                  child: pw.Text(
                                    '\u20AC${((item.priceCents * item.quantity) / 100).toStringAsFixed(2)}',
                                    style: pw.TextStyle(fontSize: 11, color: darkText),
                                    textAlign: pw.TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 24),

                      // Totales (derecha)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Container(
                            width: 260,
                            padding: const pw.EdgeInsets.all(20),
                            decoration: pw.BoxDecoration(
                              color: lightBg,
                              borderRadius: pw.BorderRadius.circular(8),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                              children: [
                                _totalRow(
                                  'Subtotal',
                                  '\u20AC${(subtotal / 100).toStringAsFixed(2)}',
                                  textGray,
                                ),
                                if (order.shippingCents > 0)
                                  _totalRow(
                                    'Envío',
                                    '\u20AC${(order.shippingCents / 100).toStringAsFixed(2)}',
                                    textGray,
                                  ),
                                if (order.discountCents != null &&
                                    order.discountCents! > 0)
                                  _totalRow(
                                    'Descuento',
                                    '-€${(order.discountCents! / 100).toStringAsFixed(2)}',
                                    textGray,
                                  ),
                                pw.SizedBox(height: 8),
                                pw.Divider(color: borderColor),
                                pw.SizedBox(height: 8),
                                pw.Row(
                                  mainAxisAlignment:
                                      pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text(
                                      'Total',
                                      style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 14,
                                        color: darkText,
                                      ),
                                    ),
                                    pw.Text(
                                      '\u20AC${(order.totalCents / 100).toStringAsFixed(2)}',
                                      style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 18,
                                        color: accentRed,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      pw.SizedBox(height: 40),

                      // Pie de página
                      pw.Center(
                        child: pw.Text(
                          'Esta es una factura electrónica generada automáticamente.',
                          style: pw.TextStyle(color: textGray, fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _infoBox({
    required String title,
    required List<pw.Widget> lines,
    required PdfColor lightBg,
    required PdfColor textGray,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: lightBg,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              color: textGray,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 8),
          ...lines,
        ],
      ),
    );
  }

  static pw.Widget _totalRow(String label, String value, PdfColor textGray) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(fontSize: 11, color: textGray)),
          pw.Text(value, style: pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  // ── FACTURA DESDE MODELO INVOICE ────────────────────────────────
  /// Genera y descarga PDF desde un objeto Invoice (usado en admin)
  static Future<void> shareInvoiceFromModel(Invoice invoice) async {
    final pdf = await _buildInvoiceFromModelPdf(invoice);
    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'factura-${invoice.invoiceNumber}.pdf',
      subject: 'Factura JGMarket - ${invoice.invoiceNumber}',
    );
  }

  static Future<pw.Document> _buildInvoiceFromModelPdf(Invoice invoice) async {
    final pdf = pw.Document();
    final fonts = await _loadFonts();
    final ttfRegular = fonts['regular']!;
    final ttfBold = fonts['bold']!;

    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    final dateStr =
        '${invoice.issuedAt.day} de ${months[invoice.issuedAt.month - 1]} de ${invoice.issuedAt.year}';

    final darkNavy = PdfColor.fromHex('#1e293b');
    final accentColor = invoice.isCreditNote
        ? PdfColor.fromHex('#dd6b20')
        : PdfColor.fromHex('#e53e3e');
    final lightBg = PdfColor.fromHex('#f8fafc');
    final borderColor = PdfColor.fromHex('#e2e8f0');
    final textGray = PdfColor.fromHex('#64748b');
    final darkText = PdfColor.fromHex('#1a202c');

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      theme: pw.ThemeData.withFont(base: ttfRegular, bold: ttfBold),
    );

    pdf.addPage(
      pw.Page(
        pageTheme: pageTheme,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ── CABECERA ──
              pw.Container(
                color: darkNavy,
                padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 28),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.RichText(
                          text: pw.TextSpan(children: [
                            pw.TextSpan(
                              text: 'JG',
                              style: pw.TextStyle(color: accentColor, fontSize: 30, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.TextSpan(
                              text: 'MARKET',
                              style: pw.TextStyle(color: PdfColors.white, fontSize: 30, fontWeight: pw.FontWeight.bold),
                            ),
                          ]),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          invoice.isCreditNote ? 'NOTA DE CRÉDITO' : 'FACTURA ELECTRÓNICA',
                          style: pw.TextStyle(color: PdfColors.grey400, fontSize: 9, letterSpacing: 2),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          invoice.invoiceNumber,
                          style: pw.TextStyle(color: accentColor, fontSize: 22, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text('Fecha: $dateStr', style: pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                        pw.SizedBox(height: 2),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: pw.BoxDecoration(
                            color: accentColor,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            invoice.statusDisplay.toUpperCase(),
                            style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── CUERPO ──
              pw.Expanded(
                child: pw.Container(
                  color: PdfColors.white,
                  padding: const pw.EdgeInsets.all(40),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: _infoBox(
                              title: 'DATOS DEL CLIENTE',
                              lines: [
                                pw.Text(
                                  invoice.customerName.isNotEmpty ? invoice.customerName : invoice.customerEmail,
                                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: darkText),
                                ),
                                pw.Text(invoice.customerEmail, style: pw.TextStyle(fontSize: 11, color: textGray)),
                              ],
                              lightBg: lightBg,
                              textGray: textGray,
                            ),
                          ),
                          pw.SizedBox(width: 16),
                          pw.Expanded(
                            child: _infoBox(
                              title: 'DATOS DE LA EMPRESA',
                              lines: [
                                pw.Text('JGMarket', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: darkText)),
                                pw.Text('CIF: B-12345678', style: pw.TextStyle(fontSize: 11, color: textGray)),
                                pw.Text('info@jgmarket.com', style: pw.TextStyle(fontSize: 11, color: textGray)),
                              ],
                              lightBg: lightBg,
                              textGray: textGray,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 32),

                      // Tabla de items
                      pw.Table(
                        columnWidths: {
                          0: const pw.FlexColumnWidth(4),
                          1: const pw.FixedColumnWidth(65),
                          2: const pw.FixedColumnWidth(90),
                          3: const pw.FixedColumnWidth(90),
                        },
                        border: pw.TableBorder(
                          bottom: pw.BorderSide(color: borderColor),
                          horizontalInside: pw.BorderSide(color: borderColor, width: 0.5),
                        ),
                        children: [
                          pw.TableRow(
                            decoration: pw.BoxDecoration(
                              border: pw.Border(bottom: pw.BorderSide(color: borderColor, width: 1.5)),
                            ),
                            children: ['PRODUCTO', 'CANTIDAD', 'PRECIO UNIT.', 'SUBTOTAL']
                                .map((h) => pw.Padding(
                                      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                      child: pw.Text(h, style: pw.TextStyle(fontSize: 9, color: textGray, fontWeight: pw.FontWeight.bold)),
                                    ))
                                .toList(),
                          ),
                          if (invoice.items.isEmpty)
                            pw.TableRow(children: [
                              pw.Padding(padding: const pw.EdgeInsets.all(12), child: pw.Text('Sin artículos', style: pw.TextStyle(color: textGray, fontSize: 11))),
                              pw.SizedBox(), pw.SizedBox(), pw.SizedBox(),
                            ]),
                          ...invoice.items.map((item) {
                            final name = item['product_name'] as String? ?? item['name'] as String? ?? 'Producto';
                            final qty = (item['quantity'] as num?)?.toInt() ?? 1;
                            final priceCents = (item['price_cents'] as num?)?.toInt() ?? (item['price'] as num?)?.toInt() ?? 0;
                            final size = item['size'] as String?;
                            return pw.TableRow(children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                                  pw.Text(name, style: pw.TextStyle(fontSize: 11, color: darkText)),
                                  if (size != null) pw.Text('Talla: $size', style: pw.TextStyle(fontSize: 9, color: textGray)),
                                ]),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                child: pw.Text('$qty', style: pw.TextStyle(fontSize: 11, color: darkText), textAlign: pw.TextAlign.center),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                child: pw.Text('\u20AC${(priceCents / 100).toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 11, color: darkText), textAlign: pw.TextAlign.right),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                child: pw.Text('\u20AC${((priceCents * qty) / 100).toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 11, color: darkText), textAlign: pw.TextAlign.right),
                              ),
                            ]);
                          }),
                        ],
                      ),
                      pw.SizedBox(height: 24),

                      // Totales
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Container(
                            width: 260,
                            padding: const pw.EdgeInsets.all(20),
                            decoration: pw.BoxDecoration(color: lightBg, borderRadius: pw.BorderRadius.circular(8)),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                              children: [
                                _totalRow('Subtotal', '\u20AC${(invoice.subtotalCents / 100).toStringAsFixed(2)}', textGray),
                                if (invoice.taxCents > 0) _totalRow('IVA', '\u20AC${(invoice.taxCents / 100).toStringAsFixed(2)}', textGray),
                                pw.SizedBox(height: 8),
                                pw.Divider(color: borderColor),
                                pw.SizedBox(height: 8),
                                pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: darkText)),
                                    pw.Text('\u20AC${(invoice.totalCents / 100).toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: accentColor)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 40),
                      pw.Center(
                        child: pw.Text(
                          invoice.isCreditNote
                              ? 'Esta es una nota de crédito electrónica generada automáticamente.'
                              : 'Esta es una factura electrónica generada automáticamente.',
                          style: pw.TextStyle(color: textGray, fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  // ── FACTURA DE DEVOLUCIÓN ────────────────────────────────────────
  /// Genera y descarga PDF de nota de crédito/devolución
  static Future<void> shareRefundInvoice(Refund refund) async {
    final pdf = await _buildRefundPdf(refund);
    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'devolucion-${refund.id.substring(0, 8)}.pdf',
      subject: 'Nota de Crédito JGMarket - Devolución',
    );
  }

  static Future<pw.Document> _buildRefundPdf(Refund refund) async {
    final pdf = pw.Document();
    final fonts = await _loadFonts();
    final ttfRegular = fonts['regular']!;
    final ttfBold = fonts['bold']!;

    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    final dateStr =
        '${refund.createdAt.day} de ${months[refund.createdAt.month - 1]} de ${refund.createdAt.year}';

    final darkNavy = PdfColor.fromHex('#1e293b');
    final accentOrange = PdfColor.fromHex('#dd6b20');
    final lightBg = PdfColor.fromHex('#f8fafc');
    final borderColor = PdfColor.fromHex('#e2e8f0');
    final textGray = PdfColor.fromHex('#64748b');
    final darkText = PdfColor.fromHex('#1a202c');

    final refundNumber = 'DEV-${refund.createdAt.year}-${refund.id.substring(0, 5).toUpperCase()}';

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      theme: pw.ThemeData.withFont(base: ttfRegular, bold: ttfBold),
    );

    pdf.addPage(
      pw.Page(
        pageTheme: pageTheme,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ── CABECERA (naranja) ──
              pw.Container(
                color: darkNavy,
                padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 28),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.RichText(
                          text: pw.TextSpan(children: [
                            pw.TextSpan(text: 'JG', style: pw.TextStyle(color: accentOrange, fontSize: 30, fontWeight: pw.FontWeight.bold)),
                            pw.TextSpan(text: 'MARKET', style: pw.TextStyle(color: PdfColors.white, fontSize: 30, fontWeight: pw.FontWeight.bold)),
                          ]),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('NOTA DE CRÉDITO / DEVOLUCIÓN', style: pw.TextStyle(color: PdfColors.grey400, fontSize: 9, letterSpacing: 2)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(refundNumber, style: pw.TextStyle(color: accentOrange, fontSize: 22, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 6),
                        pw.Text('Fecha: $dateStr', style: pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                        pw.SizedBox(height: 2),
                        pw.Text('Pedido: ${refund.orderId.substring(0, 8)}...', style: pw.TextStyle(color: PdfColors.grey400, fontSize: 10)),
                        pw.SizedBox(height: 4),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: pw.BoxDecoration(color: accentOrange, borderRadius: pw.BorderRadius.circular(4)),
                          child: pw.Text(refund.statusText.toUpperCase(), style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── CUERPO ──
              pw.Expanded(
                child: pw.Container(
                  color: PdfColors.white,
                  padding: const pw.EdgeInsets.all(40),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Datos cliente + empresa
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: _infoBox(
                              title: 'DATOS DEL CLIENTE',
                              lines: [
                                pw.Text(
                                  refund.customerName.isNotEmpty ? refund.customerName : refund.customerEmail,
                                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: darkText),
                                ),
                                pw.Text(refund.customerEmail, style: pw.TextStyle(fontSize: 11, color: textGray)),
                              ],
                              lightBg: lightBg,
                              textGray: textGray,
                            ),
                          ),
                          pw.SizedBox(width: 16),
                          pw.Expanded(
                            child: _infoBox(
                              title: 'DATOS DE LA EMPRESA',
                              lines: [
                                pw.Text('JGMarket', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: darkText)),
                                pw.Text('CIF: B-12345678', style: pw.TextStyle(fontSize: 11, color: textGray)),
                                pw.Text('info@jgmarket.com', style: pw.TextStyle(fontSize: 11, color: textGray)),
                              ],
                              lightBg: lightBg,
                              textGray: textGray,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 24),

                      // Motivo de devolución
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.all(16),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#fffaf0'),
                          border: pw.Border.all(color: accentOrange, width: 0.5),
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('MOTIVO DE DEVOLUCIÓN', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: accentOrange, letterSpacing: 1)),
                            pw.SizedBox(height: 6),
                            pw.Text(refund.reason, style: pw.TextStyle(fontSize: 11, color: darkText)),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 24),

                      // Tabla artículos devueltos
                      pw.Table(
                        columnWidths: {
                          0: const pw.FlexColumnWidth(4),
                          1: const pw.FixedColumnWidth(65),
                          2: const pw.FixedColumnWidth(90),
                        },
                        border: pw.TableBorder(
                          bottom: pw.BorderSide(color: borderColor),
                          horizontalInside: pw.BorderSide(color: borderColor, width: 0.5),
                        ),
                        children: [
                          pw.TableRow(
                            decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: borderColor, width: 1.5))),
                            children: ['ARTÍCULO DEVUELTO', 'CANTIDAD', 'IMPORTE']
                                .map((h) => pw.Padding(
                                      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                      child: pw.Text(h, style: pw.TextStyle(fontSize: 9, color: textGray, fontWeight: pw.FontWeight.bold)),
                                    ))
                                .toList(),
                          ),
                          if (refund.returnedItems.isEmpty)
                            pw.TableRow(children: [
                              pw.Padding(padding: const pw.EdgeInsets.all(12), child: pw.Text('Sin artículos', style: pw.TextStyle(color: textGray, fontSize: 11))),
                              pw.SizedBox(), pw.SizedBox(),
                            ]),
                          ...refund.returnedItems.map((item) {
                            final name = item['product_name'] as String? ?? item['name'] as String? ?? 'Producto';
                            final qty = (item['quantity'] as num?)?.toInt() ?? 1;
                            final priceCents = (item['price_cents'] as num?)?.toInt() ?? (item['price'] as num?)?.toInt() ?? 0;
                            return pw.TableRow(children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                child: pw.Text(name, style: pw.TextStyle(fontSize: 11, color: darkText)),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                child: pw.Text('$qty', style: pw.TextStyle(fontSize: 11, color: darkText), textAlign: pw.TextAlign.center),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                child: pw.Text('\u20AC${((priceCents * qty) / 100).toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 11, color: darkText), textAlign: pw.TextAlign.right),
                              ),
                            ]);
                          }),
                        ],
                      ),
                      pw.SizedBox(height: 24),

                      // Total reembolso
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Container(
                            width: 260,
                            padding: const pw.EdgeInsets.all(20),
                            decoration: pw.BoxDecoration(color: PdfColor.fromHex('#fffaf0'), borderRadius: pw.BorderRadius.circular(8)),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                              children: [
                                _totalRow('Método', refund.refundMethod == 'original_payment' ? 'Pago original' : refund.refundMethod, textGray),
                                pw.SizedBox(height: 8),
                                pw.Divider(color: borderColor),
                                pw.SizedBox(height: 8),
                                pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Text('Total Reembolso', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: darkText)),
                                    pw.Text('\u20AC${(refund.refundAmountCents / 100).toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: accentOrange)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 40),
                      pw.Center(
                        child: pw.Text(
                          'Esta es una nota de crédito electrónica generada automáticamente.',
                          style: pw.TextStyle(color: textGray, fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
    return pdf;
  }
}
