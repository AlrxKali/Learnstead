import 'package:flutter/material.dart';
import 'chats_tab.dart';

/// Wrapper so the provider home keeps its existing widget name. Renders
/// the same ChatsTab the parent uses — RLS surfaces the right rows for
/// each side.
class ProviderMessagesTab extends StatelessWidget {
  const ProviderMessagesTab({super.key});

  @override
  Widget build(BuildContext context) => const ChatsTab();
}
