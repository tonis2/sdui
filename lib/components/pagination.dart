import 'package:flutter/material.dart';
import 'dart:math';

class Pagination extends StatelessWidget {
  final int activePage;
  final Function(int value) onSelect;
  int totalPages;
  List<String> prevValues = [];
  List<String> nextValues = [];
  TextStyle buttonTextStyle;
  Color mainColor;
  Color secondaryColor;

  int pageColumns = 4;

  Pagination({
    super.key,
    required this.activePage,
    required this.totalPages,
    required this.onSelect,
    this.mainColor = const Color.fromRGBO(250, 172, 39, 1),
    this.secondaryColor = Colors.white,
    this.buttonTextStyle = const TextStyle(color: Colors.black, fontSize: 14, decoration: TextDecoration.none),
  }) {
    totalPages = max(1, totalPages);
    for (var i = activePage; i < (activePage + pageColumns) && i < totalPages; i++) {
      nextValues.add(i.toString());
    }

    for (var i = (activePage - 1); i > activePage - pageColumns; i--) {
      if (i > 1) prevValues.add(i.toString());
    }

    if (activePage - pageColumns + 1 >= 1) {
      prevValues.add("...");
    }

    if (activePage != 1) {
      prevValues.add("1");
    }

    if (prevValues.length < totalPages) {
      nextValues.add("...");
    }

    nextValues.add(totalPages.toString());
  }

  Widget numberBox(String value, double width) {
    int? intValue = int.tryParse(value);
    bool isActive = intValue == activePage;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (value != "...") {
            onSelect(intValue!);
          }
        },
        child: Container(
          width: width,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? mainColor : secondaryColor,
            border: Border.all(color: Colors.black, width: 0.1, strokeAlign: BorderSide.strokeAlignOutside),
          ),
          child: Text(value, style: buttonTextStyle.copyWith(color: isActive ? secondaryColor : buttonTextStyle.color)),
        ),
      ),
    );
  }

  Widget arrow(String name, double width) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (name == "Prev" && (activePage - 1) >= 1) {
            onSelect(activePage - 1);
          } else if (name == "Next" && (activePage + 1) <= totalPages) {
            onSelect(activePage + 1);
          }
        },
        child: Container(
          width: width * 2,
          height: 30,
          decoration: BoxDecoration(
            color: secondaryColor,
            border: Border.all(color: Colors.black, width: 0.1, strokeAlign: BorderSide.strokeAlignOutside),
          ),
          child: name == "Prev"
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_back_ios, size: 20),
                    Text("Prev", style: buttonTextStyle),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Next", style: buttonTextStyle),
                    const Icon(Icons.arrow_forward_ios, size: 20),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double buttonWidth = constraints.maxWidth / 20;

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            arrow("Prev", buttonWidth),
            ...prevValues.reversed.map((page) => numberBox(page, buttonWidth)),
            ...nextValues.map((page) => numberBox(page, buttonWidth)),
            arrow("Next", buttonWidth),
          ],
        );
      },
    );
  }
}
