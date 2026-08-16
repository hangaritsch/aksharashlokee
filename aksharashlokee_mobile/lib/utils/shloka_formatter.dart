class ShlokaFormatter {
  /// Cleans up raw shloka text by removing extra blank lines,
  /// trimming line padding, and standardizing line breaks.
  static String formatContent(String content) {
    if (content.isEmpty) return content;

    // Split lines and trim individual line whitespace
    final lines = content.split('\n');
    final cleanedLines = <String>[];

    for (var line in lines) {
      final trimmed = line.trim();
      // Only keep non-empty lines
      if (trimmed.isNotEmpty) {
        cleanedLines.add(trimmed);
      }
    }

    // Join with single newlines
    return cleanedLines.join('\n');
  }
}

class DevanagariTransliterater {
  // Mapping table for ITRANS / English to Devanagari transliteration
  static final Map<String, String> _vowels = {
    'aa': 'आ', 'A': 'आ',
    'ii': 'ई', 'I': 'ई', 'ee': 'ई',
    'uu': 'ऊ', 'U': 'ऊ', 'oo': 'ऊ',
    'RRi': 'ऋ', 'R^i': 'ऋ',
    'e': 'ए',
    'ai': 'ऐ',
    'o': 'ओ',
    'au': 'औ', 'ou': 'औ',
    'a': 'अ',
    'i': 'इ',
    'u': 'उ',
    'M': 'ं', 'nM': 'ं',
    'H': 'ः',
  };

  static final Map<String, String> _vowelMarks = {
    'aa': 'ा', 'A': 'ा',
    'ii': 'ी', 'I': 'ी', 'ee': 'ी',
    'uu': 'ू', 'U': 'ू', 'oo': 'ू',
    'RRi': 'ृ', 'R^i': 'ृ',
    'e': 'े',
    'ai': 'ै',
    'o': 'ो',
    'au': 'ौ', 'ou': 'ौ',
    'a': '', // Halant removal
    'i': 'ि',
    'u': 'ु',
  };

  static final Map<String, String> _consonants = {
    'ksha': 'क्ष', 'kSh': 'क्ष', 'kSH': 'क्ष',
    'jnya': 'ज्ञ', 'GY': 'ज्ञ', 'dnya': 'ज्ञ',
    'kh': 'ख', 'Kh': 'ख',
    'gh': 'घ', 'Gh': 'घ',
    'chh': 'छ', 'Ch': 'छ', 'CH': 'छ',
    'jh': 'झ', 'Jh': 'झ',
    'Th': 'ठ',
    'Dh': 'ढ',
    'th': 'थ', 'Thh': 'थ',
    'dh': 'ध',
    'ph': 'फ', 'Ph': 'फ', 'f': 'फ',
    'bh': 'भ', 'Bh': 'भ',
    'shh': 'ष', 'Sh': 'ष', 'SH': 'ष',
    'sh': 'श', 'sH': 'श',
    'k': 'क',
    'g': 'ग',
    'ch': 'च', 'c': 'च',
    'j': 'ज',
    'T': 'ट',
    'D': 'ड',
    'N': 'ण',
    't': 'त',
    'd': 'द',
    'n': 'न',
    'p': 'प',
    'b': 'ब',
    'm': 'म',
    'y': 'य',
    'r': 'र',
    'l': 'ल',
    'v': 'व', 'w': 'व',
    's': 'स',
    'h': 'ह',
    'L': 'ळ',
  };

  /// Transliterates ASCII/English input string into Devanagari text
  static String transliterate(String input) {
    if (input.trim().isEmpty) return input;
    
    // If input is already primarily Devanagari, return as is
    if (RegExp(r'[\u0900-\u097F]').hasMatch(input)) {
      return input;
    }

    String src = input.toLowerCase();
    StringBuffer result = StringBuffer();
    int i = 0;
    int len = src.length;

    while (i < len) {
      // Check for whitespace or punctuation
      if (RegExp(r'[\s\d.,!?:;\-/\\]').hasMatch(src[i])) {
        result.write(src[i]);
        i++;
        continue;
      }

      // Try 3-char consonant match
      String? matchConsonant;
      int matchLen = 0;

      for (var key in ['ksha', 'ksh', 'chh', 'jnya', 'dnya', 'shh']) {
        if (i + key.length <= len && src.substring(i, i + key.length) == key) {
          matchConsonant = _consonants[key];
          matchLen = key.length;
          break;
        }
      }

      // Try 2-char consonant match
      if (matchConsonant == null) {
        for (var key in ['kh', 'gh', 'ch', 'jh', 'th', 'dh', 'ph', 'bh', 'sh']) {
          if (i + key.length <= len && src.substring(i, i + key.length) == key) {
            matchConsonant = _consonants[key];
            matchLen = key.length;
            break;
          }
        }
      }

      // Try 1-char consonant match
      if (matchConsonant == null) {
        String single = src[i];
        if (_consonants.containsKey(single)) {
          matchConsonant = _consonants[single];
          matchLen = 1;
        }
      }

      if (matchConsonant != null) {
        i += matchLen;
        // Look ahead for vowel marks
        String? matchVowelMark;
        int vowelLen = 0;

        for (var vKey in ['aa', 'ii', 'ee', 'uu', 'oo', 'ai', 'au', 'ou']) {
          if (i + vKey.length <= len && src.substring(i, i + vKey.length) == vKey) {
            matchVowelMark = _vowelMarks[vKey];
            vowelLen = vKey.length;
            break;
          }
        }

        if (matchVowelMark == null) {
          for (var vKey in ['a', 'i', 'u', 'e', 'o']) {
            if (i + vKey.length <= len && src.substring(i, i + vKey.length) == vKey) {
              matchVowelMark = _vowelMarks[vKey];
              vowelLen = vKey.length;
              break;
            }
          }
        }

        if (matchVowelMark != null) {
          result.write(matchConsonant + matchVowelMark);
          i += vowelLen;
        } else {
          // No vowel following, add halant or implicit vowel 'a'
          // Standard typing defaults to implicit 'a' vowel unless ended
          result.write(matchConsonant);
        }
        continue;
      }

      // Check independent vowels
      String? matchVowel;
      int vLen = 0;

      for (var vKey in ['aa', 'ii', 'ee', 'uu', 'oo', 'ai', 'au', 'ou']) {
        if (i + vKey.length <= len && src.substring(i, i + vKey.length) == vKey) {
          matchVowel = _vowels[vKey];
          vLen = vKey.length;
          break;
        }
      }

      if (matchVowel == null) {
        for (var vKey in ['a', 'i', 'u', 'e', 'o']) {
          if (i + vKey.length <= len && src.substring(i, i + vKey.length) == vKey) {
            matchVowel = _vowels[vKey];
            vLen = vKey.length;
            break;
          }
        }
      }

      if (matchVowel != null) {
        result.write(matchVowel);
        i += vLen;
        continue;
      }

      // Fallback: character as is
      result.write(src[i]);
      i++;
    }

    return result.toString();
  }
}
