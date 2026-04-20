const fs = require('fs');
const readline = require('readline');

const inputFile = 'all_relation_factoids.json';
const outputFile = 'filtered_relation_factoids.json';

const validSources = [
  'https://spear-prosop.org/letters-severus',
  'https://spear-prosop.org/lives-eastern-saints',
  'https://spear-prosop.org/chronicle-edessa'
];

const rl = readline.createInterface({
  input: fs.createReadStream(inputFile),
  crlfDelay: Infinity
});

const output = fs.createWriteStream(outputFile);
let firstLine = true;
let firstFactoid = true;

rl.on('line', (line) => {
  if (firstLine) {
    output.write(line + '\n');
    firstLine = false;
    return;
  }
  
  try {
    const factoid = JSON.parse(line);
    if (factoid.source && validSources.includes(factoid.source.value)) {
      if (!firstFactoid) {
        output.write(',');
      }
      output.write(line + '\n');
      firstFactoid = false;
    }
  } catch (e) {
    // Skip malformed lines
  }
});

rl.on('close', () => {
  output.write('\n]}}');
  output.end();
  console.log('Filtering complete!');
});
