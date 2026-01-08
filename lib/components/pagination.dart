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
    this.mainColor = const Color.fromRGBO(251, 251, 250, 1),
    this.secondaryColor = const Color.fromRGBO(123, 122, 122, 0.2),
    this.buttonTextStyle = const TextStyle(color: Colors.black, fontSize: 12, decoration: TextDecoration.none),
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
          padding: EdgeInsets.only(top: 5, bottom: 5),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? secondaryColor : mainColor,
            border: Border.all(color: secondaryColor, width: 0.3),
          ),
          child: Text(value, style: buttonTextStyle),
        ),
      ),
    );
  }

  Widget arrow(String name, double width) {
    return InkWell(
      onTap: () {
        if (name == "Prev" && (activePage - 1) >= 1) {
          onSelect(activePage - 1);
        } else if (name == "Next" && (activePage + 1) <= totalPages) {
          onSelect(activePage + 1);
        }
      },
      child: SizedBox(
        width: width,
        height: 30,
        child: name == "Prev"
            ? Row(
                spacing: 5,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_back_ios, size: 15),
                  Text("Prev", style: buttonTextStyle),
                ],
              )
            : Row(
                spacing: 5,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
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
    Size size = MediaQuery.sizeOf(context);
    double buttonWidth = size.width / 25;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: secondaryColor, width: 2.0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          arrow("Prev", buttonWidth),
          ...prevValues.reversed.map((page) => numberBox(page, buttonWidth)),
          ...nextValues.map((page) => numberBox(page, buttonWidth)),
          arrow("Next", buttonWidth),
        ],
      ),
    );
  }
}
