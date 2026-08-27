import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/chat/chat_models.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/widgets.dart';
import '../view_models/chat_room_view_model.dart';
import '../view_models/chat_view_model.dart';

class ChatRoomView extends ConsumerStatefulWidget {
  const ChatRoomView({
    super.key,
    required this.channelId,
    required this.title,
    this.targetId,
    this.targetName,
  });

  final int channelId;
  final String title;
  final String? targetId;
  final String? targetName;

  @override
  ConsumerState<ChatRoomView> createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends ConsumerState<ChatRoomView> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();


    // Pass target info to view model after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatRoomViewModelProvider(widget.channelId).notifier)
          .setTargetInfo(widget.targetId, widget.targetName);
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vmState = ref.watch(chatRoomViewModelProvider(widget.channelId));
    final vm = ref.read(chatRoomViewModelProvider(widget.channelId).notifier);
    
    // Get presence info from the main chat list
    final chatList = ref.watch(chatViewModelProvider).channels;
    final channel = chatList.where((c) => c.id == widget.channelId).firstOrNull ??
                   chatList.where((c) => c.targetId == widget.targetId).firstOrNull;

    ref.listen<ChatRoomState>(chatRoomViewModelProvider(widget.channelId), (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        _jumpToBottom();
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(chatRoomViewModelProvider(widget.channelId).notifier).clearError();
      }
    });

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  if (channel?.isOnline ?? false)
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                    ),
                  Flexible(
                    child: Text(
                      channel?.lastSeenText ?? vmState.zegoStatus,
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.call), onPressed: () {
               vm.startCall(false).catchError((e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Call failed: $e')));
                  }
               });
            }),
            IconButton(icon: const Icon(Icons.videocam), onPressed: () {
               vm.startCall(true).catchError((e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Video call failed: $e')));
                  }
               });
            }),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: vmState.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                  : _buildMessageList(vmState, vm),
            ),
            if (vmState.isRemoteTyping)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${widget.title} is typing',
                        style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.grey)),
                    ),
                  ],
                ),
              ),
            _composer(vmState, vm),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(ChatRoomState state, ChatRoomViewModel vm) {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: state.messages.length,
      itemBuilder: (context, i) {
        final msg = state.messages[i];
        bool showDate = false;
        if (i == 0) {
          showDate = true;
        } else if (msg.dateLabel != state.messages[i - 1].dateLabel) {
          showDate = true;
        }

        return Column(
          children: [
            if (showDate)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
                child: Text(msg.dateLabel, style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold)),
              ),
            _MessageItem(
              message: msg,
              onReply: (m) {
                vm.setReplyingTo(m);
                _focusNode.requestFocus();
              },
              onCallRequest: (isVideo) => vm.startCall(isVideo),
            ),
          ],
        );
      },
    );
  }

  Widget _composer(ChatRoomState state, ChatRoomViewModel vm) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state.replyingTo != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: const Border(left: BorderSide(color: AppColors.maroon, width: 4)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.replyingTo!.isMine ? 'You' : widget.title, 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.maroon, fontSize: 13)
                      ),
                      const SizedBox(height: 2),
                      Text(state.replyingTo!.snippet, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => vm.setReplyingTo(null)),
              ],
            ),
          ),
        SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 12, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.sandalwood, width: 0.5)),
            ),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.grey), onPressed: () => _showAttachmentOptions(vm)),
                Expanded(
                  child: TextField(
                    controller: _input,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: 5,
                    style: const TextStyle(color: Colors.black),
                    onChanged: vm.onTyping,
                    decoration: InputDecoration(
                      hintText: context.tr('typeMessage'),
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      filled: true,
                      fillColor: AppColors.ivory,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: AppColors.maroon,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: () {
                      final text = _input.text.trim();
                      if (text.isNotEmpty) {
                        vm.sendText(text);
                        _input.clear();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: state.isSending
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAttachmentOptions(ChatRoomViewModel vm) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: const Icon(Icons.image, color: Colors.blue), title: const Text('Image'), onTap: () { Navigator.pop(ctx); _pickImage(vm); }),
            ListTile(leading: const Icon(Icons.insert_drive_file, color: Colors.orange), title: const Text('Document'), onTap: () { Navigator.pop(ctx); _pickFile(vm); }),
            ListTile(leading: const Icon(Icons.location_on, color: Colors.green), title: const Text('Location'), onTap: () { Navigator.pop(ctx); _sendLocation(vm); }),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ChatRoomViewModel vm) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null && mounted) _previewAndSend(File(image.path), 'image', vm);
  }

  Future<void> _pickFile(ChatRoomViewModel vm) async {
    const typeGroup = XTypeGroup(label: 'documents', extensions: ['pdf', 'doc', 'txt']);
    final XFile? picked = await openFile(acceptedTypeGroups: [typeGroup]);
    if (picked != null) _previewAndSend(File(picked.path), 'file', vm);
  }

  Future<void> _sendLocation(ChatRoomViewModel vm) async {
    final loc = Location();
    if (await loc.requestService() && await loc.requestPermission() == PermissionStatus.granted) {
      final data = await loc.getLocation();
      final url = 'https://www.google.com/maps/search/?api=1&query=${data.latitude},${data.longitude}';
      vm.sendText(url);
    }
  }

  void _previewAndSend(File file, String type, ChatRoomViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _FilePreviewSheet(
        file: file,
        type: type,
        onSend: (caption) {
          Navigator.pop(ctx);
          vm.sendFile(file, type, caption: caption);
        },
      ),
    );
  }
}

class _FilePreviewSheet extends StatefulWidget {
  final File file;
  final String type;
  final Function(String) onSend;

  const _FilePreviewSheet({required this.file, required this.type, required this.onSend});

  @override
  State<_FilePreviewSheet> createState() => _FilePreviewSheetState();
}

class _FilePreviewSheetState extends State<_FilePreviewSheet> {
  final _caption = TextEditingController();

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Preview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (widget.type == 'image')
            ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(widget.file, height: 200, fit: BoxFit.cover))
          else
            const Icon(Icons.insert_drive_file, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          TextField(
            controller: _caption,
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(hintText: 'Add a caption...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 20),
          GoldButton(label: 'Send', onPressed: () => widget.onSend(_caption.text.trim())),
        ],
      ),
    );
  }
}

class _MessageItem extends StatelessWidget {
  const _MessageItem({required this.message, required this.onReply, required this.onCallRequest});
  final Message message;
  final Function(Message) onReply;
  final Function(bool isVideo) onCallRequest;

  @override
  Widget build(BuildContext context) {
    final mine = message.isMine;

    if (message.kind == MessageKind.callLog) {
      return _buildCallLog(context);
    }

    return Dismissible(
      key: Key('msg_${message.id}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async { onReply(message); return false; },
      background: Container(padding: const EdgeInsets.only(left: 20), alignment: Alignment.centerLeft, child: const Icon(Icons.reply, color: Colors.grey, size: 24)),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.all(10),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          decoration: BoxDecoration(
            color: mine ? AppColors.maroon : Colors.white,
            borderRadius: BorderRadius.circular(16).copyWith(bottomLeft: Radius.circular(mine ? 16 : 4), bottomRight: Radius.circular(mine ? 4 : 16)),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.replyTo != null) _buildReplyPreview(context, message.replyTo!, mine),
              
              if (message.kind == MessageKind.image) 
                _buildImageMsg(context, mine),
              
              if (message.kind == MessageKind.file) 
                _buildFileMsg(context, mine),

              if (message.text != null && message.text!.isNotEmpty && message.kind == MessageKind.text) 
                _buildTextMsg(context, mine),
              
              if (message.caption != null && message.caption!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(message.caption!, style: TextStyle(color: mine ? Colors.white : Colors.black, fontSize: 14)),
                ),

              const SizedBox(height: 2),
              Row(mainAxisSize: MainAxisSize.min, children: [Text(message.time, style: TextStyle(fontSize: 9, color: mine ? Colors.white60 : Colors.black38)), if (mine) ...[const SizedBox(width: 4), const Icon(Icons.done_all, size: 12, color: AppColors.goldLight)]]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextMsg(BuildContext context, bool mine) {
    final text = message.text!;
    final isUrl = text.startsWith('http');

    if (isUrl) {
      return InkWell(
        onTap: () => launchUrl(Uri.parse(text), mode: LaunchMode.externalApplication),
        child: Text(
          text,
          style: TextStyle(
            color: mine ? AppColors.goldLight : Colors.blue,
            decoration: TextDecoration.underline,
            fontSize: 15,
          ),
        ),
      );
    }

    return Text(text, style: TextStyle(color: mine ? Colors.white : Colors.black, fontSize: 15));
  }

  Widget _buildImageMsg(BuildContext context, bool mine) {
    final path = message.text ?? '';
    final isLocal = path.startsWith('/') || path.startsWith('file://');
    
    // Safety check: Only show local file if it's ours OR it actually exists on this device.
    // Otherwise, try to treat it as a network image.
    final bool useLocal = isLocal && (mine || File(path).existsSync());

    return InkWell(
      onTap: () => _openFile(path),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: useLocal 
          ? Image.file(File(path), width: 200, height: 200, fit: BoxFit.cover)
          : Image.network(
              path, 
              width: 200, 
              height: 200, 
              fit: BoxFit.cover, 
              errorBuilder: (ctx, err, stack) => Container(
                width: 200, 
                height: 200, 
                color: Colors.grey.shade200,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 40, color: Colors.grey),
                    SizedBox(height: 4),
                    Text("Image Error", style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildFileMsg(BuildContext context, bool mine) {
    return InkWell(
      onTap: () => _openFile(message.text!),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file, color: mine ? Colors.white : AppColors.maroon, size: 32),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.fileName ?? 'Document',
              style: TextStyle(
                color: mine ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _openFile(String path) {
    try {
      OpenFilex.open(path);
    } catch (e) {
      debugPrint('Error opening file: $e');
    }
  }

  Widget _buildCallLog(BuildContext context) {
    final log = message.callLog!;
    final isMissed = log.isMissed;
    return Center(
      child: GestureDetector(
        onTap: () => onCallRequest(log.isVideo),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                log.isVideo ? Icons.videocam : Icons.call, 
                color: isMissed ? Colors.red : Colors.green, 
                size: 18
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.title, 
                    style: TextStyle(
                      color: isMissed ? Colors.red : Colors.black87, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 13
                    )
                  ),
                  Text(message.time, style: const TextStyle(fontSize: 10, color: Colors.black45)),
                ],
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context, Message original, bool isMineBubble) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMineBubble ? Colors.black26 : Colors.grey.shade100, 
        borderRadius: BorderRadius.circular(8), 
        border: const Border(left: BorderSide(color: AppColors.gold, width: 3))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            original.isMine ? 'You' : 'Other', 
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isMineBubble ? AppColors.goldLight : AppColors.maroon)
          ),
          Text(
            original.snippet, 
            maxLines: 1, 
            overflow: TextOverflow.ellipsis, 
            style: TextStyle(fontSize: 12, color: isMineBubble ? Colors.white70 : Colors.black54)
          ),
        ],
      ),
    );
  }
}
