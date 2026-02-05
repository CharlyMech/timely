#!/usr/bin/env node

/**
 * Timely Firebase Firestore Seeding Script
 *
 * This script seeds the Firestore database with initial data from JSON files.
 * It creates all necessary collections and documents for the Timely app.
 *
 * Usage:
 *   npm run seed          - Seed the database
 *   npm run seed:clear    - Clear all data before seeding
 *   npm run seed:dry-run  - Show what would be done without making changes
 */

const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");
require("dotenv").config();

// Collection names (hardcoded as per requirements)
const COLLECTIONS = {
  SETTINGS: "settings",
  EMPLOYEES: "employees",
  ROLES: "roles",
  SHIFTS: "shifts",
  SHIFT_TYPES: "shift_types",
  TIME_REGISTRATIONS: "time_registrations",
  EMPLOYEE_STATUSES: "employee_statuses",
  // Audit collections (created empty, populated by the app)
  LOGIN_AUDIT: "login_audit",
  EMPLOYEE_AUDIT: "employee_audit",
  USER_AUDIT: "user_audit",
  SHIFT_TYPE_AUDIT: "shift_type_audit",
  SHIFT_AUDIT: "shift_audit",
  TIME_REGISTRATION_AUDIT: "time_registration_audit",
};

// Parse command line arguments
const args = process.argv.slice(2);
const clearBeforeSeed = args.includes("--clear");
const dryRun = args.includes("--dry-run");

/**
 * Initialize Firebase Admin SDK
 */
function initializeFirebase() {
  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;

  if (serviceAccountPath && fs.existsSync(serviceAccountPath)) {
    // Use service account JSON file
    const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, "utf8"));
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: process.env.FIREBASE_PROJECT_ID || serviceAccount.project_id,
    });
    console.log(`Firebase initialized with service account from: ${serviceAccountPath}`);
  } else if (process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_CLIENT_EMAIL) {
    // Use individual environment variables
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, "\n"),
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      }),
      projectId: process.env.FIREBASE_PROJECT_ID,
    });
    console.log("Firebase initialized with environment variables");
  } else {
    console.error("Error: Firebase credentials not found.");
    console.error("Please either:");
    console.error("  1. Set FIREBASE_SERVICE_ACCOUNT_PATH to your service account JSON file");
    console.error("  2. Set FIREBASE_PRIVATE_KEY, FIREBASE_CLIENT_EMAIL, and FIREBASE_PROJECT_ID");
    process.exit(1);
  }

  return admin.firestore();
}

/**
 * Load JSON data from the data directory
 */
function loadJsonData(filename) {
  const filePath = path.join(__dirname, "data", filename);
  if (!fs.existsSync(filePath)) {
    console.warn(`Warning: ${filename} not found at ${filePath}`);
    return null;
  }
  const data = JSON.parse(fs.readFileSync(filePath, "utf8"));
  console.log(`Loaded ${filename}: ${Array.isArray(data) ? data.length + " items" : "1 item"}`);
  return data;
}

/**
 * Convert ISO date strings to Firestore Timestamps
 */
function convertDatesToTimestamps(data) {
  if (data === null || data === undefined) return data;

  if (typeof data === "string") {
    // Check if it's an ISO date string (but not a DD/MM/YYYY format)
    if (/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/.test(data)) {
      return admin.firestore.Timestamp.fromDate(new Date(data));
    }
    return data;
  }

  if (Array.isArray(data)) {
    return data.map(convertDatesToTimestamps);
  }

  if (typeof data === "object") {
    const converted = {};
    for (const [key, value] of Object.entries(data)) {
      converted[key] = convertDatesToTimestamps(value);
    }
    return converted;
  }

  return data;
}

/**
 * Clear all documents in a collection
 */
async function clearCollection(db, collectionName) {
  if (dryRun) {
    console.log(`[DRY RUN] Would clear collection: ${collectionName}`);
    return;
  }

  const collectionRef = db.collection(collectionName);
  const snapshot = await collectionRef.get();

  if (snapshot.empty) {
    console.log(`Collection ${collectionName} is already empty`);
    return;
  }

  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });

  await batch.commit();
  console.log(`Cleared ${snapshot.size} documents from ${collectionName}`);
}

/**
 * Seed a collection with data from JSON
 * Documents use their 'id' field as the document ID
 */
async function seedCollection(db, collectionName, data) {
  if (!data || (Array.isArray(data) && data.length === 0)) {
    console.log(`No data to seed for ${collectionName}`);
    return;
  }

  const items = Array.isArray(data) ? data : [data];

  if (dryRun) {
    console.log(`[DRY RUN] Would create ${items.length} documents in ${collectionName}`);
    items.forEach((item) => {
      console.log(`  - Document ID: ${item.id}`);
    });
    return;
  }

  // Use batched writes for efficiency (max 500 operations per batch)
  const BATCH_SIZE = 500;

  for (let i = 0; i < items.length; i += BATCH_SIZE) {
    const batch = db.batch();
    const batchItems = items.slice(i, i + BATCH_SIZE);

    for (const item of batchItems) {
      const docId = item.id;
      if (!docId) {
        console.warn(`Warning: Item without 'id' field found in ${collectionName}, skipping`);
        continue;
      }

      // Convert date strings to Timestamps
      const convertedItem = convertDatesToTimestamps(item);

      const docRef = db.collection(collectionName).doc(docId);
      batch.set(docRef, convertedItem);
    }

    await batch.commit();
    console.log(
      `Seeded ${Math.min(i + BATCH_SIZE, items.length)} / ${items.length} documents in ${collectionName}`
    );
  }

  console.log(`Successfully seeded ${items.length} documents in ${collectionName}`);
}

/**
 * Ensure an audit collection exists by writing a single placeholder document.
 * Firestore only "creates" a collection when it has at least one document.
 */
async function ensureAuditCollectionExists(db, collectionName) {
  const placeholderId = "_seed_placeholder";
  const docRef = db.collection(collectionName).doc(placeholderId);

  if (dryRun) {
    console.log(`[DRY RUN] Would create audit collection: ${collectionName}`);
    return;
  }

  await docRef.set({
    _purpose: "collection_initializer",
    _createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log(`Created audit collection: ${collectionName}`);
}

/**
 * Create all audit collections (empty, with a placeholder doc each).
 */
async function ensureAuditCollections(db) {
  const auditCollections = [
    COLLECTIONS.LOGIN_AUDIT,
    COLLECTIONS.EMPLOYEE_AUDIT,
    COLLECTIONS.USER_AUDIT,
    COLLECTIONS.SHIFT_TYPE_AUDIT,
    COLLECTIONS.SHIFT_AUDIT,
    COLLECTIONS.TIME_REGISTRATION_AUDIT,
  ];

  console.log("\nCreating audit collections...");
  for (const name of auditCollections) {
    await ensureAuditCollectionExists(db, name);
  }
  console.log("Audit collections ready.");
}

/**
 * Seed the settings collection (single document)
 */
async function seedSettings(db) {
  const config = loadJsonData("app_config.json");
  if (!config) return;

  if (dryRun) {
    console.log(`[DRY RUN] Would create settings/app_config document`);
    return;
  }

  // Settings collection has a single document called 'app_config'
  const docRef = db.collection(COLLECTIONS.SETTINGS).doc("app_config");
  await docRef.set(convertDatesToTimestamps(config));
  console.log("Successfully seeded settings/app_config");
}

/**
 * Main seeding function
 */
async function main() {
  console.log("=".repeat(60));
  console.log("Timely Firebase Seeding Script");
  console.log("=".repeat(60));

  if (dryRun) {
    console.log("\n*** DRY RUN MODE - No changes will be made ***\n");
  }

  if (clearBeforeSeed) {
    console.log("\n*** CLEAR MODE - Will delete existing data before seeding ***\n");
  }

  // Initialize Firebase
  const db = initializeFirebase();

  try {
    // Clear collections if requested
    if (clearBeforeSeed) {
      console.log("\n--- Clearing existing data ---\n");
      await clearCollection(db, COLLECTIONS.SETTINGS);
      await clearCollection(db, COLLECTIONS.ROLES);
      await clearCollection(db, COLLECTIONS.EMPLOYEE_STATUSES);
      await clearCollection(db, COLLECTIONS.EMPLOYEES);
      await clearCollection(db, COLLECTIONS.SHIFT_TYPES);
      await clearCollection(db, COLLECTIONS.SHIFTS);
      await clearCollection(db, COLLECTIONS.TIME_REGISTRATIONS);
    }

    // Seed data
    console.log("\n--- Seeding data ---\n");

    // 1. Settings (app_config)
    console.log("\n[1/7] Seeding settings...");
    await seedSettings(db);

    // 2. Roles
    console.log("\n[2/7] Seeding roles...");
    const roles = loadJsonData("roles.json");
    await seedCollection(db, COLLECTIONS.ROLES, roles);

    // 3. Employee Statuses
    console.log("\n[3/7] Seeding employee_statuses...");
    const employeeStatuses = loadJsonData("employee_statuses.json");
    await seedCollection(db, COLLECTIONS.EMPLOYEE_STATUSES, employeeStatuses);

    // 4. Employees
    console.log("\n[4/7] Seeding employees...");
    const employees = loadJsonData("employees.json");
    await seedCollection(db, COLLECTIONS.EMPLOYEES, employees);

    // 5. Shift Types
    console.log("\n[5/7] Seeding shift_types...");
    const shiftTypes = loadJsonData("shift_types.json");
    await seedCollection(db, COLLECTIONS.SHIFT_TYPES, shiftTypes);

    // 6. Shifts
    console.log("\n[6/7] Seeding shifts...");
    const shifts = loadJsonData("shifts.json");
    await seedCollection(db, COLLECTIONS.SHIFTS, shifts);

    // 7. Time Registrations
    console.log("\n[7/7] Seeding time_registrations...");
    const timeRegistrations = loadJsonData("time_registrations.json");
    await seedCollection(db, COLLECTIONS.TIME_REGISTRATIONS, timeRegistrations);

    // 8. Audit collections (create empty so they exist; app fills them at runtime)
    console.log("\n[8/8] Creating audit collections...");
    await ensureAuditCollections(db);

    console.log("\n" + "=".repeat(60));
    console.log("Seeding completed successfully!");
    console.log("=".repeat(60));
  } catch (error) {
    console.error("\nError during seeding:", error);
    process.exit(1);
  }

  process.exit(0);
}

// Run the script
main();
