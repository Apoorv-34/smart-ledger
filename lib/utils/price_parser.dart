import '../models/inventory_item.dart';

class PriceParser {
  // Normalizes a brand and model string into a pure alphanumeric ID for smart matching
  // "Apple", "iphne 13 mini" -> "13mini"
  static String normalizeModel(String brand, String model) {
    String s = '${brand.toLowerCase()} ${model.toLowerCase()}';
    final toRemove = ['apple', 'iphone', 'iphne', 'iph', 'samsung', 'sam', 'galaxy', 'xiaomi', 'redmi', 'mi', 'poco', 'vivo', 'oppo', 'oneplus'];
    for (var word in toRemove) {
      s = s.replaceAll(RegExp('\\b$word\\b'), '');
    }
    return s.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static final List<String> knownQualities = [
    'oled', 'incell', 'og', 'orig', 'original', 'care', 'wf', 'full', 'glass', 'tft', 'copy', 'crown', 'diamond', 'lcd', 'gx', 'hard', 'soft', 'china', 'meetoo', 'ring', 'fresh', 'fog', 'dd', 'gc', 'flex', 'pulled'
  ];

  static Map<String, String> _extractDetails(String raw, String fallbackBrand) {
    // Clean punctuation
    String cleanStr = raw.replaceAll(RegExp(r'[.\-,_=]+'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    
    List<String> foundQualities = [];
    List<String> modelParts = [];
    
    for (var part in cleanStr.split(' ')) {
      if (knownQualities.contains(part.toLowerCase())) {
        foundQualities.add(part);
      } else {
        modelParts.add(part);
      }
    }
    
    String quality = foundQualities.isEmpty ? 'Standard' : foundQualities.join(' ').toUpperCase();
    String modelStr = modelParts.join(' ').trim();
    String brand = '';
    
    if (modelParts.isNotEmpty) {
      final firstWord = modelParts[0].toLowerCase();
      if (firstWord.contains('iph') || firstWord.contains('apple')) {
        brand = 'Apple';
        modelStr = modelParts.sublist(1).join(' ').trim();
      } else if (firstWord.contains('sam')) {
        brand = 'Samsung';
        modelStr = modelParts.sublist(1).join(' ').trim();
      } else if (firstWord.contains('mi') || firstWord.contains('poco') || firstWord.contains('redmi')) {
        brand = 'Xiaomi';
        modelStr = modelParts.sublist(1).join(' ').trim();
      } else if (firstWord.contains('vivo')) {
        brand = 'Vivo';
        modelStr = modelParts.sublist(1).join(' ').trim();
      } else if (firstWord.contains('oppo')) {
        brand = 'Oppo';
        modelStr = modelParts.sublist(1).join(' ').trim();
      } else if (firstWord.contains('oneplus') || firstWord == '1+') {
        brand = 'OnePlus';
        modelStr = modelParts.sublist(1).join(' ').trim();
      } else if (firstWord.contains('moto')) {
        brand = 'Motorola';
        modelStr = modelParts.sublist(1).join(' ').trim();
      } else if (firstWord.contains('infinix')) {
        brand = 'Infinix';
        modelStr = modelParts.sublist(1).join(' ').trim();
      } else if (firstWord.contains('tecno')) {
        brand = 'Tecno';
        modelStr = modelParts.sublist(1).join(' ').trim();
      } else if (firstWord.contains('itel')) {
        brand = 'Itel';
        modelStr = modelParts.sublist(1).join(' ').trim();
      } else if (firstWord.contains('micromax')) {
        brand = 'Micromax';
        modelStr = modelParts.sublist(1).join(' ').trim();
      } else if (firstWord.contains('asus')) {
        brand = 'Asus';
        modelStr = modelParts.sublist(1).join(' ').trim();
      } else if (firstWord.contains('honor')) {
        brand = 'Honor';
        modelStr = modelParts.sublist(1).join(' ').trim();
      } else if (firstWord.contains('lava')) {
        brand = 'Lava';
        modelStr = modelParts.sublist(1).join(' ').trim();
      } else if (firstWord.contains('google') || firstWord.contains('pixel')) {
        brand = 'Google';
        if (firstWord.contains('google')) modelStr = modelParts.sublist(1).join(' ').trim();
      } else if (firstWord.contains('nothing')) {
        brand = 'Nothing';
        modelStr = modelParts.sublist(1).join(' ').trim();
      } else if (firstWord.contains('realme') || firstWord.contains('narzo')) {
        brand = 'Realme';
        if (firstWord.contains('realme')) modelStr = modelParts.sublist(1).join(' ').trim();
      } else if (firstWord.contains('poco')) {
        brand = 'Poco';
        modelStr = modelParts.sublist(1).join(' ').trim();
      } else if (firstWord.contains('iq') || firstWord.contains('iqoo')) {
        brand = 'iQOO';
        if (firstWord == 'iq' || firstWord == 'iqoo') modelStr = modelParts.sublist(1).join(' ').trim();
      }
    }
    
    if (modelStr.isEmpty && modelParts.isNotEmpty) {
       modelStr = modelParts[0];
    } else if (modelStr.isEmpty) {
       modelStr = 'Unknown Model';
    }

    if (brand.isEmpty) {
        brand = fallbackBrand == 'Unknown' ? '' : fallbackBrand;
    }

    return {
      'brand': brand,
      'model': modelStr,
      'quality': quality,
    };
  }

  // A generic matcher. Extracts Model and Price from lines like:
  // "iPh13 mini OLED 2500" -> Model: iPh13 mini, Quality: OLED, Price: 2500
  static List<InventoryItem> parseWhatsAppText(String text, double profitMargin, {bool isWholesalePrice = true, int defaultQuantity = 0}) {
    final List<InventoryItem> parsedItems = [];
    final lines = text.split('\n');

    String currentBrand = 'Unknown';

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Check for headers (e.g., "🔥🔥Samsung🔥🔥")
      final lowerLine = line.toLowerCase();
      if (!lowerLine.contains(RegExp(r'\d')) || (lowerLine.length < 20 && !lowerLine.contains('.'))) {
         if (lowerLine.contains('samsung')) { currentBrand = 'Samsung'; continue; }
         if (lowerLine.contains('i phone') || lowerLine.contains('iphone') || lowerLine.contains('apple')) { currentBrand = 'Apple'; continue; }
         if (lowerLine.contains('vivo')) { currentBrand = 'Vivo'; continue; }
         if (lowerLine.contains('oppo')) { currentBrand = 'Oppo'; continue; }
         if (lowerLine.contains('mi ') || lowerLine.contains('redmi') || lowerLine.contains('xiaomi')) { currentBrand = 'Xiaomi'; continue; }
         if (lowerLine.contains('oneplus')) { currentBrand = 'OnePlus'; continue; }
         if (lowerLine.contains('moto')) { currentBrand = 'Motorola'; continue; }
         if (lowerLine.contains('infinix')) { currentBrand = 'Infinix'; continue; }
         if (lowerLine.contains('tecno')) { currentBrand = 'Tecno'; continue; }
         if (lowerLine.contains('itel')) { currentBrand = 'Itel'; continue; }
      }

      // 1. Find price and optional quality modifier at the end
      // Example: "480", "480/550(MEETOO)", "500(CROWN)"
      final priceRegex = RegExp(r'([\d]+(?:[/\s-]+[\d]+)*)\s*(?:\((.*?)\))?\s*$');
      final match = priceRegex.firstMatch(line);

      if (match != null) {
        final String rawPrices = match.group(1)!;
        final String? modifier = match.group(2);

        final String rawModelInfo = line.substring(0, match.start).trim();

        // Preprocess aliases
        String preprocessed = rawModelInfo
           .replaceAll(RegExp(r'(one\+|1\+)', caseSensitive: false), 'OnePlus ')
           .replaceAll(RegExp(r'I PHONE', caseSensitive: false), 'IPHONE')
           .replaceAll(RegExp(r'WITH FRAME', caseSensitive: false), 'WF')
           .replaceAll(RegExp(r'WITH SENSOR FLEX', caseSensitive: false), 'FLEX')
           .replaceAll(RegExp(r'SET REMOVED', caseSensitive: false), 'PULLED');

        final details = _extractDetails(preprocessed, currentBrand);

        // Split models by slash, e.g., "A30/A50/A50S" -> ["A30", "A50", "A50S"]
        final models = details['model']!.split('/');

        // Parse prices
        final priceStrs = rawPrices.split(RegExp(r'[/\s-]+')).where((s) => s.isNotEmpty).toList();
        List<double> parsedPrices = priceStrs.map((s) => double.tryParse(s) ?? 0.0).toList();

        for (var modelStr in models) {
           modelStr = modelStr.trim();
           if (modelStr.isEmpty) continue;

           // First price option
           if (parsedPrices.isNotEmpty) {
               double wholesale = parsedPrices[0];
               double retail = isWholesalePrice ? wholesale + profitMargin : wholesale;

               String quality = details['quality']!;
               if (parsedPrices.length == 1 && modifier != null) {
                  quality = quality == 'Standard' ? modifier.toUpperCase() : '$quality ${modifier.toUpperCase()}';
               }

               parsedItems.add(InventoryItem(
                  brand: details['brand']!,
                  model: modelStr,
                  qualityGrade: quality,
                  wholesalePrice: wholesale,
                  retailPrice: retail,
                  stockCount: defaultQuantity,
               ));
           }

           // Second price option
           if (parsedPrices.length > 1) {
               double wholesale = parsedPrices[1];
               double retail = isWholesalePrice ? wholesale + profitMargin : wholesale;

               String quality = details['quality']!;
               if (modifier != null) {
                  quality = quality == 'Standard' ? modifier.toUpperCase() : '$quality ${modifier.toUpperCase()}';
               } else {
                  quality = '$quality Option 2';
               }

               parsedItems.add(InventoryItem(
                  brand: details['brand']!,
                  model: modelStr,
                  qualityGrade: quality,
                  wholesalePrice: wholesale,
                  retailPrice: retail,
                  stockCount: defaultQuantity,
               ));
           }
        }
      }
    }

    return parsedItems;
  }

  // Parses text where the number at the end is the STOCK QUANTITY instead of price
  // e.g., "iPh13 mini OLED 5" -> Model: iPh13 mini, Quality: OLED, Stock: 5
  static List<InventoryItem> parseStockUpdateText(String text) {
    final List<InventoryItem> parsedItems = [];
    final lines = text.split('\n');

    String currentBrand = 'Unknown';

    // Matches any line ending with a number (with optional spaces or 'pcs' at the end)
    final qtyRegex = RegExp(r'(.*?)\s+(\d+)\s*(?:pcs|pieces)?\s*$', caseSensitive: false);

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      final lowerLine = line.toLowerCase();
      if (!lowerLine.contains(RegExp(r'\d')) || (lowerLine.length < 20 && !lowerLine.contains('.'))) {
         if (lowerLine.contains('samsung')) { currentBrand = 'Samsung'; continue; }
         if (lowerLine.contains('i phone') || lowerLine.contains('iphone') || lowerLine.contains('apple')) { currentBrand = 'Apple'; continue; }
      }

      final match = qtyRegex.firstMatch(line);
      if (match != null) {
        final int quantity = int.parse(match.group(2)!);
        final String rawModelInfo = match.group(1)!.trim();

        String preprocessed = rawModelInfo
           .replaceAll(RegExp(r'(one\+|1\+)', caseSensitive: false), 'OnePlus ')
           .replaceAll(RegExp(r'I PHONE', caseSensitive: false), 'IPHONE')
           .replaceAll(RegExp(r'WITH FRAME', caseSensitive: false), 'WF')
           .replaceAll(RegExp(r'WITH SENSOR FLEX', caseSensitive: false), 'FLEX')
           .replaceAll(RegExp(r'SET REMOVED', caseSensitive: false), 'PULLED');

        final details = _extractDetails(preprocessed, currentBrand);
        
        final models = details['model']!.split('/');
        
        for (var modelStr in models) {
           modelStr = modelStr.trim();
           if (modelStr.isEmpty) continue;
           
           parsedItems.add(InventoryItem(
              brand: details['brand']!,
              model: modelStr,
              qualityGrade: details['quality']!,
              wholesalePrice: 0.0,
              retailPrice: 0.0,
              stockCount: quantity,
           ));
        }
      }
    }
    
    return parsedItems;
  }
}
