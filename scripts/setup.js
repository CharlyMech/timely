#!/usr/bin/env node

/**
 * Timely Firebase Setup Script (Node.js version)
 *
 * This script runs all necessary steps to configure Firebase Firestore:
 * - Installs dependencies
 * - Seeds data
 * - Deploys Firestore rules (if Firebase CLI available)
 * - Deploys Firestore indexes (if Firebase CLI available)
 */

const { execSync, spawn } = require("child_process");
const fs = require("fs");
const path = require("path");

// ANSI color codes
const colors = {
  reset: "\x1b[0m",
  red: "\x1b[31m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
};

// Parse command line arguments
const args = process.argv.slice(2);
const options = {
  clearData: args.includes("--clear"),
  skipRules: args.includes("--skip-rules"),
  skipIndexes: args.includes("--skip-indexes"),
  skipSeed: args.includes("--skip-seed"),
  dryRun: args.includes("--dry-run"),
  help: args.includes("--help") || args.includes("-h"),
};

/**
 * Print colored output
 */
function print(message, color = "reset") {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

/**
 * Print section header
 */
function printSection(step, total, message) {
  print(`\n[${step}/${total}] ${message}`, "yellow");
}

/**
 * Check if a command exists
 */
function commandExists(command) {
  try {
    execSync(`which ${command}`, { stdio: "ignore" });
    return true;
  } catch {
    return false;
  }
}

/**
 * Get version of a command
 */
function getVersion(command, flag = "--version") {
  try {
    return execSync(`${command} ${flag}`, { encoding: "utf8" }).trim();
  } catch {
    return "unknown";
  }
}

/**
 * Execute a command and return output
 */
function execCommand(command, options = {}) {
  try {
    return execSync(command, {
      encoding: "utf8",
      stdio: options.silent ? "pipe" : "inherit",
      ...options,
    });
  } catch (error) {
    throw new Error(`Command failed: ${command}\n${error.message}`);
  }
}

/**
 * Show help message
 */
function showHelp() {
  console.log("Usage: node setup.js [options]\n");
  console.log("Options:");
  console.log("  --clear        Clear existing data before seeding");
  console.log("  --skip-rules   Skip deploying Firestore rules");
  console.log("  --skip-indexes Skip deploying Firestore indexes");
  console.log("  --skip-seed    Skip seeding data");
  console.log("  --dry-run      Show what would be done without making changes");
  console.log("  --help, -h     Show this help message\n");
}

/**
 * Main setup function
 */
async function main() {
  print("=".repeat(60), "blue");
  print("       Timely Firebase Setup Script", "blue");
  print("=".repeat(60), "blue");
  console.log();

  if (options.help) {
    showHelp();
    process.exit(0);
  }

  if (options.dryRun) {
    print("*** DRY RUN MODE - No changes will be made ***\n", "yellow");
  }

  if (options.clearData) {
    print("*** CLEAR MODE - Will delete existing data before seeding ***\n", "yellow");
  }

  // Step 1: Check prerequisites
  printSection(1, 5, "Checking prerequisites...");

  // Check Node.js
  if (!commandExists("node")) {
    print("Error: Node.js is not installed", "red");
    print("Please install Node.js v18 or higher");
    process.exit(1);
  }

  const nodeVersion = process.version.slice(1).split(".")[0];
  if (parseInt(nodeVersion) < 18) {
    print(`Error: Node.js version must be 18 or higher (found v${nodeVersion})`, "red");
    process.exit(1);
  }
  print(`  Node.js: ${process.version}`, "green");

  // Check npm
  if (!commandExists("npm")) {
    print("Error: npm is not installed", "red");
    process.exit(1);
  }
  const npmVersion = getVersion("npm");
  print(`  npm: ${npmVersion}`, "green");

  // Check Firebase CLI (optional)
  const firebaseAvailable = commandExists("firebase");
  if (firebaseAvailable) {
    const firebaseVersion = getVersion("firebase");
    print(`  Firebase CLI: ${firebaseVersion}`, "green");
  } else {
    print("  Firebase CLI: Not installed (rules/indexes will be skipped)", "yellow");
    options.skipRules = true;
    options.skipIndexes = true;
  }

  // Check .env file
  if (!fs.existsSync(path.join(__dirname, ".env"))) {
    print("Error: .env file not found", "red");
    print("Please copy .env.example to .env and configure it");
    process.exit(1);
  }
  print("  .env file found", "green");

  // Check service account key
  if (!fs.existsSync(path.join(__dirname, "serviceAccountKey.json"))) {
    print("Warning: serviceAccountKey.json not found", "yellow");
    print("Make sure FIREBASE_PRIVATE_KEY is set in .env or provide the service account file");
  }

  // Step 2: Install dependencies
  printSection(2, 5, "Installing dependencies...");
  if (options.dryRun) {
    print("  [DRY RUN] Would run: npm install", "blue");
  } else {
    try {
      execCommand("npm install", { silent: true });
      print("  Dependencies installed", "green");
    } catch (error) {
      print(`Error installing dependencies: ${error.message}`, "red");
      process.exit(1);
    }
  }

  // Step 3: Seed data
  if (!options.skipSeed) {
    printSection(3, 5, "Seeding Firestore data...");

    const seedArgs = [];
    if (options.clearData) {
      seedArgs.push("--clear");
      print("  Mode: Clear and seed", "yellow");
    }
    if (options.dryRun) {
      seedArgs.push("--dry-run");
    }

    if (options.dryRun) {
      print(`  [DRY RUN] Would run: node seed.js ${seedArgs.join(" ")}`, "blue");
    } else {
      try {
        execCommand(`node seed.js ${seedArgs.join(" ")}`);
      } catch (error) {
        print(`Error seeding data: ${error.message}`, "red");
        process.exit(1);
      }
    }
  } else {
    printSection(3, 5, "Skipping data seeding...");
  }

  // Step 4: Deploy Firestore rules
  if (!options.skipRules && firebaseAvailable) {
    printSection(4, 5, "Deploying Firestore rules...");

    if (options.dryRun) {
      print("  [DRY RUN] Would run: firebase deploy --only firestore:rules", "blue");
    } else {
      const parentDir = path.join(__dirname, "..");
      if (fs.existsSync(path.join(parentDir, "firebase.json"))) {
        try {
          execCommand("firebase deploy --only firestore:rules", { cwd: parentDir });
          print("  Firestore rules deployed", "green");
        } catch (error) {
          print(`Warning: Failed to deploy rules: ${error.message}`, "yellow");
          print("  You can manually deploy rules from Firebase Console", "yellow");
        }
      } else {
        print("  Skipping: firebase.json not found in parent directory", "yellow");
        print("  You can manually deploy rules from Firebase Console", "yellow");
      }
    }
  } else {
    printSection(4, 5, "Skipping Firestore rules deployment...");
  }

  // Step 5: Deploy Firestore indexes
  if (!options.skipIndexes && firebaseAvailable) {
    printSection(5, 5, "Deploying Firestore indexes...");

    if (options.dryRun) {
      print("  [DRY RUN] Would run: firebase deploy --only firestore:indexes", "blue");
    } else {
      const parentDir = path.join(__dirname, "..");
      if (fs.existsSync(path.join(parentDir, "firebase.json"))) {
        try {
          execCommand("firebase deploy --only firestore:indexes", { cwd: parentDir });
          print("  Firestore indexes deployed", "green");
        } catch (error) {
          print(`Warning: Failed to deploy indexes: ${error.message}`, "yellow");
          print("  You can manually deploy indexes from Firebase Console", "yellow");
        }
      } else {
        print("  Skipping: firebase.json not found in parent directory", "yellow");
        print("  You can manually deploy indexes from Firebase Console", "yellow");
      }
    }
  } else {
    printSection(5, 5, "Skipping Firestore indexes deployment...");
  }

  // Summary
  console.log();
  print("=".repeat(60), "blue");
  print("Setup completed!", "green");
  print("=".repeat(60), "blue");
  console.log();

  if (options.skipRules || options.skipIndexes) {
    print("Note: Some steps were skipped. You may need to:", "yellow");
    if (options.skipRules) {
      print("  - Deploy rules manually: Copy firestore.rules to Firebase Console");
    }
    if (options.skipIndexes) {
      print("  - Deploy indexes manually: Copy firestore.indexes.json to Firebase Console");
    }
    console.log();
  }

  print("Next steps:");
  print(`  1. Run your Flutter app with: ${colors.blue}flutter run${colors.reset}`);
  print("  2. Test the app with the seeded data");
  console.log();
}

// Run the script
main().catch((error) => {
  print(`\nFatal error: ${error.message}`, "red");
  process.exit(1);
});
