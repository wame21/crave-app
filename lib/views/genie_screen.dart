import 'package:flutter/material.dart';
import '../components/custom_bottom_nav.dart';
import '../services/genie_service.dart';
import '../models/restaurant_model.dart';
import 'restaurant_detail_screen.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final List<RestaurantModel>? suggestions;

  ChatMessage({required this.text, required this.isUser, this.suggestions});
}

class GenieScreen extends StatefulWidget {
  const GenieScreen({super.key});

  @override
  State<GenieScreen> createState() => _GenieScreenState();
}

class _GenieScreenState extends State<GenieScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage(text: '¿Que se te antoja\nhoy?', isUser: false),
  ];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final response = await GenieService.chat(text);
      setState(() {
        _messages.add(ChatMessage(
          text: response.reply,
          isUser: false,
          suggestions: response.restaurantSuggestions,
        ));
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Error: ${e.toString().replaceAll('Exception: ', '')}',
          isUser: false,
        ));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Genio de los antojos',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false, 
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Área donde aparecerán los mensajes del chat
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),
            
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Center(child: CircularProgressIndicator(color: Colors.black)),
              ),

            // Caja de Input interactiva en la parte inferior
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Campo para escribir
                    TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: '....',
                        hintStyle: TextStyle(color: Colors.black38),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      maxLines: 3, 
                      minLines: 1,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                    // Fila de herramientas e ícono de enviar
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.image_outlined, color: Colors.black87),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.mic_none, color: Colors.black87),
                            onPressed: () {},
                          ),
                          const Spacer(), 
                          // Botón circular de enviar
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_upward, color: Colors.black45),
                              onPressed: _isLoading ? null : _sendMessage,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 2), 
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Column(
      crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: message.isUser ? Colors.teal.shade100 : Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: message.isUser ? const Radius.circular(12) : const Radius.circular(2),
                bottomRight: message.isUser ? const Radius.circular(2) : const Radius.circular(12),
              ),
            ),
            child: Text(
              message.text,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ),
        if (message.suggestions != null && message.suggestions!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
            child: SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: message.suggestions!.length,
                itemBuilder: (context, i) {
                  final suggestion = message.suggestions![i];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RestaurantDetailScreen(restaurantId: suggestion.idRestaurant),
                        ),
                      );
                    },
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 12.0),
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        border: Border.all(color: Colors.teal.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.restaurant, color: Colors.teal),
                          const SizedBox(height: 8),
                          Text(
                            suggestion.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          if (suggestion.overallRating != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.star, size: 14, color: Colors.yellow.shade700),
                                const SizedBox(width: 2),
                                Text(suggestion.overallRating!.toStringAsFixed(1), style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ]
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}