import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geek_chat/components/chat/message_block.dart';
import 'package:geek_chat/controller/chat_list_controller.dart';
import 'package:geek_chat/controller/chat_message_controller.dart';
import 'package:geek_chat/controller/chat_message_scroll_controller.dart';
import 'package:geek_chat/controller/settings.dart';
import 'package:geek_chat/controller/tracker_controller.dart';
import 'package:geek_chat/models/message.dart';
import 'package:geek_chat/models/session.dart';
import 'package:geek_chat/util/functions.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

// ignore: must_be_immutable
class DeskTopMainRightComponent extends StatelessWidget {
  DeskTopMainRightComponent({super.key, required this.sid}) {
    chatMessageController = Get.find<ChatMessageController>();

    /// init right scroll button
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      scrollController.addListener(() {
        scrollButtonListener();
      });
      scrollButtonListener();
      // questionInputFocus.requestFocus();
    });
  }

  void scrollButtonListener() {
    final extentAfter = scrollController.position.extentAfter;
    bool showGotoTopBtnLocal = chatMessageScrollController.showGotoTopBtn;
    bool showGotoBottomBtnLocal = chatMessageScrollController.showGotoBottomBtn;
    if (extentAfter < 10) {
      showGotoTopBtnLocal = false;
    } else {
      showGotoTopBtnLocal = true;
    }

    if (scrollController.position.maxScrollExtent - extentAfter <= 10) {
      showGotoBottomBtnLocal = false;
    } else {
      showGotoBottomBtnLocal = true;
    }
    if (showGotoBottomBtnLocal !=
        chatMessageScrollController.showGotoBottomBtn) {
      chatMessageScrollController.showGotoBottomBtn = showGotoBottomBtnLocal;
      chatMessageScrollController.update();
    }
    if (showGotoTopBtnLocal != chatMessageScrollController.showGotoTopBtn) {
      chatMessageScrollController.showGotoTopBtn = showGotoTopBtnLocal;
      chatMessageScrollController.update();
    }
  }

  void scrollToTop() async {
    do {
      double delta =
          scrollController.position.maxScrollExtent - scrollController.offset;
      double to = 0;
      if (delta > 50) {
        to = scrollController.offset + delta / 7;
      } else {
        to = scrollController.position.maxScrollExtent;
      }

      await scrollController.animateTo(
        to,
        duration: const Duration(microseconds: 170),
        curve: Curves.linear,
      );
    } while (
        scrollController.position.maxScrollExtent - scrollController.offset >
            20);
  }

  Future<void> scrollToBottom({animate = true}) async {
    int duration = 10;
    if (animate) {
      duration = 500;
    }

    await scrollController.animateTo(
      scrollController.position.minScrollExtent,
      duration: Duration(milliseconds: duration),
      curve: Curves.linear,
    );
  }

  Logger logger = Get.find<Logger>();

  late ChatMessageController chatMessageController;
  ChatListController chatListController = Get.find<ChatListController>();

  ScrollController scrollController = ScrollController();
  ChatMessageScrollController chatMessageScrollController =
      Get.put(ChatMessageScrollController());

  SettingsController settingsController = Get.find<SettingsController>();

  String sid;

  FocusNode questionInputFocus = FocusNode();

  @override
  Widget build(BuildContext context) {
    SessionModel session = chatListController.currentSession;
    chatMessageController.findBySessionId(sid);

    return Container(
      alignment: Alignment.centerLeft,
      width: double.infinity,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(left: 12, right: 20, top: 0),
            alignment: Alignment.centerLeft,
            height: 50,
            width: double.infinity,
            child: Row(
              children: [
                Text(
                  session.name,
                  style: const TextStyle(fontSize: 18),
                ),
                TextButton.icon(
                  onPressed: () {
                    Get.toNamed('/editchat',
                        parameters: {'opt': 'edit', 'sid': session.sid});
                  },
                  icon: const Icon(Icons.tune),
                  label: Text(session.model),
                ),
                const Expanded(
                  child: Text(''),
                ),
                IconButton(
                  onPressed: () {
                    Get.defaultDialog(
                      title: "Clean Session".tr,
                      onCancel: () {
                        Get.back();
                      },
                      onConfirm: () {
                        // onDelete(message);
                        chatMessageController.cleanSessionMessages(
                            chatListController.currentSession.sid);
                        chatMessageController.update();
                        Get.back();
                      },
                      textCancel: "Cancel".tr,
                      textConfirm: "Confirm".tr,
                      middleText: "Confirm clean session?".tr,
                      radius: 5,
                    );
                  },
                  icon: const Icon(Icons.cleaning_services),
                ),
                // IconButton(
                //   onPressed: () {
                //   },
                //   icon: const Icon(Icons.sync),
                // ),
                // IconButton(
                //   onPressed: () {
                //     Get.snackbar(
                //       'Sorry!'.tr,
                //       'This feature will coming soon!'.tr,
                //       duration: const Duration(seconds: 2),
                //       snackPosition: SnackPosition.TOP,
                //     );
                //   },
                //   icon: const Icon(Icons.save),
                // )
                // IconButton(onPressed: () {}, icon: Icon(Icons.edit))
              ],
            ),
          ),
          Expanded(
            child: GetBuilder<ChatMessageController>(builder: (controller) {
              return Stack(
                fit: StackFit.expand,
                alignment: Alignment.topLeft,
                children: [
                  ListView.builder(
                    reverse: true,
                    itemCount: controller.messages.length,
                    controller: scrollController,
                    scrollDirection: Axis.vertical,
                    physics: const ScrollPhysics(),
                    shrinkWrap: true,
                    itemBuilder: (BuildContext ctxt, int index) {
                      return MessageContent(
                          key: GlobalObjectKey(
                              controller.messages.elementAt(index).msgId),
                          message: controller.messages.elementAt(index),
                          deviceType: settingsController.deviceType,
                          session: chatListController.currentSession,
                          onQuote: (MessageModel message) {
                            if (controller
                                .isMessagesTooLong(controller.quoteMessages)) {
                              showCustomToast(
                                  title: "Too many quote messages".tr,
                                  context: context);
                            } else {
                              controller.addQuoteMessage(message);
                              controller.update();
                            }
                            questionInputFocus.requestFocus();
                          },
                          onDelete: (MessageModel message) {
                            //
                            controller.removeMessage(message);
                            controller.update();
                          },
                          moveTo: (MessageModel msg) {
                            logger.d("move to: ${msg.msgId}");
                          });
                    },
                  ),
                  MessageListScrollBtnComponent(
                    scrollToTop: scrollToTop,
                    scrollToBottom: scrollToBottom,
                  )
                ],
              );
            }),
          ),
          Container(
            padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
            child: GetBuilder<ChatMessageController>(builder: (controller) {
              return Container(
                padding: const EdgeInsets.only(top: 1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.only(left: 2, right: 2),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Theme.of(context).colorScheme.primary),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                QuestionInputComponent(
                                  sid: sid,
                                  scrollToBottom: scrollToBottom,
                                  questionInputFocus: questionInputFocus,
                                ),
                                QuoteMessagesComponent(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.only(top: 5, bottom: 3),
                      child: Text(
                        "input tips".tr,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ignore: must_be_immutable
class QuestionInputComponent extends StatelessWidget {
  QuestionInputComponent({
    super.key,
    required this.sid,
    required this.scrollToBottom,
    required this.questionInputFocus,
  });

  String sid;
  Function scrollToBottom;
  FocusNode questionInputFocus;

  TextEditingController textEditingController = TextEditingController();
  ChatListController chatListController = Get.find();
  SettingsController settingsController = Get.find();
  Logger logger = Get.find();
  ChatMessageController chatMessageController = Get.find();
  final TrackerController tracker = Get.find();

  KeyEventResult onKey(FocusNode focusNode, RawKeyEvent event) {
    // if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
    //   logger.d("Enter key is pressed!");
    //   if (event.isShiftPressed) {
    //     logger.d("Shift Enter is pressed!");
    //   } else {
    //     logger.d("Enter key is pressed!");
    //     return KeyEventResult.ignored;
    //   }
    //   return KeyEventResult.handled;
    // }
    // if (event.isKeyPressed(LogicalKeyboardKey.backspace)) {
    //   logger.d("event: $event");
    //   return KeyEventResult.skipRemainingHandlers;
    // }
    // event.physicalKey.is
    if (event.isKeyPressed(LogicalKeyboardKey.enter) &&
        !event.isShiftPressed &&
        !event.isControlPressed &&
        !event.isAltPressed) {
      logger.d("Enter key is pressed!");
      // process submit
      submit(chatMessageController);
      return KeyEventResult.handled;
    } else if (event.isKeyPressed(LogicalKeyboardKey.enter) &&
        event.isShiftPressed) {
      logger.d("Shit + Enter is pressed!");
      return KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  submit(ChatMessageController controller) async {
    await scrollToBottom(animate: false);
    controller.submit(sid, onDone: () {
      chatListController
          .updateSessionLastEdit(chatListController.currentSession);
      chatListController.update();
    }, onError: () {
      chatListController
          .updateSessionLastEdit(chatListController.currentSession);
      chatListController.update();
    });
    tracker.trackEvent("chat", {"uuid": settingsController.settings.uuid});
  }

  @override
  Widget build(BuildContext context) {
    // questionInputFocus.
    // questionInputFocus.attach(context, onKey: onKey);
    questionInputFocus.onKey = onKey;
    return GetBuilder<ChatMessageController>(
        id: 'inputQuestion',
        builder: (controller) {
          textEditingController.text = controller.inputQuestion;
          return TextFormField(
            controller: textEditingController,
            focusNode: questionInputFocus,
            minLines: 1,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
            // keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              suffixIcon: IconButton(
                  onPressed: () async {
                    submit(controller);
                    // await scrollToBottom(animate: false);
                    // controller.submit(sid, onDone: () {
                    //   chatListController.updateSessionLastEdit(
                    //       chatListController.currentSession);
                    //   chatListController.update();
                    // }, onError: () {
                    //   chatListController.updateSessionLastEdit(
                    //       chatListController.currentSession);
                    //   chatListController.update();
                    // });
                  },
                  icon: const Icon(Icons.send)),
            ),
            onChanged: (value) {
              // logger.d("onChanged $value");
              if (controller.isMessagesTooLong(controller.quoteMessages)) {
                showCustomToast(
                    title: "Too many quote messages".tr, context: context);
              }
              controller.inputQuestion = value;
              // controller.update(['inputQuestion']);
            },
            // onSubmitted: (String value) async {
            //   logger.d("onSubmitted $value");
            //   await scrollToBottom(animate: false);
            //   controller.submit(sid, onDone: () {
            //     chatListController
            //         .updateSessionLastEdit(chatListController.currentSession);
            //     chatListController.update();
            //   }, onError: () {
            //     chatListController
            //         .updateSessionLastEdit(chatListController.currentSession);
            //     chatListController.update();
            //   });
            // },
            onTap: () {
              //
            },
          );
        });
  }
}

// ignore: must_be_immutable
class QuoteMessagesComponent extends StatelessWidget {
  QuoteMessagesComponent({super.key});

  ChatListController chatListController = Get.find();
  ChatMessageController chatMessageController = Get.find();

  @override
  Widget build(BuildContext context) {
    if (chatMessageController.quoteMessages.isEmpty) {
      return const SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Wrap(
        spacing: 3,
        runSpacing: 3,
        direction: Axis.horizontal,
        textDirection: TextDirection.ltr,
        children: [
          for (MessageModel message in chatMessageController.quoteMessages)
            InputChip(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              label: SizedBox(
                width: 150,
                child: Text(
                  message.content,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              deleteIcon: const Icon(Icons.cancel_outlined),
              deleteButtonTooltipMessage: "Delete".tr,
              padding: const EdgeInsets.all(0),
              onDeleted: () {
                chatMessageController.removeQuoteMessage(message);
                chatMessageController.update();
              },
            ),
        ],
      ),
    );
  }
}

// ignore: must_be_immutable
class MessageListScrollBtnComponent extends StatelessWidget {
  MessageListScrollBtnComponent(
      {super.key, required this.scrollToTop, required this.scrollToBottom});

  Function scrollToTop;
  Function scrollToBottom;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatMessageScrollController>(builder: (controller) {
      // controller.initScrollButton();
      return Positioned(
        bottom: 20,
        right: 5,
        child: Column(
          children: [
            Opacity(
              opacity: controller.showGotoTopBtn ? 1 : 0,
              child: IconButton(
                onPressed: controller.showGotoTopBtn
                    ? () {
                        scrollToTop();
                      }
                    : null,
                icon: const Icon(Icons.arrow_circle_up_outlined),
              ),
            ),
            Opacity(
              opacity: controller.showGotoBottomBtn ? 1 : 0,
              child: IconButton(
                onPressed: controller.showGotoBottomBtn
                    ? () {
                        scrollToBottom();
                      }
                    : null,
                icon: const Icon(Icons.arrow_circle_down_outlined),
              ),
            ),
          ],
        ),
      );
    });
  }
}
