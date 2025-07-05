import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _apiService = ApiService();
  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final messages = await _apiService.getMessages();
      setState(() => _messages = messages);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final username = _usernameController.text.trim();
    final content = _messageController.text.trim();
    final req = CreateMessageRequest(username: username, content: content);
    final error = req.validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    try {
      final newMessage = await _apiService.createMessage(req);
      setState(() {
        _messages.add(newMessage);
        _messageController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _editMessage(Message message) async {
    final controller = TextEditingController(text: message.content);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
    if (result != null) {
      try {
        final updated = await _apiService.updateMessage(message.id, UpdateMessageRequest(content: result));
        setState(() {
          final index = _messages.indexWhere((m) => m.id == message.id);
          if (index != -1) _messages[index] = updated;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _deleteMessage(Message message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _apiService.deleteMessage(message.id);
        setState(() => _messages.removeWhere((m) => m.id == message.id));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }


  Future<void> _showHTTPStatus(int statusCode) async {
    try {
      final status = await _apiService.getHTTPStatus(statusCode);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${status.statusCode} ${status.description}'),
          content: Image.network(status.imageUrl, errorBuilder: (_, __, ___) => const Text('Image failed to load')),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget _buildMessageTile(Message message) {
    return ListTile(
      leading: CircleAvatar(child: Text(message.username[0].toUpperCase())),
      title: Text('${message.username} • ${message.timestamp.toLocal()}'),
      subtitle: Text(message.content),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'edit') _editMessage(message);
          if (value == 'delete') _deleteMessage(message);
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'edit', child: Text('Edit')),
          const PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
      onTap: () => _showHTTPStatus([200, 404, 500][Random().nextInt(3)]),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(labelText: 'Message'),
                ),
              ),
              IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send))
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var code in [200, 404, 500])
                ElevatedButton(
                  onPressed: () => _showHTTPStatus(code),
                  child: Text('$code'),
                ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 48),
          const SizedBox(height: 8),
          Text(_error ?? 'Unknown error', style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _loadMessages, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(child: CircularProgressIndicator());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('REST API Chat'),
        actions: [IconButton(onPressed: _loadMessages, icon: const Icon(Icons.refresh))],
      ),
      body: _isLoading
          ? _buildLoadingWidget()
          : _error != null
              ? _buildErrorWidget()
              : ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => _buildMessageTile(_messages[index]),
                ),
      bottomSheet: _buildMessageInput(),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadMessages,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class HTTPStatusDemo {
  static void showRandomStatus(BuildContext context, ApiService apiService) {
    final randomStatus = [200, 201, 400, 404, 500][Random().nextInt(5)];
    _ChatScreenState()._showHTTPStatus(randomStatus);
  }


  static void showStatusPicker(BuildContext context, ApiService apiService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick HTTP Status'),
        content: Wrap(
          spacing: 8,
          children: [
            for (var code in [100, 200, 201, 400, 401, 403, 404, 418, 500, 503])
              ElevatedButton(
                onPressed: () => _ChatScreenState()._showHTTPStatus(code),
                child: Text('$code'),
              ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
}
