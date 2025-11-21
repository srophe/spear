export function cleanPunctuationSpacing(text) {
  return text
    // Remove space before punctuation
    .replace(/\s+([.,;:!?])/g, '$1')
    // Ensure exactly one space after punctuation—EXCEPT before ] ) or end of sentence
    .replace(/([.,;:!?])(?=\S)/g, '$1 ')
    // Collapse multiple spaces
    .replace(/\s{2,}/g, ' ');
}
