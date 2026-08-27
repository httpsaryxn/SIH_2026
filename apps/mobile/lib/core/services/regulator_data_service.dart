import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/regulator_violation.dart';
import '../models/regulator_complaint.dart';
import '../models/regulator_company.dart';
import '../models/regulator_notice.dart';

/// RegulatorDataService provides data access methods for the Regulator module.
/// It currently returns rich mock data simulating network latency and mirrors
/// the static Supabase pattern used throughout the app.
class RegulatorDataService {
  // ignore: unused_element
  static SupabaseClient get _client => Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // IN-MEMORY MOCK DATA STORE
  // ---------------------------------------------------------------------------

  static final List<RegulatorViolation> _mockViolations = [
    RegulatorViolation(
      id: 'viol-001',
      scanId: '#88492-AX',
      productName: 'Organic Quinoa Flakes',
      companyName: 'Nature Organics India Pvt Ltd',
      category: 'Grains & Cereals',
      region: 'West Region - Mumbai',
      storeLocation: 'Central Market, Sector 18, Vashi, Navi Mumbai',
      imageUrl:
          'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=600&q=80',
      severity: 'High',
      riskLevel: 'High Risk',
      confidenceScore: 98,
      violationType: 'Missing MRP',
      violationSummary: 'MRP missing on Principal Display Panel',
      capturedAt: DateTime.now().subtract(const Duration(hours: 3)),
      status: 'pending',
      declarations: const [
        RegulatorDeclaration(
          fieldName: 'MAXIMUM RETAIL PRICE (MRP)',
          extractedValue: 'Not Found',
          confidencePercent: 0,
          status: 'Violation',
          ruleCitation: 'LMPC Sec 18(1) & PCR Rule 6(1)(e)',
          ruleDescription:
              'The MRP must be distinctly and clearly declared on the principal display panel inclusive of all taxes.',
        ),
        RegulatorDeclaration(
          fieldName: 'NET QUANTITY',
          extractedValue: '500g',
          confidencePercent: 98,
          status: 'Compliant',
          ruleCitation: 'PCR 2011 Rule 6(1)(c)',
          ruleDescription:
              'Net quantity declaration must comply with permissible weight units.',
        ),
        RegulatorDeclaration(
          fieldName: 'DATE OF MFG',
          extractedValue: '12/10/2023',
          confidencePercent: 92,
          status: 'Compliant',
          ruleCitation: 'PCR 2011 Rule 6(1)(d)',
          ruleDescription:
              'Month and year of manufacture or pre-packing is clearly visible.',
        ),
        RegulatorDeclaration(
          fieldName: 'MANUFACTURER ADDRESS',
          extractedValue: 'Plot 42, MIDC Industrial Area, Pune 411019',
          confidencePercent: 88,
          status: 'Compliant',
          ruleCitation: 'PCR 2011 Rule 6(1)(a)',
          ruleDescription:
              'Name and full postal address of manufacturer declared.',
        ),
        RegulatorDeclaration(
          fieldName: 'CONSUMER CARE DETAILS',
          extractedValue: 'customercare@natureorganics.in / 1800-200-8899',
          confidencePercent: 95,
          status: 'Compliant',
          ruleCitation: 'PCR 2011 Rule 6(1)(f)',
          ruleDescription:
              'Consumer helpline contact numbers and email address are provided.',
        ),
        RegulatorDeclaration(
          fieldName: 'COUNTRY OF ORIGIN',
          extractedValue: 'India',
          confidencePercent: 99,
          status: 'Compliant',
          ruleCitation: 'PCR 2011 Rule 6(3)',
          ruleDescription: 'Mandatory country of origin declaration is present.',
        ),
        RegulatorDeclaration(
          fieldName: 'UNIT SALE PRICE (USP)',
          extractedValue: '₹0.70 per g',
          confidencePercent: 91,
          status: 'Compliant',
          ruleCitation: 'PCR 2011 Rule 2(m)',
          ruleDescription:
              'Unit sale price is printed alongside the package declaration.',
        ),
      ],
      overlayBoxes: const [
        RegulatorOverlayBox(
          topPercent: 0.72,
          leftPercent: 0.12,
          widthPercent: 0.35,
          heightPercent: 0.10,
          label: 'MRP Missing',
          isViolation: true,
        ),
        RegulatorOverlayBox(
          topPercent: 0.58,
          leftPercent: 0.12,
          widthPercent: 0.28,
          heightPercent: 0.08,
          label: '98%',
          isViolation: false,
        ),
      ],
    ),
    RegulatorViolation(
      id: 'viol-002',
      scanId: '#77301-BK',
      productName: 'Artisan Sourdough Loaf',
      companyName: 'BakeCraft Foods LLP',
      category: 'Bakery & Snacks',
      region: 'North Region - Delhi NCR',
      storeLocation: 'City Gourmet Store, Greater Kailash-I, New Delhi',
      imageUrl:
          'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80',
      severity: 'High',
      riskLevel: 'High Risk',
      confidenceScore: 98,
      violationType: 'Missing Allergen',
      violationSummary: 'Undeclared walnuts in ingredient list',
      capturedAt: DateTime.now().subtract(const Duration(hours: 6)),
      status: 'pending',
      declarations: const [
        RegulatorDeclaration(
          fieldName: 'ALLERGEN DECLARATION',
          extractedValue: 'Not Declared (Contains Walnuts/Gluten)',
          confidencePercent: 96,
          status: 'Violation',
          ruleCitation: 'FSSAI Packaging Regs & PCR Rule 6(1)(e)',
          ruleDescription:
              'Mandatory allergen disclosure missing for tree nuts and gluten.',
        ),
        RegulatorDeclaration(
          fieldName: 'MAXIMUM RETAIL PRICE (MRP)',
          extractedValue: '₹180.00 (Incl. all taxes)',
          confidencePercent: 97,
          status: 'Compliant',
          ruleCitation: 'LMPC Sec 18(1)',
          ruleDescription: 'MRP clearly indicated.',
        ),
        RegulatorDeclaration(
          fieldName: 'NET QUANTITY',
          extractedValue: '400g',
          confidencePercent: 94,
          status: 'Compliant',
          ruleCitation: 'PCR 2011 Rule 6(1)(c)',
          ruleDescription: 'Net weight declared.',
        ),
      ],
      overlayBoxes: const [
        RegulatorOverlayBox(
          topPercent: 0.65,
          leftPercent: 0.20,
          widthPercent: 0.40,
          heightPercent: 0.12,
          label: 'Missing Allergen',
          isViolation: true,
        ),
      ],
    ),
    RegulatorViolation(
      id: 'viol-003',
      scanId: '#66129-DR',
      productName: 'Organic Almond Milk 1L',
      companyName: 'PureNutri Beverages India',
      category: 'Dairy & Beverages',
      region: 'South Region - Bengaluru',
      storeLocation: 'Whole Foods Prep, Indiranagar, Bengaluru',
      imageUrl:
          'https://images.unsplash.com/photo-1568651315053-4bb4268e0013?auto=format&fit=crop&w=600&q=80',
      severity: 'Medium',
      riskLevel: 'Medium Risk',
      confidenceScore: 92,
      violationType: 'Date Format',
      violationSummary: 'Expiration and use-by date obscured/smudged',
      capturedAt: DateTime.now().subtract(const Duration(hours: 12)),
      status: 'pending',
      declarations: const [
        RegulatorDeclaration(
          fieldName: 'DATE OF MFG / EXPIRY',
          extractedValue: 'Illegible / Overprinted (Smudged)',
          confidencePercent: 42,
          status: 'Violation',
          ruleCitation: 'PCR 2011 Rule 6(1)(d)',
          ruleDescription:
              'Expiry and best before date must remain smudge-resistant and clearly legible.',
        ),
        RegulatorDeclaration(
          fieldName: 'MAXIMUM RETAIL PRICE (MRP)',
          extractedValue: '₹260.00',
          confidencePercent: 96,
          status: 'Compliant',
          ruleCitation: 'LMPC Sec 18(1)',
          ruleDescription: 'MRP clearly indicated.',
        ),
      ],
      overlayBoxes: const [
        RegulatorOverlayBox(
          topPercent: 0.25,
          leftPercent: 0.30,
          widthPercent: 0.35,
          heightPercent: 0.10,
          label: 'Date Obscured',
          isViolation: true,
        ),
      ],
    ),
    RegulatorViolation(
      id: 'viol-004',
      scanId: '#55210-SP',
      productName: 'Spicy Mustard Oil 1L Pouch',
      companyName: 'Shree Kissan Agro Mills',
      category: 'Edible Oils',
      region: 'North Region - Lucknow',
      storeLocation: 'Kissan Mandi, Alambagh, Lucknow',
      imageUrl:
          'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=600&q=80',
      severity: 'High',
      riskLevel: 'High Risk',
      confidenceScore: 95,
      violationType: 'Weight Tolerance',
      violationSummary: 'Volume shortfall (Measured 910ml vs 1000ml declared)',
      capturedAt: DateTime.now().subtract(const Duration(days: 1)),
      status: 'pending',
      declarations: const [
        RegulatorDeclaration(
          fieldName: 'NET QUANTITY',
          extractedValue: 'Declared 1L / Actual 910ml (-9.0% shortfall)',
          confidencePercent: 98,
          status: 'Violation',
          ruleCitation: 'PCR 2011 Second Schedule & Sec 30',
          ruleDescription:
              'Maximum allowable deficiency exceeded for 1000ml liquid packages.',
        ),
        RegulatorDeclaration(
          fieldName: 'UNIT SALE PRICE (USP)',
          extractedValue: 'Not Printed',
          confidencePercent: 0,
          status: 'Violation',
          ruleCitation: 'PCR 2011 Rule 2(m)',
          ruleDescription: 'Unit sale price mandatory per ml.',
        ),
      ],
      overlayBoxes: const [
        RegulatorOverlayBox(
          topPercent: 0.70,
          leftPercent: 0.25,
          widthPercent: 0.50,
          heightPercent: 0.12,
          label: 'Weight Shortfall',
          isViolation: true,
        ),
      ],
    ),
    RegulatorViolation(
      id: 'viol-005',
      scanId: '#44918-SN',
      productName: 'Roasted Cashew Masala 200g',
      companyName: 'Haldiram Snacks Pvt Ltd',
      category: 'Packaged Snacks',
      region: 'North Region - Noida',
      storeLocation: 'Mega Mart, Sector 62, Noida',
      imageUrl:
          'https://images.unsplash.com/photo-1541592106381-b31e9677c0e5?auto=format&fit=crop&w=600&q=80',
      severity: 'Low',
      riskLevel: 'Low Risk',
      confidenceScore: 89,
      violationType: 'Font Size',
      violationSummary: 'Consumer care contact font size under 1.5mm standard',
      capturedAt: DateTime.now().subtract(const Duration(days: 2)),
      status: 'pending',
      declarations: const [
        RegulatorDeclaration(
          fieldName: 'CONSUMER CARE DETAILS',
          extractedValue: 'Font height 0.9mm (Min required 1.5mm)',
          confidencePercent: 91,
          status: 'Warning',
          ruleCitation: 'PCR 2011 Rule 9(1) Table 1',
          ruleDescription:
              'Height of numeral and letters must adhere to minimum area standards.',
        ),
      ],
      overlayBoxes: const [
        RegulatorOverlayBox(
          topPercent: 0.82,
          leftPercent: 0.15,
          widthPercent: 0.60,
          heightPercent: 0.08,
          label: 'Font Size < 1.5mm',
          isViolation: false,
        ),
      ],
    ),
    RegulatorViolation(
      id: 'viol-006',
      scanId: '#33812-TC',
      productName: 'Premium Assam Gold CTC Tea 500g',
      companyName: 'Tata Consumer Products Ltd',
      category: 'Beverages',
      region: 'East Region - Kolkata',
      storeLocation: 'Super Bazaar, Park Street, Kolkata',
      imageUrl:
          'https://images.unsplash.com/photo-1576092768241-dec231879fc3?auto=format&fit=crop&w=600&q=80',
      severity: 'Low',
      riskLevel: 'Low Risk',
      confidenceScore: 94,
      violationType: 'USP Missing',
      violationSummary: 'Unit sale price missing on multi-pack carton',
      capturedAt: DateTime.now().subtract(const Duration(days: 3)),
      status: 'pending',
      declarations: const [
        RegulatorDeclaration(
          fieldName: 'UNIT SALE PRICE (USP)',
          extractedValue: 'Missing',
          confidencePercent: 0,
          status: 'Violation',
          ruleCitation: 'PCR 2011 Rule 2(m)',
          ruleDescription: 'Unit sale price must be displayed per g.',
        ),
      ],
      overlayBoxes: const [
        RegulatorOverlayBox(
          topPercent: 0.60,
          leftPercent: 0.35,
          widthPercent: 0.30,
          heightPercent: 0.08,
          label: 'USP Missing',
          isViolation: true,
        ),
      ],
    ),
    RegulatorViolation(
      id: 'viol-007',
      scanId: '#22904-BT',
      productName: 'Digestive High Fiber Biscuits',
      companyName: 'Britannia Industries Ltd',
      category: 'Bakery & Biscuits',
      region: 'South Region - Chennai',
      storeLocation: 'Nilgiris Supermarket, T. Nagar, Chennai',
      imageUrl:
          'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?auto=format&fit=crop&w=600&q=80',
      severity: 'Medium',
      riskLevel: 'Medium Risk',
      confidenceScore: 91,
      violationType: 'Dual MRP',
      violationSummary: 'Dual pricing sticker superimposed on pre-printed MRP',
      capturedAt: DateTime.now().subtract(const Duration(days: 4)),
      status: 'pending',
      declarations: const [
        RegulatorDeclaration(
          fieldName: 'MAXIMUM RETAIL PRICE (MRP)',
          extractedValue: 'Sticker: ₹95.00 / Original Print: ₹85.00',
          confidencePercent: 96,
          status: 'Violation',
          ruleCitation: 'LMPC Sec 18(2) & PCR Rule 18(1)',
          ruleDescription:
              'No person shall alter or superimpose any price sticker on the pre-printed MRP.',
        ),
      ],
      overlayBoxes: const [
        RegulatorOverlayBox(
          topPercent: 0.45,
          leftPercent: 0.50,
          widthPercent: 0.35,
          heightPercent: 0.12,
          label: 'Sticker Overprint',
          isViolation: true,
        ),
      ],
    ),
    RegulatorViolation(
      id: 'viol-008',
      scanId: '#11450-DB',
      productName: '100% Pure Honey 500g Glass Jar',
      companyName: 'Dabur India Limited',
      category: 'Packaged Foods',
      region: 'North Region - Chandigarh',
      storeLocation: 'Reliance Smart, Sector 17, Chandigarh',
      imageUrl:
          'https://images.unsplash.com/photo-1587049352846-4a222e784d38?auto=format&fit=crop&w=600&q=80',
      severity: 'Low',
      riskLevel: 'Low Risk',
      confidenceScore: 97,
      violationType: 'Customer Care Info',
      violationSummary: 'Toll-free number line busy/disconnected on test call',
      capturedAt: DateTime.now().subtract(const Duration(days: 5)),
      status: 'pending',
      declarations: const [
        RegulatorDeclaration(
          fieldName: 'CONSUMER CARE DETAILS',
          extractedValue: '1800-103-1644 (Inactive in audit verification)',
          confidencePercent: 93,
          status: 'Warning',
          ruleCitation: 'PCR 2011 Rule 6(1)(f)',
          ruleDescription:
              'Consumer grievance helpline must remain functional and responsive.',
        ),
      ],
      overlayBoxes: const [
        RegulatorOverlayBox(
          topPercent: 0.78,
          leftPercent: 0.20,
          widthPercent: 0.50,
          heightPercent: 0.10,
          label: 'Helpline Warning',
          isViolation: false,
        ),
      ],
    ),
    RegulatorViolation(
      id: 'viol-009',
      scanId: '#99341-MD',
      productName: 'Cow Ghee 1L Tin',
      companyName: 'Mother Dairy Fruit & Vegetable Pvt Ltd',
      category: 'Dairy Products',
      region: 'West Region - Ahmedabad',
      storeLocation: 'Amul & Dairy Mart, Navrangpura, Ahmedabad',
      imageUrl:
          'https://images.unsplash.com/photo-1628088062854-d1870b4553da?auto=format&fit=crop&w=600&q=80',
      severity: 'High',
      riskLevel: 'High Risk',
      confidenceScore: 96,
      violationType: 'Missing Manufacturer Address',
      violationSummary: 'Only brand name declared; physical packing unit missing',
      capturedAt: DateTime.now().subtract(const Duration(days: 6)),
      status: 'pending',
      declarations: const [
        RegulatorDeclaration(
          fieldName: 'MANUFACTURER ADDRESS',
          extractedValue: 'Marketed by only. Manufacturing Unit ID missing.',
          confidencePercent: 89,
          status: 'Violation',
          ruleCitation: 'PCR 2011 Rule 6(1)(a)',
          ruleDescription:
              'Both manufacturing unit postal address and marketer details required.',
        ),
      ],
      overlayBoxes: const [
        RegulatorOverlayBox(
          topPercent: 0.55,
          leftPercent: 0.20,
          widthPercent: 0.45,
          heightPercent: 0.12,
          label: 'Unit Addr Missing',
          isViolation: true,
        ),
      ],
    ),
    RegulatorViolation(
      id: 'viol-010',
      scanId: '#88220-PT',
      productName: 'Arogya Whole Wheat Atta 10kg',
      companyName: 'Patanjali Ayurved Ltd',
      category: 'Staples & Flour',
      region: 'Central Region - Indore',
      storeLocation: 'Swadeshi Kendra, Palasia, Indore',
      imageUrl:
          'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=600&q=80',
      severity: 'Medium',
      riskLevel: 'Medium Risk',
      confidenceScore: 90,
      violationType: 'Net Quantity',
      violationSummary: 'Net weight declared as 10Kg with capital K (Standard kg)',
      capturedAt: DateTime.now().subtract(const Duration(days: 7)),
      status: 'pending',
      declarations: const [
        RegulatorDeclaration(
          fieldName: 'NET QUANTITY',
          extractedValue: '10Kg (Non-standard unit symbol; required kg)',
          confidencePercent: 95,
          status: 'Warning',
          ruleCitation: 'PCR 2011 Rule 12 & Fifth Schedule',
          ruleDescription: 'Correct symbol for kilogram is lowercase kg.',
        ),
      ],
      overlayBoxes: const [
        RegulatorOverlayBox(
          topPercent: 0.68,
          leftPercent: 0.22,
          widthPercent: 0.30,
          heightPercent: 0.09,
          label: 'Symbol Violation',
          isViolation: false,
        ),
      ],
    ),
  ];

  static final List<RegulatorComplaint> _mockComplaints = [
    RegulatorComplaint(
      id: 'cmp-001',
      complaintCode: 'CMP-2023-892',
      title: 'Mislabeled Expiry - Dairy Product',
      productName: 'Fresh Farms Greek Yogurt 400g',
      companyName: 'Apex Dairy Foods India Ltd',
      category: 'Dairy & Eggs',
      description:
          'I purchased two tubs of Fresh Farms Yogurt from the refrigerated section. When I got home, I noticed the sell-by date looked like it had been rubbed off and re-stamped with a later date over the original faded ink. The product smelled sour upon opening.',
      locationName: 'Downtown Market, Sector 18',
      address: '124 Main St, Food District, New Delhi 110001',
      status: 'Submitted',
      priority: 'High Priority',
      submittedAt: DateTime.now().subtract(const Duration(hours: 2)),
      evidencePhotos: const [
        'https://images.unsplash.com/photo-1571212515416-fef01fc43637?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&w=600&q=80',
      ],
      coordinates: '28.6139° N, 77.2090° E',
      consumerName: 'Rajesh Malhotra',
      consumerContact: '+91 98110 44219',
    ),
    RegulatorComplaint(
      id: 'cmp-002',
      complaintCode: 'CMP-2023-893',
      title: 'Missing Allergen Warning on Bread',
      productName: 'Artisan Multigrain Sourdough Loaf',
      companyName: 'BakeCraft Foods LLP',
      category: 'Bakery',
      description:
          'Artisan sourdough loaf completely lacks mandatory tree nut (walnut) and wheat/gluten allergen declaration on the rear nutritional panel despite having walnut pieces visible inside.',
      locationName: 'Riverside Bakery & Cafe',
      address: 'Shop 14, Riverside Promenade, Bandra West, Mumbai 400050',
      status: 'Submitted',
      priority: 'Allergen Flag',
      submittedAt: DateTime.now().subtract(const Duration(hours: 5)),
      evidencePhotos: const [
        'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80',
      ],
      coordinates: '19.0596° N, 72.8295° E',
      consumerName: 'Ananya Deshmukh',
      consumerContact: '+91 97230 18842',
    ),
    RegulatorComplaint(
      id: 'cmp-003',
      complaintCode: 'CMP-2023-894',
      title: 'Underweight Pre-packaged Paneer',
      productName: 'Fresh Malai Paneer 500g Pack',
      companyName: 'Shreeji Dairy Products Ltd',
      category: 'Dairy Products',
      description:
          'Multiple reports and my own kitchen scale test show that 500g paneer packs consistently weigh only 420g to 440g net. The tare weight of the brine pouch is falsely included in declared net weight.',
      locationName: 'City Supermarket - North Wing',
      address: 'Plot 77, Ring Road Mall, Malleshwaram, Bengaluru 560003',
      status: 'Under Review',
      priority: 'Weight Discrepancy',
      submittedAt: DateTime.now().subtract(const Duration(days: 1)),
      evidencePhotos: const [
        'https://images.unsplash.com/photo-1628088062854-d1870b4553da?auto=format&fit=crop&w=600&q=80',
      ],
      coordinates: '12.9716° N, 77.5946° E',
      consumerName: 'Karthik Ramanathan',
      consumerContact: '+91 94480 55192',
    ),
    RegulatorComplaint(
      id: 'cmp-004',
      complaintCode: 'CMP-2023-895',
      title: 'Overcharging Above Printed MRP at Airport',
      productName: 'Sparkling Mineral Water 750ml',
      companyName: 'Himalayan Waters India',
      category: 'Beverages',
      description:
          'Retail kiosk at Terminal 3 billed ₹120 for water bottle marked with Maximum Retail Price ₹60. Vendor refused to provide cash memo with printed MRP rate.',
      locationName: 'Terminal 3 Departure Kiosk 4',
      address: 'IGI Airport, New Delhi 110037',
      status: 'Under Review',
      priority: 'Pricing Violation',
      submittedAt: DateTime.now().subtract(const Duration(days: 2)),
      evidencePhotos: const [
        'https://images.unsplash.com/photo-1548839140-29a749e1bc4e?auto=format&fit=crop&w=600&q=80',
      ],
      coordinates: '28.5562° N, 77.1000° E',
      consumerName: 'Vikas Singhal',
      consumerContact: '+91 98101 22340',
    ),
    RegulatorComplaint(
      id: 'cmp-005',
      complaintCode: 'CMP-2023-896',
      title: 'Missing Date of Pre-packing on Pulses',
      productName: 'Organic Toor Dal 1kg Pouch',
      companyName: 'Kissan Pure Agritech Ltd',
      category: 'Grains & Pulses',
      description:
          'Pouch has best before duration given as "6 months from packing" but packing date area has blank placeholder stamp with no date entered.',
      locationName: 'Bapu Bazaar Grocery Hub',
      address: 'Shop 22, Old Mandi Road, Jaipur 302003',
      status: 'Verified',
      priority: 'High Priority',
      submittedAt: DateTime.now().subtract(const Duration(days: 3)),
      evidencePhotos: const [
        'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=600&q=80',
      ],
      coordinates: '26.9124° N, 75.7873° E',
      consumerName: 'Meenakshi Rathore',
      consumerContact: '+91 94140 77120',
    ),
    RegulatorComplaint(
      id: 'cmp-006',
      complaintCode: 'CMP-2023-897',
      title: 'Unreachable Consumer Helpline for Spoiled Juice',
      productName: 'Alphonso Mango Nectar 1L',
      companyName: 'SunTropics Juice Ltd',
      category: 'Beverages',
      description:
          'Toll-free customer care number 1800-445-0000 printed on tetra pack says "number does not exist". Email sent to support bounced back.',
      locationName: 'Heritage Store, Anna Nagar',
      address: '2nd Avenue, Anna Nagar East, Chennai 600102',
      status: 'Forwarded',
      priority: 'Medium Priority',
      submittedAt: DateTime.now().subtract(const Duration(days: 4)),
      evidencePhotos: const [
        'https://images.unsplash.com/photo-1534353473418-4cfa6c56fd38?auto=format&fit=crop&w=600&q=80',
      ],
      coordinates: '13.0827° N, 80.2707° E',
      consumerName: 'Deepak Sundaram',
      consumerContact: '+91 98400 33811',
    ),
    RegulatorComplaint(
      id: 'cmp-007',
      complaintCode: 'CMP-2023-898',
      title: 'Missing Country of Origin on Imported Olive Oil',
      productName: 'Extra Virgin Olive Oil 500ml',
      companyName: 'EuroMed Imports LLP',
      category: 'Edible Oils',
      description:
          'Imported olive oil bottle sold with generic European flags without declaring exact Country of Origin on mandatory Hindi/English importer label.',
      locationName: 'Nature Basket Gourmet',
      address: 'Koregaon Park Road, Pune 411001',
      status: 'Verified',
      priority: 'High Priority',
      submittedAt: DateTime.now().subtract(const Duration(days: 5)),
      evidencePhotos: const [
        'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=600&q=80',
      ],
      coordinates: '18.5204° N, 73.8567° E',
      consumerName: 'Priya Mukherjee',
      consumerContact: '+91 98220 99401',
    ),
    RegulatorComplaint(
      id: 'cmp-008',
      complaintCode: 'CMP-2023-899',
      title: 'Net Quantity Deficiency in Ground Spices',
      productName: 'Kashmiri Lal Mirch Powder 100g',
      companyName: 'Royal Spice Mills India',
      category: 'Spices & Condiments',
      description:
          'Net powder contents measured only 82 grams against 100g stated declaration across 3 separate boxes purchased together.',
      locationName: 'Paltan Bazaar Retail Point',
      address: 'Shop 8, Paltan Bazaar, Dehradun 248001',
      status: 'Under Review',
      priority: 'Weight Discrepancy',
      submittedAt: DateTime.now().subtract(const Duration(days: 6)),
      evidencePhotos: const [
        'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&w=600&q=80',
      ],
      coordinates: '30.3165° N, 78.0322° E',
      consumerName: 'Sanjay Rawat',
      consumerContact: '+91 97560 11944',
    ),
  ];

  static final List<RegulatorCompany> _mockCompanies = [
    RegulatorCompany(
      id: 'comp-001',
      name: 'Apex Foods India Pvt Ltd',
      address: 'Dist 4, Sector B, Industrial Area, Okhla, New Delhi 110020',
      region: 'North Zone - Delhi NCR',
      category: 'Packaged Food & Dairy',
      complianceScore: 82,
      openViolationsCount: 2,
      noticesIssuedCount: 3,
      lastAuditDate: DateTime.now().subtract(const Duration(days: 14)),
      status: 'Active',
      timeline: [
        RegulatorTimelineEvent(
          date: DateTime.now().subtract(const Duration(days: 5)),
          title: 'Violation Filed: Mislabeling',
          description:
              'Incorrect allergen and ingredient declaration identified on batch #4492 (Artisan Sourdough Loaf).',
          type: 'violation',
          officerName: 'Officer J. Sharma',
          batchNo: 'Batch #4492',
        ),
        RegulatorTimelineEvent(
          date: DateTime.now().subtract(const Duration(days: 12)),
          title: 'Show-Cause Notice Issued',
          description:
              'Formal notice SCN-2023-1092 dispatched requiring explanation for MRP discrepancy.',
          type: 'notice_issued',
          officerName: 'Officer R. Verma',
        ),
        RegulatorTimelineEvent(
          date: DateTime.now().subtract(const Duration(days: 20)),
          title: 'Company Response Received',
          description:
              'Company submitted legal clarification stating label printing error was due to packaging vendor offset misalignment.',
          type: 'response_received',
          officerName: 'Officer R. Verma',
        ),
        RegulatorTimelineEvent(
          date: DateTime.now().subtract(const Duration(days: 35)),
          title: 'Corrective Action Verified',
          description:
              'New packaging batch #4480 inspected on-site and verified for PCR 2011 compliance.',
          type: 'corrective_action',
          officerName: 'Officer M. Smith',
        ),
        RegulatorTimelineEvent(
          date: DateTime.now().subtract(const Duration(days: 60)),
          title: 'Routine Audit Passed',
          description:
              'Annual comprehensive metrology inspection completed with compliant certification.',
          type: 'audit_passed',
          officerName: 'Officer J. Sharma',
        ),
      ],
    ),
    RegulatorCompany(
      id: 'comp-002',
      name: 'GreenValley Organics India Ltd',
      address: 'Dist 1, Sector A, Sanand GIDC, Ahmedabad, Gujarat 382110',
      region: 'West Zone - Gujarat',
      category: 'Organic Cereals & Pulses',
      complianceScore: 98,
      openViolationsCount: 0,
      noticesIssuedCount: 1,
      lastAuditDate: DateTime.now().subtract(const Duration(days: 8)),
      status: 'Compliant',
      timeline: [
        RegulatorTimelineEvent(
          date: DateTime.now().subtract(const Duration(days: 8)),
          title: 'Certification Renewed',
          description:
              'Organic standard and legal metrology verification passed successfully with 98% score.',
          type: 'audit_passed',
          officerName: 'Officer K. Dave',
        ),
        RegulatorTimelineEvent(
          date: DateTime.now().subtract(const Duration(days: 90)),
          title: 'Routine Audit Passed',
          description:
              'All packaging lines inspected for net weight accuracy and unit sale price compliance.',
          type: 'audit_passed',
          officerName: 'Officer K. Dave',
        ),
      ],
    ),
    RegulatorCompany(
      id: 'comp-003',
      name: 'Britannia Industries Limited',
      address: 'Britannia Towers, Airport Road, Kodihalli, Bengaluru 560017',
      region: 'South Zone - Karnataka',
      category: 'Biscuits, Bread & Dairy',
      complianceScore: 91,
      openViolationsCount: 1,
      noticesIssuedCount: 2,
      lastAuditDate: DateTime.now().subtract(const Duration(days: 18)),
      status: 'Active',
      timeline: [
        RegulatorTimelineEvent(
          date: DateTime.now().subtract(const Duration(days: 4)),
          title: 'Violation Filed: Dual Pricing Sticker',
          description:
              'Sticker overprinting detected at retail point in Chennai branch depot.',
          type: 'violation',
          officerName: 'Officer S. Ramesh',
          batchNo: 'Batch #BT-8891',
        ),
        RegulatorTimelineEvent(
          date: DateTime.now().subtract(const Duration(days: 40)),
          title: 'Re-Audit Completed',
          description:
              'Warehouse sampling showed 99.4% conformity on net weight declaration.',
          type: 're_audit',
          officerName: 'Officer S. Ramesh',
        ),
        RegulatorTimelineEvent(
          date: DateTime.now().subtract(const Duration(days: 110)),
          title: 'Routine Audit Passed',
          description: 'Factory packaging audit approved.',
          type: 'audit_passed',
          officerName: 'Officer V. Swamy',
        ),
      ],
    ),
    RegulatorCompany(
      id: 'comp-004',
      name: 'ITC Limited - Foods Business',
      address: 'Virginia House, 37 J.L. Nehru Road, Kolkata 700071',
      region: 'East Zone - West Bengal',
      category: 'Snacks, Biscuits & Staples',
      complianceScore: 94,
      openViolationsCount: 0,
      noticesIssuedCount: 1,
      lastAuditDate: DateTime.now().subtract(const Duration(days: 22)),
      status: 'Compliant',
      timeline: [
        RegulatorTimelineEvent(
          date: DateTime.now().subtract(const Duration(days: 22)),
          title: 'Annual Surveillance Audit Passed',
          description:
              'Aashirvaad and Sunfeast packaging lines met all LMPC requirements.',
          type: 'audit_passed',
          officerName: 'Officer A. Sen',
        ),
        RegulatorTimelineEvent(
          date: DateTime.now().subtract(const Duration(days: 120)),
          title: 'Corrective Action Verified',
          description:
              'Revised font size specifications implemented across all 500g pouches.',
          type: 'corrective_action',
          officerName: 'Officer A. Sen',
        ),
      ],
    ),
    RegulatorCompany(
      id: 'comp-005',
      name: 'Shree Kissan Agro Mills',
      address: 'Plot 18, UPSIDC Industrial Area, Kanpur, Uttar Pradesh 208022',
      region: 'North Zone - Uttar Pradesh',
      category: 'Edible Oils & Vanaspati',
      complianceScore: 64,
      openViolationsCount: 4,
      noticesIssuedCount: 5,
      lastAuditDate: DateTime.now().subtract(const Duration(days: 3)),
      status: 'Action Required',
      timeline: [
        RegulatorTimelineEvent(
          date: DateTime.now().subtract(const Duration(days: 1)),
          title: 'Violation Filed: Severe Weight Shortfall',
          description:
              'Measured oil volume 910ml vs declared 1000ml (9.0% shortfall across sampled lot).',
          type: 'violation',
          officerName: 'Officer P. Tiwari',
          batchNo: 'Batch #SK-044',
        ),
        RegulatorTimelineEvent(
          date: DateTime.now().subtract(const Duration(days: 15)),
          title: 'Show-Cause Notice Issued',
          description:
              'Formal notice SCN-2023-0870 issued for repeated non-compliance of Unit Sale Price.',
          type: 'notice_issued',
          officerName: 'Officer P. Tiwari',
        ),
        RegulatorTimelineEvent(
          date: DateTime.now().subtract(const Duration(days: 45)),
          title: 'Warning Notice Dispatched',
          description:
              'Company directed to calibrate automatic packaging filling valves.',
          type: 'notice_issued',
          officerName: 'Officer D. Pandey',
        ),
      ],
    ),
    RegulatorCompany(
      id: 'comp-006',
      name: 'Haldiram Snacks Pvt Ltd',
      address: 'B-1/H-8, Mohan Co-op Industrial Estate, Mathura Road, New Delhi 110044',
      region: 'North Zone - Delhi NCR',
      category: 'Traditional Sweets & Savouries',
      complianceScore: 89,
      openViolationsCount: 1,
      noticesIssuedCount: 2,
      lastAuditDate: DateTime.now().subtract(const Duration(days: 16)),
      status: 'Active',
      timeline: [
        RegulatorTimelineEvent(
          date: DateTime.now().subtract(const Duration(days: 2)),
          title: 'Violation Noted: Font Size Inadequacy',
          description:
              'Consumer helpline font height measured 0.9mm vs statutory 1.5mm.',
          type: 'violation',
          officerName: 'Officer R. Verma',
        ),
        RegulatorTimelineEvent(
          date: DateTime.now().subtract(const Duration(days: 75)),
          title: 'Routine Audit Passed',
          description:
              'Packaging standards verified for exported and domestic snack pouches.',
          type: 'audit_passed',
          officerName: 'Officer R. Verma',
        ),
      ],
    ),
    RegulatorCompany(
      id: 'comp-007',
      name: 'Dabur India Limited',
      address: '8/3 Asaf Ali Road, Daryaganj, New Delhi 110002',
      region: 'North Zone - Delhi NCR',
      category: 'Ayurvedic & Health Food',
      complianceScore: 92,
      openViolationsCount: 1,
      noticesIssuedCount: 1,
      lastAuditDate: DateTime.now().subtract(const Duration(days: 25)),
      status: 'Compliant',
      timeline: [
        RegulatorTimelineEvent(
          date: DateTime.now().subtract(const Duration(days: 5)),
          title: 'Helpline Inquiry Logged',
          description:
              'Grievance cell responsiveness verification triggered by consumer complaint.',
          type: 'violation',
          officerName: 'Officer N. Kapoor',
        ),
        RegulatorTimelineEvent(
          date: DateTime.now().subtract(const Duration(days: 130)),
          title: 'Routine Audit Passed',
          description: 'Honey bottling line passed all tare and fill weight tests.',
          type: 'audit_passed',
          officerName: 'Officer N. Kapoor',
        ),
      ],
    ),
    RegulatorCompany(
      id: 'comp-008',
      name: 'Mother Dairy Fruit & Vegetable Pvt Ltd',
      address: 'Patparganj Industrial Area, New Delhi 110092',
      region: 'North Zone - Delhi NCR',
      category: 'Milk, Dairy & Edible Oils (Dhara)',
      complianceScore: 86,
      openViolationsCount: 2,
      noticesIssuedCount: 2,
      lastAuditDate: DateTime.now().subtract(const Duration(days: 11)),
      status: 'Active',
      timeline: [
        RegulatorTimelineEvent(
          date: DateTime.now().subtract(const Duration(days: 6)),
          title: 'Violation Filed: Manufacturing Unit Omission',
          description:
              'Packaged tin failed to specify exact location of bottling factory unit.',
          type: 'violation',
          officerName: 'Officer J. Sharma',
        ),
        RegulatorTimelineEvent(
          date: DateTime.now().subtract(const Duration(days: 50)),
          title: 'Routine Milk Pouch Check Passed',
          description: 'Weight and density analysis within standard tolerance.',
          type: 'audit_passed',
          officerName: 'Officer J. Sharma',
        ),
      ],
    ),
  ];

  static final List<RegulatorNotice> _mockNotices = [
    RegulatorNotice(
      id: 'not-001',
      noticeNumber: 'SCN-2023-1092',
      violationId: 'viol-001',
      companyId: 'comp-001',
      companyName: 'Nature Organics India Pvt Ltd',
      productName: 'Organic Quinoa Flakes 500g',
      ruleViolated:
          'Omission of Maximum Retail Price (MRP) and Unit Sale Price on Principal Display Panel',
      ruleCitation: 'LMPC Act 2009 Sec 18(1) & PCR 2011 Rule 6(1)(e)',
      issueDate: DateTime.now().subtract(const Duration(days: 2)),
      deadlineDate: DateTime.now().add(const Duration(days: 13)),
      status: 'Draft',
      officerNotes:
          'Inspected package at Central Market Vashi. The entire front and rear panel omitted mandatory MRP stamp. Recommend immediate compounding and rectification notice.',
      officerName: 'Officer J. Sharma (Enforcement Cell)',
      evidenceSummary:
          'Scan ID: #88492-AX; High-res OCR images showing zero retail price declaration on batch #Q209.',
      history: [
        RegulatorNoticeHistoryItem(
          title: 'Violation Noted',
          description:
              'Absence of MRP and price per unit verified via mobile inspection camera.',
          date: DateTime.now().subtract(const Duration(days: 2)),
          officerName: 'Officer J. Sharma',
          type: 'violation',
        ),
        RegulatorNoticeHistoryItem(
          title: 'Previous Routine Audit Passed',
          description: 'Standard facility check conducted in Pune factory.',
          date: DateTime.now().subtract(const Duration(days: 120)),
          officerName: 'Officer M. Smith',
          type: 'audit_passed',
        ),
      ],
    ),
    RegulatorNotice(
      id: 'not-002',
      noticeNumber: 'SCN-2023-1093',
      violationId: 'viol-002',
      companyId: 'comp-001',
      companyName: 'BakeCraft Foods LLP',
      productName: 'Artisan Sourdough Loaf 400g',
      ruleViolated: 'Non-disclosure of mandatory allergen declaration (Walnuts)',
      ruleCitation: 'PCR 2011 Rule 6(1)(e) & FSSAI Labelling Regs 2020',
      issueDate: DateTime.now().subtract(const Duration(days: 1)),
      deadlineDate: DateTime.now().add(const Duration(days: 14)),
      status: 'Issued',
      officerNotes:
          'Tree nut allergy hazard identified. Directing company to immediately quarantine affected batch #4492.',
      officerName: 'Officer R. Verma',
      evidenceSummary: 'Visual physical sample photographed at GK-1 store.',
      history: [
        RegulatorNoticeHistoryItem(
          title: 'Notice Dispatched via Registered Post & Email',
          description: 'Official digital copy served on compliance officer.',
          date: DateTime.now().subtract(const Duration(days: 1)),
          officerName: 'Officer R. Verma',
          type: 'notice_issued',
        ),
      ],
    ),
  ];

  // ---------------------------------------------------------------------------
  // PUBLIC SERVICE METHODS (MOCK IMPLEMENTATIONS WITH LATENCY)
  // ---------------------------------------------------------------------------

  /// Fetches flagged violations with optional filters.
  static Future<List<RegulatorViolation>> getFlaggedViolations({
    String? region,
    String? category,
    String? severity,
  }) async {
    // MOCK DATA — replace with Supabase query, see TODO
    // TODO: replace with _client.from('regulator_violations').select().order('captured_at', ascending: false)
    await Future.delayed(const Duration(milliseconds: 300));

    var results = List<RegulatorViolation>.from(_mockViolations);
    if (region != null && region.isNotEmpty && region != 'All Regions') {
      results = results
          .where((v) => v.region.toLowerCase().contains(region.toLowerCase()))
          .toList();
    }
    if (category != null && category.isNotEmpty && category != 'All Categories') {
      results = results
          .where((v) =>
              v.category.toLowerCase().contains(category.toLowerCase()))
          .toList();
    }
    if (severity != null && severity.isNotEmpty && severity != 'All') {
      results = results
          .where((v) => v.severity.toLowerCase() == severity.toLowerCase())
          .toList();
    }
    return results;
  }

  /// Fetches a single violation by ID.
  static Future<RegulatorViolation> getViolationById(String id) async {
    // MOCK DATA — replace with Supabase query, see TODO
    // TODO: replace with _client.from('regulator_violations').select().eq('id', id).single()
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockViolations.firstWhere(
      (v) => v.id == id,
      orElse: () => _mockViolations.first,
    );
  }

  /// Fetches consumer complaints with optional status filter.
  static Future<List<RegulatorComplaint>> getComplaints({String? status}) async {
    // MOCK DATA — replace with Supabase query, see TODO
    // TODO: replace with _client.from('regulator_complaints').select().order('submitted_at', ascending: false)
    await Future.delayed(const Duration(milliseconds: 300));
    if (status != null && status.isNotEmpty && status != 'All') {
      return _mockComplaints
          .where((c) => c.status.toLowerCase() == status.toLowerCase())
          .toList();
    }
    return List<RegulatorComplaint>.from(_mockComplaints);
  }

  /// Fetches a single complaint by ID.
  static Future<RegulatorComplaint> getComplaintById(String id) async {
    // MOCK DATA — replace with Supabase query, see TODO
    // TODO: replace with _client.from('regulator_complaints').select().eq('id', id).single()
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockComplaints.firstWhere(
      (c) => c.id == id,
      orElse: () => _mockComplaints.first,
    );
  }

  /// Fetches companies with optional search term filter.
  static Future<List<RegulatorCompany>> getCompanies({String? search}) async {
    // MOCK DATA — replace with Supabase query, see TODO
    // TODO: replace with _client.from('regulator_companies').select().ilike('name', '%$search%')
    await Future.delayed(const Duration(milliseconds: 300));
    if (search != null && search.trim().isNotEmpty) {
      final query = search.trim().toLowerCase();
      return _mockCompanies
          .where((c) =>
              c.name.toLowerCase().contains(query) ||
              c.address.toLowerCase().contains(query) ||
              c.category.toLowerCase().contains(query))
          .toList();
    }
    return List<RegulatorCompany>.from(_mockCompanies);
  }

  /// Fetches company detail with timeline events.
  static Future<RegulatorCompany> getCompanyDetail(String id) async {
    // MOCK DATA — replace with Supabase query, see TODO
    // TODO: replace with _client.from('regulator_companies').select('*, timeline:regulator_timeline_events(*)').eq('id', id).single()
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockCompanies.firstWhere(
      (c) => c.id == id,
      orElse: () => _mockCompanies.first,
    );
  }

  /// Generates a pre-filled Show-Cause notice draft from a violation record.
  static Future<RegulatorNotice> generateNoticeDraft(String violationId) async {
    // MOCK DATA — replace with Supabase query, see TODO
    // TODO: replace with _client.rpc('generate_notice_draft', params: {'violation_id': violationId})
    await Future.delayed(const Duration(milliseconds: 300));
    final violation = _mockViolations.firstWhere(
      (v) => v.id == violationId,
      orElse: () => _mockViolations.first,
    );

    final matchingNotice = _mockNotices.where((n) => n.violationId == violationId);
    if (matchingNotice.isNotEmpty) {
      return matchingNotice.first;
    }

    return RegulatorNotice(
      id: 'not-${DateTime.now().millisecondsSinceEpoch}',
      noticeNumber: 'SCN-2023-${(1000 + _mockNotices.length)}',
      violationId: violation.id,
      companyId: 'comp-001',
      companyName: violation.companyName,
      productName: violation.productName,
      ruleViolated: violation.violationSummary,
      ruleCitation: violation.declarations.isNotEmpty
          ? violation.declarations.first.ruleCitation
          : 'LMPC Act 2009 & PCR 2011',
      issueDate: DateTime.now(),
      deadlineDate: DateTime.now().add(const Duration(days: 15)),
      status: 'Draft',
      officerNotes:
          'Audit scan ${violation.scanId} detected ${violation.violationSummary} at ${violation.storeLocation}. Immediate formal show-cause notice initiated under Legal Metrology (Packaged Commodities) Rules 2011.',
      officerName: 'Officer J. Sharma (Metrology Division)',
      evidenceSummary:
          'Scan ID: ${violation.scanId}, Confidence: ${violation.confidenceScore}%, Location: ${violation.storeLocation}',
      history: [
        RegulatorNoticeHistoryItem(
          title: 'Violation Noted',
          description: violation.violationSummary,
          date: violation.capturedAt,
          officerName: 'Officer J. Sharma',
          type: 'violation',
        ),
        RegulatorNoticeHistoryItem(
          title: 'Routine Audit Passed',
          description:
              'Previous facility packaging inspection passed standard tolerance.',
          date: DateTime.now().subtract(const Duration(days: 90)),
          officerName: 'Officer M. Smith',
          type: 'audit_passed',
        ),
      ],
    );
  }

  /// Confirms a violation.
  static Future<void> confirmViolation(String id) async {
    // MOCK DATA — replace with Supabase query, see TODO
    // TODO: replace with _client.from('regulator_violations').update({'status': 'confirmed'}).eq('id', id)
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockViolations.indexWhere((v) => v.id == id);
    if (index != -1) {
      _mockViolations[index] =
          _mockViolations[index].copyWith(status: 'confirmed');
    }
  }

  /// Marks a flagged item as a false positive.
  static Future<void> markFalsePositive(String id) async {
    // MOCK DATA — replace with Supabase query, see TODO
    // TODO: replace with _client.from('regulator_violations').update({'status': 'false_positive'}).eq('id', id)
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockViolations.indexWhere((v) => v.id == id);
    if (index != -1) {
      _mockViolations[index] =
          _mockViolations[index].copyWith(status: 'false_positive');
    }
  }

  /// Requests manual review by another inspector.
  static Future<void> requestManualReview(String id) async {
    // MOCK DATA — replace with Supabase query, see TODO
    // TODO: replace with _client.from('regulator_violations').update({'status': 'manual_review'}).eq('id', id)
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockViolations.indexWhere((v) => v.id == id);
    if (index != -1) {
      _mockViolations[index] =
          _mockViolations[index].copyWith(status: 'manual_review');
    }
  }

  /// Escalates a violation to senior authorities.
  static Future<void> escalateViolation(String id) async {
    // MOCK DATA — replace with Supabase query, see TODO
    // TODO: replace with _client.from('regulator_violations').update({'status': 'escalated'}).eq('id', id)
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockViolations.indexWhere((v) => v.id == id);
    if (index != -1) {
      _mockViolations[index] =
          _mockViolations[index].copyWith(status: 'escalated');
    }
  }

  /// Issues and dispatches a formal legal notice.
  static Future<void> issueNotice(RegulatorNotice notice) async {
    // MOCK DATA — replace with Supabase query, see TODO
    // TODO: replace with _client.from('regulator_notices').insert(notice.toJson())
    await Future.delayed(const Duration(milliseconds: 300));
    final updatedNotice = notice.copyWith(status: 'Issued');
    final index = _mockNotices.indexWhere((n) => n.id == notice.id);
    if (index != -1) {
      _mockNotices[index] = updatedNotice;
    } else {
      _mockNotices.insert(0, updatedNotice);
    }
  }

  /// Verifies a consumer complaint and forwards it for investigation.
  static Future<void> verifyAndForwardComplaint(String id) async {
    // MOCK DATA — replace with Supabase query, see TODO
    // TODO: replace with _client.from('regulator_complaints').update({'status': 'Forwarded'}).eq('id', id)
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockComplaints.indexWhere((c) => c.id == id);
    if (index != -1) {
      _mockComplaints[index] =
          _mockComplaints[index].copyWith(status: 'Forwarded');
    }
  }

  /// Rejects an unfounded consumer complaint.
  static Future<void> rejectComplaint(String id) async {
    // MOCK DATA — replace with Supabase query, see TODO
    // TODO: replace with _client.from('regulator_complaints').update({'status': 'Rejected'}).eq('id', id)
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockComplaints.indexWhere((c) => c.id == id);
    if (index != -1) {
      _mockComplaints[index] =
          _mockComplaints[index].copyWith(status: 'Rejected');
    }
  }

  /// Creates a newly captured intake violation from camera/upload scanning.
  static Future<RegulatorViolation> createAuditViolation({
    required String productName,
    required String companyName,
    String? imagePath,
    String? imageUrl,
  }) async {
    // MOCK DATA — replace with Supabase query, see TODO
    // TODO: replace with _client.from('regulator_violations').insert(...)
    await Future.delayed(const Duration(milliseconds: 300));
    final newId = 'viol-${DateTime.now().millisecondsSinceEpoch}';
    final newViolation = RegulatorViolation(
      id: newId,
      scanId: '#${(10000 + _mockViolations.length * 111)}-AX',
      productName: productName.isNotEmpty ? productName : 'Scanned Field Sample',
      companyName: companyName.isNotEmpty ? companyName : 'Sample Packaging Unit',
      category: 'Packaged Commodities',
      region: 'North Region - Delhi NCR',
      storeLocation: 'Field Inspection Site #4',
      imageUrl: imageUrl ??
          'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=600&q=80',
      severity: 'High',
      riskLevel: 'High Risk',
      confidenceScore: 94,
      violationType: 'Missing MRP',
      violationSummary: 'MRP & Unit Sale Price Missing on Principal Display Panel',
      capturedAt: DateTime.now(),
      status: 'pending',
      declarations: const [
        RegulatorDeclaration(
          fieldName: 'MAXIMUM RETAIL PRICE (MRP)',
          extractedValue: 'Not Found',
          confidencePercent: 0,
          status: 'Violation',
          ruleCitation: 'LMPC Sec 18(1) & PCR Rule 6(1)(e)',
          ruleDescription:
              'The MRP must be distinctly declared on the principal display panel.',
        ),
        RegulatorDeclaration(
          fieldName: 'NET QUANTITY',
          extractedValue: '500g',
          confidencePercent: 98,
          status: 'Compliant',
          ruleCitation: 'PCR 2011 Rule 6(1)(c)',
          ruleDescription: 'Net weight declared.',
        ),
        RegulatorDeclaration(
          fieldName: 'DATE OF MFG',
          extractedValue: '12/10/2023',
          confidencePercent: 92,
          status: 'Compliant',
          ruleCitation: 'PCR 2011 Rule 6(1)(d)',
          ruleDescription: 'Date of manufacturing is visible.',
        ),
      ],
      overlayBoxes: const [
        RegulatorOverlayBox(
          topPercent: 0.72,
          leftPercent: 0.12,
          widthPercent: 0.35,
          heightPercent: 0.10,
          label: 'MRP Missing',
          isViolation: true,
        ),
        RegulatorOverlayBox(
          topPercent: 0.58,
          leftPercent: 0.12,
          widthPercent: 0.28,
          heightPercent: 0.08,
          label: '98%',
          isViolation: false,
        ),
      ],
    );

    _mockViolations.insert(0, newViolation);
    return newViolation;
  }
}
