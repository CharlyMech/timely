# Timely Firebase Scripts

Scripts for configuring and populating Firebase Firestore data for the Timely application.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Data Structure](#data-structure)
- [Usage](#usage)
- [Firestore Rules](#firestore-rules)
- [Firestore Indexes](#firestore-indexes)
- [Test Data](#test-data)
- [File Structure](#file-structure)
- [Troubleshooting](#troubleshooting)

## Prerequisites

1. **Node.js** (v18 or higher)
2. **npm** (included with Node.js)
3. **Firebase Project** with Firestore enabled
4. **Firebase Service Account Key** (JSON file)
5. **Firebase CLI** (optional, for deploying rules and indexes)

## Setup

### Step 1: Install Dependencies

```bash
cd scripts
npm install
```

This will install:
- `firebase-admin` - Firebase Admin SDK for Node.js
- `dotenv` - Environment variable management

### Step 2: Get Firebase Credentials

#### Option A: Service Account Key (Recommended)

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Project Settings** (gear icon) > **Service Accounts**
4. Click **Generate New Private Key**
5. Download the JSON file and save it in the `scripts/` folder as `serviceAccountKey.json`

> **IMPORTANT**: Never commit the `serviceAccountKey.json` file to version control. It's already included in `.gitignore`.

#### Option B: Individual Environment Variables

Alternatively, you can extract the values from the service account JSON and set them individually in the `.env` file (see Step 3).

### Step 3: Configure Environment Variables

1. Copy the example file:

   ```bash
   cp .env.example .env
   ```

2. Edit `.env` with your project values:

   **Option A: Using Service Account File**
   ```env
   FIREBASE_PROJECT_ID=your-project-id
   FIREBASE_SERVICE_ACCOUNT_PATH=./serviceAccountKey.json
   ```

   **Option B: Using Individual Credentials**
   ```env
   FIREBASE_PROJECT_ID=your-project-id
   FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
   FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project-id.iam.gserviceaccount.com
   ```

### Step 4: Install Firebase CLI (Optional)

The Firebase CLI is needed to deploy rules and indexes automatically. If not installed, you can still deploy them manually through the Firebase Console.

```bash
npm install -g firebase-tools
firebase login
```

## Data Structure

### Collections

The scripts create the following collections in Firestore:

| Collection | Description |
| --- | --- |
| `settings` | Application configuration (single document: `app_config`) |
| `employees` | Company employees |
| `shift_types` | Available shift types (morning, afternoon, split) |
| `shifts` | Shifts assigned to employees |
| `time_registrations` | Employee time records |

### Entity Relationships

```
employees
    |
    +-- shifts (employeeId -> employee.id)
    |       |
    |       +-- shiftTypeId -> shift_types.id
    |
    +-- time_registrations (employeeId -> employee.id)
            |
            +-- shiftId -> shifts.id
```

### Data Models

#### AppConfig (settings/app_config)

```json
{
  "defaultTargetTimeMinutes": 480,
  "warningThresholdMinutes": 15,
  "redThresholdMinutes": 60,
  "workingDays": [1, 2, 3, 4, 5]
}
```

#### Employee

```json
{
  "id": "uuid",
  "firstName": "string",
  "lastName": "string",
  "avatarUrl": "string | null",
  "pin": "string (6 digits)",
  "status": "active | inactive | vacation | leave",
  "email": "string | null",
  "phone": "string (9 digits)",
  "address": "string | null"
}
```

#### ShiftType

```json
{
  "id": "uuid",
  "name": "string",
  "colorHex": "#RRGGBB",
  "startTime": "HH:mm",
  "endTime": "HH:mm",
  "pauseTime": "HH:mm | null",
  "resumeTime": "HH:mm | null",
  "targetTimeMinutes": "number"
}
```

#### Shift

```json
{
  "id": "uuid",
  "employeeId": "uuid (reference to employee)",
  "date": "Timestamp",
  "shiftTypeId": "uuid (reference to shift_type)",
  "notes": "string | null"
}
```

#### TimeRegistration

```json
{
  "id": "uuid",
  "employeeId": "uuid (reference to employee)",
  "shiftId": "uuid (reference to shift)",
  "startTime": "Timestamp",
  "endTime": "Timestamp | null",
  "pauseTime": "Timestamp | null",
  "resumeTime": "Timestamp | null",
  "date": "string (DD/MM/YYYY)"
}
```

## Usage

### Complete Setup (Recommended)

The `setup.js` script runs all necessary steps to configure Firebase:

```bash
node setup.js
```

Or using npm:

```bash
npm run setup
```

This command will:
1. Check prerequisites (Node.js, npm, Firebase CLI)
2. Install Node.js dependencies
3. Populate Firestore with test data
4. Deploy Firestore security rules (if Firebase CLI is available)
5. Deploy Firestore indexes (if Firebase CLI is available)

#### Setup Options

```bash
node setup.js --clear        # Clear existing data before seeding
node setup.js --skip-rules   # Skip deploying Firestore rules
node setup.js --skip-indexes # Skip deploying Firestore indexes
node setup.js --skip-seed    # Skip data seeding
node setup.js --dry-run      # Show what would be done without making changes
node setup.js --help         # Show help message
```

Using npm scripts:

```bash
npm run setup             # Complete setup
npm run setup:clear       # Setup with data clearing
npm run setup:dry-run     # Dry run mode
```

### Seed Data Only

To populate Firestore without deploying rules or indexes:

```bash
npm run seed
```

This command:
1. Reads JSON files from the `data/` folder
2. Creates all collections and documents in Firestore
3. Automatically converts ISO date strings to Firestore Timestamps

### Clear and Seed

To remove all existing data before seeding:

```bash
npm run seed:clear
```

> **WARNING**: This will delete all documents in the collections before seeding new data.

### Dry Run Mode

To preview what would be done without making actual changes:

```bash
npm run seed:dry-run
```

This is useful for:
- Testing the scripts before running them
- Verifying which data will be created
- Checking for errors in JSON files

## Firestore Rules

The `firestore.rules` file contains security rules for Firestore:

- **settings**: Read-only for all users
- **employees**: Read-only for all users
- **shift_types**: Read-only for all users
- **shifts**: Read-only for all users
- **time_registrations**: Read and write for all users

### Deploying Rules

**Automatic (if Firebase CLI is installed):**

The `setup.js` script will automatically deploy rules. You can also deploy them manually:

```bash
# From the project root directory
firebase deploy --only firestore:rules
```

**Manual (via Firebase Console):**

1. Go to Firestore Database > Rules in the Firebase Console
2. Copy the content of `firestore.rules`
3. Paste it into the editor
4. Click **Publish**

## Firestore Indexes

The `firestore.indexes.json` file contains composite indexes for efficient queries.

### Deploying Indexes

**Automatic (if Firebase CLI is installed):**

The `setup.js` script will automatically deploy indexes. You can also deploy them manually:

```bash
# From the project root directory
firebase deploy --only firestore:indexes
```

**Manual (via Firebase Console):**

Firestore will automatically suggest indexes when you run queries that require them. You can also:

1. Go to Firestore Database > Indexes in the Firebase Console
2. Click **Add Index**
3. Configure the index according to `firestore.indexes.json`

### Included Indexes

| Collection | Fields | Order | Purpose |
| --- | --- | --- | --- |
| `shifts` | employeeId, date | ASC | Get employee shifts ordered by date |
| `shifts` | employeeId, date | DESC | Get recent employee shifts |
| `shifts` | date, shiftTypeId | ASC | Filter shifts by date and type |
| `time_registrations` | employeeId, startTime | DESC | Get employee registrations |
| `time_registrations` | employeeId, date | ASC | Filter registrations by employee and date |
| `time_registrations` | shiftId, startTime | ASC | Get registrations for a specific shift |

## Test Data

The JSON files in `data/` contain test data with:

- **4 employees** with different statuses (active, vacation, leave, inactive)
- **3 shift types**:
  - Morning (08:00-16:00, no break)
  - Afternoon (15:00-23:00, no break)
  - Split (08:00-20:00, with break 14:00-17:00)
- **Shifts** for December 2025, January 2026, and first half of February 2026
- **Time registrations** completed from December 2025 to current date

### Data Files

- `app_config.json` - Application configuration
- `employees.json` - Employee data
- `shift_types.json` - Shift type definitions
- `shifts.json` - Assigned shifts
- `time_registrations.json` - Time records

### Customizing Test Data

You can modify the content inside the JSON files in the `data/` folder to match your organization's needs:

**Important Guidelines:**
- **DO modify** the values inside each JSON file (names, dates, times, etc.)
- **DO NOT change** the file names or structure
- **DO NOT add or remove** JSON files from the `data/` folder
- **DO NOT modify** the field names or data types in the JSON objects

**What you can customize:**
- Employee names, emails, phone numbers, PINs, and statuses
- Shift type names, colors, and time ranges
- Shift assignments and dates
- Time registration records
- Application configuration values (thresholds, working days)

**Example - Modifying an employee:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "firstName": "Your",          // ✅ Change this
  "lastName": "Employee",        // ✅ Change this
  "email": "your@email.com",     // ✅ Change this
  "pin": "123456",               // ✅ Change this
  "status": "active",            // ✅ Change this
  "phone": "123456789",          // ✅ Change this
  "address": "Your Address",     // ✅ Change this
  "avatarUrl": null              // ✅ Change this or keep null
}
```

**What NOT to do:**
```json
{
  "employeeId": "...",     // ❌ Don't rename fields
  "newField": "value",     // ❌ Don't add new fields
  "firstName": 123         // ❌ Don't change data types (should be string)
}
```

After modifying the data files, run the seed script to populate your Firebase:
```bash
npm run seed:clear  # Clear old data and seed new data
```

## File Structure

```
scripts/
├── data/
│   ├── app_config.json        # Application configuration
│   ├── employees.json         # Employee data
│   ├── shift_types.json       # Shift type definitions
│   ├── shifts.json            # Assigned shifts
│   └── time_registrations.json # Time records
├── .env                       # Environment variables (DO NOT COMMIT)
├── .env.example               # Environment variable template
├── .gitignore                 # Git ignore file
├── firestore.indexes.json     # Firestore indexes
├── firestore.rules            # Firestore security rules
├── package.json               # Node.js dependencies
├── README.md                  # This documentation (English)
├── README.es.md               # Documentation in Spanish
├── seed.js                    # Main seeding script
├── setup.js                   # Complete setup script
└── serviceAccountKey.json     # Firebase credentials (DO NOT COMMIT)
```

## Troubleshooting

### Error: Firebase credentials not found

**Cause**: The service account key file is missing or the path in `.env` is incorrect.

**Solution**:
1. Verify that `serviceAccountKey.json` exists in the `scripts/` folder
2. Check that the path in `.env` is correct: `FIREBASE_SERVICE_ACCOUNT_PATH=./serviceAccountKey.json`
3. Or use individual credentials (see [Step 3](#step-3-configure-environment-variables))

### Error: Permission denied

**Cause**: The service account doesn't have sufficient permissions.

**Solution**:
1. Verify that the Service Account has **Cloud Datastore User** or **Firebase Admin** role
2. Check that Firestore rules allow writes (you can temporarily use open rules for testing)

### Dates are not displayed correctly

**Cause**: The script automatically converts ISO date strings to Firestore Timestamps.

**Notes**:
1. Make sure dates in JSON files are in ISO 8601 format (e.g., `2025-01-15T10:30:00.000Z`)
2. Be aware of timezones - dates are stored in UTC
3. The `date` field in `TimeRegistration` is stored as a string in DD/MM/YYYY format

### Error: Cannot find module

**Cause**: Dependencies are not installed.

**Solution**:
```bash
cd scripts
npm install
```

### Firebase CLI commands not working

**Cause**: Firebase CLI is not installed or not logged in.

**Solution**:
```bash
npm install -g firebase-tools
firebase login
```

If Firebase CLI is not available, you can deploy rules and indexes manually through the Firebase Console.

### Dry run shows what I expect, but nothing happens

**Cause**: You're in dry run mode.

**Solution**: Run without the `--dry-run` flag:
```bash
npm run seed  # Instead of npm run seed:dry-run
```

---

For more information about Firebase and Firestore, visit the [Firebase Documentation](https://firebase.google.com/docs).
