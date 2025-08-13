const fs = require('fs');
const path = require('path');

// Read package.json
const packagePath = path.join(__dirname, '..', 'package.json');
const packageJson = JSON.parse(fs.readFileSync(packagePath, 'utf8'));

// Get current version
const currentVersion = packageJson.version;
console.log(`Current version: ${currentVersion}`);

// Parse the version to extract the last number
// Expected format: "1.0.29-alpha-fork-0.X" where X is the number to increment
// We need to find the last number in the version string and increment it by 1

// Split by hyphens and find the last part that contains a number
const parts = currentVersion.split('-');
let lastPart = parts[parts.length - 1];

// Check if the last part contains a number
const numberMatch = lastPart.match(/(\d+)$/);

if (numberMatch) {
    const prefix = lastPart.substring(0, lastPart.length - numberMatch[1].length);
    const lastNumber = parseInt(numberMatch[1]);
    
    // Increment the last number
    const newLastNumber = lastNumber + 1;
    const newLastPart = prefix + newLastNumber;
    
    // Reconstruct the version
    parts[parts.length - 1] = newLastPart;
    const newVersion = parts.join('-');
    
    console.log(`Incrementing version from ${currentVersion} to ${newVersion}`);
    
    // Update package.json
    packageJson.version = newVersion;
    fs.writeFileSync(packagePath, JSON.stringify(packageJson, null, 2) + '\n');
    
    console.log(`Version successfully updated to: ${newVersion}`);
} else {
    console.error(`Could not parse version format: ${currentVersion}`);
    console.error('Expected format: X.X.X-alpha-fork-X.X where X.X ends with a number');
    process.exit(1);
}
