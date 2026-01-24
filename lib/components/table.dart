import 'dart:math' as math;
import 'package:flutter/material.dart';

abstract class TableSize {
  double minWidth;
  double? maxWidth;
  final double width;

  TableSize({this.width = 100, this.maxWidth, this.minWidth = 100});
}

class FlexSize implements TableSize {
  @override
  double minWidth;
  @override
  double? maxWidth;
  @override
  final double width;

  FlexSize({this.width = 100, this.maxWidth, this.minWidth = 100});
}

class FixedSize implements TableSize {
  @override
  double minWidth;
  @override
  double? maxWidth;
  @override
  final double width;

  FixedSize({this.width = 100, this.maxWidth, this.minWidth = 100});
}

class CustomRow {
  final EdgeInsets padding;
  final EdgeInsets margin;
  double height;
  final List<Widget> children;
  final BoxDecoration? decoration;
  final BoxDecoration? itemDecoration;
  final BorderSide? columnBorder;
  CustomRow({
    required this.children,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
    this.decoration,
    this.itemDecoration,
    this.columnBorder,
    this.height = 50,
  });
}

class CustomTable extends StatelessWidget {
  final Map<int, TableSize> columnWidths;
  final CustomRow? headerRow;
  final List<CustomRow> children;
  final double maxHeight;
  final EdgeInsets padding;
  final BoxDecoration? decoration;
  final MainAxisAlignment rowAlignment;

  const CustomTable({
    super.key,
    required this.columnWidths,
    required this.children,
    required this.maxHeight,
    this.decoration,
    this.padding = EdgeInsets.zero,
    this.rowAlignment = .start,
    this.headerRow,
  });

  Widget row(CustomRow row) {
    return Container(
      height: row.height,
      margin: row.margin,
      decoration: row.decoration,
      child: Row(
        crossAxisAlignment: .center,
        mainAxisAlignment: .center,
        children: row.children.asMap().entries.map((entry) {
          int index = entry.key;
          Widget item = entry.value;
          TableSize size = columnWidths[index] ?? FixedSize();
          bool isFirst = index == 0;
          BorderSide? borderSide = row.columnBorder ?? (row.itemDecoration?.border as Border?)?.top;
          BoxDecoration? cellDecoration = row.itemDecoration;
          if (borderSide != null) {
            cellDecoration = (row.itemDecoration ?? const BoxDecoration()).copyWith(
              border: Border(
                left: isFirst ? borderSide : BorderSide.none,
                right: borderSide,
                top: borderSide,
                bottom: borderSide,
              ),
            );
          }
          return Container(
            padding: row.padding,
            alignment: Alignment.centerLeft,
            constraints: BoxConstraints(minWidth: size.minWidth),
            decoration: cellDecoration,
            width: size is FixedSize ? size.width : null,
            height: row.height,
            child: item,
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.sizeOf(context);
    double headerHeight = headerRow?.height ?? 0;
    double contentHeight = math.max(0, maxHeight - headerHeight);
    return Container(
      padding: padding,
      decoration: decoration,
      width: size.width,
      height: maxHeight,
      child: Column(
        children: [
          if (headerRow != null) row(headerRow!),
          SizedBox(
            width: size.width,
            height: contentHeight,
            child: SingleChildScrollView(child: Column(children: children.map((child) => row(child)).toList())),
          ),
        ],
      ),
    );
  }
}
