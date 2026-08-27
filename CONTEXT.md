# CONTEXT.md — Packaged Commodity Compliance Platform

## 1. Project Overview

This is a Flutter-based web/mobile application for packaged commodity compliance under the Legal Metrology (Packaged Commodities) Rules, 2011.

The platform connects four user groups:

1. Small Businesses
2. Large Businesses / Corporations
3. Consumers
4. Regulatory Authorities

The core product loop is:

CREATE → AUDIT → SCAN → REPORT → VERIFY → NOTIFY → CORRECT → RE-AUDIT

The application is currently in the **frontend screen development phase**. Prioritize implementing the screens, navigation, layouts, states, reusable components, and role-specific user flows before backend integration.

The existing design system is already defined separately in `design.md`. **Do not create or override design guidelines in this file.** Follow `design.md` for all visual/design decisions.

---

# 2. Core Product Concept

## Small Business

Small businesses can enter product information such as ingredients/composition, net quantity, MRP, manufacturer details, consumer-care information, and other applicable information.

The application helps generate a product label/template and checks it for potential compliance issues.

Primary flow:

Onboarding → Authentication → Small Business Dashboard → Create Product → Enter Details → Generate Label → Compliance Check → Fix Issues → Export

## Large Business / Corporation

Large companies can upload existing product labels/package images and audit them for potential compliance issues.

The system can extract declarations, identify missing or potentially non-compliant information, analyze readability/font requirements, compare label versions, and generate compliance reports.

Primary flow:

Onboarding → Authentication → Enterprise Dashboard → Products → Upload/Audit Label → Compliance Analysis → Issues → Corrective Action → Re-Audit → Reports

## Consumer

Consumers can scan packaged products or labels and receive a simplified summary of available product information, ingredients, and nutrition information where available.

Consumers can also report potentially misleading or non-compliant labels to the authorities with supporting evidence.

Primary flow:

Onboarding → Authentication → Consumer Home → Scan Product → Product Summary → Label Analysis → Report Issue → Complaint Status

## Regulatory Authority

Regulators receive and manage complaints, review evidence, investigate potential violations, communicate required changes to responsible companies, and track corrective actions and resolution.

Primary flow:

Onboarding → Authentication → Regulatory Dashboard → Complaints → Complaint Details → Verify → Notify Company → Track Corrective Action → Resolution

---

# 3. User Roles

The onboarding screen must allow the user to select exactly one role:

### Small Business
For small businesses and manufacturers that need help creating and checking compliant labels.

### Large Business
For established companies/corporations managing product labels and compliance across products.

### Consumer
For consumers who want to scan products, understand labels, and report potential issues.

### Regulator
For regulatory/enforcement authorities managing complaints and compliance activities.

The selected role should be carried into registration/login and determine the appropriate application experience after authentication.

---

# 4. Frontend Screen Inventory

The following is the planned screen structure. Implement screens progressively; the current priority is onboarding and authentication.

## A. Common / Entry Screens

### A1. Splash Screen
- Application logo
- Application name
- Initial loading state
- Routes to onboarding or authenticated experience

### A2. Onboarding / Role Selection
Purpose: Ask the user how they intend to use the platform.

Content:
- Heading: "How will you use the platform?"
- Supporting text explaining that the experience will be tailored to the selected role
- Four selectable role cards:
  - Small Business
  - Large Business
  - Consumer
  - Regulator
- Continue button
- Login link for existing users

The selected role must be visually represented in the selected state.

### A3. Authentication Screen
Supports:
- Create Account
- Log In
- Google authentication
- Forgot password
- Change role

Registration fields depend on role.

Common fields:
- Full Name
- Email
- Password
- Confirm Password

Business/regulator roles may also collect:
- Business/Company/Organization name
- Department/Authority name where applicable

---

# 5. Small Business Screens

## SB1. Small Business Dashboard

Purpose: Give the business an overview of its products and compliance.

Potential sections:
- Overall compliance status
- Products
- Labels requiring review
- Open compliance issues
- Recent activity
- Quick action: Create Product
- Quick action: Audit Label
- Quick action: Generate Report

## SB2. Create Product

Fields may include:
- Product name
- Product category
- Ingredients/composition
- Net quantity
- MRP
- Manufacturer/packer/importer details
- Address
- Manufacturing/packing information
- Consumer-care details
- Other applicable declarations

## SB3. Product Details

Displays:
- Product information
- Current label
- Compliance status
- Compliance score
- Issues
- Label versions
- Reports
- Scan/audit history

## SB4. Label Generator

Purpose:
Generate a label/template from the entered product information.

Features:
- Label preview
- Editable product information
- Required declaration sections
- Compliance indicators
- Generate/update label
- Export label

## SB5. Label Compliance Analysis

Displays:
- Overall compliance score
- Passed checks
- Warnings
- Potential violations
- Unverifiable items
- Highlighted areas on the label
- Explanation for each issue
- Recommended action

## SB6. Compliance Issues

Displays:
- Open issues
- Warning issues
- Resolved issues
- Issue severity
- Product
- Description
- Required action
- Status

## SB7. Label Version History

Displays:
- Previous label versions
- Current version
- Changes between versions
- Compliance result for each version
- Re-audit option

## SB8. Reports

Displays:
- Generated compliance reports
- Report details
- Download/export options
- PDF and editable report formats

---

# 6. Large Business / Enterprise Screens

## LB1. Enterprise Dashboard

Overview:
- Total products
- Products audited
- Compliance percentage
- Open issues
- Products requiring review
- Recent audits
- Recent corrective actions

## LB2. Product Repository

Features:
- Search products
- Filter products
- Product status
- Compliance status
- Last audit
- Label version

## LB3. Add / Upload Product

Allows enterprise users to:
- Create a product record
- Upload packaging/label images
- Add product information
- Upload previous label where available

## LB4. Label Audit Upload

Allows:
- Image upload
- Package image upload
- Label upload
- Previous label upload
- New label upload

## LB5. Compliance Analysis

Shows:
- OCR/extracted information
- Detected declarations
- Compliance checks
- Warnings
- Potential violations
- Readability/font analysis
- Areas requiring review

## LB6. Label Comparison

Compares:
- Previous label
- New label
- Changed text
- Changed values
- Changed declarations
- Compliance impact

## LB7. Enterprise Issues

Tracks:
- Open issues
- Authority-raised issues
- Internal audit issues
- Corrective actions
- Resolved issues

## LB8. Corrective Action

Shows:
- Issue details
- Evidence
- Required action
- Company response
- Corrected label upload
- Submit for re-audit
- Status

## LB9. Reports

Provides:
- Compliance reports
- Audit reports
- Product reports
- Historical reports
- Export options

## LB10. Label Version History

Tracks every product label version and its corresponding compliance result.

---

# 7. Consumer Screens

## C1. Consumer Home

Primary actions:
- Scan Product
- View recent scans
- View submitted complaints
- Search/view saved products if implemented

## C2. Product Scanner

Purpose:
Use camera/image upload to scan a packaged product or label.

Possible states:
- Camera
- Image capture
- Upload image
- Processing
- Scan failed / retry

## C3. Product Summary

Displays:
- Product name
- Brand/company where available
- Ingredients
- Nutrition information where available
- Net quantity
- MRP
- Manufacturer information
- Other extracted declarations

Information should be presented in a consumer-friendly format.

## C4. Label Analysis

Displays:
- Detected declarations
- Potential compliance concerns
- Explanation in simple language
- Label evidence/image
- Report issue CTA

The system should clearly distinguish between an automated indication and an official regulatory determination.

## C5. Report an Issue

Fields:
- Issue category
- Description
- Product information
- Product/label photographs
- Supporting evidence
- Optional location/store details where applicable

CTA:
"Submit Complaint"

## C6. Complaint Submitted

Shows:
- Complaint ID
- Submitted date
- Product
- Issue
- Current status

## C7. Complaint History / Status

Displays:
- Submitted complaints
- Current status
- Updates from authorities
- Resolution information

---

# 8. Regulatory Authority Screens

## R1. Regulatory Dashboard

Key metrics:
- Products scanned
- Potential violations
- Consumer complaints
- Pending reviews
- Resolved cases
- Companies flagged

Also provide:
- Recent complaints
- High-priority cases
- Recent activity
- Filters

## R2. Complaint Inbox

Displays complaints with:
- Complaint ID
- Product
- Company
- Issue type
- Date
- Severity/priority
- Status

Filters:
- Status
- Issue type
- Company
- Product
- Date
- Location where applicable

## R3. Complaint Details

Displays:
- Complaint information
- Consumer-submitted description
- Product information
- Evidence/photos
- Automated analysis
- Relevant detected declaration
- Complaint timeline

Actions:
- Verify
- Reject / mark insufficient evidence
- Request additional information
- Forward to responsible company

## R4. Product Details

Displays:
- Product information
- Company
- Current label
- Compliance history
- Previous violations
- Complaints
- Label versions
- Reports

## R5. Company Details

Displays:
- Company information
- Products
- Compliance status
- Complaints
- Open corrective actions
- Historical compliance information

## R6. Verify Violation

Allows authority users to:
- Review evidence
- Review automated findings
- Confirm potential violation
- Categorize issue
- Add official notes
- Decide next action

## R7. Company Notification / Enforcement Action

Allows authorities to:
- Select responsible company
- Specify issue
- Attach evidence
- Explain required corrective action
- Set status/deadline where applicable
- Send notification

## R8. Corrective Action Tracking

Tracks:
- Company
- Product
- Issue
- Required action
- Company response
- Corrected label
- Re-audit status
- Resolution status

## R9. Reports & Analytics

Displays:
- Compliance trends
- Complaint trends
- Violation categories
- Company/product history
- Resolution statistics
- Exportable reports

---

# 9. Shared Screens / Supporting Screens

These can be implemented as needed across roles:

### S1. Notifications
- Compliance notifications
- Complaint updates
- Corrective action notifications
- System notifications

### S2. Search
Role-specific search across products, reports, complaints, and organizations.

### S3. Profile
- User information
- Organization information
- Role
- Account settings

### S4. Settings
- Account preferences
- Notification preferences
- Security settings

### S5. Help / Support
- FAQ
- Help content
- Contact/support

---

# 10. Navigation Logic

## Unauthenticated

Splash
→ Onboarding
→ Role Selection
→ Authentication

## Existing User

Splash
→ Authentication / Session Check
→ Role-specific Home/Dashboard

## Small Business

Dashboard
→ Products
→ Product Details
→ Label Generator / Audit
→ Compliance Analysis
→ Issues
→ Reports

## Large Business

Dashboard
→ Product Repository
→ Product
→ Label Audit
→ Analysis
→ Version Comparison
→ Corrective Action
→ Reports

## Consumer

Home
→ Scanner
→ Product Summary
→ Label Analysis
→ Report Issue
→ Complaint Status

## Regulator

Dashboard
→ Complaint Inbox
→ Complaint Details
→ Verification
→ Company Action
→ Corrective Action Tracking
→ Resolution

---

# 11. Important UI States

Every major data-driven screen should account for:

- Loading
- Empty state
- Success
- Error
- No results
- Processing
- Permission denied
- Invalid input
- Upload failure
- OCR failure
- Low-confidence extraction
- Compliance warning
- Potential violation
- Resolved state

For example, scanning should not jump directly from upload to results. It should support a processing state such as:

"Analyzing product label..."

Then:

"Extracting declarations..."

Then:

"Checking compliance..."

Then the final result.

---

# 12. Compliance Result Categories

Use these conceptual statuses throughout the frontend:

### Compliant
No issue detected by the automated checks.

### Warning
Potential issue or item requiring review.

### Potential Non-Compliance
The system has identified a likely compliance issue.

### Unable to Verify
The available image/data is insufficient for reliable automated verification.

### Resolved
A previously identified issue has been corrected and resolved/re-verified.

Do not represent automated results as a legally binding certification.

---

# 13. Core Frontend Components

Build reusable Flutter components rather than creating every screen independently.

Important reusable components include:

- Role selection card
- Primary/secondary buttons
- Form fields
- Password field
- Authentication tabs
- Product card
- Compliance status badge
- Compliance score
- Issue card
- Severity indicator
- Product information section
- Declaration row
- Label preview
- Upload component
- Image scanner component
- Report/complaint card
- Timeline
- Dashboard metric card
- Filter component
- Search component
- Data table/list
- Empty state
- Loading state
- Error state
- Confirmation dialog
- Notification item

---

# 14. Frontend Development Priority

Implement the application in this order:

## Phase 1 — Entry Flow

1. Splash Screen
2. Onboarding / Role Selection
3. Authentication
4. Navigation based on selected role

## Phase 2 — Role Home Screens

5. Small Business Dashboard
6. Large Business Dashboard
7. Consumer Home
8. Regulatory Dashboard

## Phase 3 — Core Workflows

9. Small Business Product Creation
10. Label Generator
11. Label Compliance Analysis
12. Enterprise Product Repository
13. Enterprise Label Audit
14. Consumer Scanner
15. Product Summary
16. Consumer Complaint
17. Authority Complaint Inbox
18. Complaint Details
19. Corrective Action

## Phase 4 — Supporting Screens

20. Product Details
21. Label Version History
22. Reports
23. Notifications
24. Profile
25. Settings
26. Search

---

# 15. Current Development Scope

**Current priority: FRONTEND ONLY**

Start with:

1. Onboarding / Role Selection
2. Authentication

Then proceed to the four role-specific home/dashboard screens.

At this stage:

- Use mock/static data where backend data is not available.
- Build navigation and UI states.
- Use reusable Flutter widgets.
- Keep business logic separated from presentation.
- Keep backend/API integration replaceable.
- Do not block frontend progress waiting for OCR, AI, database, or regulatory API integration.

The frontend should be structured so real services can be connected later without rebuilding the UI.

---

# 16. Important Product Constraint

The application is specifically intended to address packaged commodity compliance under the Legal Metrology (Packaged Commodities) Rules, 2011.

The official problem statement requires capabilities including:

- Scanning/analyzing packaged commodity images
- Detecting mandatory declarations
- Checking correctness, completeness and placement
- Identifying missing/non-compliant declarations
- Checking readability and font-size requirements
- Generating compliance reports
- Maintaining scanned-product/compliance history
- Providing enforcement dashboards
- Supporting image uploads, evidence, role-based access, search, and report export

Frontend screens should therefore always map back to these core capabilities.

---

# 17. Design Context

A separate `design.md` file defines the visual design system for this project.

**Always follow `design.md` for:**
- Colors
- Typography
- Spacing
- Components
- Visual style
- Icons
- Design language
- Responsive behavior where specified

Do not introduce a competing design system in this file.

This `CONTEXT.md` exists primarily to provide **product, user-role, feature, screen, navigation, and implementation context** to AI coding/design agents working on the Flutter frontend.
