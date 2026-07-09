import 'package:flutter/material.dart';

// ── Models ───────────────────────────────────────────────────────────────────

enum HelpBlockType { paragraph, iconList, sectionHeader, checkList }

class HelpBlock {
  const HelpBlock({required this.type, this.text, this.items});
  final HelpBlockType type;
  final String? text;
  final List<String>? items;
}

class HelpArticle {
  const HelpArticle({
    required this.id,
    required this.topicId,
    required this.title,
    required this.date,
    required this.views,
    required this.readMinutes,
    required this.preview,
    required this.blocks,
  });
  final String id;
  final String topicId;
  final String title;
  final String date;
  final int views;
  final int readMinutes;
  final String preview;
  final List<HelpBlock> blocks;
}

class HelpTopic {
  const HelpTopic({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.articles,
  });
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<HelpArticle> articles;
}

// ── FAQ ──────────────────────────────────────────────────────────────────────

class FaqItem {
  const FaqItem({required this.question, required this.answer});
  final String question;
  final String answer;
}

const kFaqs = <FaqItem>[
  FaqItem(
    question: 'How do I track my order?',
    answer:
        'Go to Profile → My Orders, tap your order and select "Track Order". You\'ll see real-time updates including the courier name, tracking number, and estimated delivery date.',
  ),
  FaqItem(
    question: 'What\'s your return policy?',
    answer:
        'You can request a return within 7 days of delivery if the item is damaged, defective, incorrect, or unused in its original packaging. To start a return, contact our support team with your order number and photos (if applicable).',
  ),
  FaqItem(
    question: 'How long does shipping take?',
    answer:
        'Standard shipping takes 3–7 business days. Express shipping (where available) delivers in 1–2 business days. International orders may take 7–21 business days depending on the destination.',
  ),
  FaqItem(
    question: 'Can I change my order after placing it?',
    answer:
        'Orders can be modified within 1 hour of placing them. After that, the order moves to fulfillment and cannot be changed. Contact Live Chat immediately if you need to update your order.',
  ),
  FaqItem(
    question: 'How do I become a Creator?',
    answer:
        'Tap your profile, select "Become a Creator", and complete the application. You\'ll need to connect at least one social media account. Applications are reviewed within 1–3 business days.',
  ),
];

// ── Contact options ───────────────────────────────────────────────────────────

class ContactOption {
  const ContactOption({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
}

const kContactOptions = <ContactOption>[
  ContactOption(
    icon: Icons.chat_bubble_outline_rounded,
    title: 'Live Chat',
    subtitle: 'Available • Wait: 2min',
  ),
  ContactOption(
    icon: Icons.mail_outline_rounded,
    title: 'Email Support',
    subtitle: '24 hour response',
  ),
  ContactOption(
    icon: Icons.phone_outlined,
    title: 'Direct Call (1-800-Reel-Com)',
    subtitle: 'Mon-Fri, 9 AM – 6 PM EST',
  ),
];

// ── Topics & Articles ─────────────────────────────────────────────────────────

const kHelpTopics = <HelpTopic>[
  HelpTopic(
    id: 'orders',
    title: 'Orders & Shipping',
    subtitle: 'Track, modify, or cancel orders',
    icon: Icons.inventory_2_outlined,
    articles: _ordersArticles,
  ),
  HelpTopic(
    id: 'returns',
    title: 'Returns & Refunds',
    subtitle: 'Return policies & refund process',
    icon: Icons.assignment_return_outlined,
    articles: _returnsArticles,
  ),
  HelpTopic(
    id: 'account',
    title: 'Account & Settings',
    subtitle: 'Manage your account & preferences',
    icon: Icons.person_outline_rounded,
    articles: _accountArticles,
  ),
  HelpTopic(
    id: 'payment',
    title: 'Payment & Billing',
    subtitle: 'Payment methods & billing questions',
    icon: Icons.credit_card_outlined,
    articles: _paymentArticles,
  ),
  HelpTopic(
    id: 'safety',
    title: 'Safety & Privacy',
    subtitle: 'Security & data protection',
    icon: Icons.shield_outlined,
    articles: _safetyArticles,
  ),
  HelpTopic(
    id: 'creators',
    title: 'For Creators',
    subtitle: 'Becoming a creator & earning',
    icon: Icons.play_circle_outline_rounded,
    articles: _creatorArticles,
  ),
  HelpTopic(
    id: 'vendors',
    title: 'For Vendors',
    subtitle: 'Selling on ReelCommerce',
    icon: Icons.storefront_outlined,
    articles: _vendorArticles,
  ),
];

// ── Orders & Shipping articles ────────────────────────────────────────────────

const _ordersArticles = <HelpArticle>[
  HelpArticle(
    id: 'orders_track',
    topicId: 'orders',
    title: 'How to Track Your Order',
    date: 'Thursday, 15th Aug, 2024, 12:45 AM',
    views: 2456,
    readMinutes: 3,
    preview:
        'Once your order is confirmed and dispatched, you can track it in real time directly from the app. Get updates on every step from warehouse to your doorstep...',
    blocks: [
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'Once your order is confirmed and dispatched, you can track it in real time from the Reel Commerce app. Tracking details are automatically updated every time the package moves through a new checkpoint.',
      ),
      HelpBlock(
        type: HelpBlockType.iconList,
        items: [
          'Open the app and tap the Profile icon in the bottom navigation.',
          'Select My Orders from the menu.',
          'Tap on the order you want to track.',
          'Press the Track Order button to see the live status.',
        ],
      ),
      HelpBlock(
        type: HelpBlockType.sectionHeader,
        text: 'Using a Tracking Number',
      ),
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'Every dispatched order includes a courier tracking number. You can use this number on the courier\'s website for more detailed location updates. The tracking number is visible on the Order Detail screen next to the shipment section.',
      ),
      HelpBlock(
        type: HelpBlockType.checkList,
        items: [
          'Tracking updates within 24 hours of dispatch.',
          'Delivery attempt notifications via push and email.',
          'Estimated delivery date shown on the order screen.',
          'Contact support if tracking hasn\'t updated in 48 hours.',
          'Tap "Report Issue" on the order if the parcel appears stuck.',
          'International shipments may have gaps in tracking at customs.',
        ],
      ),
    ],
  ),
  HelpArticle(
    id: 'orders_cancel',
    topicId: 'orders',
    title: 'How to Modify or Cancel an Order',
    date: 'Friday, 16th Aug, 2024, 10:00 AM',
    views: 3789,
    readMinutes: 4,
    preview:
        'Orders can be modified or cancelled within 1 hour of placement. After that the order enters fulfilment and changes may not be possible...',
    blocks: [
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'You have a 1-hour window after placing an order to request changes or a cancellation. Once the warehouse begins processing your order, modifications are no longer possible through the app.',
      ),
      HelpBlock(
        type: HelpBlockType.iconList,
        items: [
          'Go to Profile → My Orders and open the order.',
          'Tap "Cancel Order" or "Edit Order" if still within the 1-hour window.',
          'Select a reason and confirm.',
          'A confirmation email will be sent to your registered address.',
        ],
      ),
      HelpBlock(
        type: HelpBlockType.sectionHeader,
        text: 'After the 1-Hour Window',
      ),
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'If the window has passed, contact our Live Chat team immediately. We can sometimes intercept an order before it ships, but this is not guaranteed. If the order has already shipped, you will need to follow the returns process instead.',
      ),
      HelpBlock(
        type: HelpBlockType.checkList,
        items: [
          'Cancelled orders are refunded within 5–7 business days.',
          'Partially shipped orders cannot be cancelled mid-delivery.',
          'Custom or made-to-order items are non-cancellable.',
        ],
      ),
    ],
  ),
  HelpArticle(
    id: 'orders_shipping_times',
    topicId: 'orders',
    title: 'Shipping Options and Delivery Times',
    date: 'Saturday, 17th Aug, 2024, 9:00 AM',
    views: 4012,
    readMinutes: 4,
    preview:
        'We offer standard and express shipping options across all supported regions. Delivery timelines vary by location and the vendor\'s fulfilment centre...',
    blocks: [
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'Reel Commerce partners with multiple courier services to ensure fast and reliable delivery. The shipping option available to you depends on your location and the vendor fulfilling your order.',
      ),
      HelpBlock(
        type: HelpBlockType.iconList,
        items: [
          'Standard Shipping: 3–7 business days.',
          'Express Shipping: 1–2 business days (select regions).',
          'International: 7–21 business days depending on destination.',
          'Same-Day Delivery: Available in select metro areas.',
        ],
      ),
      HelpBlock(type: HelpBlockType.sectionHeader, text: 'Shipping Costs'),
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'Shipping costs are calculated at checkout based on your delivery address and the total weight of your order. Free shipping is available on orders above the threshold set by each vendor.',
      ),
      HelpBlock(
        type: HelpBlockType.checkList,
        items: [
          'Free standard shipping on orders over the vendor\'s minimum.',
          'Express shipping is charged separately and is non-refundable.',
          'Remote area surcharges may apply for certain postcodes.',
        ],
      ),
    ],
  ),
  HelpArticle(
    id: 'orders_damaged',
    topicId: 'orders',
    title: 'What to Do if Your Order Arrives Damaged',
    date: 'Sunday, 18th Aug, 2024, 8:00 AM',
    views: 5678,
    readMinutes: 6,
    preview:
        'If your order arrives in a damaged condition, take photos immediately and report it within 48 hours. We\'ll arrange a replacement or full refund...',
    blocks: [
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'We take product quality seriously. If your order arrives damaged, defective, or significantly different from what was advertised, we will make it right. Please act quickly — reports older than 48 hours of delivery may not be eligible.',
      ),
      HelpBlock(
        type: HelpBlockType.iconList,
        items: [
          'Do not discard the packaging — it may be needed for the claim.',
          'Take clear photos of the damage from multiple angles.',
          'Go to My Orders and tap "Report a Problem" on the order.',
          'Upload the photos and describe the issue.',
        ],
      ),
      HelpBlock(type: HelpBlockType.sectionHeader, text: 'Resolution Options'),
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'Once your report is reviewed (usually within 24 hours), you will be offered one of three resolutions depending on the vendor\'s policy and stock availability.',
      ),
      HelpBlock(
        type: HelpBlockType.checkList,
        items: [
          'Full replacement shipped at no cost to you.',
          'Partial refund for minor cosmetic damage.',
          'Full refund if a replacement is not available.',
          'Return label provided if the item needs to come back.',
        ],
      ),
    ],
  ),
];

// ── Returns & Refunds articles ────────────────────────────────────────────────

const _returnsArticles = <HelpArticle>[
  HelpArticle(
    id: 'returns_request',
    topicId: 'returns',
    title: 'How to Request a Return',
    date: 'Monday, 19th Aug, 2024, 9:00 AM',
    views: 3100,
    readMinutes: 3,
    preview:
        'You have 7 days from delivery to request a return for eligible items. Start the process directly from My Orders in the app...',
    blocks: [
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'Returns must be initiated within 7 days of the delivery date. The item must be unused, in its original packaging, with all tags intact. Some categories such as perishables, digital goods, and personalised items are excluded.',
      ),
      HelpBlock(
        type: HelpBlockType.iconList,
        items: [
          'Go to Profile → My Orders and select the order.',
          'Tap "Return Item" and choose the item(s) to return.',
          'Select a return reason and upload photos if applicable.',
          'Choose between drop-off or courier pickup.',
        ],
      ),
      HelpBlock(
        type: HelpBlockType.sectionHeader,
        text: 'After Submitting a Return',
      ),
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'Our team reviews your return request within 1 business day. Once approved, you will receive a prepaid return label by email. Pack the item securely and hand it to the courier or drop-off point.',
      ),
      HelpBlock(
        type: HelpBlockType.checkList,
        items: [
          'Refunds are processed within 5–7 business days of item receipt.',
          'Original shipping fees are non-refundable.',
          'Refunds go back to the original payment method.',
        ],
      ),
    ],
  ),
  HelpArticle(
    id: 'returns_refund_times',
    topicId: 'returns',
    title: 'Refund Processing Times',
    date: 'Tuesday, 20th Aug, 2024, 11:00 AM',
    views: 2200,
    readMinutes: 3,
    preview:
        'Once we receive your returned item, refunds are processed within 5–7 business days. Bank processing times may add additional days...',
    blocks: [
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'After we confirm receipt of your return, your refund is initiated immediately on our end. The actual credit appearing in your account depends on your bank or payment provider.',
      ),
      HelpBlock(
        type: HelpBlockType.iconList,
        items: [
          'Credit/Debit cards: 5–7 business days.',
          'PayPal & digital wallets: 1–3 business days.',
          'Bank transfers: 7–10 business days.',
          'Original payment method credits within the stated window.',
        ],
      ),
      HelpBlock(
        type: HelpBlockType.sectionHeader,
        text: 'Tracking Your Refund',
      ),
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'You can check the status of your refund at any time under Profile → My Orders → select the order → Refund Status. You will also receive email updates at each stage.',
      ),
      HelpBlock(
        type: HelpBlockType.checkList,
        items: [
          'Email confirmation sent when refund is initiated.',
          'Refund confirmation email once funds are released.',
          'Contact support if no refund after 10 business days.',
        ],
      ),
    ],
  ),
  HelpArticle(
    id: 'returns_ineligible',
    topicId: 'returns',
    title: 'Items Ineligible for Return',
    date: 'Wednesday, 21st Aug, 2024, 2:00 PM',
    views: 1850,
    readMinutes: 2,
    preview:
        'Certain product categories cannot be returned due to hygiene, safety, or digital delivery reasons. Check before you buy...',
    blocks: [
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'While we have a broad return policy, some items cannot be returned for safety, hygiene, or fulfilment reasons. These exclusions are clearly marked on the product page before purchase.',
      ),
      HelpBlock(
        type: HelpBlockType.checkList,
        items: [
          'Perishable goods: food, flowers, plants.',
          'Personalised or custom-made products.',
          'Digital downloads and gift cards.',
          'Underwear and swimwear (hygiene reasons).',
          'Hazardous materials or flammable goods.',
          'Items marked "Final Sale" at time of purchase.',
        ],
      ),
    ],
  ),
];

// ── Account & Settings articles ───────────────────────────────────────────────

const _accountArticles = <HelpArticle>[
  HelpArticle(
    id: 'account_profile',
    topicId: 'account',
    title: 'How to Update Your Profile Information',
    date: 'Thursday, 22nd Aug, 2024, 9:00 AM',
    views: 1900,
    readMinutes: 2,
    preview:
        'Keep your profile information current to ensure accurate delivery, notifications, and personalised recommendations...',
    blocks: [
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'Keeping your profile up to date ensures smooth order processing and personalised recommendations. You can update your name, profile photo, phone number, and bio directly from the app.',
      ),
      HelpBlock(
        type: HelpBlockType.iconList,
        items: [
          'Tap your avatar on the Profile screen.',
          'Select "Edit Profile".',
          'Update the fields you want to change.',
          'Tap "Save Changes" to confirm.',
        ],
      ),
      HelpBlock(type: HelpBlockType.sectionHeader, text: 'Changing Your Email'),
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'Email changes require verification. After updating your email, a confirmation link will be sent to both your old and new address. The change takes effect once you click the link in the new email.',
      ),
      HelpBlock(
        type: HelpBlockType.checkList,
        items: [
          'Profile photo changes are instant.',
          'Email changes require re-verification.',
          'Phone number changes trigger an OTP.',
        ],
      ),
    ],
  ),
  HelpArticle(
    id: 'account_password',
    topicId: 'account',
    title: 'Changing Your Password',
    date: 'Friday, 23rd Aug, 2024, 10:00 AM',
    views: 2700,
    readMinutes: 2,
    preview:
        'Regularly updating your password helps keep your account secure. You can change it any time from Account Settings...',
    blocks: [
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'We recommend changing your password every 3–6 months and immediately if you suspect unauthorised access. Reel Commerce will never ask for your password via email or chat.',
      ),
      HelpBlock(
        type: HelpBlockType.iconList,
        items: [
          'Go to Profile → Settings → Change Password.',
          'Enter your current password.',
          'Enter and confirm your new password.',
          'Tap "Update Password".',
        ],
      ),
      HelpBlock(
        type: HelpBlockType.sectionHeader,
        text: 'Forgot Your Password?',
      ),
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'On the login screen, tap "Forgot Password" and enter your registered email. You\'ll receive a reset link within a few minutes. The link expires after 15 minutes for security.',
      ),
      HelpBlock(
        type: HelpBlockType.checkList,
        items: [
          'Passwords must be at least 8 characters.',
          'Use a mix of letters, numbers, and symbols.',
          'Do not reuse the last 3 passwords.',
        ],
      ),
    ],
  ),
  HelpArticle(
    id: 'account_deactivate',
    topicId: 'account',
    title: 'How to Deactivate Your Account',
    date: 'Saturday, 24th Aug, 2024, 8:00 AM',
    views: 980,
    readMinutes: 2,
    preview:
        'You can deactivate your account at any time from Settings. Deactivation hides your profile and pauses all activity without deleting your data...',
    blocks: [
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'Deactivating your account temporarily hides your profile, pauses creator earnings, and stops all notifications. Your data is preserved and you can reactivate at any time by logging back in.',
      ),
      HelpBlock(
        type: HelpBlockType.iconList,
        items: [
          'Go to Profile → Settings → Account.',
          'Scroll to the bottom and tap "Deactivate Account".',
          'Read the information and confirm with your password.',
          'Your account is immediately deactivated.',
        ],
      ),
      HelpBlock(type: HelpBlockType.sectionHeader, text: 'Permanent Deletion'),
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'If you want to permanently delete your account and all associated data, tap "Delete Account" instead. This action is irreversible and complies with GDPR right-to-erasure requests. Pending orders must be completed or cancelled before deletion.',
      ),
      HelpBlock(
        type: HelpBlockType.checkList,
        items: [
          'Deactivation is reversible — just log back in.',
          'Deletion is permanent and cannot be undone.',
          'Creator earnings will be paid out before deletion.',
        ],
      ),
    ],
  ),
];

// ── Payment & Billing articles ────────────────────────────────────────────────

const _paymentArticles = <HelpArticle>[
  HelpArticle(
    id: 'payment_add',
    topicId: 'payment',
    title: 'Adding or Removing Payment Methods',
    date: 'Sunday, 25th Aug, 2024, 9:00 AM',
    views: 3400,
    readMinutes: 3,
    preview:
        'Store multiple cards and wallets for quick checkout. Add, edit, or remove payment methods from the Payment Methods screen in your profile...',
    blocks: [
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'Reel Commerce supports credit/debit cards, PayPal, Apple Pay, and Google Pay. You can store multiple methods and set one as your default for faster checkout.',
      ),
      HelpBlock(
        type: HelpBlockType.iconList,
        items: [
          'Go to Profile → Payment Methods.',
          'Tap the green "Add Card +" button.',
          'Enter your card details securely.',
          'Check "Set as Default" if you want this card used first.',
        ],
      ),
      HelpBlock(type: HelpBlockType.sectionHeader, text: 'Removing a Card'),
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'To remove a saved card, open Payment Methods, tap the three-dot menu on the card, and select "Remove". You cannot remove your only payment method if you have active subscriptions.',
      ),
      HelpBlock(
        type: HelpBlockType.checkList,
        items: [
          'Card details are encrypted and never stored on our servers.',
          'Removing a card does not affect past transactions.',
          'Digital wallets are linked via secure OAuth tokens.',
        ],
      ),
    ],
  ),
  HelpArticle(
    id: 'payment_failed',
    topicId: 'payment',
    title: 'Failed Payment Troubleshooting',
    date: 'Monday, 26th Aug, 2024, 11:00 AM',
    views: 2850,
    readMinutes: 4,
    preview:
        'If your payment fails at checkout, here are the most common reasons and how to resolve them quickly...',
    blocks: [
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'Payment failures are usually caused by one of a few common issues. Most can be resolved in under a minute. If the problem persists, contact your bank or our support team.',
      ),
      HelpBlock(
        type: HelpBlockType.iconList,
        items: [
          'Insufficient funds: top up your account or use another card.',
          'Card expired: update your card details in Payment Methods.',
          'Bank declined: contact your bank to authorise the transaction.',
          '3D Secure failure: approve the payment in your banking app.',
        ],
      ),
      HelpBlock(type: HelpBlockType.sectionHeader, text: 'Still Failing?'),
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'Try using a different browser or clear your app cache. Occasionally our payment processor has brief outages — check our status page for any known issues.',
      ),
      HelpBlock(
        type: HelpBlockType.checkList,
        items: [
          'You are not charged for failed transactions.',
          'Pending charges clear automatically within 24 hours.',
          'Try a digital wallet (Apple/Google Pay) as an alternative.',
        ],
      ),
    ],
  ),
];

// ── Safety & Privacy articles ─────────────────────────────────────────────────

const _safetyArticles = <HelpArticle>[
  HelpArticle(
    id: 'safety_data',
    topicId: 'safety',
    title: 'How We Protect Your Data',
    date: 'Tuesday, 27th Aug, 2024, 9:00 AM',
    views: 2100,
    readMinutes: 3,
    preview:
        'Your personal and payment information is protected with industry-standard encryption. We are GDPR-compliant and never sell your data to third parties...',
    blocks: [
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'Reel Commerce is built with privacy by design. We collect only the data necessary to provide our service, and we protect it with multiple layers of security.',
      ),
      HelpBlock(
        type: HelpBlockType.iconList,
        items: [
          'All data in transit is encrypted with TLS 1.3.',
          'Payment data is tokenised — we never see raw card numbers.',
          'Passwords are hashed with bcrypt — we cannot read them.',
          'Two-factor authentication is available on all accounts.',
        ],
      ),
      HelpBlock(type: HelpBlockType.sectionHeader, text: 'Your Privacy Rights'),
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'Under GDPR and equivalent laws, you have the right to access, correct, export, or delete your personal data at any time. Submit a data request from Profile → Settings → Privacy & Data.',
      ),
      HelpBlock(
        type: HelpBlockType.checkList,
        items: [
          'We never sell your data to advertisers.',
          'Marketing emails can be unsubscribed from in one tap.',
          'Data requests are fulfilled within 30 days.',
        ],
      ),
    ],
  ),
  HelpArticle(
    id: 'safety_2fa',
    topicId: 'safety',
    title: 'Setting Up Two-Factor Authentication',
    date: 'Wednesday, 28th Aug, 2024, 10:00 AM',
    views: 1750,
    readMinutes: 3,
    preview:
        '2FA adds a second layer of security to your account. Enable it in Account Settings using an authenticator app or SMS...',
    blocks: [
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'Two-factor authentication (2FA) requires a second form of verification at login, making it much harder for attackers to access your account even if they have your password.',
      ),
      HelpBlock(
        type: HelpBlockType.iconList,
        items: [
          'Go to Profile → Settings → Security → Enable 2FA.',
          'Choose SMS or authenticator app (recommended).',
          'Scan the QR code with your authenticator app.',
          'Enter the 6-digit code to verify and activate.',
        ],
      ),
      HelpBlock(type: HelpBlockType.sectionHeader, text: 'Backup Codes'),
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'After enabling 2FA, save your backup codes in a secure place. These 10 single-use codes allow you to log in if you lose access to your authentication device.',
      ),
      HelpBlock(
        type: HelpBlockType.checkList,
        items: [
          'Authenticator app is more secure than SMS.',
          'Keep backup codes offline, not in a cloud note.',
          'Disable 2FA from Settings if you lose your device.',
        ],
      ),
    ],
  ),
  HelpArticle(
    id: 'safety_report',
    topicId: 'safety',
    title: 'Reporting Suspicious Activity',
    date: 'Thursday, 29th Aug, 2024, 8:00 AM',
    views: 1300,
    readMinutes: 2,
    preview:
        'If you notice unfamiliar orders, login attempts, or profile changes, report it immediately. We\'ll investigate and secure your account...',
    blocks: [
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'If you receive an unexpected login alert, see orders you didn\'t place, or notice profile changes you didn\'t make, take action immediately.',
      ),
      HelpBlock(
        type: HelpBlockType.iconList,
        items: [
          'Change your password immediately from Settings.',
          'Enable 2FA if not already active.',
          'Review Recent Activity in Profile → Account → Activity Log.',
          'Contact Live Chat and report the suspicious activity.',
        ],
      ),
      HelpBlock(type: HelpBlockType.sectionHeader, text: 'Phishing Scams'),
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'Reel Commerce will never ask for your password, OTP, or full card details via email, SMS, or phone. If you receive such a request, it is a phishing attempt — do not respond and forward it to security@reelcommerce.com.',
      ),
      HelpBlock(
        type: HelpBlockType.checkList,
        items: [
          'We never request passwords via any channel.',
          'Official emails come only from @reelcommerce.com.',
          'Report phishing to security@reelcommerce.com.',
        ],
      ),
    ],
  ),
];

// ── Creator articles ──────────────────────────────────────────────────────────

const _creatorArticles = <HelpArticle>[
  HelpArticle(
    id: 'creator_apply',
    topicId: 'creators',
    title: 'How to Apply as a Creator',
    date: 'Friday, 30th Aug, 2024, 9:00 AM',
    views: 5200,
    readMinutes: 4,
    preview:
        'Becoming a creator unlocks reel uploads, product tagging, and commission earnings. The application takes under 5 minutes and is reviewed within 3 business days...',
    blocks: [
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'The Reel Commerce Creator Programme lets you earn commission by tagging products in your short-form videos. Applications are reviewed by our team within 1–3 business days.',
      ),
      HelpBlock(
        type: HelpBlockType.iconList,
        items: [
          'Open your Profile and tap "Become a Creator".',
          'Connect at least one social account (Instagram, TikTok, YouTube, or Facebook).',
          'Complete the creator profile with a bio and content category.',
          'Submit the application and await approval.',
        ],
      ),
      HelpBlock(
        type: HelpBlockType.sectionHeader,
        text: 'Eligibility Requirements',
      ),
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'There is no minimum follower count. We evaluate applications on content quality, category alignment, and community guidelines compliance. Accounts with recent violations may be ineligible.',
      ),
      HelpBlock(
        type: HelpBlockType.checkList,
        items: [
          'Must be 18 years or older.',
          'At least one connected social media account.',
          'Content must comply with platform guidelines.',
          'Approval email sent to your registered address.',
        ],
      ),
    ],
  ),
  HelpArticle(
    id: 'creator_earnings',
    topicId: 'creators',
    title: 'Understanding Creator Earnings',
    date: 'Saturday, 31st Aug, 2024, 10:00 AM',
    views: 4100,
    readMinutes: 5,
    preview:
        'Earn a commission every time a viewer purchases a product you tagged in your reel. Commissions vary by vendor and product category...',
    blocks: [
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'You earn a commission every time someone buys a product you tagged in your reel. Commission rates are set by each vendor and typically range from 5% to 20% of the sale price.',
      ),
      HelpBlock(
        type: HelpBlockType.iconList,
        items: [
          'View your earnings in Creator Dashboard → Earnings.',
          'Earnings are settled monthly on the 1st of each month.',
          'Minimum payout threshold: \$25 or equivalent.',
          'Withdrawals available via bank transfer or PayPal.',
        ],
      ),
      HelpBlock(type: HelpBlockType.sectionHeader, text: 'Boosted Commissions'),
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'Vendors occasionally run campaigns with boosted commission rates for a limited period. You will see a "Boosted" badge on eligible products in the product catalogue when tagging.',
      ),
      HelpBlock(
        type: HelpBlockType.checkList,
        items: [
          'Commissions are tracked per attributed sale.',
          'Returns reduce your commission accordingly.',
          'Tax documentation available in Creator Dashboard.',
        ],
      ),
    ],
  ),
];

// ── Vendor articles ───────────────────────────────────────────────────────────

const _vendorArticles = <HelpArticle>[
  HelpArticle(
    id: 'vendor_setup',
    topicId: 'vendors',
    title: 'Setting Up Your Vendor Shop',
    date: 'Sunday, 1st Sep, 2024, 9:00 AM',
    views: 3600,
    readMinutes: 4,
    preview:
        'Vendors can list products, manage orders, and run creator campaigns from the Vendor Dashboard. Start by completing KYC verification...',
    blocks: [
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'Becoming a vendor on Reel Commerce allows you to reach millions of potential buyers through creator-driven short-form video. To get started, complete KYC verification and set up your shop profile.',
      ),
      HelpBlock(
        type: HelpBlockType.iconList,
        items: [
          'Apply via Profile → Become a Vendor.',
          'Submit KYC documents (business registration + ID).',
          'Set up your shop name, logo, and banner.',
          'Add your first product to go live.',
        ],
      ),
      HelpBlock(type: HelpBlockType.sectionHeader, text: 'Vendor Fees'),
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'There is no monthly subscription fee. Reel Commerce charges a platform fee of 8–12% per successful sale, depending on your vendor tier. This fee covers payment processing, logistics support, and platform maintenance.',
      ),
      HelpBlock(
        type: HelpBlockType.checkList,
        items: [
          'KYC approval takes 1–3 business days.',
          'No upfront fees — pay only on successful sales.',
          'Vendor earnings are settled weekly.',
        ],
      ),
    ],
  ),
  HelpArticle(
    id: 'vendor_products',
    topicId: 'vendors',
    title: 'Listing Your First Product',
    date: 'Monday, 2nd Sep, 2024, 11:00 AM',
    views: 2900,
    readMinutes: 3,
    preview:
        'A great product listing with clear photos, accurate descriptions, and competitive pricing is key to driving sales through creator reels...',
    blocks: [
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'Your product listing is the first thing buyers see after watching a creator\'s reel. High-quality photos and accurate descriptions significantly improve conversion rates.',
      ),
      HelpBlock(
        type: HelpBlockType.iconList,
        items: [
          'Open Vendor Dashboard → Products → Add Product.',
          'Upload at least 3 high-resolution photos (1:1 ratio recommended).',
          'Write a clear, keyword-rich title and description.',
          'Set price, stock quantity, and shipping options.',
        ],
      ),
      HelpBlock(type: HelpBlockType.sectionHeader, text: 'Product Approval'),
      HelpBlock(
        type: HelpBlockType.paragraph,
        text:
            'All new listings are reviewed by our moderation team before going live, typically within 4 hours. Products that violate our guidelines will be returned with feedback for revision.',
      ),
      HelpBlock(
        type: HelpBlockType.checkList,
        items: [
          'Photos must be on a clean background.',
          'No watermarks or promotional text on product images.',
          'Accurate category selection improves discoverability.',
        ],
      ),
    ],
  ),
];
