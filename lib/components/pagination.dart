import 'package:flutter/material.dart';
import 'dart:math';

class Pagination extends StatelessWidget {
  final int activePage;
  final int totalPages;
  final Function(int value) onSelect;
  final TextStyle buttonTextStyle;
  final Color mainColor;
  final Color secondaryColor;

  const Pagination({
    super.key,
    required this.activePage,
    required this.totalPages,
    required this.onSelect,
    this.mainColor = const Color.fromRGBO(251, 251, 250, 1),
    this.secondaryColor = const Color.fromRGBO(123, 122, 122, 0.2),
    this.buttonTextStyle = const TextStyle(color: Colors.black, fontSize: 12, decoration: TextDecoration.none),
  });

  /// Build a compact page list: 1 ... 4 5 [6] 7 8 ... 20
  List<String> _buildPageList() {
    final pages = totalPages < 1 ? 1 : totalPages;
    const siblings = 2;

    final items = <String>[];
    final rangeStart = max(2, activePage - siblings);
    final rangeEnd = min(pages - 1, activePage + siblings);

    items.add('1');
    if (rangeStart > 2) items.add('...');
    for (var i = rangeStart; i <= rangeEnd; i++) {
      items.add(i.toString());
    }
    if (rangeEnd < pages - 1) items.add('...');
    if (pages > 1) items.add(pages.toString());

    return items;
  }

  Widget numberBox(String value) {
    int? intValue = int.tryParse(value);
    bool isActive = intValue == activePage;
    return Flexible(
      child: MouseRegion(
        cursor: value == '...' ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            if (intValue != null) onSelect(intValue);
          },
          child: Container(
            constraints: const BoxConstraints(minWidth: 30, maxWidth: 50),
            height: 30,
            padding: const EdgeInsets.only(top: 5, bottom: 5),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isActive ? secondaryColor : mainColor,
              border: Border.all(color: secondaryColor, width: 0.3),
            ),
            child: Text(value, style: buttonTextStyle),
          ),
        ),
      ),
    );
  }

  Widget arrow(String name) {
    return InkWell(
      onTap: () {
        if (name == "Prev" && (activePage - 1) >= 1) {
          onSelect(activePage - 1);
        } else if (name == "Next" && (activePage + 1) <= totalPages) {
          onSelect(activePage + 1);
        }
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 50, maxWidth: 80),
        height: 30,
        child: name == "Prev"
            ? Row(
                spacing: 5,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_back_ios, size: 15),
                  Text("Prev", style: buttonTextStyle),
                ],
              )
            : Row(
                spacing: 5,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Next", style: buttonTextStyle),
                  const Icon(Icons.arrow_forward_ios, size: 15),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageList = _buildPageList();
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: secondaryColor, width: 2.0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          arrow("Prev"),
          ...pageList.map((page) => numberBox(page)),
          arrow("Next"),
        ],
      ),
    );
  }
}
