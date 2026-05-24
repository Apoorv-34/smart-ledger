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
      } else if (firstWord.contains('mi')) {
        brand = 'Mi';
        modelStr = modelParts.sublist(1).join(' ').trim();
      } else if (firstWord.contains('redmi')) {
        brand = 'Redmi';
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
         if (lowerLine.contains('mi ')) { currentBrand = 'Mi'; continue; }
         if (lowerLine.contains('redmi')) { currentBrand = 'Redmi'; continue; }
         if (lowerLine.contains('oneplus')) { currentBrand = 'OnePlus'; continue; }
         if (lowerLine.contains('moto')) { currentBrand = 'Motorola'; continue; }
         if (lowerLine.contains('infinix')) { currentBrand = 'Infinix'; continue; }
         if (lowerLine.contains('tecno')) { currentBrand = 'Tecno'; continue; }
         if (lowerLine.contains('itel')) { currentBrand = 'Itel'; continue; }
         if (lowerLine.contains('poco')) { currentBrand = 'Poco'; continue; }
      }

      String preprocessed = line
         .replaceAll(RegExp(r'(one\+|1\+)', caseSensitive: false), 'OnePlus ')
         .replaceAll(RegExp(r'I PHONE', caseSensitive: false), 'IPHONE')
         .replaceAll(RegExp(r'WITH FRAME', caseSensitive: false), 'WF')
         .replaceAll(RegExp(r'WITH SENSOR FLEX', caseSensitive: false), 'FLEX')
         .replaceAll(RegExp(r'SET REMOVED', caseSensitive: false), 'PULLED');

      String rawModel = preprocessed;
      String pricesStr = '';
      
      // Suppliers often use multiple dots to separate the model from the price
      final dotSplit = preprocessed.split(RegExp(r'\.{2,}'));
      if (dotSplit.length > 1) {
          rawModel = dotSplit.first.trim();
          pricesStr = dotSplit.sublist(1).join('.').trim();
      } else {
          // Fallback: look for numbers at the end of the string
          final priceRegex = RegExp(r'([\d]+(?:[/\s-]+[\d]+)*)\s*(?:\((.*?)\))?\s*$');
          final match = priceRegex.firstMatch(preprocessed);
          if (match != null) {
              pricesStr = preprocessed.substring(match.start).trim();
              rawModel = preprocessed.substring(0, match.start).trim();
          }
      }

      final details = _extractDetails(rawModel, currentBrand);
      final models = details['model']!.split('/');
      
      final options = pricesStr.split('/').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      
      for (var modelStr in models) {
         modelStr = modelStr.trim();
         if (modelStr.isEmpty) continue;

         if (options.isEmpty) {
             parsedItems.add(InventoryItem(
                brand: details['brand']!,
                model: modelStr,
                qualityGrade: details['quality']!,
                wholesalePrice: 0.0,
                retailPrice: 0.0,
                stockCount: defaultQuantity,
             ));
             continue;
         }

         double lastPrice = 0.0;
         for (var option in options) {
             final priceMatch = RegExp(r'\d+').firstMatch(option);
             double currentPrice = lastPrice;
             if (priceMatch != null) {
                 currentPrice = double.parse(priceMatch.group(0)!);
                 lastPrice = currentPrice;
             }
             
             String modifier = option.replaceAll(RegExp(r'\d+'), '').replaceAll(RegExp(r'[\(\)]'), '').trim();
             
             String quality = details['quality']!;
             if (modifier.isNotEmpty) {
                quality = quality == 'Standard' ? modifier.toUpperCase() : '$quality ${modifier.toUpperCase()}';
             } else if (options.length > 1) {
                quality = '$quality Option ${options.indexOf(option) + 1}'; 
             }
             
             parsedItems.add(InventoryItem(
                brand: details['brand']!,
                model: modelStr,
                qualityGrade: quality,
                wholesalePrice: currentPrice,
                retailPrice: currentPrice == 0.0 ? 0.0 : (isWholesalePrice ? currentPrice + profitMargin : currentPrice),
                stockCount: defaultQuantity,
             ));
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
