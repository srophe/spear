export function cleanPunctuationSpacing(text) {
  return text
    // Remove double periods
    .replace(/\.{2,}/g, '.')
    // Remove space before punctuation
    .replace(/\s+([.,;:!?])/g, '$1')
    // Ensure exactly one space after punctuation—EXCEPT before ] ) or end of sentence
    .replace(/([.,;:!?])(?=\S)/g, '$1 ')
    // Collapse multiple spaces
    .replace(/\s{2,}/g, ' ');
}

export function toAggregateUri(uri) {
  const result = uri.replace('syriaca.org', 'spear-prosop.org').replace(/(\/)(person|place|keyword|work)(\/)/,  '$1aggregate/$2$3');
  return result.endsWith('.html') ? result : result + '.html';
}

export function uriDisplayString(uri){
  if (uri == null) return '';
  if (uri.startsWith("http://syriaca.org/prop/") || uri.startsWith("http://syriaca.org/taxonomy/")) {
    return uri.split('/').pop().replace(/([A-Z])/g, ' $1').trim();
  }
  return ('' + uri);
};

/**
 * Deduplicates factoid results by factoid URI
 * Keeps the first occurrence of each unique factoid
 * @param {Array} factoids - Array of factoid objects
 * @returns {Array} - Deduplicated array of factoids
 */
export function deduplicateFactoids(factoids) {
  if (!factoids || factoids.length === 0) return factoids;
  
  const seen = new Map();
  const duplicates = [];
  
  factoids.forEach(factoid => {
    const uri = factoid.uri || factoid.factoid;
    
    if (!uri) {
      console.warn('Factoid without URI found:', factoid);
      return;
    }
    
    if (!seen.has(uri)) {
      seen.set(uri, factoid);
    } else {
      duplicates.push(uri);
    }
  });
  
  if (duplicates.length > 0) {
    console.log(`Removed ${duplicates.length} duplicate factoids`);
  }
  
  const deduplicated = Array.from(seen.values());
  console.log(`Deduplication: ${factoids.length} → ${deduplicated.length} factoids`);
  
  return deduplicated;
}


