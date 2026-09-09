/// Contact-channel availability returned by the Support API.
///
/// The API advertises live-chat availability and the configured direct
/// channels. It does not create a live-chat session; customer conversations
/// continue through support tickets until that capability exists.
class ContactChannels {
  const ContactChannels({
    required this.liveChatAvailable,
    required this.liveChatHoursLocal,
    required this.supportEmail,
    required this.directCallPhoneE164,
  });

  final bool liveChatAvailable;
  final String liveChatHoursLocal;
  final String supportEmail;
  final String directCallPhoneE164;
}
