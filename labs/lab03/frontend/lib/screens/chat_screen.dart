
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
  ApiService? _apiService;
  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_apiService == null) {
      try {
        _apiService = Provider.of<ApiService>(context, listen: false);
      } catch (e) {
        // Fallback to creating our own ApiService if Provider is not available
        _apiService = ApiService();
      }
      _loadMessages();
    }
  }

  @override
  void dispose() {
    // TODO: Dispose controllers and API service
    _usernameController.dispose();
    _messageController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  Widget _buildMessageTile(Message message) {
    return ListTile(
      leading: CircleAvatar(child: Text(message.username[0].toUpperCase())),
      title: Text("${message.username} • ${message.timestamp.toLocal().toIso8601String()}"),
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
      onTap: () {
        final statusCodes = [200, 404, 500];
        _showHTTPStatus(statusCodes[Random().nextInt(statusCodes.length)]);
      },
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 48),
          Text(_error ?? 'Unknown error', style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _loadMessages, child: const Text("Retry"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('REST API Chat'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMessages)],
      ),
      body: const Center(child: Text('TODO: Implement chat functionality')),
    );
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final messages = await _apiService!.getMessages();
      setState(() {
        _messages = messages;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    // TODO: Implement _sendMessage
    // Get username and content from controllers
    // Validate that both fields are not empty
    // Create CreateMessageRequest
    // Try to send message using _apiService.createMessage()
    // Add new message to _messages list
    // Clear the message controller
    // Catch any exceptions and show error
    // Call setState() to update UI
    final username = _usernameController.text.trim();
    final content = _messageController.text.trim();
    if (username.isEmpty || content.isEmpty) {
      setState(() {
        _error = 'Username and message cannot be empty.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final request =
          CreateMessageRequest(username: username, content: content);
      final newMessage = await _apiService!.createMessage(request);
      setState(() {
        _messages.insert(0, newMessage);
        _messageController.clear();
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _editMessage(Message message) async {
    // TODO: Implement _editMessage
    // Show dialog with text field pre-filled with message content
    // Allow user to edit the content
    // When saved, create UpdateMessageRequest
    // Try to update message using _apiService.updateMessage()
    // Update the message in _messages list
    // Catch any exceptions and show error
    // Call setState() to update UI
    final TextEditingController editController =
        TextEditingController(text: message.content);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Message'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, editController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && result != message.content) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      try {
        final request = UpdateMessageRequest(content: result);
        final updatedMessage =
            await _apiService!.updateMessage(message.id, request);
        setState(() {
          final index = _messages.indexWhere((m) => m.id == message.id);
          if (index != -1) {
            _messages[index] = updatedMessage;
          }
        });
      } catch (e) {
        setState(() {
          _error = e.toString();
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteMessage(Message message) async {
    // TODO: Implement _deleteMessage
    // Show confirmation dialog
    // If confirmed, try to delete using _apiService.deleteMessage()
    // Remove message from _messages list
    // Catch any exceptions and show error
    // Call setState() to update UI
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      try {
        await _apiService!.deleteMessage(message.id);
        setState(() {
          _messages.removeWhere((m) => m.id == message.id);
        });
      } catch (e) {
        setState(() {
          _error = e.toString();
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showHTTPStatus(int statusCode) async {
    // TODO: Implement _showHTTPStatus
    // Try to get HTTP status info using _apiService.getHTTPStatus()
    // Show dialog with status code, description, and HTTP cat image
    // Use Image.network() to display the cat image
    // http.cat
    // Handle loading and error states for the image
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final statusInfo = await _apiService!.getHTTPStatus(statusCode);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('HTTP Status: $statusCode'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(statusInfo.description),
                const SizedBox(height: 16),
                Image.network(
                  statusInfo.imageUrl,
                  height: 150,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.error, color: Colors.red, size: 48),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Widget _buildMessageTile(Message message) {
    // TODO: Implement _buildMessageTile
    // Return ListTile with:
    // - leading: CircleAvatar with first letter of username
    // - title: Text with username and timestamp
    // - subtitle: Text with message content
    // - trailing: PopupMenuButton with Edit and Delete options
    // - onTap: Show HTTP status dialog for random status code (200, 404, 500)
    return ListTile(
      leading: CircleAvatar(
        child: Text(message.username.isNotEmpty
            ? message.username[0].toUpperCase()
            : '?'),
      ),
      title: Row(
        children: [
          Text(
            message.username,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(
            message.timestamp.toLocal().toString().substring(0, 16),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      subtitle: Text(message.content),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'edit') {
            _editMessage(message);
          } else if (value == 'delete') {
            _deleteMessage(message);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Text('Edit'),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Text('Delete'),
          ),
        ],
      ),
      onTap: () {
        final codes = [200, 404, 500];
        final code = codes[message.id.hashCode % codes.length];
        _showHTTPStatus(code);
      },
    );
  }

  Widget _buildMessageInput() {
    // TODO: Implement _buildMessageInput
    // Return Container with:
    // - Padding and background color
    // - Column with username TextField and message TextField
    // - Row with Send button and HTTP Status demo buttons (200, 404, 500)
    // - Connect controllers to text fields
    // - Handle send button press
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Enter your username',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Enter your message',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendMessage,
                child: const Text('Send'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: OutlinedButton(
                  onPressed: () => _showHTTPStatus(200),
                  child: const Text('200 OK'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: OutlinedButton(
                  onPressed: () => _showHTTPStatus(404),
                  child: const Text('404 Not Found'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: OutlinedButton(
                  onPressed: () => _showHTTPStatus(500),
                  child: const Text('500 Error'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    // TODO: Implement _buildErrorWidget
    // Return Center widget with:
    // - Column containing error icon, error message, and retry button
    // - Red color scheme for error state
    // - Retry button should call _loadMessages()
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(
            _error ?? 'An error occurred.',
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadMessages,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Implement build method
    // Return Scaffold with:
    // - AppBar with title "REST API Chat" and refresh action
    // - Body that shows loading, error, or message list based on state
    // - BottomSheet with message input
    // - FloatingActionButton for refresh
    // Handle different states: loading, error, success
    return Scaffold(
      appBar: AppBar(
        title: const Text('REST API Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadMessages,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingWidget()
          : _error != null
              ? _buildErrorWidget()
              : _messages.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('No messages yet'),
                          SizedBox(height: 8),
                          Text('Send your first message to get started!'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) =>
                          _buildMessageTile(_messages[index]),
                    ),
      bottomSheet: _buildMessageInput(),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _loadMessages,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

// Helper class for HTTP status demonstrations
class HTTPStatusDemo {
  static Future<void> showRandomStatus(
      BuildContext context, ApiService apiService) async {
    final codes = [200, 201, 400, 404, 500];
    codes.shuffle();
    final code = codes.first;
    final _ChatScreenState? state =
        context.findAncestorStateOfType<_ChatScreenState>();
    if (state != null) {
      await state._showHTTPStatus(code);
    }
  }

  static Future<void> showStatusPicker(
      BuildContext context, ApiService apiService) async {
    final codes = [100, 200, 201, 400, 401, 403, 404, 418, 500, 503];
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick HTTP Status'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: codes
              .map(
                (code) => OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    final _ChatScreenState? state =
                        context.findAncestorStateOfType<_ChatScreenState>();
                    if (state != null) {
                      state._showHTTPStatus(code);
                    }
                  },
                  child: Text('$code'),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}